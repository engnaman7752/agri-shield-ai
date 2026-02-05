package com.cropinsurance.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Sensor Reading Request - From simulator or real sensor
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SensorReadingRequest {

    @NotBlank(message = "Sensor code is required")
    private String sensorCode;

    @NotNull(message = "Soil moisture is required")
    private BigDecimal soilMoisture;

    @NotNull(message = "Humidity is required")
    private BigDecimal humidity;

    @NotNull(message = "Temperature is required")
    private BigDecimal temperature;

    private BigDecimal rainfall;
}
