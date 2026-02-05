package com.cropinsurance.controller;

import com.cropinsurance.dto.request.InsuranceApplicationRequest;
import com.cropinsurance.dto.request.PaymentConfirmRequest;
import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.InsuranceResponse;
import com.cropinsurance.dto.response.PaymentOrderResponse;
import com.cropinsurance.service.InsuranceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Insurance Controller
 * Apply for insurance, payment, view policies
 */
@RestController
@RequestMapping("/api/insurance")
@RequiredArgsConstructor
@Tag(name = "Insurance", description = "Insurance application and payment")
@SecurityRequirement(name = "bearerAuth")
public class InsuranceController {

    private final InsuranceService insuranceService;

    /**
     * Apply for insurance - creates insurance and Razorpay order
     */
    @PostMapping("/apply")
    @Operation(summary = "Apply for crop insurance")
    public ResponseEntity<ApiResponse<PaymentOrderResponse>> applyForInsurance(
            @AuthenticationPrincipal String userId,
            @Valid @RequestBody InsuranceApplicationRequest request) {
        PaymentOrderResponse response = insuranceService.applyForInsurance(UUID.fromString(userId), request);
        return ResponseEntity
                .ok(ApiResponse.success(response, "Insurance application created. Please complete payment."));
    }

    /**
     * Confirm payment
     */
    @PostMapping("/payment/confirm")
    @Operation(summary = "Confirm Razorpay payment")
    public ResponseEntity<ApiResponse<InsuranceResponse>> confirmPayment(
            @AuthenticationPrincipal String userId,
            @Valid @RequestBody PaymentConfirmRequest request) {
        InsuranceResponse response = insuranceService.confirmPayment(UUID.fromString(userId), request);
        return ResponseEntity.ok(ApiResponse.success(response, "Payment confirmed. Verification pending."));
    }

    /**
     * Get all policies of farmer
     */
    @GetMapping("/my-policies")
    @Operation(summary = "Get all insurance policies of logged in farmer")
    public ResponseEntity<ApiResponse<List<InsuranceResponse>>> getMyPolicies(
            @AuthenticationPrincipal String userId) {
        List<InsuranceResponse> policies = insuranceService.getFarmerPolicies(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(policies));
    }

    /**
     * Get policy by ID
     */
    @GetMapping("/{policyId}")
    @Operation(summary = "Get insurance policy details")
    public ResponseEntity<ApiResponse<InsuranceResponse>> getPolicyById(
            @AuthenticationPrincipal String userId,
            @PathVariable UUID policyId) {
        InsuranceResponse policy = insuranceService.getPolicyById(UUID.fromString(userId), policyId);
        return ResponseEntity.ok(ApiResponse.success(policy));
    }

    /**
     * Get active policies (for filing claims)
     */
    @GetMapping("/active")
    @Operation(summary = "Get active policies eligible for claims")
    public ResponseEntity<ApiResponse<List<InsuranceResponse>>> getActivePolicies(
            @AuthenticationPrincipal String userId) {
        List<InsuranceResponse> policies = insuranceService.getActivePolicies(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(policies));
    }
}
