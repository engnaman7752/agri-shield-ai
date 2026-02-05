package com.cropinsurance.service;

import com.cropinsurance.dto.response.ClaimResponse;
import com.cropinsurance.entity.enums.ClaimStatus;
import com.cropinsurance.entity.enums.InsuranceStatus;
import com.cropinsurance.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final FarmerRepository farmerRepository;
    private final InsurancePolicyRepository insurancePolicyRepository;
    private final ClaimRepository claimRepository;
    private final SensorRepository sensorRepository;
    private final ClaimService claimService;

    public Map<String, Object> getGlobalStats() {
        Map<String, Object> stats = new HashMap<>();

        long totalFarmers = farmerRepository.count();
        long activePolicies = insurancePolicyRepository.findByStatus(InsuranceStatus.ACTIVE).size();

        BigDecimal totalCoverage = insurancePolicyRepository.findAll().stream()
                .filter(p -> p.getStatus() == InsuranceStatus.ACTIVE)
                .map(p -> p.getCoverageAmount())
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long pendingVerifications = insurancePolicyRepository.findByStatus(InsuranceStatus.PAID).size();

        long totalClaims = claimRepository.count();
        long approvedClaims = claimRepository.findAll().stream()
                .filter(c -> c.getStatus() == ClaimStatus.APPROVED).count();
        long rejectedClaims = claimRepository.findAll().stream()
                .filter(c -> c.getStatus() == ClaimStatus.REJECTED).count();

        stats.put("totalFarmers", totalFarmers);
        stats.put("activePolicies", activePolicies);
        stats.put("totalCoverage", totalCoverage);
        stats.put("pendingVerifications", pendingVerifications);
        stats.put("totalClaims", totalClaims);
        stats.put("approvedClaims", approvedClaims);
        stats.put("rejectedClaims", rejectedClaims);
        stats.put("sensorCount", sensorRepository.count());
        stats.put("availableSensors", sensorRepository.findAvailableSensors().size());

        return stats;
    }

    public List<ClaimResponse> getAllClaims() {
        // Reuse existing logic but for all farmers
        return claimRepository.findAll().stream()
                .map(c -> claimService.getClaimById(c.getFarmer().getId(), c.getId()))
                .collect(Collectors.toList());
    }
}
