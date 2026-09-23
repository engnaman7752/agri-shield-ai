# 🌾 Agri Shield AI

**AI-Powered Crop Insurance Platform** — Protecting farmers with smart, automated crop damage assessment using deep learning.

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.0-brightgreen)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.9+-yellow)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#1-backend-setup)
  - [AI Service Setup](#2-ai-service-setup)
  - [Mobile Apps Setup](#3-mobile-apps-setup)
- [API Documentation](#-api-documentation)
- [Demo Credentials](#-demo-credentials)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**Agri Shield AI** is a comprehensive crop insurance management system that leverages artificial intelligence to automate crop damage assessment. The platform connects farmers, government officials (Patwaris), and insurers through a seamless digital workflow.

### The Problem
- Traditional crop insurance relies on manual inspections
- Delayed claim processing causes financial stress for farmers
- Inconsistent damage assessments lead to disputes
- Lack of transparency in the claims process

### Our Solution
- **AI-powered damage detection** using ResNet50 trained on PlantVillage dataset (98.7% accuracy)
- **Real-time claim processing** with automated damage percentage calculation
- **Multi-stakeholder platform** connecting farmers, verifiers, and insurers
- **IoT sensor integration** for environmental data collection

---

## ✨ Features

### 👨‍🌾 For Farmers
- Phone-based OTP authentication
- Easy insurance policy enrollment
- One-click claim filing with photo uploads
- **AI Agent Chatbot** for instant Q&A and policy support
- Real-time claim status tracking
- Razorpay payment integration
- Push notifications for updates
- **Runtime server configuration** — Easily switch backend servers without rebuilding

### 👮 For Patwaris (Government Verifiers)
- QR-code based farmer verification
- Pending claims dashboard
- Field verification workflow
- GPS-tagged inspections
- Sensor data integration
- **Runtime server configuration** — Configure backend IP on the fly

### 🤖 AI Capabilities
- **AI Chatbot**: Conversational agent providing 24/7 agricultural & policy assistance
- **Model**: ResNet-50 (50-layer Residual Network)
- **Dataset**: PlantVillage (54,000+ images, 38 classes)
- **Accuracy**: ~98.7% on validation set
- **Supported Crops**: Apple, Corn, Grape, Potato, Tomato, Pepper, and more
- **Diseases Detected**: 38 categories including blight, rust, rot, mildew

### 🔐 Security
- JWT-based authentication
- Role-based access control (Farmer/Patwari)
- Secure file uploads
- Input validation & sanitization

---

## 🏗 Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Farmer App    │     │   Patwari App   │     │  Admin Dashboard│
│    (Flutter)    │     │    (Flutter)    │     │     (Web)       │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │     Spring Boot API     │
                    │    (REST + Security)    │
                    └────────────┬────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌────────▼────────┐    ┌────────▼────────┐    ┌────────▼────────┐
│   PostgreSQL    │    │   AI Service    │    │   File Storage  │
│   (Database)    │    │  (FastAPI +     │    │   (Uploads)     │
│                 │    │   ResNet50)     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|------------|
| **Mobile Apps** | Flutter 3.8+, Riverpod, Dio |
| **Backend API** | Spring Boot 3.2, Spring Security, JPA |
| **AI Service** | Python 3.9+, FastAPI, PyTorch, ResNet50 |
| **Database** | PostgreSQL 14+ |
| **Authentication** | JWT, OTP (Fast2SMS) |
| **Payments** | Razorpay |
| **Documentation** | Swagger/OpenAPI |

---

## 📁 Project Structure

```
agri-shield-ai/
├── 📱 farmer_app/          # Flutter app for farmers
│   ├── lib/
│   │   ├── core/           # Shared utilities, themes, constants
│   │   └── features/       # Feature modules
│   │       ├── auth/       # OTP login/registration
│   │       ├── dashboard/  # Home screen
│   │       ├── insurance/  # Policy management
│   │       ├── claims/     # Claim filing
│   │       └── profile/    # User profile
│   └── pubspec.yaml
│
├── 📱 patwari_app/         # Flutter app for government verifiers
│   ├── lib/
│   │   ├── core/
│   │   └── features/
│   │       ├── auth/       # GovtID login
│   │       └── verification/ # Claim verification
│   └── pubspec.yaml
│
├── ⚙️ backend/              # Spring Boot REST API
│   ├── src/main/java/com/cropinsurance/
│   │   ├── config/         # Security, Swagger, Web configs
│   │   ├── controller/     # REST endpoints
│   │   ├── dto/            # Request/Response DTOs
│   │   ├── entity/         # JPA entities
│   │   ├── repository/     # Data access layer
│   │   ├── security/       # JWT implementation
│   │   └── service/        # Business logic
│   ├── src/main/resources/
│   │   ├── application.properties
│   │   ├── schema.sql      # Database schema
│   │   └── data.sql        # Seed data
│   └── pom.xml
│
├── 🤖 ai_service/          # FastAPI AI microservice
│   ├── main.py             # ResNet50 inference API
│   ├── requirements.txt
│   └── README.md
│
├── 🖥️ admin_dashboard/     # Web admin panel (future)
│
└── 📂 uploads/             # File storage for claim images
    └── claims/
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| Java | 21+ | [Download](https://adoptium.net/) |
| Maven | 3.8+ | [Download](https://maven.apache.org/) |
| PostgreSQL | 14+ | [Download](https://postgresql.org/) |
| Python | 3.9+ | [Download](https://python.org/) |
| Flutter | 3.8+ | [Download](https://flutter.dev/) |
| Android Studio | Latest | [Download](https://developer.android.com/studio) |

---

### 1. Backend Setup

```bash
# Navigate to backend
cd backend

# Create PostgreSQL database
psql -U postgres -c "CREATE DATABASE crop_insurance_db;"

# Run schema
psql -U postgres -d crop_insurance_db -f src/main/resources/schema.sql

# Run seed data
psql -U postgres -d crop_insurance_db -f src/main/resources/data.sql

# Configure application.properties
# Update: spring.datasource.password=YOUR_PASSWORD

# Run the server
mvn spring-boot:run
```

**Backend runs at**: `http://localhost:8080`  
**Swagger UI**: `http://localhost:8080/swagger-ui.html`

---

### 2. AI Service Setup

```bash
# Navigate to AI service
cd ai_service

# Create virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\activate

# Activate (Linux/Mac)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the service
python main.py
```

**AI Service runs at**: `http://localhost:8000`  
**API Docs**: `http://localhost:8000/docs`

---

### 3. Mobile Apps Setup

#### Farmer App
```bash
cd farmer_app

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

#### Patwari App
```bash
cd patwari_app

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

#### ⚙️ Server Configuration

Both mobile apps support **runtime server IP configuration**. On first launch or from the login screen:

1. **Tap the settings icon** (gear icon) on the login screen
2. **Enter your server IP** (e.g., `192.168.1.100:8080`)
3. **Save** — the app will use this server for all API calls

This is useful when:
- Testing on different networks (e.g., switching Wi-Fi)
- Deploying to multiple environments
- Development with changing IP addresses

---

## 📡 API Documentation

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/farmer/send-otp` | Send OTP to phone |
| `POST` | `/api/auth/farmer/verify-otp` | Verify OTP & login |
| `POST` | `/api/auth/farmer/register` | Register new farmer |
| `POST` | `/api/auth/patwari/login` | Patwari login |

### Insurance Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/insurance/apply` | Apply for insurance |
| `POST` | `/api/insurance/payment/confirm` | Confirm payment |
| `GET` | `/api/insurance/my-policies` | Get farmer's policies |
| `GET` | `/api/insurance/active` | Get active policies |

### Claims Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/claims` | File a claim (with images) |
| `GET` | `/api/claims/my-claims` | Get farmer's claims |
| `GET` | `/api/claims/{claimId}` | Get claim details |

### AI Service Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `POST` | `/api/predict` | Analyze crop images |
| `POST` | `/api/chat` | Chat with AI agent |

**Full API documentation available at Swagger UI when server is running.**

---

## 🔐 Demo Credentials

### Farmer Login (Phone + OTP)

| Phone Number | OTP Code |
|--------------|----------|
| 9999900001 | 123456 |
| 9999900002 | 123456 |

### Patwari Login (Government ID + Password)

| Government ID | Password | District |
|---------------|----------|----------|
| PAT-RJ-001 | password123 | Kota |
| PAT-MP-001 | password123 | Bhopal |

---

## 📸 Screenshots

<!-- Add your screenshots here -->

| Farmer App | Patwari App |
|------------|-------------|
| Login Screen | Dashboard |
| Insurance Application | Verification Queue |
| Claim Filing | Field Inspection |

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow existing code style and patterns
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

**Agri Shield AI** - Built with ❤️ for Indian Farmers

---

<p align="center">
  <b>🌾 Empowering Farmers Through Technology 🤖</b>
</p>
