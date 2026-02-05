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

                // Check if khasra is already registered
                if (landRepository.existsByKhasraNumber(request.getKhasraNumber())) {
                        throw new BadRequestException("Land with this Khasra number is already registered");
                }

                // Get crop type for premium calculation
                CropType cropType = cropTypeRepository.findByName(request.getCropType())
                                .orElseThrow(() -> new ResourceNotFoundException("CropType", "name",
                                                request.getCropType()));

                // Calculate premium (simplified: rate * area * 1000)
                BigDecimal premium = cropType.getPremiumRate()
                                .multiply(request.getAreaAcres())
                                .multiply(BigDecimal.valueOf(100)); // Premium per acre * area

                // Calculate coverage (simplified: max coverage * area ratio)
                BigDecimal coverage = cropType.getMaxCoverage()
                                .multiply(request.getAreaAcres())
                                .divide(BigDecimal.TEN, 2, java.math.RoundingMode.HALF_UP);

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

                // Mark khasra as registered
                khasraRegistryRepository.findByKhasraNumber(request.getKhasraNumber())
                                .ifPresent(k -> {
                                        k.setIsRegistered(true);
                                        khasraRegistryRepository.save(k);
                                });

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
                InsurancePolicy insurance = insurancePolicyRepository
                                .findByRazorpayOrderId(request.getRazorpayOrderId())
                                .orElseThrow(() -> new ResourceNotFoundException("Insurance", "orderId",
                                                request.getRazorpayOrderId()));

                // Verify farmer owns this insurance
                if (!insurance.getFarmer().getId().equals(farmerId)) {
                        throw new BadRequestException("Unauthorized access to insurance");
                }

                // Update status
                insurance.setStatus(InsuranceStatus.PAID);
                insurance.setRazorpayPaymentId(request.getRazorpayPaymentId());
                insurancePolicyRepository.save(insurance);

                // Create verification record (for patwari)
                Verification verification = Verification.builder()
                                .insurance(insurance)
                                .status(VerificationStatus.PENDING)
                                .build();
                verificationRepository.save(verification);

                // Send notification
                notificationService.sendInsuranceNotification(
                                insurance.getFarmer().getId(),
                                "Payment Received",
                                "Your insurance application " + insurance.getPolicyNumber() +
                                                " payment is confirmed. Verification pending by Patwari.");

                log.info("💰 Payment confirmed for insurance: {}", insurance.getPolicyNumber());

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
}
