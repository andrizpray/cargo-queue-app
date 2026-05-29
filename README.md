# Cargo Queue App

**Flutter Mobile Application** - Sistem antrian kendaraan untuk muat/bongkar di pabrik/warehouse.

## 📋 Overview

Cargo Queue App adalah aplikasi mobile untuk mengelola antrian kendaraan di warehouse/pabrik. Aplikasi ini terhubung ke backend Laravel Cargo Queue System dan menyediakan fitur real-time queue tracking, barcode scanning, dan manajemen antrian.

## 🎯 Target Platform

- **Android:** Primary target (min SDK 21, target SDK 34)
- **iOS:** Can be built from source (Flutter cross-platform)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
├─────────────────────────────────────────────────────────┤
│  Presentation Layer (Screens, Widgets)                  │
│  ↓                                                     │
│  BLoC Layer (Business Logic - flutter_bloc)             │
│  ↓                                                     │
│  Repository Layer (Data abstraction)                    │
│  ↓                                                     │
│  Data Sources (API via Dio, Local Storage)              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│            Laravel Backend (API + WebSocket)             │
│  http://43.134.37.14:8000                               │
│  ws://43.134.37.14:8080 (Reverb)                        │
└─────────────────────────────────────────────────────────┘
```

## ✨ Features

### Core Features
- **🔐 User Authentication** - Login/register dengan Laravel Sanctum (Bearer token)
- **📋 Queue Management** - Create, view, dan update queue status
- **📷 Barcode Scanning** - Scan Code128 untuk identifikasi kendaraan (mobile_scanner)
- **🔔 Real-time Updates** - WebSocket untuk update status antrian secara langsung
- **📍 Location Selection** - Multi-location support
- **👤 Profile Management** - View dan update user profile

### Queue Status Flow
```
waiting → loading → done
       ↘ cancelled
```

### Screen Flow
```
Login → Home (Queue List) → Create Queue
                  ↓
            Queue Detail → Update Status
                  ↓
         Scan Barcode → Vehicle Detail
                  ↓
            Profile
```

## 📱 Screens

| Screen | Description |
|--------|-------------|
| **Login** | Email + password login dengan remember me |
| **Register** | New user registration |
| **Home** | List antrian dengan filter status, pull-to-refresh |
| **Create Queue** | Form untuk membuat antrian baru |
| **Queue Detail** | Detail antrian dengan tombol update status |
| **Scan Barcode** | Kamera scanner untuk Code128 |
| **Vehicle Detail** | Info kendaraan setelah scan |
| **Profile** | User info dan logout |

## 🛠️ Tech Stack

### Flutter Packages

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bloc` | ^9.0.0 | State management (BLoC pattern) |
| `dio` | ^5.4.0 | HTTP client untuk API calls |
| `mobile_scanner` | ^5.0.0 | Barcode/QR scanning |
| `equatable` | ^2.0.5 | Value equality for BLoC states |
| `get_it` | ^7.6.0 | Dependency injection |
| `shared_preferences` | ^2.2.0 | Local token storage |
| `intl` | ^0.19.0 | Date/number formatting |
| `pull_to_refresh_flutter3` | ^2.0.2 | Pull-to-refresh widget |

### State Management

Using **BLoC (Business Logic Component)** pattern:
- `AuthBloc` - Authentication state
- `QueueBloc` - Queue CRUD operations
- `VehicleBloc` - Vehicle scanning/lookup
- `LocationBloc` - Location data

## 🔌 API Integration

### Base Configuration
- **Base URL:** `http://43.134.37.14:8000`
- **API Prefix:** `/api`
- **Auth:** Bearer token (Laravel Sanctum)

### Key Endpoints

```dart
// Authentication
POST   /api/login
POST   /api/register
POST   /api/logout

// Queues
GET    /api/queues/location/{location_id}  // List queues
POST   /api/queues                         // Create queue
GET    /api/queues/{id}                    // Get queue detail
PUT    /api/queues/{id}/status             // Update status

// Vehicles
POST   /api/vehicles/scan                 // Scan barcode
GET    /api/vehicles/{barcode}            // Get by barcode
GET    /api/vehicles/location/{id}        // Vehicles by location

// Reference Data
GET    /api/locations
GET    /api/vehicle-types
```

### WebSocket (Real-time)
- **URL:** `ws://43.134.37.14:8080`
- **Events:** Queue status updates broadcast to all connected clients

## 🔐 Permissions Required

```xml
<!-- Android (android/app/src/main/AndroidManifest.xml) -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## 💻 Setup & Installation

### Prerequisites
- Flutter SDK 3.19+
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)
- Git

### Clone & Setup

```bash
# Clone the repository
git clone git@github.com:andrizpray/cargo_queue_app.git
cd cargo_queue_app

