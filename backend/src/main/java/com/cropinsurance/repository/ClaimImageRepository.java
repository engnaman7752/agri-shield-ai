package com.cropinsurance.repository;

import com.cropinsurance.entity.ClaimImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ClaimImageRepository extends JpaRepository<ClaimImage, UUID> {

    List<ClaimImage> findByClaimId(UUID claimId);
}
