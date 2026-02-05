package com.cropinsurance.service;

import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * AI Service - Communicates with FastAPI AI model service
 * For prototype: simulates AI predictions
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AiService {

    private final WebClient.Builder webClientBuilder;
    private final Random random = new Random();

    @Value("${ai.service.url:http://localhost:8000}")
    private String aiServiceUrl;

    /**
     * Predict crop damage from images
     */
    public AiPredictionResult predictDamage(List<String> imageUrls) {
        log.info("🤖 Sending {} images to AI service for analysis", imageUrls.size());

        try {
            // Try to call real AI service
            return callRealAiService(imageUrls);
        } catch (Exception e) {
            log.warn("⚠️ AI service not available, using simulated prediction: {}", e.getMessage());
            return simulatePrediction(imageUrls);
        }
    }

    /**
     * Call real AI service (FastAPI)
     */
    private AiPredictionResult callRealAiService(List<String> imageUrls) {
        WebClient client = webClientBuilder.baseUrl(aiServiceUrl).build();

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("image_urls", imageUrls);

        Map response = client.post()
                .uri("/api/predict")
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(Map.class)
                .block();

        if (response != null) {
            double damage = ((Number) response.get("damage_percentage")).doubleValue();
            String disease = (String) response.get("disease_detected");
            String modelVersion = (String) response.getOrDefault("model_version", "1.0.0");

            return AiPredictionResult.builder()
                    .damagePercentage(BigDecimal.valueOf(damage))
                    .diseaseDetected(disease)
                    .modelVersion(modelVersion)
                    .details(response)
                    .build();
        }

        throw new RuntimeException("Empty response from AI service");
    }

    /**
     * Simulate AI prediction (for prototype when AI service is not running)
     */
    private AiPredictionResult simulatePrediction(List<String> imageUrls) {
        // Simulate realistic damage percentages
        // 40% chance of high damage (75-95%)
        // 30% chance of medium damage (40-74%)
        // 30% chance of low damage (5-39%)

        double damagePercent;
        String disease;
        double roll = random.nextDouble();

        if (roll < 0.4) {
            // High damage
            damagePercent = 75 + random.nextDouble() * 20; // 75-95%
            disease = pickRandomDisease(true);
        } else if (roll < 0.7) {
            // Medium damage
            damagePercent = 40 + random.nextDouble() * 34; // 40-74%
            disease = pickRandomDisease(false);
        } else {
            // Low damage
            damagePercent = 5 + random.nextDouble() * 34; // 5-39%
            disease = "Minor stress detected";
        }

        Map<String, Object> details = new HashMap<>();
        details.put("simulated", true);
        details.put("confidence", 0.85 + random.nextDouble() * 0.1);
        details.put("analysis", String.format("Analyzed %d images, detected: %s", imageUrls.size(), disease));
        details.put("affected_area_percent", damagePercent);

        log.info("🔮 Simulated prediction: {:.1f}% damage, disease: {}", damagePercent, disease);

        return AiPredictionResult.builder()
                .damagePercentage(BigDecimal.valueOf(damagePercent).setScale(2, BigDecimal.ROUND_HALF_UP))
                .diseaseDetected(disease)
                .modelVersion("SIMULATED-1.0")
                .details(details)
                .build();
    }

    private String pickRandomDisease(boolean severe) {
        String[] severesDiseases = {
                "Late Blight",
                "Bacterial Leaf Blight",
                "Brown Spot Disease",
                "Wheat Rust",
                "Downy Mildew"
        };

        String[] mildDiseases = {
                "Early Blight",
                "Leaf Curl",
                "Powdery Mildew",
                "Mosaic Virus",
                "Nutrient Deficiency"
        };

        String[] pool = severe ? severesDiseases : mildDiseases;
        return pool[random.nextInt(pool.length)];
    }

    /**
     * AI Prediction Result DTO
     */
    @Data
    @Builder
    public static class AiPredictionResult {
        private BigDecimal damagePercentage;
        private String diseaseDetected;
        private String modelVersion;
        private Map<String, Object> details;
    }
}
