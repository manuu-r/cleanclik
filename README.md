# CleanClik

An AR-powered mobile application that gamifies urban cleanup through real-time object detection, tracking, and reward systems.

## 🌟 Features

- **AR Object Detection**: Real-time trash detection with colored overlays
- **Gamified Cleanup**: Points, streaks, and leaderboards
- **Interactive Map**: Bin locations and cleanup hotspots
- **Social Competition**: Leaderboards and achievements
- **Environmental Impact**: Track your contribution to city cleanliness

## 🏗️ Current Implementation Status

### ✅ Task 1: Project Foundation and Core Navigation (COMPLETED)

- ✅ Flutter project with iOS and Android support
- ✅ Core dependencies added:
  - `go_router` for navigation
  - `flutter_riverpod` for state management
  - `camera` for AR capabilities
  - `permission_handler` for permissions
  - `google_maps_flutter` for mapping
  - `geolocator` for location services
- ✅ Camera and location permissions configured for both platforms
- ✅ Complete navigation shell with 5 main routes:
  - Home: Welcome screen with stats and category guide
  - Camera: AR scanner interface (placeholder)
  - Map: Interactive cleanup map (placeholder)
  - Leaderboard: Competition rankings with time periods
  - Profile: User stats and achievements
- ✅ Environmental color scheme with Material 3 design
- ✅ Routing structure with proper state management
- ✅ Basic UI screens with consistent styling and placeholder content

## 🎨 Design System

### Color Scheme
- **EcoGems** (Recycle): Green `#4CAF50`
- **FuelShards** (Organic): Blue `#2196F3`
- **VoidDust** (Landfill): Gray `#757575`
- **SparkCores** (E-waste): Orange `#FF9800`
- **ToxicCrystals** (Hazardous): Red `#E91E63`

### Architecture
- **Framework**: Flutter with Dart
- **State Management**: Riverpod
- **Navigation**: go_router with StatefulShellRoute
- **Theme**: Material 3 with custom environmental colors
- **Permissions**: Handled for both iOS and Android

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.24.0)
- Dart SDK (^3.9.0)
- Android Studio / Xcode for platform-specific development

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Build

```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## 📱 Permissions

The app requires the following permissions:

### Android
- `CAMERA` - For AR object detection
- `ACCESS_FINE_LOCATION` - For proximity detection
- `ACCESS_COARSE_LOCATION` - For general location services
- `INTERNET` - For backend connectivity

### iOS
- `NSCameraUsageDescription` - AR scanning functionality
- `NSLocationWhenInUseUsageDescription` - Location-based features
- `NSPhotoLibraryUsageDescription` - Photo saving capabilities

## 🏗️ Next Steps

The foundation is complete! Next tasks in the implementation plan:

2. **AR Camera System** - Implement ML Kit object detection
3. **Object State Management** - Track user interactions
4. **Location-Based Bin System** - Proximity detection
5. **Disposal Validation** - Reward system
6. **Interactive Map** - Google Maps integration
7. **Leaderboard System** - Social competition
8. **Firebase Integration** - Backend services

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.