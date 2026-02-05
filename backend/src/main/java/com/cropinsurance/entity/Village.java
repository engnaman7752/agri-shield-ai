package com.cropinsurance.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Village Entity - Master data for villages with GPS center
 */
@Entity
@Table(name = "villages")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Village {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "district_id", nullable = false)
    private District district;

    @Column(name = "name", nullable = false, length = 50)
    private String name;

    @Column(name = "center_latitude", nullable = false, precision = 10, scale = 8)
    private BigDecimal centerLatitude;

    @Column(name = "center_longitude", nullable = false, precision = 11, scale = 8)
    private BigDecimal centerLongitude;
}
