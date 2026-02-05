package com.cropinsurance.repository;

import com.cropinsurance.entity.Land;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LandRepository extends JpaRepository<Land, UUID> {

    List<Land> findByFarmerId(UUID farmerId);

    Optional<Land> findByKhasraNumber(String khasraNumber);

    boolean existsByKhasraNumber(String khasraNumber);
}
