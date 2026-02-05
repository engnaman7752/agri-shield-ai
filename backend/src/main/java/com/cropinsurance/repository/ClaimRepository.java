package com.cropinsurance.repository;

import com.cropinsurance.entity.Claim;
import com.cropinsurance.entity.enums.ClaimStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ClaimRepository extends JpaRepository<Claim, UUID> {

    List<Claim> findByFarmerId(UUID farmerId);

    List<Claim> findByInsuranceId(UUID insuranceId);

    List<Claim> findByStatus(ClaimStatus status);

    List<Claim> findByFarmerIdOrderByFiledAtDesc(UUID farmerId);
}
