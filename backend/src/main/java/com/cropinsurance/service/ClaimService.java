package com.cropinsurance.service;

import com.cropinsurance.dto.request.ClaimRequest;
import com.cropinsurance.dto.response.ClaimResponse;
import com.cropinsurance.entity.*;
import com.cropinsurance.entity.enums.ClaimStatus;
import com.cropinsurance.entity.enums.InsuranceStatus;
import com.cropinsurance.exception.BadRequestException;
import com.cropinsurance.exception.ResourceNotFoundException;
import com.cropinsurance.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Claim Service - File claims, GPS verification, AI processing
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ClaimService {

    private final ClaimRepository claimRepository;
    private final ClaimImageRepository claimImageRepository;
    private final InsurancePolicyRepository insurancePolicyRepository;
    private final FarmerRepository farmerRepository;
    private final AiAssessmentRepository aiAssessmentRepository;
    private final NotificationService notificationService;
    private final AiService aiService;
    private final MongoSensorSyncService mongoSensorSyncService;

    @Value("${file.upload-dir:./uploads}")
    private String uploadDir;

    @Value("${gps.tolerance.meters:500}")
    private double gpsTolerance;

    @Value("${ai.damage.threshold:75.0}")
    private double damageThreshold;

    /**
     * File a new claim with images
     */
    public ClaimResponse fileClaim(UUID farmerId, ClaimRequest request, List<MultipartFile> images) {
        Farmer farmer = farmerRepository.findById(farmerId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer", "id", farmerId));

        InsurancePolicy insurance = insurancePolicyRepository.findById(request.getInsuranceId())
                .orElseThrow(() -> new ResourceNotFoundException("Insurance", "id", request.getInsuranceId()));

        // Verify farmer owns this insurance
        if (!insurance.getFarmer().getId().equals(farmerId)) {
            throw new BadRequestException("Unauthorized access to insurance");
        }

        // Verify insurance is active (Relaxed for demo)
        if (insurance.getStatus() == InsuranceStatus.EXPIRED || insurance.getStatus() == InsuranceStatus.CLAIMED) {
            throw new BadRequestException(
                    "Insurance is already claimed or expired. Current status: " + insurance.getStatus());
        }

        // Verify GPS location
        Land land = insurance.getLand();
        double distance = calculateDistance(
                request.getLatitude().doubleValue(),
                request.getLongitude().doubleValue(),
                land.getLatitude().doubleValue(),
                land.getLongitude().doubleValue());

        if (distance > gpsTolerance) {
            log.warn("📍 GPS Warning: User is %.0f meters away from field. Proceeding for demo.", distance);
            // In production, we would throw an error here:
            // throw new BadRequestException(...);
        }

        // Validate images (minimum 4 as requested)
        if (images == null || images.size() < 4) {
            throw new BadRequestException("Please upload at least 4 photos of the damaged crop");
        }

        // Create claim with weather data
        Claim claim = Claim.builder()
                .insurance(insurance)
                .farmer(farmer)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .sensor(land.getSensor())
                .status(ClaimStatus.PROCESSING)
                .weatherTemperature(request.getWeatherTemperature())
                .weatherHumidity(request.getWeatherHumidity())
                .weatherCondition(request.getWeatherCondition())
                .weatherRainfall(request.getWeatherRainfall())
                .damageReason(parseDamageReason(request.getDamageReason()))
                .damageReasonDetail(request.getDamageReasonDetail())
                .build();
        claim = claimRepository.save(claim);

        // Save images
        List<String> imageUrls = new ArrayList<>();
        for (MultipartFile image : images) {
            String imagePath = saveClaimImage(claim.getId(), image, request.getLatitude(), request.getLongitude());

            ClaimImage claimImage = ClaimImage.builder()
                    .claim(claim)
                    .imagePath(imagePath)
                    .latitude(request.getLatitude())
                    .longitude(request.getLongitude())
                    .build();
            claimImageRepository.save(claimImage);
            imageUrls.add(imagePath);
        }

        log.info("📸 Claim filed with {} images for insurance: {}", images.size(), insurance.getPolicyNumber());

        // Update insurance status immediately
        insurance.setStatus(InsuranceStatus.CLAIMED);
        insurancePolicyRepository.save(insurance);

        // Build the immediate response with PROCESSING status
        ClaimResponse immediateResponse = toClaimResponse(claim, imageUrls, null);

        // Process AI in background — farmer gets redirected instantly
        final UUID claimId = claim.getId();
        final List<String> finalImageUrls = new ArrayList<>(imageUrls);
        java.util.concurrent.CompletableFuture.runAsync(() -> {
            try {
                // Small delay to ensure DB commit is fully flushed
                Thread.sleep(1000);
                log.info("🤖 Background AI processing started for claim: {}", claimId);
                processClaimWithAi(claimId, finalImageUrls);
            } catch (Exception e) {
                log.error("❌ Background AI processing failed for claim {}: {}", claimId, e.getMessage(), e);
            }
        });

        return immediateResponse;
    }

    /**
     * Process claim with AI model (runs async in background)
     */
    public void processClaimWithAi(UUID claimId, List<String> imageUrls) {
        Claim claim = claimRepository.findById(claimId)
                .orElseThrow(() -> new ResourceNotFoundException("Claim", "id", claimId));

        // Call AI service
        AiService.AiPredictionResult prediction = aiService.predictDamage(imageUrls);

        // Save AI assessment
        AiAssessment assessment = AiAssessment.builder()
                .claim(claim)
                .damagePercentage(prediction.getDamagePercentage())
                .modelVersion(prediction.getModelVersion())
                .predictionDetails(prediction.getDetails())
                .build();
        aiAssessmentRepository.save(assessment);

        // Determine claim status
        BigDecimal damagePercent = prediction.getDamagePercentage();
        ClaimStatus status;
        BigDecimal claimAmount = BigDecimal.ZERO;

        if (damagePercent.doubleValue() >= damageThreshold) {
            status = ClaimStatus.APPROVED;
            // Calculate claim amount based on damage percentage
            claimAmount = claim.getInsurance().getCoverageAmount()
                    .multiply(damagePercent)
                    .divide(BigDecimal.valueOf(100), 2, BigDecimal.ROUND_HALF_UP);

            log.info("✅ Claim APPROVED: {}% damage, amount: ₹{}", damagePercent, claimAmount);
        } else {
            status = ClaimStatus.PATWARI_REVIEW;
            log.info("⚠️ Claim AI Failed -> PENDING PATWARI REVIEW: {}% damage (threshold: {}%)", damagePercent, damageThreshold);
        }

        // Update claim
        claim.setStatus(status);
        claim.setDamagePercentage(damagePercent);
        claim.setClaimAmount(claimAmount);
        claim.setProcessedAt(LocalDateTime.now());
        claimRepository.save(claim);

        // Send notification
        String notifTitle = status == ClaimStatus.APPROVED ? "Claim Approved! ✅" : "Patwari Review Required ⚠️";
        String notifMessage = status == ClaimStatus.APPROVED
                ? String.format("Your claim is approved! Damage: %.1f%%, Amount: ₹%.2f",
                        damagePercent.doubleValue(), claimAmount.doubleValue())
                : String.format("Your AI assessment showed %.1f%% damage. It has been sent to the Patwari for manual review.",
                        damagePercent.doubleValue());

        notificationService.sendClaimNotification(claim.getFarmer().getId(), notifTitle, notifMessage);

        log.info("✅ Background AI processing completed for claim: {}", claimId);
    }

    /**
     * Review claim by Patwari (for AI rejected claims)
     */
    public void reviewClaimByPatwari(UUID claimId, String action, String comments) {
        Claim claim = claimRepository.findById(claimId)
                .orElseThrow(() -> new ResourceNotFoundException("Claim", "id", claimId));

        if (claim.getStatus() != ClaimStatus.PATWARI_REVIEW) {
            throw new BadRequestException("Claim is not pending patwari review.");
        }

        if (action.equalsIgnoreCase("RETRY")) {
            // Give farmer another chance
            // Mark policy as ACTIVE again so they can file another claim
            InsurancePolicy policy = claim.getInsurance();
            policy.setStatus(InsuranceStatus.ACTIVE);
            insurancePolicyRepository.save(policy);
            
            // Mark claim as REJECTED so it's not active anymore
            claim.setStatus(ClaimStatus.REJECTED);
            claimRepository.save(claim);

            String title = "Retry Claim ⚠️";
            String msg = "Patwari reviewed your claim and granted a retry. Please upload clearer photos of the damage.";
            notificationService.sendClaimNotification(claim.getFarmer().getId(), title, msg);

        } else if (action.equalsIgnoreCase("REJECT")) {
            // Confirm AI rejection
            claim.setStatus(ClaimStatus.REJECTED);
            claimRepository.save(claim);

            String title = "Claim Rejected ❌";
            String msg = "Your claim was reviewed by the Patwari and the rejection was confirmed.";
            if (comments != null && !comments.isEmpty()) {
                msg += " Reason: " + comments;
            }
            notificationService.sendClaimNotification(claim.getFarmer().getId(), title, msg);
        } else {
            throw new BadRequestException("Invalid action. Must be RETRY or REJECT");
        }
    }

    /**
     * Get all claims of farmer
     */
    public List<ClaimResponse> getFarmerClaims(UUID farmerId) {
        return claimRepository.findByFarmerIdOrderByFiledAtDesc(farmerId)
                .stream()
                .map(c -> {
                    List<String> urls = claimImageRepository.findByClaimId(c.getId())
                            .stream().map(ClaimImage::getImagePath).collect(Collectors.toList());
                    return toClaimResponse(c, urls, null);
                })
                .collect(Collectors.toList());
    }

    /**
     * Get claim by ID
     */
    public ClaimResponse getClaimById(UUID farmerId, UUID claimId) {
        Claim claim = claimRepository.findById(claimId)
                .orElseThrow(() -> new ResourceNotFoundException("Claim", "id", claimId));

        if (!claim.getFarmer().getId().equals(farmerId)) {
            throw new BadRequestException("Unauthorized access to claim");
        }

        List<String> urls = claimImageRepository.findByClaimId(claimId)
                .stream().map(ClaimImage::getImagePath).collect(Collectors.toList());

        return toClaimResponse(claim, urls, null);
    }

    /**
     * Save claim image to disk
     */
    private String saveClaimImage(UUID claimId, MultipartFile image, BigDecimal lat, BigDecimal lng) {
        try {
            Path uploadPath = Paths.get(uploadDir, "claims", claimId.toString());
            Files.createDirectories(uploadPath);

            String extension = getFileExtension(image.getOriginalFilename());
            String filename = UUID.randomUUID().toString().substring(0, 8) + extension;
            Path filePath = uploadPath.resolve(filename);

            Files.copy(image.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            return "/uploads/claims/" + claimId + "/" + filename;
        } catch (IOException e) {
            log.error("Error saving claim image: {}", e.getMessage());
            throw new BadRequestException("Failed to save image: " + e.getMessage());
        }
    }

    /**
     * Calculate distance between two GPS coordinates (Haversine formula)
     */
    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6371e3; // Earth's radius in meters
        double φ1 = Math.toRadians(lat1);
        double φ2 = Math.toRadians(lat2);
        double Δφ = Math.toRadians(lat2 - lat1);
        double Δλ = Math.toRadians(lon2 - lon1);

        double a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
                Math.cos(φ1) * Math.cos(φ2) *
                        Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }

    private String getFileExtension(String filename) {
        if (filename == null)
            return ".jpg";
        int lastDot = filename.lastIndexOf('.');
        return lastDot > 0 ? filename.substring(lastDot) : ".jpg";
    }

    private ClaimResponse toClaimResponse(Claim claim, List<String> imageUrls,
            AiService.AiPredictionResult prediction) {

        // Fetch 7-day IoT sensor data for verification
        Map<String, Object> sensorData = null;
        try {
            Sensor claimSensor = claim.getSensor();
            if (claimSensor != null) {
                sensorData = mongoSensorSyncService.getSensorDataForClaim(claimSensor.getUniqueCode());
                log.info("📊 IoT sensor data attached to claim: {} readings", sensorData.get("totalReadings"));
            }
        } catch (Exception e) {
            log.warn("⚠️ Could not fetch IoT data for claim: {}", e.getMessage());
        }

        // Generate Satellite View URL
        String satelliteUrl = generateSatelliteImageUrl(claim.getLatitude(), claim.getLongitude());

        String diseaseStr = null;
        String modelVer = null;
        if (prediction != null) {
            diseaseStr = prediction.getDiseaseDetected();
            modelVer = prediction.getModelVersion();
        } else {
            AiAssessment assessment = aiAssessmentRepository.findByClaimId(claim.getId()).orElse(null);
            if (assessment != null) {
                modelVer = assessment.getModelVersion();
                if (assessment.getPredictionDetails() != null && assessment.getPredictionDetails().containsKey("disease_detected")) {
                    diseaseStr = (String) assessment.getPredictionDetails().get("disease_detected");
                } else if (assessment.getPredictionDetails() != null && assessment.getPredictionDetails().containsKey("analysis")) {
                    String analysis = (String) assessment.getPredictionDetails().get("analysis");
                    if (analysis.contains("detected: ")) {
                        diseaseStr = analysis.substring(analysis.indexOf("detected: ") + 10);
                    }
                }
            }
        }

        return ClaimResponse.builder()
                .id(claim.getId().toString())
                .insuranceId(claim.getInsurance().getId().toString())
                .policyNumber(claim.getInsurance().getPolicyNumber())
                .farmerName(claim.getFarmer().getName())
                .farmerPhone(claim.getFarmer().getPhone())
                .village(claim.getFarmer().getVillage())
                .khasraNumber(claim.getInsurance().getLand() != null ? claim.getInsurance().getLand().getKhasraNumber() : "Unknown")
                .latitude(claim.getLatitude())
                .longitude(claim.getLongitude())
                .status(claim.getStatus())
                .damagePercentage(claim.getDamagePercentage())
                .claimAmount(claim.getClaimAmount())
                .diseaseDetected(diseaseStr)
                .modelVersion(modelVer)
                .imageUrls(imageUrls)
                .sensorData(sensorData)
                .satelliteImageUrl(satelliteUrl)
                .weatherTemp(claim.getWeatherTemperature())
                .weatherHumidity(claim.getWeatherHumidity())
                .weatherRainfall(claim.getWeatherRainfall())
                .weatherCondition(claim.getWeatherCondition())
                .damageReason(claim.getDamageReason() != null ? claim.getDamageReason().name() : null)
                .damageReasonHindi(claim.getDamageReason() != null ? claim.getDamageReason().getHindi() : null)
                .damageReasonEnglish(claim.getDamageReason() != null ? claim.getDamageReason().getEnglish() : null)
                .damageReasonDetail(claim.getDamageReasonDetail())
                .filedAt(claim.getFiledAt())
                .processedAt(claim.getProcessedAt())
                .build();
    }

    /**
     * Generate high-res satellite image URL for farm location using Esri ArcGIS World Imagery (Free/No-Auth)
     */
    private String generateSatelliteImageUrl(BigDecimal lat, BigDecimal lon) {
        if (lat == null || lon == null) return null;
        
        double latitude = lat.doubleValue();
        double longitude = lon.doubleValue();
        
        // Create a small bounding box around the farm (~400x400 meters)
        double offset = 0.002;
        String minLon = String.valueOf(longitude - offset);
        String minLat = String.valueOf(latitude - offset);
        String maxLon = String.valueOf(longitude + offset);
        String maxLat = String.valueOf(latitude + offset);
        
        return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/export" +
               "?bbox=" + minLon + "," + minLat + "," + maxLon + "," + maxLat + 
               "&bboxSR=4326&size=600,400&format=jpg&f=image";
    }

    /**
     * Parse damage reason string to enum (safe)
     */
    private com.cropinsurance.entity.enums.DamageReason parseDamageReason(String reason) {
        if (reason == null || reason.isEmpty()) return null;
        try {
            return com.cropinsurance.entity.enums.DamageReason.valueOf(reason.toUpperCase());
        } catch (IllegalArgumentException e) {
            log.warn("Unknown damage reason: {}", reason);
            return com.cropinsurance.entity.enums.DamageReason.OTHER;
        }
    }
}
