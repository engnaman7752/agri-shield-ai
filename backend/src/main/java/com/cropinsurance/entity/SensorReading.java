package com.cropinsurance.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * SensorReading Entity - Readings from IoT sensors
 */
@Entity
@Table(name = "sensor_readings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SensorReading {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sensor_id", nullable = false)
    private Sensor sensor;

    @Column(name = "soil_moisture", precision = 5, scale = 2)
    private BigDecimal soilMoisture;  // Percentage 0-100

    @Column(name = "humidity", precision = 5, scale = 2)
    private BigDecimal humidity;  // Percentage 0-100

    @Column(name = "temperature", precision = 5, scale = 2)
    private BigDecimal temperature;  // Celsius

    @Column(name = "rainfall", precision = 5, scale = 2)
    private BigDecimal rainfall;  // mm

    @CreationTimestamp
    @Column(name = "recorded_at")
    private LocalDateTime recordedAt;
}
