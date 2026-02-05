package com.cropinsurance.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * CropType Entity - Master data for crop types
 */
@Entity
@Table(name = "crop_types")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CropType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", unique = true, nullable = false, length = 50)
    private String name;

    @Column(name = "name_hindi", length = 50)
    private String nameHindi;

    @Column(name = "season", length = 20)
    private String season; // Kharif, Rabi, Zaid

    @Column(name = "premium_rate", precision = 5, scale = 2)
    private BigDecimal premiumRate; // % of coverage

    @Column(name = "max_coverage", precision = 12, scale = 2)
    private BigDecimal maxCoverage;
}
