# CleanClik

An AR-powered mobile application that gamifies urban cleanup through real-time object detection, tracking, and reward systems. Transform waste management into an engaging, competitive experience with ML-powered categorization and social features.

> **⚠️ Platform Status**: Currently tested and verified on **Android only**. iOS support exists in code but is untested.

## 🌟 Features

### 🎯 Core Functionality
- **AR Object Detection**: Real-time ML Kit-powered object detection with colored overlays
- **Smart Categorization**: Advanced waste categorization system with 4 categories
- **QR Code Scanning**: Bin identification and validation system
- **Inventory Management**: Track picked-up items with cloud synchronization
- **Proximity Detection**: GPS-based bin detection within 10m radius
- **Disposal Validation**: Reward system for proper waste disposal

### 🎮 Gamification & Social
- **Points & Achievements**: Category-based scoring with multipliers and streaks
- **Leaderboards**: Real-time competition with time-based rankings
- **Social Sharing**: Generate and share achievement cards
- **Deep Linking**: Email verification and social sharing integration
- **User Profiles**: Track personal stats and environmental impact

### 🗺️ Location & Navigation
- **Interactive Maps**: Bin locations and cleanup hotspots
- **Bin Matching**: Intelligent matching of detected objects to nearby bins
- **Location Services**: Comprehensive GPS and geofencing capabilities

### 🔐 Authentication & Data
- **Supabase Integration**: Full backend with authentication and real-time sync
- **Google Sign-In**: OAuth integration with platform-specific configuration
- **Offline Support**: Local storage with sync

## 🎨 Design System

### Waste Categories & Branding
- **EcoGems** (Recycle): Green `#4CAF50` - Plastic, metal, paper, glass
- **BioShards** (Organic): Light Green `#8BC34A` - Food waste, plant matter
- **TechCores** (E-waste): Orange `#FF9800` - Electronics, batteries, devices
- **ToxicVials** (Hazardous): Pink `#E91E63` - Chemicals, paint, medical waste

### Architecture
- **Framework**: Flutter 3.24.0+ with Dart 3.9.0+
- **State Management**: Riverpod with code generation
- **Navigation**: GoRouter with declarative routing
- **Backend**: Supabase (Auth, Database, Storage, Real-time)
- **ML/AR**: Google ML Kit for object detection
- **Maps**: Google Maps Flutter integration
- **Theme**: Material 3 with environmental color palette

## 🏗️ Technical Architecture

### Service Layer Organization
```
lib/core/services/
├── auth/                    # Authentication & user management
│   ├── auth_service.dart           # Main authentication service
│   └── supabase_config_service.dart # Supabase configuration
├── business/                # Business logic services
│   ├── inventory_service.dart      # User inventory management
│   ├── object_management_service.dart # Object lifecycle management
│   └── smart_suggestions_service.dart # AI-powered recommendations
├── camera/                  # Camera, AR, and ML detection
│   ├── ml_detection_service.dart   # Google ML Kit integration
│   ├── qr_bin_service.dart        # QR code scanning
│   ├── disposal_detection_service.dart # Disposal validation
│   └── camera_resource_manager.dart # Camera lifecycle management
├── data/                    # Database and storage
│   ├── database_service.dart       # Supabase database operations
│   ├── sync_service.dart          # Cloud synchronization
│   ├── local_storage_service.dart # Local data persistence
│   └── data_migration_service.dart # Schema migrations
├── location/                # Location and mapping
│   ├── location_service.dart       # GPS and geolocation
│   ├── bin_location_service.dart   # Bin proximity detection
│   └── bin_matching_service.dart   # Object-to-bin matching
├── social/                  # Social and sharing features
│   ├── leaderboard_service.dart    # Competition rankings
│   ├── social_sharing_service.dart # Achievement sharing
│   └── deep_link_service.dart      # Deep link handling
└── platform/                # Platform-specific implementations
    ├── hand_tracking_service.dart  # Gesture recognition
    └── platform_optimizer.dart    # Performance optimization
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.24.0)
- Dart SDK (>=3.9.0)
- **Android Studio** for Android development (primary platform)
- Supabase account (optional - app runs in demo mode without)

> **📱 Platform Note**: This app has been tested and verified on Android devices only. While iOS code exists, it has not been tested and may require additional work.

### Quick Start

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd cleanclik
   make setup  # Installs dependencies and generates code
   ```

