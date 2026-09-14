package com.cropinsurance.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Claim Filing Request
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClaimRequest {

    @NotNull(message = "Insurance ID is required")
    private UUID insuranceId;

    @NotNull(message = "Latitude is required")
    private BigDecimal latitude;

    @NotNull(message = "Longitude is required")
    private BigDecimal longitude;

    // Weather data captured at claim time (optional)
    private BigDecimal weatherTemperature;
    private BigDecimal weatherHumidity;
    private String weatherCondition;
    private BigDecimal weatherRainfall;

    // Damage reason (PMFBY categories)
    private String damageReason;  // DamageReason enum name as string
    private String damageReasonDetail;  // Optional free-text detail

    // Images will be sent separately as multipart
}
