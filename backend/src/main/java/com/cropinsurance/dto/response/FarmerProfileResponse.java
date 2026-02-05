package com.cropinsurance.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Farmer Profile Response
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FarmerProfileResponse {
    private String id;
    private String name;
    private String phone;
    private String address;
    private String state;
    private String district;
    private String village;
    private String profileImage;
    private LocalDateTime createdAt;

    // Bank Details
    private String accountHolderName;
    private String bankName;
    private String accountNumber;
    private String ifscCode;

    // Stats
    private int totalLands;
    private int activeInsurances;
    private int pendingClaims;
    private int unreadNotifications;
}
