package com.cropinsurance.entity.enums;

/**
 * Insurance Policy Status
 */
public enum InsuranceStatus {
    PENDING, // Waiting for payment
    PAID, // Payment done, waiting for verification
    VERIFIED, // Patwari verified
    ACTIVE, // Insurance is active
    EXPIRED, // Policy expired
    CLAIMED // Claim filed
}
