package com.cropinsurance.dto.response;

import com.cropinsurance.entity.enums.VerificationStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Pending Verification DTO - For Patwari
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PendingVerificationDTO {
    private String verificationId;
    private String insuranceId;
    private String policyNumber;

    // Farmer details
    private String farmerName;
    private String farmerPhone;
    private String farmerAddress;

    // Land details
    private String khasraNumber;
    private BigDecimal areaAcres;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String state;
    private String district;
    private String village;

    // Insurance details
    private String cropType;
    private BigDecimal premiumAmount;
    private BigDecimal coverageAmount;

    private VerificationStatus status;
    private LocalDateTime createdAt;
}
