package com.cropinsurance.controller;

import com.cropinsurance.dto.request.InsuranceApplicationRequest;
import com.cropinsurance.dto.request.PaymentConfirmRequest;
import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.InsuranceResponse;
import com.cropinsurance.dto.response.PaymentOrderResponse;
import com.cropinsurance.exception.BadRequestException;
import com.cropinsurance.exception.ResourceNotFoundException;
import com.cropinsurance.service.InsuranceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Insurance Controller
 * Apply for insurance, payment, view policies
 */
@Slf4j
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
        try {
            PaymentOrderResponse response = insuranceService.applyForInsurance(UUID.fromString(userId), request);
            return ResponseEntity
                    .ok(ApiResponse.success(response, "Insurance application created. Please complete payment."));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to apply for insurance", e.getMessage()));
        }
    }

    /**
     * Apply for insurance (Internal - used by AI Agent)
     */
    @PostMapping("/internal/apply")
    @Operation(summary = "Apply for crop insurance internally via AI")
    public ResponseEntity<ApiResponse<PaymentOrderResponse>> applyForInsuranceInternal(
            @RequestParam("farmerId") String farmerId,
            @Valid @RequestBody InsuranceApplicationRequest request) {
        try {
            PaymentOrderResponse response = insuranceService.applyForInsurance(UUID.fromString(farmerId), request);
            return ResponseEntity
                    .ok(ApiResponse.success(response, "Insurance application created. Please complete payment."));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to apply for insurance via AI", e.getMessage()));
        }
    }

    /**
     * Confirm payment
     */
    @PostMapping("/payment/confirm")
    @Operation(summary = "Confirm Razorpay payment")
    public ResponseEntity<ApiResponse<InsuranceResponse>> confirmPayment(
            @AuthenticationPrincipal String userId,
            @Valid @RequestBody PaymentConfirmRequest request) {
        try {
            log.info("🔵 CONFIRM PAYMENT ENDPOINT CALLED");
            log.info("  User ID: {}", userId);
            log.info("  Insurance ID: {}", request.getInsuranceId());
            log.info("  Payment ID: {}", request.getRazorpayPaymentId());
            log.info("  Order ID: {}", request.getRazorpayOrderId());
            
            InsuranceResponse response = insuranceService.confirmPayment(UUID.fromString(userId), request);
            
            log.info("🟢 PAYMENT CONFIRMED SUCCESSFULLY");
            log.info("  Response: {}", response);
            return ResponseEntity.ok(ApiResponse.success(response, "Payment confirmed successfully!"));
        } catch (ResourceNotFoundException e) {
            log.error("❌ RESOURCE NOT FOUND: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(
                        "Insurance not found",
                        "Could not find insurance: " + e.getMessage()
                    ));
        } catch (BadRequestException e) {
            log.error("❌ BAD REQUEST: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Invalid request", e.getMessage()));
        } catch (Exception e) {
            log.error("❌ UNEXPECTED ERROR: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(
                        "Payment confirmation failed",
                        e.getMessage() != null ? e.getMessage() : "Unknown error"
                    ));
        }
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
     * Get all policies of farmer (Internal - used by AI Agent)
     */
    @GetMapping("/internal/policies")
    @Operation(summary = "Get all insurance policies internally via AI")
    public ResponseEntity<ApiResponse<List<InsuranceResponse>>> getMyPoliciesInternal(
            @RequestParam("farmerId") String farmerId) {
        List<InsuranceResponse> policies = insuranceService.getFarmerPolicies(UUID.fromString(farmerId));
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

    /**
     * Retry payment for PENDING policy (payment cancelled or failed)
     */
    @PostMapping("/{policyId}/retry-payment")
    @Operation(summary = "Generate new payment order for PENDING policy")
    public ResponseEntity<ApiResponse<PaymentOrderResponse>> retryPayment(
            @AuthenticationPrincipal String userId,
            @PathVariable UUID policyId) {
        try {
            PaymentOrderResponse response = insuranceService.retryPayment(UUID.fromString(userId), policyId);
            return ResponseEntity.ok(ApiResponse.success(response, "Payment order regenerated. Please complete payment."));
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Policy not found", e.getMessage()));
        } catch (BadRequestException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Cannot retry payment", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Retry failed", e.getMessage()));
        }
    }

    /**
     * Cancel a PENDING policy (payment failed)
     */
    @DeleteMapping("/{policyId}")
    @Operation(summary = "Cancel a PENDING policy")
    public ResponseEntity<ApiResponse<String>> cancelPolicy(
            @AuthenticationPrincipal String userId,
            @PathVariable UUID policyId) {
        insuranceService.cancelPolicy(UUID.fromString(userId), policyId);
        return ResponseEntity.ok(ApiResponse.success("Policy cancelled", "PENDING policy deleted successfully"));
    }
}
