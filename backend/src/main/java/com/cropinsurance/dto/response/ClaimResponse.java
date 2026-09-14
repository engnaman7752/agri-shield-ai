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

    // Farmer Context
    private String farmerName;
    private String farmerPhone;
    private String village;
    private String khasraNumber;

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

    // Damage Reason
    private String damageReason;
    private String damageReasonHindi;
    private String damageReasonEnglish;
    private String damageReasonDetail;

    // Images
    private List<String> imageUrls;

    // IoT Sensor Data (from ESP32 via MongoDB)
    private java.util.Map<String, Object> sensorData;

    // Satellite Verification
    private String satelliteImageUrl;

    // Weather data fallback (captured at claim time)
    private BigDecimal weatherTemp;
    private BigDecimal weatherHumidity;
    private BigDecimal weatherRainfall;
    private String weatherCondition;

    private LocalDateTime filedAt;
    private LocalDateTime processedAt;
}
