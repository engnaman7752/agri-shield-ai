# 🌾 Crop Insurance Backend - Spring Boot

## Quick Start

### Prerequisites
- Java 17+
- Maven 3.8+
- PostgreSQL 14+

### 1. Setup Database
```powershell
# Create database
psql -U postgres -c "CREATE DATABASE crop_insurance_db;"

# Run schema (creates tables)
psql -U postgres -d crop_insurance_db -f src/main/resources/schema.sql

# Run seed data (demo data)
psql -U postgres -d crop_insurance_db -f src/main/resources/data.sql
```

### 2. Configure Application
Update `src/main/resources/application.properties`:
```properties
# Database
spring.datasource.username=postgres
spring.datasource.password=YOUR_PASSWORD

# SMS (optional - mock mode by default)
sms.mock-mode=true
# For real SMS, get API key from fast2sms.com
sms.fast2sms.api-key=YOUR_API_KEY
```

### 3. Run Application
```powershell
cd backend
mvn spring-boot:run
```

### 4. Access
- **API**: http://localhost:8080
- **Swagger UI**: http://localhost:8080/swagger-ui.html

---

## 🔐 Demo Credentials

### Farmer Login (Phone + OTP)
| Phone | OTP |
|-------|-----|
| **8440071773** (Your phone) | 123456 |
| 9999900001 | 123456 |

### Patwari Login (GovtID + Password)
| Government ID | Password |
|---------------|----------|
| PAT-RJ-001 (Kota) | password123 |
| PAT-MP-001 (Bhopal) | password123 |

---

## 📡 API Endpoints

### Authentication
```
POST /api/auth/farmer/send-otp    - Send OTP
POST /api/auth/farmer/verify-otp  - Verify OTP & login
POST /api/auth/farmer/register    - Register new farmer
POST /api/auth/patwari/login      - Patwari login
```

### Location (Public)
```
GET  /api/location/states                           - Get states
GET  /api/location/districts/{stateName}            - Get districts
GET  /api/location/villages/{state}/{district}      - Get villages
GET  /api/location/khasra/available                 - Get available khasra
GET  /api/location/crops                            - Get crop types
```

### Farmer (Requires Auth)
```
GET  /api/farmer/profile          - Get profile
PUT  /api/farmer/profile          - Update profile
POST /api/farmer/profile/photo    - Upload photo
```

### Insurance (Requires Auth)
```
POST /api/insurance/apply           - Apply for insurance
POST /api/insurance/payment/confirm - Confirm payment
GET  /api/insurance/my-policies     - Get my policies
GET  /api/insurance/active          - Get active policies
```

### Claims (Requires Auth)
```
POST /api/claims                  - File claim (with images)
GET  /api/claims/my-claims        - Get my claims
GET  /api/claims/{claimId}        - Get claim details
```

### Patwari (Requires Patwari Auth)
```
GET  /api/patwari/verifications/pending  - Get pending verifications
POST /api/patwari/verifications/action   - Approve/reject
GET  /api/patwari/sensors/available      - Get available sensors
```

### Sensors
```
POST /api/sensors/reading              - Record reading
GET  /api/sensors/{code}/readings      - Get readings
```

---

## 📁 Project Structure

```
backend/
├── pom.xml
└── src/main/java/com/cropinsurance/
    ├── CropInsuranceApplication.java   # Main class
    ├── config/
    │   ├── SecurityConfig.java         # JWT security
    │   ├── OpenApiConfig.java          # Swagger
    │   └── WebConfig.java              # File serving
    ├── controller/                      # REST controllers
    ├── dto/
    │   ├── request/                     # Request DTOs
    │   └── response/                    # Response DTOs
    ├── entity/                          # JPA entities
    │   └── enums/                       # Status enums
    ├── exception/                       # Custom exceptions
    ├── repository/                      # JPA repositories
    ├── security/
    │   ├── JwtTokenProvider.java        # JWT generation
    │   └── JwtAuthenticationFilter.java # JWT validation
    └── service/                         # Business logic
```

---

## 🔥 Real SMS Setup (Fast2SMS)

1. Go to https://www.fast2sms.com/
2. Create free account
3. Get API key from dashboard
4. Update `application.properties`:
```properties
sms.mock-mode=false
sms.fast2sms.api-key=YOUR_API_KEY
```

Now OTP will be sent to your real phone! 📱
