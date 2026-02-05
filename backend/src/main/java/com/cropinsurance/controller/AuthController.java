package com.cropinsurance.controller;

import com.cropinsurance.dto.request.FarmerRegisterRequest;
import com.cropinsurance.dto.request.LoginRequest;
import com.cropinsurance.dto.request.PatwariLoginRequest;
import com.cropinsurance.dto.request.VerifyOtpRequest;
import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.AuthResponse;
import com.cropinsurance.dto.response.OtpResponse;
import com.cropinsurance.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Authentication Controller
 * Handles OTP login for farmers and password login for patwari
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Login and registration APIs")
public class AuthController {

    private final AuthService authService;

    /**
     * Send OTP to farmer's phone
     */
    @PostMapping("/farmer/send-otp")
    @Operation(summary = "Send OTP to farmer's phone")
    public ResponseEntity<OtpResponse> sendOtp(@Valid @RequestBody LoginRequest request) {
        OtpResponse response = authService.sendOtp(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Verify OTP and login farmer
     */
    @PostMapping("/farmer/verify-otp")
    @Operation(summary = "Verify OTP and login farmer")
    public ResponseEntity<AuthResponse> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        AuthResponse response = authService.verifyOtp(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Register new farmer (after OTP verification)
     */
    @PostMapping("/farmer/register")
    @Operation(summary = "Register new farmer after OTP verification")
    public ResponseEntity<AuthResponse> registerFarmer(@Valid @RequestBody FarmerRegisterRequest request) {
        AuthResponse response = authService.registerFarmer(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Patwari login with government ID and password
     */
    @PostMapping("/patwari/login")
    @Operation(summary = "Patwari login with government ID")
    public ResponseEntity<AuthResponse> patwariLogin(@Valid @RequestBody PatwariLoginRequest request) {
        AuthResponse response = authService.patwariLogin(request);
        return ResponseEntity.ok(response);
    }

    /**
     * Refresh token
     */
    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token")
    public ResponseEntity<AuthResponse> refreshToken(@RequestHeader("Authorization") String authHeader) {
        String refreshToken = authHeader.replace("Bearer ", "");
        AuthResponse response = authService.refreshToken(refreshToken);
        return ResponseEntity.ok(response);
    }

    /**
     * Health check
     */
    @GetMapping("/health")
    @Operation(summary = "Health check endpoint")
    public ResponseEntity<ApiResponse<String>> health() {
        return ResponseEntity.ok(ApiResponse.success("Crop Insurance API is running! 🌾"));
    }
}