2. **Environment Configuration** (Optional)
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase credentials
   ```

3. **Run the App**
   ```bash
   flutter run
   # Or use the Makefile
   make test  # Run all tests
   ```

### Development Commands

```bash
# Setup and dependencies
make setup              # Install dependencies and generate code
make clean              # Clean build artifacts

# Testing
make test               # Run all tests
make test-unit          # Unit tests only
make test-widget        # Widget tests only
make test-integration   # Integration tests only
make coverage           # Generate coverage report

# Code quality
make analyze            # Run Flutter analyzer
make format             # Format Dart code
make check              # Run all quality checks

# Riverpod code generation
make generate           # Generate provider code
make watch-generate     # Watch for changes
```

### Build Commands

```bash
# Development builds (Android)
flutter run --debug
flutter run -d <android_device_id>

# Production builds (Android - untested)
flutter build apk --release

# iOS builds (untested - contributions welcome)
flutter build ios --release

# With environment variables
flutter build apk --dart-define=SUPABASE_URL="your-url"
```

## 🔧 Configuration & Setup

### Environment Variables

CleanClik supports both full functionality with Supabase and demo mode:

```bash
# Required for full functionality
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key

# Optional for Google Sign-In (Removed from UI)
GOOGLE_WEB_CLIENT_ID=your-web-client-id.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your-ios-client-id.googleusercontent.com
```

### Database Schema
The app uses Supabase with the following tables:
- **users**: User profiles with points and levels
- **inventory**: User's collected items with metadata
- **achievements**: Unlocked achievements and progress
- **category_stats**: Per-category statistics and totals

## 📱 Platform Support

### ✅ Android (Tested & Verified)

#### Required Permissions (`android/app/src/main/AndroidManifest.xml`)
- `CAMERA` - AR object detection and QR scanning
- `ACCESS_FINE_LOCATION` - Bin proximity detection
- `ACCESS_COARSE_LOCATION` - General location services
- `INTERNET` - Supabase connectivity

#### Tested Features
- AR object detection with ML Kit
- Camera resource management
- Location services and GPS
- Supabase authentication and database
- Google Sign-In integration

### ❓ iOS (Code Exists - Untested)

#### Permissions (`ios/Runner/Info.plist`)
- `NSCameraUsageDescription` - AR scanning functionality
- `NSLocationWhenInUseUsageDescription` - Location-based features
- `NSPhotoLibraryUsageDescription` - Achievement sharing

> **🚨 iOS Status**: While iOS code is implemented, it has not been tested on actual devices. Contributions are welcome to test and improve iOS compatibility.

## 🧪 Testing Strategy

### Comprehensive Test Suite
```
test/
├── unit/           # Service and model unit tests (95% coverage)
├── widget/         # UI component tests with golden files
├── integration/    # End-to-end user flow tests
└── golden/         # Visual regression tests
```

### Test Categories
- **Unit Tests**: All services and business logic
- **Widget Tests**: UI components and screens
- **Integration Tests**: Complete user workflows
- **Golden Tests**: Visual regression testing
- **Performance Tests**: ML detection and AR performance

### Coverage Analysis
- **Target**: 90%+ code coverage
- **Automated**: CI/CD integration with coverage reports
- **Analysis**: Detailed coverage analysis with `make coverage-analyze`


## 📚 Documentation

### Additional Resources
- **[Environment Setup Guide](docs/ENVIRONMENT_SETUP.md)** - Detailed configuration instructions
- **[Supabase Setup](docs/supabase-setup.md)** - Database and authentication setup
- **[Test Organization](test/TEST_ORGANIZATION.md)** - Testing strategy and conventions
- **[Testing Guide](test/TESTING_GUIDE.md)** - How to write and run tests

### Key Dependencies
```yaml
# Core Framework
flutter: ">=3.24.0"
dart: "^3.9.0"