# Get dependencies
flutter pub get

# Copy environment template
cp .env.example .env

# Run the app
flutter run
```

### Environment Configuration

Create `.env` file in root:

```env
API_BASE_URL=http://43.134.37.14:8000
WS_URL=ws://43.134.37.14:8080
```

Or configure via `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://43.134.37.14:8000';
  static const String wsUrl = 'ws://43.134.37.14:8080';
  static const String apiPrefix = '/api';
}
```

## 📦 Building APK

### Debug Build
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release Build
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Install to Device
```bash
# Via ADB (device must be connected)
adb install build/app/outputs/flutter-apk/app-release.apk

# Or drag APK to emulator/device
```

### Build with Custom Configuration
```bash
# Build with flavor (if configured)
flutter build apk --release --flavor production

# Build for specific architecture
flutter build apk --release --target-platform android-arm64
```

## 👥 Test Users

Login dengan user yang sudah di-seed di backend:

| Role    | Email              | Password    |
|---------|--------------------|-------------|
| driver  | driver@test.com    | password123 |
| security| security@test.com  | password123 |
| admin   | admin@test.com     | password123 |

## 🐛 Known Issues

### Current Limitations
1. **WebSocket reconnection** - App doesn't auto-reconnect on network loss (workaround: pull-to-refresh)
2. **Camera permission** - Must grant camera permission manually on first scan
3. **Token expiry** - Tokens don't auto-refresh; logout required if expired

### Android Specific
- Camera preview may be rotated on some devices (OEM-specific)
- Background location not required (location stored server-side)

## 📁 Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_interceptor.dart
│   │   └── ws_client.dart
│   └── utils/
│       └── helpers.dart
├── data/
│   ├── datasources/
│   │   ├── auth_datasource.dart
│   │   ├── queue_datasource.dart
│   │   └── vehicle_datasource.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── queue_model.dart
│   │   ├── vehicle_model.dart
│   │   └── location_model.dart
│   └── repositories/
│       ├── auth_repository_impl.dart
│       ├── queue_repository_impl.dart
│       └── vehicle_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── queue.dart
│   │   └── vehicle.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── queue_repository.dart
│       └── vehicle_repository.dart
├── presentation/
│   ├── blocs/
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── queue/
│   │   │   ├── queue_bloc.dart
│   │   │   ├── queue_event.dart
│   │   │   └── queue_state.dart
│   │   └── vehicle/
│   │       ├── vehicle_bloc.dart
│   │       ├── vehicle_event.dart
│   │       └── vehicle_state.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── create_queue_screen.dart
│   │   ├── queue_detail_screen.dart
│   │   ├── scan_screen.dart
│   │   ├── vehicle_detail_screen.dart
│   │   └── profile_screen.dart
│   └── widgets/
│       ├── queue_card.dart
│       ├── status_badge.dart
│       ├── loading_widget.dart
│       └── error_widget.dart
└── injection_container.dart
```

## 🔄 Daily Development Workflow

```bash
# Start developing
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Build for testing on device
flutter build apk && adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 📸 Screenshots Placeholder

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Login     │  │   Home      │  │   Create    │
│   Screen    │  │   Screen    │  │   Queue     │
│             │  │             │  │   Screen    │
│  [email]    │  │ [Queue List]│  │             │
│  [password] │  │ [Filter]    │  │ [Form]      │
│  [Login]    │  │ [Cards]     │  │ [Submit]    │
└─────────────┘  └─────────────┘  └─────────────┘

┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Queue     │  │   Scan      │  │   Profile   │
│   Detail    │  │   Screen    │  │   Screen    │
│             │  │             │  │             │
│ [Status]    │  │ [Camera]    │  │ [Avatar]    │
│ [Actions]   │  │ [Overlay]   │  │ [Name]      │
│ [History]   │  │ [Result]    │  │ [Email]     │
└─────────────┘  └─────────────┘  └─────────────┘
```

*Screenshots coming soon*

## 🚀 Future Enhancements

- [ ] Push notifications for queue status changes
- [ ] Offline queue creation with sync
- [ ] Dark mode theme
- [ ] Multi-language support (Indonesian/English)
- [ ] Print queue ticket feature
- [ ] QR code generation for vehicles
- [ ] Analytics dashboard in-app

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature/your-feature`
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 👤 Author

**Andriz** - [GitHub](https://github.com/andrizpray)

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: andriz@example.com

---

**Last Updated:** 2026-05-29
**Version:** 1.0.0
**Backend API:** http://43.134.37.14:8000
