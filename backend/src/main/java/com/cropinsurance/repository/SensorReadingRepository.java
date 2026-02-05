package com.cropinsurance.repository;

import com.cropinsurance.entity.SensorReading;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SensorReadingRepository extends JpaRepository<SensorReading, UUID> {

    List<SensorReading> findBySensorIdOrderByRecordedAtDesc(UUID sensorId, Pageable pageable);

    @Query("SELECT sr FROM SensorReading sr WHERE sr.sensor.id = :sensorId ORDER BY sr.recordedAt DESC")
    List<SensorReading> findLatestBySensorId(@Param("sensorId") UUID sensorId, Pageable pageable);
}
