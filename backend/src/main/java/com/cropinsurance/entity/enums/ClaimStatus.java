package com.cropinsurance.entity.enums;

/**
 * Claim Status
 */
public enum ClaimStatus {
    PENDING, // Claim filed, waiting for processing
    PROCESSING, // AI is analyzing
    APPROVED, // Claim approved (damage >= 75%)
    REJECTED // Claim rejected (damage < 75%)
}
