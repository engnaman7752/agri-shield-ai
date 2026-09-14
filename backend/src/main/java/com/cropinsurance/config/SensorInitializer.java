package com.cropinsurance.config;

import com.cropinsurance.entity.Sensor;
import com.cropinsurance.repository.SensorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Ensures sensors exist in the database at application startup.
 * This runs AFTER schema.sql and data.sql, guaranteeing sensors are always available.
 */
@Component
@RequiredArgsConstructor
@Slf4j
@Order(1)
public class SensorInitializer implements CommandLineRunner {

    private final SensorRepository sensorRepository;

    @Override
    public void run(String... args) {
        long count = sensorRepository.count();
        log.info("📡 Sensor check on startup: found {} sensors in database", count);

        if (count == 0) {
            log.warn("⚠️ No sensors found! Creating 10 prototype sensors...");
            for (int i = 1; i <= 10; i++) {
                String code = String.format("SENS-%03d", i);
                try {
                    if (!sensorRepository.existsByUniqueCode(code)) {
                        Sensor sensor = new Sensor();
                        sensor.setUniqueCode(code);
                        sensor.setIsActive(true);
                        sensorRepository.saveAndFlush(sensor);
                        log.info("  ✅ Created sensor: {}", code);
                    }
                } catch (Exception e) {
                    log.warn("  ⚠️ Sensor {} skipped: {}", code, e.getMessage());
                }
            }
            log.info("📡 Sensor initialization complete. Total: {}", sensorRepository.count());
        } else {
            log.info("✅ Sensors already exist. No initialization needed.");
        }
    }
}
