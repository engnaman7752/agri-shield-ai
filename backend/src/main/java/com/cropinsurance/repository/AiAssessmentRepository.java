package com.cropinsurance.repository;

import com.cropinsurance.entity.AiAssessment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AiAssessmentRepository extends JpaRepository<AiAssessment, UUID> {

    Optional<AiAssessment> findByClaimId(UUID claimId);
}
