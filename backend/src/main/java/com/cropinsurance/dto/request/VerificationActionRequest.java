package com.cropinsurance.dto.request;

import com.cropinsurance.entity.enums.VerificationStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Verification Action Request (by Patwari)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerificationActionRequest {

    @NotNull(message = "Verification ID is required")
    private UUID verificationId;

    @NotNull(message = "Status is required")
    private VerificationStatus status;

    private String remarks;

    private String sensorCode; // Sensor to assign (for approved)
}
