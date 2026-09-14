package com.cropinsurance.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Response DTO for khasra requests
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KhasraRequestResponse {

    private String id;
    private String farmerId;
    private String farmerName;
    private String farmerPhone;
    private String village;
    private String khasraNumber;
    private BigDecimal areaAcres;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String status;
    private String patwariRemarks;
    private LocalDateTime createdAt;
    private LocalDateTime processedAt;
}
