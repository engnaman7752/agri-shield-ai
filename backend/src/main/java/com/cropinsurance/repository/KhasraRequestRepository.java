package com.cropinsurance.repository;

import com.cropinsurance.entity.KhasraRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface KhasraRequestRepository extends JpaRepository<KhasraRequest, UUID> {

    List<KhasraRequest> findByFarmerIdOrderByCreatedAtDesc(UUID farmerId);

    List<KhasraRequest> findByStatusOrderByCreatedAtAsc(String status);
}
