package com.cropinsurance.repository;

import com.cropinsurance.entity.CropType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CropTypeRepository extends JpaRepository<CropType, Long> {

    Optional<CropType> findByName(String name);
}
