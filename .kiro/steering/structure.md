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
│   ├── services/               # Core business logic services
│   └── theme/                  # Material 3 theme configuration
└── presentation/               # UI layer
    ├── navigation/             # Navigation shell and components
    ├── screens/                # Feature screens (camera, map, etc.)
    └── widgets/                # Reusable UI components
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