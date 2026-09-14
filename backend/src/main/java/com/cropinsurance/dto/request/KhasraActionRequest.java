package com.cropinsurance.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * DTO for patwari approving/rejecting khasra request
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KhasraActionRequest {

    @NotNull(message = "Request ID is required")
    private UUID requestId;

    @NotBlank(message = "Action is required (APPROVED or REJECTED)")
    private String action; // APPROVED or REJECTED

    private String remarks;
}
