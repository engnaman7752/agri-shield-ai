package com.cropinsurance.controller;

import com.cropinsurance.dto.request.ClaimRequest;
import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.ClaimResponse;
import com.cropinsurance.service.ClaimService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Claim Controller
 * File and track insurance claims
 */
@RestController
@RequestMapping("/api/claims")
@RequiredArgsConstructor
@Tag(name = "Claims", description = "File and track insurance claims")
@SecurityRequirement(name = "bearerAuth")
public class ClaimController {

    private final ClaimService claimService;

    /**
     * File a new claim with images
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "File a new insurance claim with photos")
    public ResponseEntity<ApiResponse<ClaimResponse>> fileClaim(
            @AuthenticationPrincipal String userId,
            @RequestParam("insuranceId") UUID insuranceId,
            @RequestParam("latitude") BigDecimal latitude,
            @RequestParam("longitude") BigDecimal longitude,
            @RequestParam("images") List<MultipartFile> images) {

        ClaimRequest request = ClaimRequest.builder()
                .insuranceId(insuranceId)
                .latitude(latitude)
                .longitude(longitude)
                .build();

        ClaimResponse response = claimService.fileClaim(UUID.fromString(userId), request, images);
        return ResponseEntity.ok(ApiResponse.success(response, "Claim filed successfully. Processing..."));
    }

    /**
     * Get all claims of farmer
     */
    @GetMapping("/my-claims")
    @Operation(summary = "Get all claims of logged in farmer")
    public ResponseEntity<ApiResponse<List<ClaimResponse>>> getMyClaims(
            @AuthenticationPrincipal String userId) {
        List<ClaimResponse> claims = claimService.getFarmerClaims(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(claims));
    }

    /**
     * Get claim by ID
     */
    @GetMapping("/{claimId}")
    @Operation(summary = "Get claim details")
    public ResponseEntity<ApiResponse<ClaimResponse>> getClaimById(
            @AuthenticationPrincipal String userId,
            @PathVariable UUID claimId) {
        ClaimResponse claim = claimService.getClaimById(UUID.fromString(userId), claimId);
        return ResponseEntity.ok(ApiResponse.success(claim));
    }
}
