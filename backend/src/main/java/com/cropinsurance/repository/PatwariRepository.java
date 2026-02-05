package com.cropinsurance.repository;

import com.cropinsurance.entity.Patwari;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PatwariRepository extends JpaRepository<Patwari, UUID> {

    Optional<Patwari> findByGovernmentId(String governmentId);

    Optional<Patwari> findByPhone(String phone);

    boolean existsByGovernmentId(String governmentId);
}
