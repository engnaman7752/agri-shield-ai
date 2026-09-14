package com.cropinsurance.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO for farmer submitting a new khasra request
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KhasraRequestDTO {

    @NotBlank(message = "Village is required")
    private String village;

    @NotBlank(message = "Khasra number is required")
    private String khasraNumber;

    @NotNull(message = "Area is required")
    @Positive(message = "Area must be positive")
    private BigDecimal areaAcres;

    @NotNull(message = "Latitude is required")
    private BigDecimal latitude;

    @NotNull(message = "Longitude is required")
    private BigDecimal longitude;
}
