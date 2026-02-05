package com.cropinsurance.service;

import com.cropinsurance.dto.request.SensorReadingRequest;
import com.cropinsurance.entity.Sensor;
import com.cropinsurance.entity.SensorReading;
import com.cropinsurance.exception.ResourceNotFoundException;
import com.cropinsurance.repository.SensorReadingRepository;
import com.cropinsurance.repository.SensorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Sensor Service - IoT sensor data management
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SensorService {

    private final SensorRepository sensorRepository;
    private final SensorReadingRepository sensorReadingRepository;

    /**
     * Record sensor reading (from simulator or real sensor)
     */
    @Transactional
    public SensorReading recordReading(SensorReadingRequest request) {
        Sensor sensor = sensorRepository.findByUniqueCode(request.getSensorCode())
                .orElseThrow(() -> new ResourceNotFoundException("Sensor", "code", request.getSensorCode()));

        SensorReading reading = SensorReading.builder()
                .sensor(sensor)
                .soilMoisture(request.getSoilMoisture())
                .humidity(request.getHumidity())
                .temperature(request.getTemperature())
                .rainfall(request.getRainfall())
                .build();

        reading = sensorReadingRepository.save(reading);

        // Update sensor last reading time
        sensor.setLastReadingAt(LocalDateTime.now());
        sensorRepository.save(sensor);

        log.info("📊 Sensor {} reading: moisture={}%, humidity={}%, temp={}°C",
                sensor.getUniqueCode(),
                request.getSoilMoisture(),
                request.getHumidity(),
                request.getTemperature());

        return reading;
    }

    /**
     * Get latest readings for a sensor
     */
    public List<SensorReading> getLatestReadings(String sensorCode, int limit) {
        Sensor sensor = sensorRepository.findByUniqueCode(sensorCode)
                .orElseThrow(() -> new ResourceNotFoundException("Sensor", "code", sensorCode));

        return sensorReadingRepository.findLatestBySensorId(sensor.getId(), PageRequest.of(0, limit));
    }

    /**
     * Get sensor by code
     */
    public Sensor getSensorByCode(String sensorCode) {
        return sensorRepository.findByUniqueCode(sensorCode)
                .orElseThrow(() -> new ResourceNotFoundException("Sensor", "code", sensorCode));
    }

    /**
     * Get all sensors
     */
    public List<Sensor> getAllSensors() {
        return sensorRepository.findAll();
    }
}
