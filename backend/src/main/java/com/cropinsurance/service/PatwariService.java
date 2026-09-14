package com.cropinsurance.service;

import com.cropinsurance.dto.request.KhasraActionRequest;
import com.cropinsurance.dto.request.VerificationActionRequest;
import com.cropinsurance.dto.response.KhasraRequestResponse;
import com.cropinsurance.dto.response.PendingVerificationDTO;
import com.cropinsurance.entity.*;
import com.cropinsurance.entity.enums.VerificationStatus;
import com.cropinsurance.exception.BadRequestException;
import com.cropinsurance.exception.ResourceNotFoundException;
import com.cropinsurance.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Patwari Service - Verification and sensor assignment
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PatwariService {

    private final PatwariRepository patwariRepository;
    private final VerificationRepository verificationRepository;
    private final SensorRepository sensorRepository;
    private final LandRepository landRepository;
    private final InsuranceService insuranceService;
    private final NotificationService notificationService;
    private final KhasraRequestRepository khasraRequestRepository;
    private final KhasraRegistryRepository khasraRegistryRepository;
    private final VillageRepository villageRepository;

    /**
     * Get pending verifications
     */
    public List<PendingVerificationDTO> getPendingVerifications(UUID patwariId) {
        // For prototype, show all pending (in real app, filter by patwari's area)
        return verificationRepository.findPendingVerifications()
                .stream()
                .map(this::toVerificationDTO)
                .collect(Collectors.toList());
    }

    /**
     * Get verification by ID
     */
    public PendingVerificationDTO getVerificationById(UUID patwariId, UUID verificationId) {
        Verification verification = verificationRepository.findById(verificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Verification", "id", verificationId));
        return toVerificationDTO(verification);
    }

    /**
     * Process verification (approve/reject)
     */
    @Transactional
    public PendingVerificationDTO processVerification(UUID patwariId, VerificationActionRequest request) {
        Patwari patwari = patwariRepository.findById(patwariId)
                .orElseThrow(() -> new ResourceNotFoundException("Patwari", "id", patwariId));

        Verification verification = verificationRepository.findById(request.getVerificationId())
                .orElseThrow(() -> new ResourceNotFoundException("Verification", "id", request.getVerificationId()));

        if (verification.getStatus() != VerificationStatus.PENDING) {
            throw new BadRequestException("Verification already processed");
        }

        verification.setPatwari(patwari);
        verification.setStatus(request.getStatus());
        verification.setRemarks(request.getRemarks());
        verification.setVerifiedAt(LocalDateTime.now());

        InsurancePolicy insurance = verification.getInsurance();
        Farmer farmer = insurance.getFarmer();

        if (request.getStatus() == VerificationStatus.APPROVED) {
            // Assign sensor if provided
            if (request.getSensorCode() != null) {
                Sensor sensor = sensorRepository.findByUniqueCode(request.getSensorCode())
                        .orElseThrow(() -> new ResourceNotFoundException("Sensor", "code", request.getSensorCode()));

                // For prototype: Allow reusing the single sensor for all lands
                // if (sensor.getLand() != null) {
                //     throw new BadRequestException("Sensor is already assigned to another land");
                // }

                Land land = insurance.getLand();
                land.setSensor(sensor);
                landRepository.save(land);

                verification.setAssignedSensorId(sensor.getId());
                log.info("📡 Sensor {} assigned to land {}", sensor.getUniqueCode(), land.getKhasraNumber());
            }

            // Activate insurance
            insuranceService.activateInsurance(insurance.getId());

            // Notify farmer
            notificationService.sendVerificationNotification(
                    farmer.getId(),
                    "Insurance Verified! ✅",
                    "Your insurance " + insurance.getPolicyNumber() + " has been verified and activated.");

            log.info("✅ Insurance {} approved by patwari {}", insurance.getPolicyNumber(), patwari.getName());

        } else {
            // Rejected
            notificationService.sendVerificationNotification(
                    farmer.getId(),
                    "Verification Rejected ❌",
                    "Your insurance " + insurance.getPolicyNumber() + " verification was rejected. Reason: " +
                            request.getRemarks());

            log.info("❌ Insurance {} rejected by patwari {}: {}",
                    insurance.getPolicyNumber(), patwari.getName(), request.getRemarks());
        }

        verificationRepository.save(verification);
        return toVerificationDTO(verification);
    }

    /**
     * Get available sensors
     */
    @org.springframework.transaction.annotation.Transactional
    public List<Sensor> getAvailableSensors() {
        List<Sensor> sensors = new java.util.ArrayList<>(sensorRepository.findAvailableSensors());
        
        // Auto-provision default prototype sensors if DB is totally empty
        if (sensors.isEmpty()) {
            log.warn("⚠️ No sensors found in DB! Auto-creating prototype sensors...");
            for (int i = 1; i <= 5; i++) {
                String code = "SENS-00" + i;
                try {
                    if (!sensorRepository.existsByUniqueCode(code)) {
                        Sensor defaultSensor = new Sensor();
                        defaultSensor.setUniqueCode(code);
                        defaultSensor.setIsActive(true);
                        defaultSensor = sensorRepository.saveAndFlush(defaultSensor);
                        sensors.add(defaultSensor);
                        log.info("✅ Auto-created sensor: {}", code);
                    } else {
                        // Already exists, just fetch it
                        sensorRepository.findByUniqueCode(code).ifPresent(sensors::add);
                        log.info("📡 Sensor {} already exists, reusing", code);
                    }
                } catch (Exception e) {
                    log.warn("⚠️ Could not create sensor {}: {}", code, e.getMessage());
                    // Try to fetch existing one
                    sensorRepository.findByUniqueCode(code).ifPresent(sensors::add);
                }
            }
        }
        
        log.info("🔍 Available sensors count: {}", sensors.size());
        sensors.forEach(s -> log.info("  📡 Sensor: {} (id={})", s.getUniqueCode(), s.getId()));
        return sensors;
    }

    /**
     * Get dashboard stats
     */
    public Object getDashboardStats(UUID patwariId) {
        Map<String, Object> stats = new HashMap<>();

        long pending = verificationRepository.findByStatus(VerificationStatus.PENDING).size();
        long approved = verificationRepository.findByStatus(VerificationStatus.APPROVED).size();
        long rejected = verificationRepository.findByStatus(VerificationStatus.REJECTED).size();
        long availableSensors = getAvailableSensors().size(); // Use the method that auto-provisions if empty

        stats.put("pendingVerifications", pending);
        stats.put("approvedVerifications", approved);
        stats.put("rejectedVerifications", rejected);
        stats.put("availableSensors", availableSensors);
        stats.put("totalProcessed", approved + rejected);

        return stats;
    }

    private PendingVerificationDTO toVerificationDTO(Verification v) {
        InsurancePolicy ins = v.getInsurance();
        Land land = ins.getLand();
        Farmer farmer = ins.getFarmer();

        return PendingVerificationDTO.builder()
                .verificationId(v.getId().toString())
                .insuranceId(ins.getId().toString())
                .policyNumber(ins.getPolicyNumber())
                .farmerName(farmer.getName())
                .farmerPhone(farmer.getPhone())
                .farmerAddress(farmer.getAddress())
                .khasraNumber(land.getKhasraNumber())
                .areaAcres(land.getAreaAcres())
                .latitude(land.getLatitude())
                .longitude(land.getLongitude())
                .state(farmer.getState())
                .district(farmer.getDistrict())
                .village(farmer.getVillage())
                .cropType(ins.getCropType())
                .premiumAmount(ins.getPremiumAmount())
                .coverageAmount(ins.getCoverageAmount())
                .status(v.getStatus())
                .createdAt(ins.getCreatedAt())
                .build();
    }

    // ==========================================
    // KHASRA REQUEST HANDLING
    // ==========================================

    /**
     * Get pending khasra requests
     */
    public List<KhasraRequestResponse> getPendingKhasraRequests() {
        return khasraRequestRepository.findByStatusOrderByCreatedAtAsc("PENDING")
                .stream()
                .map(this::toKhasraRequestResponse)
                .collect(Collectors.toList());
    }

    /**
     * Process khasra request (approve/reject)
     */
    @Transactional
    public KhasraRequestResponse processKhasraRequest(UUID patwariId, KhasraActionRequest request) {
        KhasraRequest khasraRequest = khasraRequestRepository.findById(request.getRequestId())
                .orElseThrow(() -> new ResourceNotFoundException("KhasraRequest", "id", request.getRequestId()));

        if (!"PENDING".equals(khasraRequest.getStatus())) {
            throw new BadRequestException("Khasra request already processed");
        }

        khasraRequest.setStatus(request.getAction());
        khasraRequest.setPatwariRemarks(request.getRemarks());
        khasraRequest.setProcessedAt(java.time.LocalDateTime.now());

        if ("APPROVED".equals(request.getAction())) {
            // Auto-create khasra_registry entry
            Village village = villageRepository.findByName(khasraRequest.getVillage()).orElse(null);

            if (village != null) {
                KhasraRegistry existingKhasra = khasraRegistryRepository
                        .findByVillageIdAndKhasraNumber(village.getId(), khasraRequest.getKhasraNumber())
                        .orElse(null);

                if (existingKhasra == null) {
                    KhasraRegistry newKhasra = KhasraRegistry.builder()
                            .village(village)
                            .khasraNumber(khasraRequest.getKhasraNumber())
                            .areaAcres(khasraRequest.getAreaAcres())
                            .latitude(khasraRequest.getLatitude())
                            .longitude(khasraRequest.getLongitude())
                            .ownerName(khasraRequest.getFarmer().getName())
                            .isRegistered(false)
                            .build();
                    khasraRegistryRepository.save(newKhasra);
                    log.info("✅ Khasra {} added to registry after Patwari approval (Village: {})", khasraRequest.getKhasraNumber(), village.getName());
                } else {
                    existingKhasra.setOwnerName(khasraRequest.getFarmer().getName());
                    khasraRegistryRepository.save(existingKhasra);
                    log.info("✅ Khasra {} updated in registry after Patwari approval (Village: {})", khasraRequest.getKhasraNumber(), village.getName());
                }
            } else {
                log.error("❌ CRITICAL: Could not find DB Village for name '{}'. Khasra was NOT added to registry!", 
                    khasraRequest.getVillage());
            }

            // Notify farmer
            notificationService.sendInsuranceNotification(
                    khasraRequest.getFarmer().getId(),
                    "Land Approved! ✅",
                    "Your khasra " + khasraRequest.getKhasraNumber() + " has been verified. You can now apply for insurance.");
        } else {
            // Notify farmer of rejection
            notificationService.sendInsuranceNotification(
                    khasraRequest.getFarmer().getId(),
                    "Land Request Rejected ❌",
                    "Your khasra " + khasraRequest.getKhasraNumber() + " was rejected. Reason: " + request.getRemarks());
        }

        khasraRequestRepository.save(khasraRequest);
        log.info("📋 Khasra request {} processed: {}", khasraRequest.getKhasraNumber(), request.getAction());

        return toKhasraRequestResponse(khasraRequest);
    }

    private KhasraRequestResponse toKhasraRequestResponse(KhasraRequest r) {
        return KhasraRequestResponse.builder()
                .id(r.getId().toString())
                .farmerId(r.getFarmer().getId().toString())
                .farmerName(r.getFarmer().getName())
                .farmerPhone(r.getFarmer().getPhone())
                .village(r.getVillage())
                .khasraNumber(r.getKhasraNumber())
                .areaAcres(r.getAreaAcres())
                .latitude(r.getLatitude())
                .longitude(r.getLongitude())
                .status(r.getStatus())
                .patwariRemarks(r.getPatwariRemarks())
                .createdAt(r.getCreatedAt())
                .processedAt(r.getProcessedAt())
                .build();
    }
}
