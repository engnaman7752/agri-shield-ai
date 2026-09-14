package com.cropinsurance.entity;

import com.cropinsurance.entity.enums.ClaimStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Claim Entity - Insurance claim filed by farmer
 */
@Entity
@Table(name = "claims")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Claim {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "insurance_id", nullable = false)
    private InsurancePolicy insurance;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id", nullable = false)
    private Farmer farmer;

    @Column(name = "latitude", nullable = false, precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(name = "longitude", nullable = false, precision = 11, scale = 8)
    private BigDecimal longitude;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sensor_id")
    private Sensor sensor;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private ClaimStatus status = ClaimStatus.PENDING;

    @Column(name = "damage_percentage", precision = 5, scale = 2)
    private BigDecimal damagePercentage;

    @Column(name = "claim_amount", precision = 12, scale = 2)
    private BigDecimal claimAmount;

    @CreationTimestamp
    @Column(name = "filed_at", updatable = false)
    private LocalDateTime filedAt;

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    // Weather data captured at claim time
    @Column(name = "weather_temp")
    private BigDecimal weatherTemperature; // in Celsius

    @Column(name = "weather_humidity")
    private BigDecimal weatherHumidity; // in %

    @Column(name = "weather_condition")
    private String weatherCondition; // e.g., "Rain", "Clear", "Cloudy"

    @Column(name = "weather_rainfall")
    private BigDecimal weatherRainfall; // in mm

    // PMFBY Damage Reason
    @Enumerated(EnumType.STRING)
    @Column(name = "damage_reason", length = 50)
    private com.cropinsurance.entity.enums.DamageReason damageReason;

    @Column(name = "damage_reason_detail", columnDefinition = "TEXT")
    private String damageReasonDetail;

    // Claim images
    @OneToMany(mappedBy = "claim", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<ClaimImage> images = new ArrayList<>();

    // AI Assessment
    @OneToOne(mappedBy = "claim", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private AiAssessment aiAssessment;
}
