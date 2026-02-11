# DrugDoZer - Smart Medical Companion

<p align="center">
  <strong>Your trusted companion for medication management and family health tracking</strong>
</p>

---

## 📱 Overview

DrugDoZer is a premium Flutter medical application designed to help users manage their medications, track family health profiles, and find nearby pharmacies. Built with reliability, security, and user experience as top priorities.

## ✨ Features

### 🔔 Medication Reminders
- **Reliable Notifications**: Never miss a dose with our robust notification system
- **Background Execution**: Reminders work even when the app is closed or phone is restarted
- **Smart Scheduling**: Timezone-aware scheduling with proper alarm management
- **Stock Tracking**: Get alerts when medication stock is running low

### 👨‍👩‍👧‍👦 Family Health Profiles
- **Multi-Member Support**: Track health profiles for the entire family
- **Medical History**: Record chronic diseases, allergies, and current medications
- **Drug Interaction Warnings**: Automatic alerts for potential drug interactions
- **PDF Export**: Export family health records as PDF documents

### 🗺️ Nearby Pharmacies
- **Real-time Location**: Find pharmacies near your current location
- **Detailed Information**: View pharmacy name, distance, phone number, and open/closed status
- **Direct Actions**: Call pharmacies or get directions with one tap
- **Map & List Views**: Switch between map and list views for convenience

### 💊 Medicine Library
- **500+ Medicines**: Comprehensive database of medications
- **Search & Filter**: Quick search by name or category
- **Detailed Information**: Dosage, side effects, and usage instructions
- **Pediatric Calculator**: Safe dose calculator for children

## 🏗️ Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                    # Core utilities and theme
│   ├── providers/          # State management providers
│   ├── theme/              # App theme and design system
│   └── utils/              # Utility functions
├── data/                    # Data layer
│   ├── datasources/        # Local and remote data sources
│   └── repositories/       # Repository implementations
├── domain/                  # Domain layer
│   ├── entities/           # Business entities
│   └── repositories/       # Repository interfaces
├── presentation/            # Presentation layer
│   ├── screens/            # App screens
│   └── widgets/            # Reusable widgets
├── services/               # Application services
│   ├── notification_service.dart
│   ├── background_service.dart
│   ├── pharmacy_service.dart
│   └── connectivity_service.dart
└── di/                     # Dependency injection
    └── service_locator.dart
```

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Google Maps API Key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-repo/drugdozer.git
   cd drugdozer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   
   Update the Google Maps API key in the pharmacy service.

4. **Android Configuration**
   
   Ensure your Google Maps API key is in `android/app/src/main/AndroidManifest.xml`

5. **iOS Configuration**
   
   Add your Google Maps API key to `ios/Runner/AppDelegate.swift`

6. **Run the app**
   ```bash
   flutter run
   ```

## ⚙️ Notification System

The notification system is configured to work reliably across all scenarios:

| Feature | Implementation |
|---------|---------------|
| Local Notifications | `flutter_local_notifications` |
| Timezone Handling | `timezone` package |
| Background Execution | `android_alarm_manager_plus` |
| Work Manager | `workmanager` for periodic tasks |
| Boot Receiver | Auto-reschedule on device restart |

### Required Permissions

**Android:**
- `RECEIVE_BOOT_COMPLETED` - Reschedule alarms after restart
- `SCHEDULE_EXACT_ALARM` - Precise notification timing
- `USE_EXACT_ALARM` - Exact alarm scheduling
- `ACCESS_FINE_LOCATION` - Nearby pharmacies
- `ACCESS_COARSE_LOCATION` - Location services
- `CALL_PHONE` - Direct pharmacy calls
- `VIBRATE` - Notification vibration
- `WAKE_LOCK` - Background processing

**iOS:**
- Location When In Use
- Location Always
- Notifications
- Background Fetch
- Remote Notifications

## 🎨 Design System

The app uses a comprehensive design system with:

### Colors
| Color | Light Mode | Dark Mode |
|-------|-----------|-----------|
| Primary | `#00695C` | `#4DB6AC` |
| Secondary | `#FF7043` | `#FFAB91` |
| Success | `#4CAF50` | `#81C784` |
| Warning | `#FFC107` | `#FFD54F` |
| Error | `#F44336` | `#E57373` |

### Typography
- **Headlines**: Cairo Bold
- **Body**: Cairo Regular
- **Labels**: Cairo Medium

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| flutter_local_notifications | Local notifications |
| android_alarm_manager_plus | Alarm scheduling |
| workmanager | Background tasks |
| google_maps_flutter | Maps integration |
| geolocator | Location services |
| provider | State management |
| shared_preferences | Local storage |
| get_it | Dependency injection |

## 📱 Supported Platforms

| Platform | Minimum Version |
|----------|----------------|
| Android | API 23 (Android 6.0) |
| iOS | iOS 12.0 |

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📄 Version

**Version 2.0.0** - Major upgrade with:
- Reliable notification system
- Premium UI/UX redesign
- Complete nearby pharmacies feature
- Clean architecture refactoring
- Performance optimizations
- Dark mode support

---

<p align="center">
  Made with ❤️ for better health management
</p>
