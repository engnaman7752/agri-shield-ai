package com.cropinsurance.repository;

import com.cropinsurance.entity.Verification;
import com.cropinsurance.entity.enums.VerificationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VerificationRepository extends JpaRepository<Verification, UUID> {

    Optional<Verification> findByInsuranceId(UUID insuranceId);

    List<Verification> findByStatus(VerificationStatus status);

    List<Verification> findByPatwariId(UUID patwariId);

    @Query("SELECT v FROM Verification v WHERE v.status = 'PENDING'")
    List<Verification> findPendingVerifications();

    @Query("SELECT v FROM Verification v WHERE v.status = 'PENDING' AND v.insurance.land.farmer.district = :district")
    List<Verification> findPendingByDistrict(@Param("district") String district);
}
