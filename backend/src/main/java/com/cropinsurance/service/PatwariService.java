package com.cropinsurance.service;

import com.cropinsurance.dto.request.VerificationActionRequest;
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

                if (sensor.getLand() != null) {
                    throw new BadRequestException("Sensor is already assigned to another land");
                }

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
    public List<Sensor> getAvailableSensors() {
        return sensorRepository.findAvailableSensors();
    }

    /**
     * Get dashboard stats
     */
    public Object getDashboardStats(UUID patwariId) {
        Map<String, Object> stats = new HashMap<>();

        long pending = verificationRepository.findByStatus(VerificationStatus.PENDING).size();
        long approved = verificationRepository.findByStatus(VerificationStatus.APPROVED).size();
        long rejected = verificationRepository.findByStatus(VerificationStatus.REJECTED).size();
        long availableSensors = sensorRepository.findAvailableSensors().size();

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
}
