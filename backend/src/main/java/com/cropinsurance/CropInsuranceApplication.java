package com.cropinsurance;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Smart AI Crop Insurance System
 * Main Spring Boot Application
 * 
 * @author Semester Project Team
 * @version 1.0.0
 */
@SpringBootApplication
@EnableScheduling
public class CropInsuranceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CropInsuranceApplication.class, args);
        System.out.println("\n");
        System.out.println("╔═══════════════════════════════════════════════════════════╗");
        System.out.println("║     🌾 CROP INSURANCE SYSTEM STARTED SUCCESSFULLY! 🌾     ║");
        System.out.println("╠═══════════════════════════════════════════════════════════╣");
        System.out.println("║  API:     http://localhost:8080                           ║");
        System.out.println("║  Swagger: http://localhost:8080/swagger-ui.html           ║");
        System.out.println("║  Docs:    http://localhost:8080/api-docs                  ║");
        System.out.println("╚═══════════════════════════════════════════════════════════╝");
        System.out.println("\n");
    }
}