# State Management & Navigation
flutter_riverpod: ^2.6.1
riverpod_annotation: ^2.6.1
go_router: ^14.6.2

# Backend & Authentication
supabase_flutter: ^2.8.2
google_sign_in: ^6.2.1

# Camera & ML
camera: ^0.11.0+2
google_mlkit_object_detection: ^0.12.0
qr_code_scanner_plus: ^2.0.10+1

# Location & Maps
geolocator: ^12.0.0
flutter_map: ^7.0.2

# Development Tools
build_runner: ^2.4.13
riverpod_generator: ^2.6.2
mockito: ^5.4.4
golden_toolkit: ^0.15.0
```

## 🤝 Contributing

**We welcome contributions!** This project was entirely generated using Kiro, any contributions are welcome to improve, test, and expand the codebase.

### 🎯 High-Priority Contribution Areas

1. **Code Deletion / Refactoring**: Identify and remove unused or redundant code, and refactor existing code for clarity and maintainability.
2. **iOS Testing & Fixes**: Test the app on iOS devices and fix any platform-specific issues
3. **Performance Optimization**: Improve AR detection performance on various devices
4. **UI/UX Improvements**: Enhance the user interface and experience
5. **Feature Enhancements**: Add new gamification features or improve existing ones
6. **Bug Fixes**: Identify and fix issues in the current implementation
7. **Documentation**: Improve documentation and add tutorials

### Code Organization
- **Services**: Domain-organized in `lib/core/services/`
- **Models**: Data structures in `lib/core/models/`
- **UI**: Feature-organized in `lib/presentation/`
- **Tests**: Mirror source structure in `test/`

### Architecture Principles
- **Clean Architecture**: Separation of concerns with service layers
- **Dependency Injection**: Constructor injection via Riverpod
- **Error Handling**: Comprehensive error handling and logging
- **Resource Management**: Proper lifecycle management for cameras and streams

### 🚀 Getting Started as a Contributor
1. Fork the repository
2. Test the app on your Android device
3. Identify areas for improvement
4. Submit pull requests with your enhancements
5. Help test iOS functionality

## 🔮 Future Roadmap

### Immediate Priorities
- **iOS Testing & Compatibility**: Verify and fix iOS functionality
- **Performance Optimization**: Improve AR detection on mid-range devices
- **Bug Fixes**: Address any issues found during testing
- **Documentation**: Improve setup guides and API documentation

### Planned Features
- **AR Enhancements**: Improved object tracking and overlay precision
- **Community Features**: Team challenges and group competitions
- **Analytics Dashboard**: Detailed environmental impact metrics
- **Offline Mode**: Enhanced offline functionality with sync
- **Multi-language**: Internationalization support
- **Accessibility**: Enhanced accessibility features and voice guidance

### Technical Improvements
- **Cross-Platform Testing**: Comprehensive iOS and Android testing
- **Performance**: Further ML optimization and caching strategies
- **Testing**: Expanded test coverage and automated UI testing
- **CI/CD**: Enhanced deployment pipeline and automated releases
- **Monitoring**: Real-time performance monitoring and crash reporting

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

**CleanClik** - Transforming urban cleanup through AR gamification 🌱📱

> **🤖 AI-Generated • 📱 Android-Tested • 🤝 Contributions Welcome**
>
> *P.S. If this README claims the app can do something impossible like time travel or make perfect coffee, that's just the AI being creative. Please test everything yourself! ☕️🤖 contributions are welcome..*
