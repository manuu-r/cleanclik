---
inclusion: always
---

# Project Architecture & Structure

## Clean Architecture Implementation
```
lib/
├── main.dart                    # App entry point with ProviderScope
├── app.dart                     # Root app widget with routing
├── core/                        # Shared infrastructure
│   ├── constants/              # App-wide constants and enums
│   ├── models/                 # Core data models and entities
│   ├── providers/              # Global Riverpod providers
│   ├── routing/                # GoRouter configuration
│   ├── services/               # Core business logic services (organized by domain)
│   │   ├── auth/              # Authentication & user management
│   │   ├── camera/            # Camera, AR, ML detection
│   │   ├── data/              # Database, storage, sync
│   │   ├── location/          # GPS, mapping, proximity
│   │   ├── social/            # Sharing, leaderboards, achievements
│   │   ├── platform/          # Platform-specific implementations
│   │   ├── system/            # Core system services (logging, performance)
│   │   └── business/          # Business logic services
│   └── theme/                  # Material 3 theme configuration
└── presentation/               # UI layer
    ├── navigation/             # Navigation shell and components
    ├── screens/                # Feature screens (organized by feature)
    │   ├── auth/              # Authentication screens
    │   ├── camera/            # AR camera screens
    │   ├── map/               # Map screens
    │   ├── profile/           # Profile screens
    │   └── leaderboard/       # Leaderboard screens
    └── widgets/                # Reusable UI components (organized by feature)
        ├── camera/            # AR camera related widgets
        ├── map/               # Map and location widgets
        ├── inventory/         # Inventory and object widgets
        ├── social/            # Social and sharing widgets
        ├── overlays/          # All overlay widgets
        ├── animations/        # Animation widgets
        ├── debug/             # Debug and diagnostic widgets
        └── common/            # Shared/reusable widgets
```

## Service Layer Architecture
- **ARDetectionService**: ML Kit object detection and categorization
- **ObjectTrackingService**: State management for detected objects
- **ProximityService**: GPS-based bin detection with geofencing
- **UserInventoryService**: Local/cloud inventory management
- **PointsCalculatorService**: Scoring logic and reward calculations

## State Management Patterns
- Use **Riverpod providers** for all state management
- **AsyncNotifierProvider** for services with async operations
- **NotifierProvider** for synchronous state management
- **FutureProvider** for one-time async data fetching
- Always use code generation with `@riverpod` annotations

## Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Providers**: `camelCaseProvider` (auto-generated)
- **Screens**: `FeatureScreen` (e.g., `ARCameraScreen`)
- **Services**: `FeatureService` (e.g., `ARDetectionService`)

## Feature Organization
Each major feature should follow this structure:
```
presentation/screens/feature_name/
├── feature_screen.dart          # Main screen widget
├── widgets/                     # Feature-specific widgets
└── providers/                   # Feature-specific providers
```

## Asset Organization
```
assets/
├── images/                      # Static images and illustrations
├── icons/                       # Custom icons and category symbols
└── animations/                  # Lottie animations and effects
```

## Testing Structure
```
test/
├── unit/                        # Unit tests for services and models
├── widget/                      # Widget tests for UI components
└── integration/                 # Integration tests for user flows
```