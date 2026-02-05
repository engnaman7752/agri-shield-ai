package com.cropinsurance.repository;

import com.cropinsurance.entity.InsurancePolicy;
import com.cropinsurance.entity.enums.InsuranceStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InsurancePolicyRepository extends JpaRepository<InsurancePolicy, UUID> {

    List<InsurancePolicy> findByFarmerId(UUID farmerId);

    List<InsurancePolicy> findByFarmerIdAndStatus(UUID farmerId, InsuranceStatus status);

    Optional<InsurancePolicy> findByPolicyNumber(String policyNumber);

    Optional<InsurancePolicy> findByRazorpayOrderId(String orderId);

    boolean existsByPolicyNumber(String policyNumber);

    List<InsurancePolicy> findByStatus(InsuranceStatus status);
}
