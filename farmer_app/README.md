# 📱 Agri Shield AI - Farmer App

Flutter mobile application for farmers to manage crop insurance and file claims.

## Features

- 📲 **OTP Authentication** - Phone-based secure login
- 🌾 **Insurance Enrollment** - Apply for crop insurance policies
- 📸 **Claim Filing** - Upload photos of damaged crops
- 🔔 **Real-time Updates** - Track claim status with notifications
- 💳 **Razorpay Payments** - Seamless premium payments
- 📍 **Location Services** - GPS-tagged claims

## Tech Stack

- **Framework**: Flutter 3.8+
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Storage**: SharedPreferences
- **Payments**: Razorpay Flutter SDK

## Project Structure

```
lib/
├── main.dart           # App entry point
├── core/               # Shared utilities, themes, constants
└── features/
    ├── auth/           # Login & registration
    ├── dashboard/      # Home screen
    ├── insurance/      # Policy management
    ├── claims/         # File & track claims
    └── profile/        # User profile
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

Update the API base URL in the app configuration to point to your backend server.

## Screenshots

<!-- Add screenshots here -->

---

Part of **Agri Shield AI** - AI-Powered Crop Insurance Platform
