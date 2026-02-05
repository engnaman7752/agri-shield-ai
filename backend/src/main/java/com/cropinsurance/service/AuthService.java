package com.cropinsurance.service;

import com.cropinsurance.dto.request.FarmerRegisterRequest;
import com.cropinsurance.dto.request.LoginRequest;
import com.cropinsurance.dto.request.PatwariLoginRequest;
import com.cropinsurance.dto.request.VerifyOtpRequest;
import com.cropinsurance.dto.response.AuthResponse;
import com.cropinsurance.dto.response.OtpResponse;
import com.cropinsurance.entity.Farmer;
import com.cropinsurance.entity.OtpRecord;
import com.cropinsurance.entity.Patwari;
import com.cropinsurance.exception.BadRequestException;
import com.cropinsurance.exception.UnauthorizedException;
import com.cropinsurance.repository.FarmerRepository;
import com.cropinsurance.repository.OtpRecordRepository;
import com.cropinsurance.repository.PatwariRepository;
import com.cropinsurance.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Authentication Service - Handles OTP login for farmers and password login for
 * patwari
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final FarmerRepository farmerRepository;
    private final PatwariRepository patwariRepository;
    private final OtpRecordRepository otpRecordRepository;
    private final SmsService smsService;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;

    /**
     * Send OTP to farmer's phone
     */
    @Transactional
    public OtpResponse sendOtp(LoginRequest request) {
        try {
            String phone = cleanPhone(request.getPhone());
            log.info("📱 OTP request for phone: {}", phone);

            // Generate OTP
            String otp = smsService.generateOtp();

            // Mark previous OTPs as used
            otpRecordRepository.markAllAsUsed(phone);

            // Create new OTP record
            OtpRecord otpRecord = OtpRecord.builder()
                    .phone(phone)
                    .otp(otp)
                    .expiresAt(LocalDateTime.now().plusMinutes(5))
                    .build();
            otpRecordRepository.save(otpRecord);

            // Send OTP via SMS
            boolean sent = smsService.sendOtp(phone, otp);

            // Check if farmer exists
            boolean isNewUser = !farmerRepository.existsByPhone(phone);

            return OtpResponse.builder()
                    .success(sent)
                    .message(sent ? "OTP sent successfully" : "Failed to send OTP")
                    .phone(phone)
                    .isNewUser(isNewUser)
                    .otpValidMinutes(5)
                    .debugOtp(otp)
                    .build();
        } catch (Exception e) {
            log.error("💥 Error in sendOtp: ", e);
            return OtpResponse.builder()
                    .success(false)
                    .message("Server Error Detail: " + e.getMessage() + " (Check logs for stack trace)")
                    .build();
        }
    }

    /**
     * Verify OTP and login farmer
     */
    @Transactional
    public AuthResponse verifyOtp(VerifyOtpRequest request) {
        String phone = cleanPhone(request.getPhone());
        String otp = request.getOtp();

        log.info("🔐 Verifying OTP for phone: {}", phone);

        // Find valid OTP
        OtpRecord otpRecord = otpRecordRepository
                .findValidOtp(phone, LocalDateTime.now())
                .orElseThrow(() -> new BadRequestException("Invalid or expired OTP"));

        // Verify OTP
        if (!otpRecord.getOtp().equals(otp)) {
            throw new BadRequestException("Invalid OTP");
        }

        // Mark OTP as used
        otpRecord.setIsUsed(true);
        otpRecordRepository.save(otpRecord);

        // Find or require registration
        Farmer farmer = farmerRepository.findByPhone(phone).orElse(null);

        if (farmer == null) {
            // New user - return response indicating registration needed
            return AuthResponse.builder()
                    .success(true)
                    .requiresRegistration(true)
                    .phone(phone)
                    .message("OTP verified. Please complete registration.")
                    .build();
        }

        // Existing user - generate tokens
        return generateFarmerAuthResponse(farmer);
    }

    /**
     * Register new farmer (after OTP verification)
     */
    @Transactional
    public AuthResponse registerFarmer(FarmerRegisterRequest request) {
        String phone = cleanPhone(request.getPhone());

        log.info("👤 Registering new farmer: {}", phone);

        // Check if already registered
        if (farmerRepository.existsByPhone(phone)) {
            throw new BadRequestException("Phone number already registered");
        }

        // Create farmer
        Farmer farmer = Farmer.builder()
                .phone(phone)
                .name(request.getName())
                .address(request.getAddress())
                .state(request.getState())
                .district(request.getDistrict())
                .village(request.getVillage())
                .build();

        farmer = farmerRepository.save(farmer);
        log.info("✅ Farmer registered: {} (ID: {})", farmer.getName(), farmer.getId());

        return generateFarmerAuthResponse(farmer);
    }

    /**
     * Patwari login with government ID and password
     */
    public AuthResponse patwariLogin(PatwariLoginRequest request) {
        log.info("🏛️ Patwari login attempt: {}", request.getGovernmentId());

        Patwari patwari = patwariRepository.findByGovernmentId(request.getGovernmentId())
                .orElseThrow(() -> new UnauthorizedException("Invalid credentials"));

        // Verify password
        if (!passwordEncoder.matches(request.getPassword(), patwari.getPasswordHash())) {
            throw new UnauthorizedException("Invalid credentials");
        }

        if (!patwari.getIsActive()) {
            throw new UnauthorizedException("Account is disabled");
        }

        log.info("✅ Patwari logged in: {}", patwari.getName());

        // Generate tokens
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", "PATWARI");
        claims.put("govtId", patwari.getGovernmentId());
        claims.put("area", patwari.getAssignedArea());

        String token = jwtTokenProvider.generateToken(patwari.getId().toString(), claims);
        String refreshToken = jwtTokenProvider.generateRefreshToken(patwari.getId().toString());

        return AuthResponse.builder()
                .success(true)
                .token(token)
                .refreshToken(refreshToken)
                .userId(patwari.getId().toString())
                .name(patwari.getName())
                .role("PATWARI")
                .message("Login successful")
                .build();
    }

    /**
     * Refresh token
     */
    public AuthResponse refreshToken(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new UnauthorizedException("Invalid refresh token");
        }

        String userId = jwtTokenProvider.getUserIdFromToken(refreshToken);

        // Check if farmer
        var farmer = farmerRepository.findById(java.util.UUID.fromString(userId));
        if (farmer.isPresent()) {
            return generateFarmerAuthResponse(farmer.get());
        }

        // Check if patwari
        var patwari = patwariRepository.findById(java.util.UUID.fromString(userId));
        if (patwari.isPresent()) {
            Map<String, Object> claims = new HashMap<>();
            claims.put("role", "PATWARI");
            String token = jwtTokenProvider.generateToken(userId, claims);
            String newRefreshToken = jwtTokenProvider.generateRefreshToken(userId);

            return AuthResponse.builder()
                    .success(true)
                    .token(token)
                    .refreshToken(newRefreshToken)
                    .userId(userId)
                    .role("PATWARI")
                    .build();
        }

        throw new UnauthorizedException("User not found");
    }

    /**
     * Generate auth response for farmer
     */
    private AuthResponse generateFarmerAuthResponse(Farmer farmer) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", "FARMER");
        claims.put("phone", farmer.getPhone());
        claims.put("name", farmer.getName());

        String token = jwtTokenProvider.generateToken(farmer.getId().toString(), claims);
        String refreshToken = jwtTokenProvider.generateRefreshToken(farmer.getId().toString());

        return AuthResponse.builder()
                .success(true)
                .token(token)
                .refreshToken(refreshToken)
                .userId(farmer.getId().toString())
                .name(farmer.getName())
                .phone(farmer.getPhone())
                .role("FARMER")
                .profileComplete(farmer.getName() != null && farmer.getState() != null)
                .message("Login successful")
                .build();
    }

    /**
     * Clean phone number
     */
    private String cleanPhone(String phone) {
        String clean = phone.replaceAll("[^0-9]", "");
        if (clean.startsWith("91") && clean.length() == 12) {
            clean = clean.substring(2);
        }
        return clean;
    }
}
