package com.cropinsurance.service;

import com.cropinsurance.entity.Sensor;
import com.cropinsurance.entity.SensorReading;
import com.cropinsurance.repository.SensorReadingRepository;
import com.cropinsurance.repository.SensorRepository;
import com.mongodb.client.*;
import com.mongodb.ConnectionString;
import com.mongodb.MongoClientSettings;
import lombok.extern.slf4j.Slf4j;
import org.bson.Document;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;

/**
 * MongoDB Sensor Sync Service
 * 
 * Connects to MongoDB Atlas where ESP32 IoT device pushes sensor readings.
 * Syncs latest 5 readings every 30 minutes into PostgreSQL.
 * Retains data for 7 days for claim verification.
 * Fetches rainfall from OpenWeatherMap API for cross-verification.
 * 
 * Actual MongoDB document structure (from ESP32):
 * {
 *   _id: ObjectId(...),
 *   temp: 22.3,
 *   humidity: 67.3,
 *   soil_moisture: 349,
 *   timestamp: ISODate("2026-04-17T17:42:18.432+00:00"),
 *   __v: 0
 * }
 * 
 * NOTE: Only one sensor in prototype. All readings are assigned to the
 * first active sensor in the system.
 */
@Service
@Slf4j
public class MongoSensorSyncService {

    private final SensorRepository sensorRepository;
    private final SensorReadingRepository sensorReadingRepository;

    @Value("${mongodb.uri:}")
    private String mongoUri;

    @Value("${mongodb.database:test}")
    private String databaseName;

    @Value("${mongodb.collection:sensors}")
    private String collectionName;

    @Value("${mongodb.sync.retention-days:7}")
    private int retentionDays;

    @Value("${weather.api.key:}")
    private String weatherApiKey;

    @Value("${weather.api.url:https://api.openweathermap.org/data/2.5/weather}")
    private String weatherApiUrl;

    private MongoClient mongoClient;
    private boolean mongoAvailable = false;

    public MongoSensorSyncService(SensorRepository sensorRepository,
                                   SensorReadingRepository sensorReadingRepository) {
        this.sensorRepository = sensorRepository;
        this.sensorReadingRepository = sensorReadingRepository;
    }

    @PostConstruct
    public void init() {
        if (mongoUri == null || mongoUri.isEmpty()) {
            log.warn("⚠️ MongoDB URI not configured. IoT sensor sync disabled.");
            return;
        }

        try {
            MongoClientSettings settings = MongoClientSettings.builder()
                    .applyConnectionString(new ConnectionString(mongoUri))
                    .build();
            mongoClient = MongoClients.create(settings);

            // Test connection by listing collections
            mongoClient.getDatabase(databaseName).listCollectionNames().first();
            mongoAvailable = true;
            log.info("✅ MongoDB Atlas connected! DB: {}, Collection: {}", databaseName, collectionName);
        } catch (Exception e) {
            log.warn("⚠️ MongoDB connection failed: {}. IoT sync will use fallback.", e.getMessage());
            mongoAvailable = false;
        }
    }

    @PreDestroy
    public void cleanup() {
        if (mongoClient != null) {
            mongoClient.close();
            log.info("🔌 MongoDB connection closed.");
        }
    }

