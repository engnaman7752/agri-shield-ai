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

    @Value("${file.upload-dir:./uploads}")
    private String uploadDir;

    @Value("${gps.tolerance.meters:500}")
    private double gpsTolerance;

    @Value("${ai.damage.threshold:75.0}")
    private double damageThreshold;

    /**
     * File a new claim with images
     */
    @Transactional
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

        // Create claim
        Claim claim = Claim.builder()
                .insurance(insurance)
                .farmer(farmer)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .sensor(land.getSensor())
                .status(ClaimStatus.PROCESSING)
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

        // Process with AI (async in real app, sync for prototype)
        ClaimResponse response = processClaimWithAi(claim, imageUrls);

        // Update insurance status
        insurance.setStatus(InsuranceStatus.CLAIMED);
        insurancePolicyRepository.save(insurance);

        return response;
    }

    /**
     * Process claim with AI model
     */
    private ClaimResponse processClaimWithAi(Claim claim, List<String> imageUrls) {
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
            status = ClaimStatus.REJECTED;
            log.info("❌ Claim REJECTED: {}% damage (threshold: {}%)", damagePercent, damageThreshold);
        }

        // Update claim
        claim.setStatus(status);
        claim.setDamagePercentage(damagePercent);
        claim.setClaimAmount(claimAmount);
        claim.setProcessedAt(LocalDateTime.now());
        claimRepository.save(claim);

        // Send notification
        String notifTitle = status == ClaimStatus.APPROVED ? "Claim Approved! ✅" : "Claim Rejected ❌";
        String notifMessage = status == ClaimStatus.APPROVED
                ? String.format("Your claim is approved! Damage: %.1f%%, Amount: ₹%.2f",
                        damagePercent.doubleValue(), claimAmount.doubleValue())
                : String.format("Your claim is rejected. Damage detected: %.1f%% (minimum: %.0f%% required)",
                        damagePercent.doubleValue(), damageThreshold);

        notificationService.sendClaimNotification(claim.getFarmer().getId(), notifTitle, notifMessage);

        return toClaimResponse(claim, imageUrls, prediction);
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
        return ClaimResponse.builder()
                .id(claim.getId().toString())
                .insuranceId(claim.getInsurance().getId().toString())
                .policyNumber(claim.getInsurance().getPolicyNumber())
                .latitude(claim.getLatitude())
                .longitude(claim.getLongitude())
                .status(claim.getStatus())
                .damagePercentage(claim.getDamagePercentage())
                .claimAmount(claim.getClaimAmount())
                .diseaseDetected(prediction != null ? prediction.getDiseaseDetected() : null)
                .modelVersion(prediction != null ? prediction.getModelVersion() : null)
                .imageUrls(imageUrls)
                .filedAt(claim.getFiledAt())
                .processedAt(claim.getProcessedAt())
                .build();
    }
}
