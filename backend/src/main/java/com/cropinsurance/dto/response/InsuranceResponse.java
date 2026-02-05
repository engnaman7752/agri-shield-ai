package com.cropinsurance.dto.response;

import com.cropinsurance.entity.enums.InsuranceStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Insurance Policy Response
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InsuranceResponse {
    private String id;
    private String policyNumber;

    // Land details
    private String khasraNumber;
    private BigDecimal areaAcres;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String sensorCode;

    // Insurance details
    private String cropType;
    private BigDecimal premiumAmount;
    private BigDecimal coverageAmount;
    private LocalDate startDate;
    private LocalDate endDate;
    private InsuranceStatus status;

    // Verification
    private String verificationStatus;
    private String verificationRemarks;

    private LocalDateTime createdAt;
}