    /**
     * Scheduled sync: Fetch latest 5 readings from MongoDB every 30 min
     */
    @Scheduled(fixedDelayString = "${mongodb.sync.interval-ms:1800000}", initialDelay = 10000)
    public void syncSensorData() {
        if (!mongoAvailable) {
            log.debug("MongoDB not available, skipping sync.");
            return;
        }

        log.info("🔄 Syncing IoT sensor data from MongoDB Atlas...");

        try {
            MongoDatabase database = mongoClient.getDatabase(databaseName);
            MongoCollection<Document> collection = database.getCollection(collectionName);

            // PROTOTYPE: Only one sensor — assign all readings to first active sensor
            Sensor sensor = getPrototypeSensor();
            if (sensor == null) {
                log.warn("No active sensor found in system. Skipping sync.");
                return;
            }

            // Fetch latest 5 readings sorted by timestamp descending
            List<Document> docs = new ArrayList<>();
            collection.find()
                    .sort(new Document("timestamp", -1))
                    .limit(5)
                    .into(docs);

            int synced = 0;
            for (Document doc : docs) {
                LocalDateTime recordedAt = extractTimestamp(doc);
                if (recordedAt == null) continue;

                // Skip duplicates
                if (sensorReadingRepository.existsBySensorIdAndRecordedAt(sensor.getId(), recordedAt)) {
                    continue;
                }

                // Map ESP32 fields: temp, humidity, soil_moisture (raw analog 0-1023)
                BigDecimal temperature = extractBigDecimal(doc, "temp");
                BigDecimal humidity = extractBigDecimal(doc, "humidity");
                BigDecimal soilMoistureRaw = extractBigDecimal(doc, "soil_moisture");

                // Convert raw soil moisture (0-1023 analog) to percentage (0-100)
                // Higher raw value = drier soil (capacitive sensor), so invert
                BigDecimal soilMoisturePct = null;
                if (soilMoistureRaw != null) {
                    double raw = soilMoistureRaw.doubleValue();
                    double pct = Math.max(0, Math.min(100, (1023 - raw) / 1023 * 100));
                    soilMoisturePct = BigDecimal.valueOf(pct).setScale(2, BigDecimal.ROUND_HALF_UP);
                }

                SensorReading reading = SensorReading.builder()
                        .sensor(sensor)
                        .temperature(temperature)
                        .humidity(humidity)
                        .soilMoisture(soilMoisturePct)
                        .rainfall(null) // Will be filled by weather API
                        .recordedAt(recordedAt)
                        .build();

                sensorReadingRepository.save(reading);
                synced++;
            }

            // Update sensor timestamp
            if (synced > 0) {
                sensor.setLastReadingAt(LocalDateTime.now());
                sensorRepository.save(sensor);
            }

            // Cleanup old data
            cleanupOldReadings();

            log.info("✅ IoT sync done: {} new readings from ESP32", synced);

        } catch (Exception e) {
            log.error("❌ IoT sensor sync failed: {}", e.getMessage());
        }
    }

