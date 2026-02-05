package com.cropinsurance.dto.response;

import com.cropinsurance.entity.enums.ClaimStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Claim Response
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClaimResponse {
    private String id;
    private String insuranceId;
    private String policyNumber;

    // Location
    private BigDecimal latitude;
    private BigDecimal longitude;

    // Status
    private ClaimStatus status;
    private BigDecimal damagePercentage;
    private BigDecimal claimAmount;

    // AI Assessment
    private String diseaseDetected;
    private String modelVersion;

    // Images
    private List<String> imageUrls;

    private LocalDateTime filedAt;
    private LocalDateTime processedAt;
}
