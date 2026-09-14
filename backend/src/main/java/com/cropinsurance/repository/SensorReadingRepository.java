package com.cropinsurance.repository;

import com.cropinsurance.entity.SensorReading;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface SensorReadingRepository extends JpaRepository<SensorReading, UUID> {

    List<SensorReading> findBySensorIdOrderByRecordedAtDesc(UUID sensorId, Pageable pageable);

    @Query("SELECT sr FROM SensorReading sr WHERE sr.sensor.id = :sensorId ORDER BY sr.recordedAt DESC")
    List<SensorReading> findLatestBySensorId(@Param("sensorId") UUID sensorId, Pageable pageable);

    // Check if a reading already exists (for dedup during MongoDB sync)
    boolean existsBySensorIdAndRecordedAt(UUID sensorId, LocalDateTime recordedAt);

    // Get readings from last N days for claim verification
    List<SensorReading> findBySensorIdAndRecordedAtAfterOrderByRecordedAtDesc(
            UUID sensorId, LocalDateTime after);

    // Cleanup old readings
    @Modifying
    @Transactional
    @Query("DELETE FROM SensorReading sr WHERE sr.recordedAt < :cutoff")
    long deleteByRecordedAtBefore(@Param("cutoff") LocalDateTime cutoff);
}