    /**
     * Manual sync for a specific sensor (called during claim verification)
     */
    public List<SensorReading> fetchLatestForSensor(String sensorCode) {
        if (!mongoAvailable) {
            return Collections.emptyList();
        }

        try {
            Sensor sensor = sensorRepository.findByUniqueCode(sensorCode).orElse(null);
            if (sensor == null) return Collections.emptyList();

            MongoDatabase database = mongoClient.getDatabase(databaseName);
            MongoCollection<Document> collection = database.getCollection(collectionName);

            // Fetch latest 5 readings (single sensor prototype — no filter by sensor_id)
            List<Document> docs = new ArrayList<>();
            collection.find()
                    .sort(new Document("timestamp", -1))
                    .limit(5)
                    .into(docs);

            List<SensorReading> readings = new ArrayList<>();
            for (Document doc : docs) {
                LocalDateTime recordedAt = extractTimestamp(doc);
                if (recordedAt == null) continue;

                BigDecimal temperature = extractBigDecimal(doc, "temp");
                BigDecimal humidity = extractBigDecimal(doc, "humidity");
                BigDecimal soilMoistureRaw = extractBigDecimal(doc, "soil_moisture");
                BigDecimal soilMoisturePct = null;
                if (soilMoistureRaw != null) {
                    double raw = soilMoistureRaw.doubleValue();
                    double pct = Math.max(0, Math.min(100, (1023 - raw) / 1023 * 100));
                    soilMoisturePct = BigDecimal.valueOf(pct).setScale(2, BigDecimal.ROUND_HALF_UP);
                }

                SensorReading reading = SensorReading.builder()
                        .sensor(sensor)
                        .temperature(temperature)
                        .humidity(humidity)
                        .soilMoisture(soilMoisturePct)
                        .rainfall(null)
                        .recordedAt(recordedAt)
                        .build();

                if (!sensorReadingRepository.existsBySensorIdAndRecordedAt(sensor.getId(), recordedAt)) {
                    sensorReadingRepository.save(reading);
                }
                readings.add(reading);
            }

            return readings;

        } catch (Exception e) {
            log.error("❌ Manual sync failed: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * Get 7-day sensor data summary for claim verification
     * Includes IoT data + OpenWeatherMap rainfall
     */
    public Map<String, Object> getSensorDataForClaim(String sensorCode) {
        Map<String, Object> summary = new LinkedHashMap<>();

        // Fresh sync from MongoDB
        fetchLatestForSensor(sensorCode);

        Optional<Sensor> sensorOpt = sensorRepository.findByUniqueCode(sensorCode);
        if (sensorOpt.isEmpty()) {
            summary.put("error", "Sensor not found: " + sensorCode);
            return summary;
        }

        Sensor sensor = sensorOpt.get();
        LocalDateTime sevenDaysAgo = LocalDateTime.now().minusDays(7);

        List<SensorReading> readings = sensorReadingRepository
                .findBySensorIdAndRecordedAtAfterOrderByRecordedAtDesc(sensor.getId(), sevenDaysAgo);

        summary.put("sensorCode", sensorCode);
        summary.put("totalReadings", readings.size());
        summary.put("dataSource", mongoAvailable ? "ESP32 → MongoDB Atlas" : "Local PostgreSQL");
        summary.put("periodDays", 7);

        if (!readings.isEmpty()) {
            // Calculate averages
            double avgTemp = readings.stream()
                    .filter(r -> r.getTemperature() != null)
                    .mapToDouble(r -> r.getTemperature().doubleValue())
                    .average().orElse(0);

            double avgHumidity = readings.stream()
                    .filter(r -> r.getHumidity() != null)
                    .mapToDouble(r -> r.getHumidity().doubleValue())
                    .average().orElse(0);

            double avgMoisture = readings.stream()
                    .filter(r -> r.getSoilMoisture() != null)
                    .mapToDouble(r -> r.getSoilMoisture().doubleValue())
                    .average().orElse(0);

            double maxTemp = readings.stream()
                    .filter(r -> r.getTemperature() != null)
                    .mapToDouble(r -> r.getTemperature().doubleValue())
                    .max().orElse(0);

            double minTemp = readings.stream()
                    .filter(r -> r.getTemperature() != null)
                    .mapToDouble(r -> r.getTemperature().doubleValue())
                    .min().orElse(0);

            summary.put("avgTemperature", String.format("%.1f°C", avgTemp));
            summary.put("maxTemperature", String.format("%.1f°C", maxTemp));
            summary.put("minTemperature", String.format("%.1f°C", minTemp));
            summary.put("avgHumidity", String.format("%.1f%%", avgHumidity));
            summary.put("avgSoilMoisture", String.format("%.1f%%", avgMoisture));
            summary.put("lastReadingAt", readings.get(0).getRecordedAt().toString());

            // Risk assessment flags
            List<String> risks = new ArrayList<>();
            if (maxTemp > 42) risks.add("🔥 EXTREME_HEAT (>" + maxTemp + "°C)");
            if (minTemp < 5) risks.add("❄️ FROST_RISK (<" + minTemp + "°C)");
            if (avgHumidity > 85) risks.add("💧 HIGH_HUMIDITY_DISEASE_RISK");
            if (avgMoisture < 20) risks.add("🏜️ DROUGHT_RISK (soil moisture <20%)");
            if (avgMoisture > 90) risks.add("🌊 WATERLOGGING_RISK");
            summary.put("riskFlags", risks);

            // Add individual readings (latest 5)
            List<Map<String, Object>> readingDetails = new ArrayList<>();
            for (int i = 0; i < Math.min(5, readings.size()); i++) {
                SensorReading r = readings.get(i);
                Map<String, Object> rd = new LinkedHashMap<>();
                rd.put("timestamp", r.getRecordedAt().toString());
                rd.put("temperature", r.getTemperature() != null ? r.getTemperature() + "°C" : "N/A");
                rd.put("humidity", r.getHumidity() != null ? r.getHumidity() + "%" : "N/A");
                rd.put("soilMoisture", r.getSoilMoisture() != null ? r.getSoilMoisture() + "%" : "N/A");
                readingDetails.add(rd);
            }
            summary.put("latestReadings", readingDetails);
        }

        // Fetch rainfall from OpenWeatherMap if API key is configured
        try {
            Map<String, Object> weather = fetchWeatherData(sensor);
            if (weather != null) {
                summary.put("weatherData", weather);
            }
        } catch (Exception e) {
            log.warn("Weather API not available: {}", e.getMessage());
        }

        return summary;
    }

    /**
     * Fetch current weather data from OpenWeatherMap API
     */
    private Map<String, Object> fetchWeatherData(Sensor sensor) {
        if (weatherApiKey == null || weatherApiKey.isEmpty()) {
            // No API key — return simulated weather for demo
            Map<String, Object> mock = new LinkedHashMap<>();
            mock.put("source", "Simulated (no API key)");
            mock.put("rainfall_mm", 12.5);
            mock.put("weather_condition", "Light Rain");
            mock.put("wind_speed_kmh", 15.3);
            return mock;
        }

        try {
            // Get lat/lng from associated land
            if (sensor.getLands() == null || sensor.getLands().isEmpty()) return null;

            double lat = sensor.getLands().get(0).getLatitude().doubleValue();
            double lon = sensor.getLands().get(0).getLongitude().doubleValue();

            WebClient client = WebClient.create();
            String url = String.format("%s?lat=%.4f&lon=%.4f&appid=%s&units=metric",
                    weatherApiUrl, lat, lon, weatherApiKey);

            Map response = client.get()
                    .uri(url)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (response != null) {
                Map<String, Object> result = new LinkedHashMap<>();
                result.put("source", "OpenWeatherMap API");

                // Extract rainfall
                Map rain = (Map) response.get("rain");
                if (rain != null) {
                    result.put("rainfall_1h_mm", rain.get("1h"));
                    result.put("rainfall_3h_mm", rain.get("3h"));
                }

                // Extract main weather
                List weather = (List) response.get("weather");
                if (weather != null && !weather.isEmpty()) {
                    Map w = (Map) weather.get(0);
                    result.put("weather_condition", w.get("description"));
                }

                // Extract temp/humidity from API too (for cross-verification)
                Map main = (Map) response.get("main");
                if (main != null) {
                    result.put("api_temperature", main.get("temp") + "°C");
                    result.put("api_humidity", main.get("humidity") + "%");
                }

                return result;
            }
        } catch (Exception e) {
            log.warn("OpenWeatherMap API error: {}", e.getMessage());
        }
        return null;
    }

    /**
     * PROTOTYPE: Get the first active sensor to assign all readings to
     */
    private Sensor getPrototypeSensor() {
        return sensorRepository.findByUniqueCode("SENS-001")
                .orElseGet(() -> {
                    List<Sensor> sensors = sensorRepository.findAll();
                    return sensors.isEmpty() ? null : sensors.get(0);
                });
    }

    /**
     * Delete readings older than retention period
     */
    private void cleanupOldReadings() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(retentionDays);
        long deleted = sensorReadingRepository.deleteByRecordedAtBefore(cutoff);
        if (deleted > 0) {
            log.info("🧹 Cleaned {} old sensor readings (> {} days)", deleted, retentionDays);
        }
    }

    // ============================================
    // Helper methods for MongoDB document parsing
    // ============================================

    private LocalDateTime extractTimestamp(Document doc) {
        Object ts = doc.get("timestamp");
        if (ts instanceof Date) {
            return ((Date) ts).toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
        } else if (ts instanceof Long) {
            return Instant.ofEpochMilli((Long) ts).atZone(ZoneId.systemDefault()).toLocalDateTime();
        } else if (ts instanceof String) {
            try {
                return Instant.parse((String) ts).atZone(ZoneId.systemDefault()).toLocalDateTime();
            } catch (Exception e) {
                try {
                    return LocalDateTime.parse((String) ts);
                } catch (Exception e2) {
                    return null;
                }
            }
        }
        return LocalDateTime.now();
    }

    private BigDecimal extractBigDecimal(Document doc, String field) {
        Object val = doc.get(field);
        if (val instanceof Number) {
            return BigDecimal.valueOf(((Number) val).doubleValue());
        }
        return null;
    }

    public boolean isMongoAvailable() {
        return mongoAvailable;
    }
}
