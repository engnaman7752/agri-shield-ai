package com.cropinsurance.controller;

import com.cropinsurance.dto.request.FarmerRegisterRequest;
import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.FarmerProfileResponse;
import com.cropinsurance.service.FarmerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

/**
 * Farmer Controller
 * Profile and farmer-related operations
 */
@RestController
@RequestMapping("/api/farmer")
@RequiredArgsConstructor
@Tag(name = "Farmer", description = "Farmer profile and operations")
@SecurityRequirement(name = "bearerAuth")
public class FarmerController {

    private final FarmerService farmerService;

    /**
     * Get farmer profile
     */
    @GetMapping("/profile")
    @Operation(summary = "Get current farmer's profile")
    public ResponseEntity<ApiResponse<FarmerProfileResponse>> getProfile(
            @AuthenticationPrincipal String userId) {
        FarmerProfileResponse profile = farmerService.getProfile(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(profile));
    }

    /**
     * Update farmer profile
     */
    @PutMapping("/profile")
    @Operation(summary = "Update farmer profile")
    public ResponseEntity<ApiResponse<FarmerProfileResponse>> updateProfile(
            @AuthenticationPrincipal String userId,
            @RequestBody FarmerRegisterRequest request) {
        FarmerProfileResponse profile = farmerService.updateProfile(UUID.fromString(userId), request);
        return ResponseEntity.ok(ApiResponse.success(profile, "Profile updated successfully"));
    }

    /**
     * Upload profile photo
     */
    @PostMapping(value = "/profile/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload farmer profile photo")
    public ResponseEntity<ApiResponse<String>> uploadProfilePhoto(
            @AuthenticationPrincipal String userId,
            @RequestParam("photo") MultipartFile photo) {
        String photoUrl = farmerService.uploadProfilePhoto(UUID.fromString(userId), photo);
        return ResponseEntity.ok(ApiResponse.success(photoUrl, "Photo uploaded successfully"));
    }

    /**
     * Get dashboard stats
     */
    @GetMapping("/dashboard")
    @Operation(summary = "Get farmer dashboard statistics")
    public ResponseEntity<ApiResponse<FarmerProfileResponse>> getDashboard(
            @AuthenticationPrincipal String userId) {
        FarmerProfileResponse dashboard = farmerService.getProfile(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(dashboard));
    }

    /**
     * Submit a khasra addition request
     */
    @PostMapping("/khasra-request")
    @Operation(summary = "Submit new khasra land request for Patwari verification")
    public ResponseEntity<ApiResponse<com.cropinsurance.dto.response.KhasraRequestResponse>> submitKhasraRequest(
            @AuthenticationPrincipal String userId,
            @Valid @RequestBody com.cropinsurance.dto.request.KhasraRequestDTO request) {
        var response = farmerService.submitKhasraRequest(UUID.fromString(userId), request);
        return ResponseEntity.ok(ApiResponse.success(response, "Khasra request submitted for Patwari verification"));
    }

    /**
     * Get my khasra requests
     */
    @GetMapping("/khasra-requests")
    @Operation(summary = "Get farmer's khasra requests")
    public ResponseEntity<ApiResponse<java.util.List<com.cropinsurance.dto.response.KhasraRequestResponse>>> getMyKhasraRequests(
            @AuthenticationPrincipal String userId) {
        var requests = farmerService.getMyKhasraRequests(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(requests));
    }
}
