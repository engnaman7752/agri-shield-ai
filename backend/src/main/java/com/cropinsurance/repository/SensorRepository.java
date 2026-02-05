package com.cropinsurance.repository;

import com.cropinsurance.entity.Sensor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SensorRepository extends JpaRepository<Sensor, UUID> {

    Optional<Sensor> findByUniqueCode(String uniqueCode);

    @Query("SELECT s FROM Sensor s WHERE s.land IS NULL AND s.isActive = true")
    List<Sensor> findAvailableSensors();

    boolean existsByUniqueCode(String uniqueCode);
}
