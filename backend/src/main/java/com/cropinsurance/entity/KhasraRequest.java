package com.cropinsurance.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * KhasraRequest Entity - Farmer-submitted land records pending Patwari approval
 */
@Entity
@Table(name = "khasra_requests")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KhasraRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id", nullable = false)
    private Farmer farmer;

    @Column(name = "village", nullable = false, length = 50)
    private String village;

    @Column(name = "khasra_number", nullable = false, length = 50)
    private String khasraNumber;

    @Column(name = "area_acres", nullable = false, precision = 10, scale = 2)
    private BigDecimal areaAcres;

    @Column(name = "latitude", nullable = false, precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(name = "longitude", nullable = false, precision = 11, scale = 8)
    private BigDecimal longitude;

    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "PENDING"; // PENDING, APPROVED, REJECTED

    @Column(name = "patwari_remarks")
    private String patwariRemarks;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "processed_at")
    private LocalDateTime processedAt;
}
