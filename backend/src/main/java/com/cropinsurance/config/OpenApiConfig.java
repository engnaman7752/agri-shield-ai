package com.cropinsurance.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(info = @Info(title = "🌾 Crop Insurance API", version = "1.0.0", description = "Smart AI Crop Insurance System - Backend API\n\n"
        +
        "## Authentication\n" +
        "- **Farmer**: Phone + OTP (OTP is always `123456` in mock mode)\n" +
        "- **Patwari**: Government ID + Password\n\n" +
        "## Demo Credentials\n" +
        "| User | Login | Credential |\n" +
        "|------|-------|------------|\n" +
        "| Farmer | 8440071773 | OTP: 123456 |\n" +
        "| Patwari | PAT-RJ-001 | password123 |", contact = @Contact(name = "Semester Project Team")), servers = {
                @Server(url = "http://localhost:8080", description = "Local Development")
        })
@SecurityScheme(name = "bearerAuth", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT")
public class OpenApiConfig {
}
