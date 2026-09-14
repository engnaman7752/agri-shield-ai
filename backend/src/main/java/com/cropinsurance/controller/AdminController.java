package com.cropinsurance.controller;

import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.ClaimResponse;
import com.cropinsurance.service.AdminService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Tag(name = "Admin", description = "Admin dashboard and global operations")
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/stats")
    @Operation(summary = "Get global system statistics")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getGlobalStats() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getGlobalStats()));
    }

    @GetMapping("/claims")
    @Operation(summary = "Get all claims for admin review")
    public ResponseEntity<ApiResponse<List<ClaimResponse>>> getAllClaims() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllClaims()));
    }

    private final com.cropinsurance.service.ClaimService claimService;

    public static class PatwariReviewRequest {
        public String action; // RETRY or REJECT
        public String comments;
    }

    @org.springframework.web.bind.annotation.PostMapping("/claims/{claimId}/review")
    @Operation(summary = "Patwari manual review of a claim")
    public ResponseEntity<ApiResponse<String>> reviewClaim(
            @org.springframework.web.bind.annotation.PathVariable java.util.UUID claimId,
            @org.springframework.web.bind.annotation.RequestBody PatwariReviewRequest request) {
        claimService.reviewClaimByPatwari(claimId, request.action, request.comments);
        return ResponseEntity.ok(ApiResponse.success("Review submitted successfully"));
    }
}
