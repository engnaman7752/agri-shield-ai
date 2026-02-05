package com.cropinsurance.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * AiAssessment Entity - AI model prediction results
 */
@Entity
@Table(name = "ai_assessments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiAssessment {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "claim_id", nullable = false)
    private Claim claim;

    @Column(name = "damage_percentage", nullable = false, precision = 5, scale = 2)
    private BigDecimal damagePercentage;

    @Column(name = "model_version", nullable = false, length = 20)
    private String modelVersion;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "prediction_details", columnDefinition = "jsonb")
    private Map<String, Object> predictionDetails;

    @CreationTimestamp
    @Column(name = "assessed_at")
    private LocalDateTime assessedAt;
}
