package com.cropinsurance.controller;

import com.cropinsurance.dto.request.VerificationActionRequest;
import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.PendingVerificationDTO;
import com.cropinsurance.entity.Sensor;
import com.cropinsurance.service.PatwariService;
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
 * Patwari Controller
 * Verification and sensor assignment operations
 */
@RestController
@RequestMapping("/api/patwari")
@RequiredArgsConstructor
@Tag(name = "Patwari", description = "Patwari verification operations")
@SecurityRequirement(name = "bearerAuth")
public class PatwariController {

    private final PatwariService patwariService;

    /**
     * Get pending verifications
     */
    @GetMapping("/verifications/pending")
    @Operation(summary = "Get all pending verifications")
    public ResponseEntity<ApiResponse<List<PendingVerificationDTO>>> getPendingVerifications(
            @AuthenticationPrincipal String userId) {
        List<PendingVerificationDTO> verifications = patwariService.getPendingVerifications(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(verifications));
    }

    /**
     * Get verification details
     */
    @GetMapping("/verifications/{verificationId}")
    @Operation(summary = "Get verification details")
    public ResponseEntity<ApiResponse<PendingVerificationDTO>> getVerificationDetails(
            @AuthenticationPrincipal String userId,
            @PathVariable UUID verificationId) {
        PendingVerificationDTO verification = patwariService.getVerificationById(UUID.fromString(userId),
                verificationId);
        return ResponseEntity.ok(ApiResponse.success(verification));
    }

    /**
     * Approve or reject verification
     */
    @PostMapping("/verifications/action")
    @Operation(summary = "Approve or reject insurance verification")
    public ResponseEntity<ApiResponse<PendingVerificationDTO>> processVerification(
            @AuthenticationPrincipal String userId,
            @Valid @RequestBody VerificationActionRequest request) {
        PendingVerificationDTO result = patwariService.processVerification(UUID.fromString(userId), request);
        return ResponseEntity.ok(ApiResponse.success(result, "Verification processed successfully"));
    }

    /**
     * Get available sensors
     */
    @GetMapping("/sensors/available")
    @Operation(summary = "Get available sensors for assignment")
    public ResponseEntity<ApiResponse<List<Sensor>>> getAvailableSensors() {
        List<Sensor> sensors = patwariService.getAvailableSensors();
        return ResponseEntity.ok(ApiResponse.success(sensors));
    }

    /**
     * Get patwari dashboard stats
     */
    @GetMapping("/dashboard")
    @Operation(summary = "Get patwari dashboard statistics")
    public ResponseEntity<ApiResponse<Object>> getDashboard(
            @AuthenticationPrincipal String userId) {
        Object stats = patwariService.getDashboardStats(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(stats));
    }
}
