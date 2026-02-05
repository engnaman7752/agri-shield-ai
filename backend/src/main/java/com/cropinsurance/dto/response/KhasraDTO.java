package com.cropinsurance.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Khasra Registry DTO - For dropdown
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KhasraDTO {
    private String id;
    private String khasraNumber;
    private BigDecimal areaAcres;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private boolean isAvailable;
}
