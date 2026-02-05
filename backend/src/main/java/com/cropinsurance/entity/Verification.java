package com.cropinsurance.entity;

import com.cropinsurance.entity.enums.VerificationStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Verification Entity - Patwari verification of insurance application
 */
@Entity
@Table(name = "verifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Verification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "insurance_id", nullable = false)
    private InsurancePolicy insurance;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patwari_id")
    private Patwari patwari;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private VerificationStatus status = VerificationStatus.PENDING;

    @Column(name = "remarks", columnDefinition = "TEXT")
    private String remarks;

    @Column(name = "assigned_sensor_id")
    private UUID assignedSensorId;

    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;
}
