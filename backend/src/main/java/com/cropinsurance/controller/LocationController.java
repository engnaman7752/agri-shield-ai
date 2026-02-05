package com.cropinsurance.controller;

import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.KhasraDTO;
import com.cropinsurance.entity.CropType;
import com.cropinsurance.entity.District;
import com.cropinsurance.entity.KhasraRegistry;
import com.cropinsurance.entity.State;
import com.cropinsurance.entity.Village;
import com.cropinsurance.repository.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Location Controller
 * Provides dropdown data for State, District, Village, Khasra
 */
@RestController
@RequestMapping("/api/location")
@RequiredArgsConstructor
@Tag(name = "Location", description = "Location dropdown data APIs")
public class LocationController {

    private final StateRepository stateRepository;
    private final DistrictRepository districtRepository;
    private final VillageRepository villageRepository;
    private final KhasraRegistryRepository khasraRegistryRepository;
    private final CropTypeRepository cropTypeRepository;

    /**
     * Get all states
     */
    @GetMapping("/states")
    @Operation(summary = "Get all states for dropdown")
    public ResponseEntity<ApiResponse<List<State>>> getStates() {
        List<State> states = stateRepository.findAll();
        return ResponseEntity.ok(ApiResponse.success(states));
    }

    /**
     * Get districts by state ID (used by frontend)
     */
    @GetMapping("/districts/{stateId}")
    @Operation(summary = "Get districts by state ID")
    public ResponseEntity<ApiResponse<List<District>>> getDistrictsById(@PathVariable Long stateId) {
        List<District> districts = districtRepository.findByStateId(stateId);
        return ResponseEntity.ok(ApiResponse.success(districts));
    }

    /**
     * Get districts by state name
     */
    @GetMapping("/districts/name/{stateName}")
    @Operation(summary = "Get districts by state name")
    public ResponseEntity<ApiResponse<List<District>>> getDistrictsByName(@PathVariable String stateName) {
        List<District> districts = districtRepository.findByStateName(stateName);
        return ResponseEntity.ok(ApiResponse.success(districts));
    }

    /**
     * Get districts by state code
     */
    @GetMapping("/districts/code/{stateCode}")
    @Operation(summary = "Get districts by state code")
    public ResponseEntity<ApiResponse<List<District>>> getDistrictsByCode(@PathVariable String stateCode) {
        List<District> districts = districtRepository.findByStateCode(stateCode);
        return ResponseEntity.ok(ApiResponse.success(districts));
    }

    /**
     * Get villages by district ID (used by frontend)
     */
    @GetMapping("/villages/{districtId}")
    @Operation(summary = "Get villages by district ID")
    public ResponseEntity<ApiResponse<List<Village>>> getVillagesById(@PathVariable Long districtId) {
        List<Village> villages = villageRepository.findByDistrictId(districtId);
        return ResponseEntity.ok(ApiResponse.success(villages));
    }

    /**
     * Get villages by state and district names
     */
    @GetMapping("/villages/{stateName}/{districtName}")
    @Operation(summary = "Get villages by state and district")
    public ResponseEntity<ApiResponse<List<Village>>> getVillages(
            @PathVariable String stateName,
            @PathVariable String districtName) {
        List<Village> villages = villageRepository.findByDistrictAndState(districtName, stateName);
        return ResponseEntity.ok(ApiResponse.success(villages));
    }

    /**
     * Get available Khasra numbers for a village
     */
    @GetMapping("/khasra/available")
    @Operation(summary = "Get available (unregistered) Khasra numbers")
    public ResponseEntity<ApiResponse<List<KhasraDTO>>> getAvailableKhasra(
            @RequestParam String state,
            @RequestParam String district,
            @RequestParam String village) {

        List<KhasraRegistry> khasraList = khasraRegistryRepository
                .findAvailableByLocation(state, district, village);

        List<KhasraDTO> dtos = khasraList.stream()
                .map(k -> KhasraDTO.builder()
                        .id(k.getId().toString())
                        .khasraNumber(k.getKhasraNumber())
                        .areaAcres(k.getAreaAcres())
                        .latitude(k.getLatitude())
                        .longitude(k.getLongitude())
                        .isAvailable(!k.getIsRegistered())
                        .build())
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(dtos));
    }

    /**
     * Get all crop types
     */
    @GetMapping("/crops")
    @Operation(summary = "Get all crop types for dropdown")
    public ResponseEntity<ApiResponse<List<CropType>>> getCropTypes() {
        List<CropType> crops = cropTypeRepository.findAll();
        return ResponseEntity.ok(ApiResponse.success(crops));
    }
}
