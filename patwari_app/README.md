# 📱 Agri Shield AI - Patwari App

Flutter mobile application for government officials (Patwaris) to verify insurance claims.

## Features

- 🔐 **Government ID Login** - Secure credential-based authentication
- 📋 **Verification Queue** - View pending claims for your district
- 📷 **QR Code Scanner** - Quick farmer identification
- ✅ **Approve/Reject Claims** - Field verification workflow
- 📍 **GPS Tagging** - Location-verified inspections
- 📊 **Sensor Integration** - Access IoT sensor data

## Tech Stack

- **Framework**: Flutter 3.8+
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Storage**: SharedPreferences
- **QR Scanner**: Mobile Scanner

## Project Structure

```
lib/
├── main.dart           # App entry point
├── core/               # Shared utilities, themes, constants
└── features/
    ├── auth/           # Government ID login
    └── verification/   # Claim verification workflow
```

## Getting Started

### Prerequisites
- Flutter SDK 3.8+
- Android Studio / VS Code
- Android emulator or physical device

### Installation

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Build APK
flutter build apk --release
```

### Configuration

Update the API base URL in the app configuration.

## Demo Credentials

| Government ID | Password | District |
|---------------|----------|----------|
| PAT-RJ-001 | password123 | Kota |
| PAT-MP-001 | password123 | Bhopal |

---

Part of **Agri Shield AI** - AI-Powered Crop Insurance Platform
