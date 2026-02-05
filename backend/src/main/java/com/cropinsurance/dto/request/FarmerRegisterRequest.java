package com.cropinsurance.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Farmer Registration Request
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FarmerRegisterRequest {

    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^[0-9]{10}$", message = "Invalid phone number")
    private String phone;

    @NotBlank(message = "Name is required")
    private String name;

    private String address;

    @NotBlank(message = "State is required")
    private String state;

    @NotBlank(message = "District is required")
    private String district;

    @NotBlank(message = "Village is required")
    private String village;

    // Bank Details (optional during registration, but available)
    private String accountHolderName;
    private String bankName;
    private String accountNumber;
    private String ifscCode;
}
