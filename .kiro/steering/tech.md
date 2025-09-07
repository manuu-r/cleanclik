---
inclusion: always
---

# Technology Stack & Development Guidelines

## Core Technologies
- **Framework**: Flutter 3.24.0+
- **Language**: Dart 3.9.0+
- **Target Platforms**: iOS, Android (primary focus)
- **State Management**: Riverpod with code generation
- **Navigation**: GoRouter for declarative routing
- **AR/ML**: Google ML Kit for object detection
- **Backend**: Firebase (Auth, Firestore, Storage, Functions, Analytics)

## Key Dependencies
- **Camera & AR**: `camera`, `google_mlkit_object_detection`, `google_mlkit_commons`
- **Location**: `geolocator`, `permission_handler`
- **Maps**: `google_maps_flutter`
- **State**: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`
- **UI**: Material 3 design system, `flutter_svg`

## Code Generation
Always run code generation after modifying Riverpod providers:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Performance Requirements
- **AR Overlay**: <200ms latency on mid-range devices
- **Frame Rate**: ≥30fps (high-end), ≥15fps (mid-range)
- **Proximity Detection**: <1 second response time
- **Leaderboard Updates**: 30-second cadence

## Platform-Specific Considerations
- **iOS**: Requires camera and location permissions in Info.plist
- **Android**: Requires camera, location, and storage permissions in manifest
- **AR Capabilities**: Implement graceful fallback for devices without AR support

## Development Commands
```bash
# Development
flutter pub get && dart run build_runner build
flutter run --debug
flutter run -d <device_id>

# Testing & Quality
flutter test
flutter analyze
dart format .
flutter pub outdated

# Building
flutter build apk --release
flutter build ios --release
```