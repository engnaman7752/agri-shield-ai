package com.cropinsurance.repository;

import com.cropinsurance.entity.Farmer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface FarmerRepository extends JpaRepository<Farmer, UUID> {

    Optional<Farmer> findByPhone(String phone);

    boolean existsByPhone(String phone);
}
