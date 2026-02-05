package com.cropinsurance.controller;

import com.cropinsurance.dto.request.SensorReadingRequest;
import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.entity.Sensor;
import com.cropinsurance.entity.SensorReading;
import com.cropinsurance.service.SensorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Sensor Controller
 * IoT sensor data management (for simulator and real sensors)
 */
@RestController
@RequestMapping("/api/sensors")
@RequiredArgsConstructor
@Tag(name = "Sensors", description = "IoT sensor data management")
public class SensorController {

    private final SensorService sensorService;

    /**
     * Record sensor reading (from simulator or real sensor)
     */
    @PostMapping("/reading")
    @Operation(summary = "Record a sensor reading")
    public ResponseEntity<ApiResponse<SensorReading>> recordReading(
            @Valid @RequestBody SensorReadingRequest request) {
        SensorReading reading = sensorService.recordReading(request);
        return ResponseEntity.ok(ApiResponse.success(reading, "Reading recorded successfully"));
    }

    /**
     * Get latest readings for a sensor
     */
    @GetMapping("/{sensorCode}/readings")
    @Operation(summary = "Get latest readings for a sensor")
    public ResponseEntity<ApiResponse<List<SensorReading>>> getReadings(
            @PathVariable String sensorCode,
            @RequestParam(defaultValue = "10") int limit) {
        List<SensorReading> readings = sensorService.getLatestReadings(sensorCode, limit);
        return ResponseEntity.ok(ApiResponse.success(readings));
    }

    /**
     * Get sensor by code
     */
    @GetMapping("/{sensorCode}")
    @Operation(summary = "Get sensor details")
    public ResponseEntity<ApiResponse<Sensor>> getSensor(@PathVariable String sensorCode) {
        Sensor sensor = sensorService.getSensorByCode(sensorCode);
        return ResponseEntity.ok(ApiResponse.success(sensor));
    }

    /**
     * Get all sensors
     */
    @GetMapping
    @Operation(summary = "Get all sensors")
    public ResponseEntity<ApiResponse<List<Sensor>>> getAllSensors() {
        List<Sensor> sensors = sensorService.getAllSensors();
        return ResponseEntity.ok(ApiResponse.success(sensors));
    }
}
