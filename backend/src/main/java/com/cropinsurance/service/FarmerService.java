package com.cropinsurance.service;

import com.cropinsurance.dto.request.FarmerRegisterRequest;
import com.cropinsurance.dto.response.FarmerProfileResponse;
import com.cropinsurance.entity.Farmer;
import com.cropinsurance.entity.enums.InsuranceStatus;
import com.cropinsurance.exception.BadRequestException;
import com.cropinsurance.exception.ResourceNotFoundException;
import com.cropinsurance.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * Farmer Service - Profile and farmer operations
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FarmerService {

    private final FarmerRepository farmerRepository;
    private final LandRepository landRepository;
    private final InsurancePolicyRepository insurancePolicyRepository;
    private final ClaimRepository claimRepository;
    private final NotificationRepository notificationRepository;

    @Value("${file.upload-dir:./uploads}")
    private String uploadDir;

    /**
     * Get farmer profile with stats
     */
    public FarmerProfileResponse getProfile(UUID farmerId) {
        Farmer farmer = farmerRepository.findById(farmerId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer", "id", farmerId));

        int totalLands = landRepository.findByFarmerId(farmerId).size();
        int activeInsurances = insurancePolicyRepository
                .findByFarmerIdAndStatus(farmerId, InsuranceStatus.ACTIVE).size();
        int pendingClaims = (int) claimRepository.findByFarmerId(farmerId)
                .stream().filter(c -> c.getStatus().name().equals("PENDING")).count();
        long unreadNotifications = notificationRepository.countByFarmerIdAndIsReadFalse(farmerId);

        return FarmerProfileResponse.builder()
                .id(farmer.getId().toString())
                .name(farmer.getName())
                .phone(farmer.getPhone())
                .address(farmer.getAddress())
                .state(farmer.getState())
                .district(farmer.getDistrict())
                .village(farmer.getVillage())
                .profileImage(farmer.getProfileImage())
                .createdAt(farmer.getCreatedAt())
                .accountHolderName(farmer.getAccountHolderName())
                .bankName(farmer.getBankName())
                .accountNumber(farmer.getAccountNumber())
                .ifscCode(farmer.getIfscCode())
                .totalLands(totalLands)
                .activeInsurances(activeInsurances)
                .pendingClaims(pendingClaims)
                .unreadNotifications((int) unreadNotifications)
                .build();
    }

    /**
     * Update farmer profile
     */
    @Transactional
    public FarmerProfileResponse updateProfile(UUID farmerId, FarmerRegisterRequest request) {
        Farmer farmer = farmerRepository.findById(farmerId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer", "id", farmerId));

        farmer.setName(request.getName());
        farmer.setAddress(request.getAddress());
        farmer.setState(request.getState());
        farmer.setDistrict(request.getDistrict());
        farmer.setVillage(request.getVillage());

        // Update bank details
        farmer.setAccountHolderName(request.getAccountHolderName());
        farmer.setBankName(request.getBankName());
        farmer.setAccountNumber(request.getAccountNumber());
        farmer.setIfscCode(request.getIfscCode());

        farmer = farmerRepository.save(farmer);
        log.info("✅ Profile updated for farmer: {}", farmer.getName());

        return getProfile(farmerId);
    }

    /**
     * Upload profile photo
     */
    @Transactional
    public String uploadProfilePhoto(UUID farmerId, MultipartFile photo) {
        Farmer farmer = farmerRepository.findById(farmerId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer", "id", farmerId));

        if (photo.isEmpty()) {
            throw new BadRequestException("Photo file is empty");
        }

        // Validate file type
        String contentType = photo.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new BadRequestException("File must be an image");
        }

        try {
            // Create upload directory if not exists
            Path uploadPath = Paths.get(uploadDir, "profiles");
            Files.createDirectories(uploadPath);

            // Generate unique filename
            String extension = getFileExtension(photo.getOriginalFilename());
            String filename = farmerId.toString() + "_" + System.currentTimeMillis() + extension;
            Path filePath = uploadPath.resolve(filename);

            // Save file
            Files.copy(photo.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // Update farmer
            String relativePath = "/uploads/profiles/" + filename;
            farmer.setProfileImage(relativePath);
            farmerRepository.save(farmer);

            log.info("📷 Profile photo uploaded for farmer: {}", farmer.getName());
            return relativePath;

        } catch (IOException e) {
            log.error("Error uploading photo: {}", e.getMessage());
            throw new BadRequestException("Failed to upload photo: " + e.getMessage());
        }
    }

    private String getFileExtension(String filename) {
        if (filename == null)
            return ".jpg";
        int lastDot = filename.lastIndexOf('.');
        return lastDot > 0 ? filename.substring(lastDot) : ".jpg";
    }
}
