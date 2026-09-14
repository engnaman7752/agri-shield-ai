package com.cropinsurance.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Forgot Password Request
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ForgotPasswordRequest {

    @NotBlank(message = "Phone number is required")
    private String phone;

    // Method: SMS or EMAIL (optional, defaulting to SMS)
    private String method = "SMS";
}
