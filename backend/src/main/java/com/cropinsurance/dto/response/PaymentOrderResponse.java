package com.cropinsurance.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Payment Order Response - For Razorpay
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentOrderResponse {
    private String orderId; // Razorpay order ID
    private String insuranceId;
    private BigDecimal amount;
    private String currency;
    private String razorpayKeyId; // Public key for frontend

    // Prefill data
    private String farmerName;
    private String farmerPhone;
    private String policyNumber;
}
