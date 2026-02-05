package com.cropinsurance.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * OTP Send Response
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OtpResponse {
    private boolean success;
    private String message;
    private String phone;
    private boolean isNewUser;
    private int otpValidMinutes;

    // Only for demo/development - remove in production!
    private String debugOtp;
}
