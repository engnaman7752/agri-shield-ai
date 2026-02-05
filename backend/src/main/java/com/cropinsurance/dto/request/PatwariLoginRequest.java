package com.cropinsurance.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Patwari Login Request
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PatwariLoginRequest {

    @NotBlank(message = "Government ID is required")
    private String governmentId;

    @NotBlank(message = "Password is required")
    private String password;
}
