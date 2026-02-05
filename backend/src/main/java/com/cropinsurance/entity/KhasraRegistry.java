package com.cropinsurance.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * KhasraRegistry Entity - Pre-filled land records (Khasra data)
 */
@Entity
@Table(name = "khasra_registry")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KhasraRegistry {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "village_id", nullable = false)
    private Village village;

    @Column(name = "khasra_number", nullable = false, length = 20)
    private String khasraNumber;

    @Column(name = "area_acres", nullable = false, precision = 10, scale = 2)
    private BigDecimal areaAcres;

    @Column(name = "latitude", nullable = false, precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(name = "longitude", nullable = false, precision = 11, scale = 8)
    private BigDecimal longitude;

    @Column(name = "owner_name", length = 100)
    @Builder.Default
    private String ownerName = "Available";

    @Column(name = "is_registered")
    @Builder.Default
    private Boolean isRegistered = false; // true when a farmer registers this land
}
