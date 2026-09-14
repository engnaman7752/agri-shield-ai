package com.cropinsurance.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Sensor Entity - IoT sensor assigned to land
 */
@Entity
@Table(name = "sensors")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Sensor {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "unique_code", unique = true, nullable = false, length = 20)
    private String uniqueCode;

    @OneToMany(mappedBy = "sensor", fetch = FetchType.LAZY)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private List<Land> lands = new ArrayList<>();

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "last_reading_at")
    private LocalDateTime lastReadingAt;

    @CreationTimestamp
    @Column(name = "installed_at")
    private LocalDateTime installedAt;

    // Sensor readings
    @OneToMany(mappedBy = "sensor", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    @com.fasterxml.jackson.annotation.JsonIgnore
    private List<SensorReading> readings = new ArrayList<>();
}
