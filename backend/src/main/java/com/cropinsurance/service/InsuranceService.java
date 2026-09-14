package com.cropinsurance.service;

import com.cropinsurance.dto.request.InsuranceApplicationRequest;
import com.cropinsurance.dto.request.PaymentConfirmRequest;
import com.cropinsurance.dto.response.InsuranceResponse;
import com.cropinsurance.dto.response.PaymentOrderResponse;
import com.cropinsurance.entity.*;
import com.cropinsurance.entity.enums.InsuranceStatus;
import com.cropinsurance.entity.enums.VerificationStatus;
import com.cropinsurance.exception.BadRequestException;
import com.cropinsurance.exception.ResourceNotFoundException;
import com.cropinsurance.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Insurance Service - Apply for insurance, payment, verification
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class InsuranceService {

        private final FarmerRepository farmerRepository;
        private final LandRepository landRepository;
        private final InsurancePolicyRepository insurancePolicyRepository;
        private final KhasraRegistryRepository khasraRegistryRepository;
        private final CropTypeRepository cropTypeRepository;
        private final VerificationRepository verificationRepository;
        private final NotificationService notificationService;

        @Value("${razorpay.key.id:rzp_test_xxxx}")
        private String razorpayKeyId;

        /**
         * Apply for insurance - creates insurance and payment order
         */
        @Transactional
        public PaymentOrderResponse applyForInsurance(UUID farmerId, InsuranceApplicationRequest request) {
                Farmer farmer = farmerRepository.findById(farmerId)
                                .orElseThrow(() -> new ResourceNotFoundException("Farmer", "id", farmerId));

                // DEMO MODE: Allow re-registration of same khasra for demo purposes
                // if (landRepository.existsByKhasraNumber(request.getKhasraNumber())) {
                //         throw new BadRequestException("Land with this Khasra number is already registered");
                // }

                // Get crop type for premium calculation
                CropType cropType = cropTypeRepository.findByName(request.getCropType())
                                .orElseThrow(() -> new ResourceNotFoundException("CropType", "name",
                                                request.getCropType()));

                // Calculate coverage (simplified: max coverage * area)
                BigDecimal coverage = cropType.getMaxCoverage()
                                .multiply(request.getAreaAcres());

                // Calculate premium (PremiumRate % of coverage)
                BigDecimal premium = coverage.multiply(cropType.getPremiumRate())
                                .divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);

                // Log calculation details
                log.info("💰 PREMIUM CALCULATION");
                log.info("  Area: {} acres", request.getAreaAcres());
                log.info("  Crop Type: {} (Rate: {}%)", request.getCropType(), cropType.getPremiumRate());
                log.info("  Max Coverage: ₹{}", cropType.getMaxCoverage());
                log.info("  Total Coverage: ₹{}", coverage);
                log.info("  Premium Amount (in ₹): ₹{}", premium);
                log.info("  Premium Amount (in paisas): {} (will be: {} × 100)", premium, premium);
                log.info("  Scale: {}, Precision: {}", premium.scale(), premium.precision());

                // Create Land
                Land land = Land.builder()
                                .farmer(farmer)
                                .khasraNumber(request.getKhasraNumber())
                                .areaAcres(request.getAreaAcres())
                                .cropType(request.getCropType())
                                .latitude(request.getLatitude())
                                .longitude(request.getLongitude())
                                .build();
                land = landRepository.save(land);

                // DEMO MODE: Do not mark khasra as registered so professor can re-test
                // khasraRegistryRepository.findByKhasraNumber(request.getKhasraNumber())
                //                 .ifPresent(k -> {
                //                         k.setIsRegistered(true);
                //                         khasraRegistryRepository.save(k);
                //                 });

                // Generate policy number
                String policyNumber = generatePolicyNumber();

                // Create Insurance Policy (PENDING status until payment)
                InsurancePolicy insurance = InsurancePolicy.builder()
                                .farmer(farmer)
                                .land(land)
                                .policyNumber(policyNumber)
                                .premiumAmount(premium)
                                .coverageAmount(coverage)
                                .cropType(request.getCropType())
                                .startDate(LocalDate.now())
                                .endDate(LocalDate.now().plusMonths(6)) // 6 months coverage
                                .status(InsuranceStatus.PENDING)
                                .build();

                // Generate Razorpay order ID (simulated for prototype)
                String razorpayOrderId = "order_" + UUID.randomUUID().toString().substring(0, 14);
                insurance.setRazorpayOrderId(razorpayOrderId);

                insurance = insurancePolicyRepository.save(insurance);
                log.info("📝 Insurance application created: {} for farmer {}", policyNumber, farmer.getName());

                return PaymentOrderResponse.builder()
                                .orderId(razorpayOrderId)
                                .insuranceId(insurance.getId().toString())
                                .amount(premium)
                                .currency("INR")
                                .razorpayKeyId(razorpayKeyId)
                                .farmerName(farmer.getName())
                                .farmerPhone(farmer.getPhone())
                                .policyNumber(policyNumber)
                                .build();
        }

        /**
         * Confirm payment (from Razorpay callback)
         */
        @Transactional
        public InsuranceResponse confirmPayment(UUID farmerId, PaymentConfirmRequest request) {
                // Log payment confirmation request
                log.info("📱 Payment confirmation received");
                log.info("  Insurance ID: {}", request.getInsuranceId());
                log.info("  Farmer ID: {}", farmerId);
                log.info("  Payment ID: {}", request.getRazorpayPaymentId());
                
                // Validate request has all required fields
                if (request.getInsuranceId() == null || request.getInsuranceId().isEmpty()) {
                        log.error("❌ MISSING INSURANCE ID in request");
                        throw new BadRequestException("Insurance ID is required");
                }
                
                if (request.getRazorpayPaymentId() == null || request.getRazorpayPaymentId().isEmpty()) {
                        log.error("❌ MISSING PAYMENT ID in request");
                        throw new BadRequestException("Payment ID is required");
                }
                
                // Find insurance by ID (more reliable than order ID for standalone Razorpay)
                InsurancePolicy insurance = insurancePolicyRepository
                                .findById(UUID.fromString(request.getInsuranceId()))
                                .orElseThrow(() -> {
                                        log.error("❌ Insurance not found for ID: {}", request.getInsuranceId());
                                        return new ResourceNotFoundException("Insurance", "id",
                                                        request.getInsuranceId());
                                });

                log.info("✓ Insurance found: {}", insurance.getPolicyNumber());

                // Verify farmer owns this insurance
                if (!insurance.getFarmer().getId().equals(farmerId)) {
                        log.error("❌ Unauthorized payment confirmation attempt");
                        log.error("   Farmer trying to confirm: {}", farmerId);
                        log.error("   Insurance belongs to: {}", insurance.getFarmer().getId());
                        throw new BadRequestException("Unauthorized access to insurance");
                }

                // Check if payment already confirmed (idempotency)
                if (InsuranceStatus.PAID.equals(insurance.getStatus())) {
                        log.warn("⚠️ Payment already confirmed for insurance: {}", request.getInsuranceId());
                        return toInsuranceResponse(insurance);
                }

                log.info("🔄 Processing payment confirmation...");

                // Update status
                insurance.setStatus(InsuranceStatus.PAID);
                insurance.setRazorpayPaymentId(request.getRazorpayPaymentId());
                if (request.getRazorpayOrderId() != null && !request.getRazorpayOrderId().isEmpty()) {
                        insurance.setRazorpayOrderId(request.getRazorpayOrderId());
                }
                insurancePolicyRepository.save(insurance);
                
                log.info("💾 Saved payment details");
                log.info("  Policy: {}", insurance.getPolicyNumber());
                log.info("  Premium Amount: ₹{}", insurance.getPremiumAmount());
                log.info("  Razorpay Payment ID: {}", request.getRazorpayPaymentId());

                // Create verification record (for patwari)
                try {
                        Verification verification = Verification.builder()
                                        .insurance(insurance)
                                        .status(VerificationStatus.PENDING)
                                        .build();
                        verificationRepository.save(verification);
                        log.info("📋 Verification record created");
                } catch (Exception e) {
                        log.error("❌ Failed to create verification record: {}", e.getMessage());
                        // Don't throw - let payment confirmation succeed even if verification creation fails
                }

                // Send notification
                try {
                        notificationService.sendInsuranceNotification(
                                        insurance.getFarmer().getId(),
                                        "Payment Received",
                                        "Your insurance application " + insurance.getPolicyNumber() +
                                                        " payment is confirmed. Verification pending by Patwari.");
                        log.info("📧 Notification sent");
                } catch (Exception e) {
                        log.warn("⚠️ Failed to send notification: {}", e.getMessage());
                        // Don't throw - notification failure shouldn't fail the payment confirmation
                }

                log.info("✓ ✓ ✓ PAYMENT CONFIRMED SUCCESSFULLY");
                log.info("  Policy: {}", insurance.getPolicyNumber());
                log.info("  Amount: ₹{}", insurance.getPremiumAmount());
                log.info("  Local Status: {}", insurance.getStatus());

                return toInsuranceResponse(insurance);
        }

        /**
         * Get all policies of farmer
         */
        public List<InsuranceResponse> getFarmerPolicies(UUID farmerId) {
                return insurancePolicyRepository.findByFarmerId(farmerId)
                                .stream()
                                .map(this::toInsuranceResponse)
                                .collect(Collectors.toList());
        }

        /**
         * Get policy by ID
         */
        public InsuranceResponse getPolicyById(UUID farmerId, UUID policyId) {
                InsurancePolicy insurance = insurancePolicyRepository.findById(policyId)
                                .orElseThrow(() -> new ResourceNotFoundException("Insurance", "id", policyId));

                if (!insurance.getFarmer().getId().equals(farmerId)) {
                        throw new BadRequestException("Unauthorized access to insurance");
                }

                return toInsuranceResponse(insurance);
        }

        /**
         * Get active policies (for filing claims)
         */
        public List<InsuranceResponse> getActivePolicies(UUID farmerId) {
                return insurancePolicyRepository.findByFarmerIdAndStatus(farmerId, InsuranceStatus.ACTIVE)
                                .stream()
                                .map(this::toInsuranceResponse)
                                .collect(Collectors.toList());
        }

        /**
         * Activate insurance (called by patwari after verification)
         */
        @Transactional
        public void activateInsurance(UUID insuranceId) {
                InsurancePolicy insurance = insurancePolicyRepository.findById(insuranceId)
                                .orElseThrow(() -> new ResourceNotFoundException("Insurance", "id", insuranceId));

                insurance.setStatus(InsuranceStatus.ACTIVE);
                insurancePolicyRepository.save(insurance);

                // Send notification
                notificationService.sendInsuranceNotification(
                                insurance.getFarmer().getId(),
                                "Insurance Activated! 🎉",
                                "Your crop insurance " + insurance.getPolicyNumber() +
                                                " is now active. Coverage: ₹" + insurance.getCoverageAmount());

                log.info("✅ Insurance activated: {}", insurance.getPolicyNumber());
        }

        private InsuranceResponse toInsuranceResponse(InsurancePolicy insurance) {
                Verification verification = verificationRepository.findByInsuranceId(insurance.getId()).orElse(null);
                Land land = insurance.getLand();

                return InsuranceResponse.builder()
                                .id(insurance.getId().toString())
                                .policyNumber(insurance.getPolicyNumber())
                                .khasraNumber(land.getKhasraNumber())
                                .areaAcres(land.getAreaAcres())
                                .latitude(land.getLatitude())
                                .longitude(land.getLongitude())
                                .sensorCode(land.getSensor() != null ? land.getSensor().getUniqueCode() : null)
                                .cropType(insurance.getCropType())
                                .premiumAmount(insurance.getPremiumAmount())
                                .coverageAmount(insurance.getCoverageAmount())
                                .startDate(insurance.getStartDate())
                                .endDate(insurance.getEndDate())
                                .status(insurance.getStatus())
                                .verificationStatus(verification != null ? verification.getStatus().name() : null)
                                .verificationRemarks(verification != null ? verification.getRemarks() : null)
                                .createdAt(insurance.getCreatedAt())
                                .build();
        }

        private String generatePolicyNumber() {
                String timestamp = String.valueOf(System.currentTimeMillis()).substring(5);
                return "CI-" + timestamp + "-" + String.format("%04d", (int) (Math.random() * 10000));
        }

        /**
         * Retry payment for PENDING policy (payment cancelled/failed)
         */
        @Transactional
        public PaymentOrderResponse retryPayment(UUID farmerId, UUID policyId) {
                InsurancePolicy insurance = insurancePolicyRepository.findById(policyId)
                                .orElseThrow(() -> new ResourceNotFoundException("Insurance", "id", policyId));

                // Verify farmer owns this insurance
                if (!insurance.getFarmer().getId().equals(farmerId)) {
                        throw new BadRequestException("Unauthorized access to insurance");
                }

                // Only PENDING policies can retry payment
                if (insurance.getStatus() != InsuranceStatus.PENDING) {
                        throw new BadRequestException(
                                "Only PENDING policies can retry payment. Current status: " + insurance.getStatus());
                }

                log.info("🔄 RETRY PAYMENT for: {} (Policy: {})", insurance.getPolicyNumber(), policyId);
                log.info("  Premium Amount: ₹{}", insurance.getPremiumAmount());

                // Generate new Razorpay order ID (using existing payment id or generate new)
                if (insurance.getRazorpayOrderId() == null) {
                        String razorpayOrderId = "order_" + UUID.randomUUID().toString().substring(0, 14);
                        insurance.setRazorpayOrderId(razorpayOrderId);
                        insurancePolicyRepository.save(insurance);
                }

                return PaymentOrderResponse.builder()
                                .orderId(insurance.getRazorpayOrderId())
                                .insuranceId(insurance.getId().toString())
                                .amount(insurance.getPremiumAmount())
                                .currency("INR")
                                .razorpayKeyId(razorpayKeyId)
                                .farmerName(insurance.getFarmer().getName())
                                .farmerPhone(insurance.getFarmer().getPhone())
                                .policyNumber(insurance.getPolicyNumber())
                                .build();
        }

        /**
         * Cancel a PENDING policy (payment failed / user wants to retry)
         */
        @Transactional
        public void cancelPolicy(UUID farmerId, UUID policyId) {
                InsurancePolicy insurance = insurancePolicyRepository.findById(policyId)
                                .orElseThrow(() -> new ResourceNotFoundException("Insurance", "id", policyId));

                if (!insurance.getFarmer().getId().equals(farmerId)) {
                        throw new BadRequestException("Unauthorized access to insurance");
                }

                if (insurance.getStatus() != InsuranceStatus.PENDING) {
                        throw new BadRequestException("Only PENDING policies can be cancelled");
                }

                // Delete related land record
                Land land = insurance.getLand();
                insurancePolicyRepository.delete(insurance);
                if (land != null) {
                        landRepository.delete(land);
                }

                log.info("🗑️ PENDING policy {} cancelled by farmer", insurance.getPolicyNumber());
        }
}
