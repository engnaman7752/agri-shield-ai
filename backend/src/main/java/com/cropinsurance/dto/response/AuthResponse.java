package com.cropinsurance.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Authentication Response with JWT tokens
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private boolean success;
    private String message;

    private String token;
    private String refreshToken;

    private String userId;
    private String name;
    private String phone;
    private String role; // FARMER or PATWARI

    private Boolean requiresRegistration;
    private Boolean profileComplete;
}
