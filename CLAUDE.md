# CLAUDE.md - CleanClik AI Assistant Guide

> Comprehensive guide for AI assistants working with the CleanClik codebase

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Codebase Structure](#codebase-structure)
- [Architecture & Design Patterns](#architecture--design-patterns)
- [State Management with Riverpod](#state-management-with-riverpod)
- [Key Services Reference](#key-services-reference)
- [Data Models](#data-models)
- [UI Organization](#ui-organization)
- [Testing Strategy](#testing-strategy)
- [Development Workflows](#development-workflows)
- [Code Generation](#code-generation)
- [Dependencies & Integrations](#dependencies--integrations)
- [Configuration Files](#configuration-files)
- [Naming Conventions](#naming-conventions)
- [Common Tasks](#common-tasks)
- [Additional Resources](#additional-resources)

---

## Project Overview

**CleanClik** is an AR-powered mobile application that gamifies urban cleanup through real-time object detection, tracking, and reward systems.

### Technology Stack

- **Framework**: Flutter 3.24.0+ with Dart 3.9.0+
- **State Management**: Riverpod with code generation
- **Navigation**: GoRouter (declarative routing)
- **Backend**: Supabase (auth, database, storage, real-time)
- **ML/AR**: Google ML Kit (object detection, image labeling, hand tracking)
- **Maps**: Flutter Map with OpenStreetMap tiles
- **Theme**: Material 3 design system

### Platform Status

- ✅ **Android**: Fully tested and verified
- ❓ **iOS**: Code exists but untested - contributions needed

### Key Features

- Real-time AR object detection with ML Kit
- Smart waste categorization (4 categories)
- QR code bin identification
- GPS-based bin proximity detection
- Points, achievements, and leaderboards
- Supabase backend with offline support

---

## Codebase Structure

### Root Directory Layout

```
cleanclik/
├── lib/                          # Main application code
│   ├── app.dart                  # Root app widget with lifecycle
│   ├── main.dart                 # Entry point, service initialization
│   ├── core/                     # Business logic and infrastructure
│   │   ├── models/               # Data models (User, Waste, Camera, etc.)
│   │   ├── providers/            # Riverpod providers (generated)
│   │   ├── routing/              # GoRouter configuration
│   │   ├── services/             # Service layer (domain-organized)
│   │   │   ├── auth/             # Authentication services
│   │   │   ├── business/         # Business logic (inventory, user)
│   │   │   ├── camera/           # Camera, AR, ML detection
│   │   │   ├── data/             # Database and storage
│   │   │   ├── location/         # GPS, bins, mapping
│   │   │   ├── platform/         # Platform-specific code
│   │   │   └── system/           # Logging, performance
│   │   ├── theme/                # Material 3 theme
│   │   └── utils/                # Utilities and helpers
│   └── presentation/             # UI layer
│       ├── navigation/           # Navigation shell, home
│       ├── screens/              # Full-screen views
│       │   ├── auth/             # Login, signup, verification
│       │   ├── camera/           # AR camera screen
│       │   ├── map/              # Map with bin locations
│       │   └── profile/          # User profile and stats
│       └── widgets/              # Reusable UI components
│           ├── animations/       # Custom animations
│           ├── camera/           # AR overlays, detection UI
│           ├── common/           # Shared components
│           ├── inventory/        # Inventory widgets
│           ├── map/              # Map markers, overlays
│           └── overlays/         # Modal overlays
├── test/                         # Comprehensive test suite
│   ├── unit/                     # Service and model tests
│   ├── widget/                   # UI component tests
│   ├── integration/              # End-to-end tests
│   ├── golden/                   # Visual regression tests
│   ├── fixtures/                 # Test data and mocks
│   └── helpers/                  # Test utilities
├── database/                     # Supabase migrations and schema
├── scripts/                      # Development scripts
├── android/, ios/, macos/        # Platform-specific code
└── docs/                         # Documentation
```

### Service Layer Organization

Services are **domain-organized** in `lib/core/services/`:

| Domain | Services | Purpose |
|--------|----------|---------|
| **auth/** | `auth_service.dart`<br>`supabase_config_service.dart`<br>`deep_link_service.dart` | Authentication, Supabase config, deep links |
| **business/** | `inventory_service.dart`<br>`user_service.dart`<br>`pickup_service.dart`<br>`database_helper.dart` | Inventory management, user profiles, pickups, CRUD |
| **camera/** | `waste_detection_service.dart`<br>`waste_categorizer.dart`<br>`qr_bin_service.dart`<br>`disposal_handling_service.dart`<br>`camera_resource_manager.dart`<br>`ml_background_processor.dart` | Object detection, categorization, QR scanning, camera lifecycle, ML processing |
| **location/** | `location_service.dart`<br>`bin_location_service.dart`<br>`bin_matching_service.dart`<br>`map_data_service.dart` | GPS, bin proximity, object-to-bin matching, map data |
| **platform/** | `hand_tracking_service.dart`<br>`enhanced_gesture_recognition_service.dart` | Hand gestures, gesture recognition |
| **system/** | `logging_service.dart`<br>`performance_service.dart`<br>`ui_context_service.dart` | Logging, performance monitoring, UI context |
| **data/** | `local_storage_service.dart` | SharedPreferences wrapper (singleton) |

---

## Architecture & Design Patterns

### Clean Architecture

**Layer Separation**:
1. **Presentation** (`lib/presentation/`) - UI components, screens, widgets
2. **Domain** (`lib/core/models/`) - Business entities and rules
3. **Service** (`lib/core/services/`) - Business logic and external integrations
4. **Data** - Handled by services (Supabase, local storage)

### Key Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| **Service Layer** | All business logic in domain-organized services | `AuthService`, `InventoryService` |
| **Repository** | Data access abstraction | `DatabaseHelper`, individual services |
| **Dependency Injection** | Via Riverpod with constructor injection | `@riverpod` providers |
| **Singleton** | For stateful services | `LocalStorageService`, `AuthService`, `WasteCategorizer` |
| **Factory** | Model creation from different sources | `.fromJson()`, `.fromSupabase()`, `.fromDatabaseRow()` |
| **Stream** | Event broadcasting | `authStateStream`, `eventsStream` |
| **Observer** | Riverpod listeners for state changes | `ref.listen()`, `ref.watch()` |

### Error Handling

- **Try-catch blocks** in all service methods
- **User-friendly error messages** via `user_friendly_errors.dart`
- **Schema error handling** for Supabase operations
- **Logging** with debug prints (removed in production)
- **Custom exceptions**: `AuthException`, etc.

---

## State Management with Riverpod

### Code Generation Pattern

CleanClik uses `riverpod_annotation` with `build_runner` for automatic provider generation.

**Annotation**:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_service.g.dart';  // Generated file

@riverpod
class MyService extends _$MyService {  // Base class from .g.dart
  @override
  MyService build() {
    // Initialization
    return this;
  }
}
```

### Key Providers

**Authentication** (`lib/core/providers/auth_provider.dart`):
- `authServiceProvider` - Singleton `AuthService`
- `authStateProvider` - Stream of `AuthState`
- `currentUserProvider` - Current authenticated user

**User Management** (`lib/core/providers/user_provider.dart`):
- `currentUserProfileProvider` - Current user profile
- `userProfileStreamProvider` - Real-time profile updates
- `dashboardStatsProvider` - User stats (points, level)
- `syncedCurrentUserProvider` - User with synced stats

**Inventory** (`lib/core/providers/inventory_provider.dart`):
- `inventoryServiceProvider` - Singleton `InventoryService`
- `inventoryItemsProvider` - Current inventory items
- `inventoryItemsByCategoryProvider` - Filtered by category
- `isInventoryEmptyProvider` - Empty state check

### Provider Usage

**In Widgets** (use `ConsumerWidget` or `Consumer`):
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for changes (rebuilds on updates)
    final authState = ref.watch(authStateProvider);

    // Read once (no rebuild)
    final authService = ref.read(authServiceProvider);

    // Listen for side effects
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      next.when(
        data: (state) => print('Auth state changed: $state'),
        loading: () => print('Loading...'),
        error: (err, stack) => print('Error: $err'),
      );
    });

    return Container();
  }
}
```

**In Services**:
```dart
@riverpod
class MyService extends _$MyService {
  @override
  MyService build() {
    // Access other providers
    final inventory = ref.watch(inventoryServiceProvider);

    // Lifecycle management
    ref.onDispose(() {
      // Cleanup resources
    });

    return this;
  }
}
```

### Code Generation Commands

```bash
# Generate once
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on changes)
dart run build_runner watch --delete-conflicting-outputs

# Clean and regenerate
flutter clean
dart run build_runner build --delete-conflicting-outputs
```

---

## Key Services Reference

### AuthService (`lib/core/services/auth/auth_service.dart`)

**Purpose**: User authentication and session management

**Key Methods**:
- `signInWithEmail(email, password)` - Email/password auth
- `signInWithGoogle()` - Google OAuth flow
- `signUpWithEmail(email, password, username)` - Registration
- `signOut()` - Clear session
- `refreshAuthState()` - Refresh on app resume
- `handleAuthCallback(url)` - Deep link callbacks

**State**:
- `AuthState`: `{ status, user, error }`
- `AuthStatus` enum: `loading`, `authenticated`, `unauthenticated`, `error`
- Broadcasts via `authStateStream`

### InventoryService (`lib/core/services/business/inventory_service.dart`)

**Purpose**: Manage user's collected items with local + cloud sync

**Key Methods**:
- `addItemFromDetectedObject(DetectedObject)` - Add from ML detection
- `removeItem(itemId)` - Delete item
- `getItemsByCategory(category)` - Filter by category
- `syncWhenOnline()` - Manual sync
- `clearInventory()` - Remove all items

**Data Flow**:
1. DetectedObject → InventoryItem (via `WasteCategorizer`)
2. Save to local storage (immediate)
3. Save to Supabase (if authenticated)
4. Broadcast `ItemAddedEvent`
5. Notify Riverpod listeners

**Storage**:
- Local: `LocalStorageService` (SharedPreferences)
- Cloud: Supabase `inventory` table via `DatabaseHelper`
- Offline-first design

### WasteDetectionService + WasteCategorizer

**Purpose**: ML-powered object detection and waste categorization

**Detection Pipeline**:
1. Camera captures frame
2. ML Kit object detection identifies objects
3. ML Kit image labeling generates labels
4. `WasteCategorizer` maps labels to categories
5. Create `DetectedObject` with metadata
6. Broadcast to UI for AR overlay

**Categories** (4 types):
- **EcoGems** (recycle): Green `#4CAF50` - plastic, metal, paper, glass
- **BioShards** (organic): Light Green `#8BC34A` - food, plant matter
- **TechCores** (e-waste): Orange `#FF9800` - electronics, batteries
- **ToxicVials** (hazardous): Pink `#E91E63` - chemicals, paint, medical

**Categorization Logic**:
- Direct ML Kit category mapping
- Keyword matching with priority system
- Fuzzy matching for variations
- Confidence thresholding (30% minimum)
- Multi-label detection

**Files**:
- `lib/core/services/camera/waste_detection_service.dart`
- `lib/core/services/camera/waste_categorizer.dart`
- `lib/core/models/waste_models.dart`

### DatabaseHelper (`lib/core/services/business/database_helper.dart`)

**Purpose**: Supabase CRUD operations with RLS

**Key Methods**:
- `create(table, data)` - Insert with `user_id` injection
- `read(table, userId)` - Query user's data
- `update(table, id, data)` - Update by ID
- `deleteById(table, id)` - Delete by ID
- `syncPendingOperations()` - Retry failed operations

**Features**:
- Automatic `user_id` injection for Row Level Security
- Offline queue for failed operations
- Error recovery and retry logic

---

## Data Models

All models in `lib/core/models/` follow consistent serialization patterns.

### Model Serialization Pattern

```dart
class MyModel {
  // 1. Load from local storage (SharedPreferences)
  factory MyModel.fromJson(Map<String, dynamic> json) { ... }

  // 2. Save to local storage
  Map<String, dynamic> toJson() { ... }

  // 3. Load from database (snake_case columns)
  factory MyModel.fromSupabase(Map<String, dynamic> data) { ... }

  // 4. Save to database (snake_case columns)
  Map<String, dynamic> toSupabase() { ... }

  // 5. Immutable updates
  MyModel copyWith({ ... }) { ... }
}
```

### Core Models

**user_models.dart**:
- `User` - Main user model
  - Fields: `id`, `username`, `email`, `points`, `level`, `stats`
  - Methods: `calculateLevel()`, `levelProgress`, `pointsToNextLevel`
  - Dual serialization: `.toJson()` (local), `.toSupabase()` (database)
- `CategoryStats` - Per-category statistics

**waste_models.dart**:
- `WasteCategory` enum - 4 waste categories with colors
  - Methods: `fromImageLabel()`, `fromMLKitLabel()`, `fromMultipleLabels()`
  - Keyword mappings and priority system

**camera_models.dart**:
- `DetectedObject` - ML detection result with AR metadata
  - Fields: `trackingId`, `objectId`, `category`, `confidence`, `boundingBox`
  - Image labels, categorization reasoning, detection metadata
  - Methods: `toInventoryMetadata()`, `getCategorizationSummary()`
- `ImageLabel` - ML Kit label with confidence
- `CameraMode` enum: `none`, `qrScanning`, `mlDetection`
- `CameraState` - Camera status tracking

**location_models.dart**:
- `BinLocation` - Waste bin location with geohash
- `GeohashUtils` - Distance calculations, encoding/decoding

---

## UI Organization

### Presentation Layer (`lib/presentation/`)

**Screens** (`screens/`):
- **auth/**: Login, signup, email verification, auth wrapper
- **camera/**: AR camera screen with ML detection and QR scanning
- **map/**: Interactive map with bin locations
- **profile/**: User stats, achievements, inventory

**Navigation** (`navigation/`):
- `ar_navigation_shell.dart` - Bottom navigation (3 tabs)
- `home/home_screen.dart` - Dashboard with stats

**Widgets** (`widgets/`):
- **animations/**: Breathing animations, particles, progress rings
- **common/**: Glassmorphism, FAB hub, category cards, sync indicator
- **camera/**: AR overlays, QR scanner UI, ML detection integration
- **map/**: Bin markers, mission markers, holographic markers
- **overlays/**: Celebration animations, confirmation dialogs
- **inventory/**: Inventory-specific widgets
- **profile/**: Profile-specific widgets

### Widget Patterns

- **ConsumerWidget** for Riverpod integration
- **StatefulWidget** for local state
- **Material 3** design system
- **Responsive layouts** with `MediaQuery`
- **Accessibility** support with semantic labels

---

## Testing Strategy

### Test Organization

```
test/
├── unit/              # Service and model tests (85%+ coverage target)
├── widget/            # UI component tests with pump/find
├── integration/       # End-to-end user flows
├── golden/            # Visual regression tests
├── fixtures/          # Test data, mocks, responses
└── helpers/           # Test utilities, base classes
```

### Test Types

**Unit Tests**:
- Test services and models in isolation
- Mock dependencies with Mockito
- Test edge cases and error handling
- Example: `test/unit/auth_service_test.dart`

**Widget Tests**:
- Test UI components
- Use `pumpWidget()` and `find` API
- Verify user interactions
- Example: `test/widget/screens/auth/login_screen_test.dart`

**Integration Tests**:
- Test complete workflows
- Real service interactions (with test Supabase)
- Performance benchmarks
- Example: `test/integration/auth_flow_test.dart`

**Golden Tests**:
- Visual regression testing
- Snapshot UI components
- Compare against golden files
- Use `golden_toolkit` package

### Running Tests

```bash
# All tests
flutter test

# Specific test directory
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/

# Specific test file
flutter test test/unit/auth_service_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Coverage Targets

- Overall: 85%+
- Services: 85%+
- Critical paths: 90%+
- Supabase integration: 90%+
- Camera/ML: 80%+

---

## Development Workflows

### Setup & Dependencies

```bash
# Install dependencies
flutter pub get

# Clean and reinstall
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade
```

### Code Generation

```bash
# Generate Riverpod providers (run after modifying @riverpod files)
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate)
dart run build_runner watch --delete-conflicting-outputs
```

### Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d <device_id>

# With environment variables
flutter run --dart-define=SUPABASE_URL="..." --dart-define=SUPABASE_PUBLISHABLE_KEY="..."
```

### Testing & Analysis

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Static analysis
flutter analyze

# Format code
dart format lib/ test/

# Auto-fix issues
dart fix --apply
```

### Building

```bash
# Android APK (debug)
flutter build apk

# Android APK (release)
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (untested)
flutter build ios --release
```

### Development Scripts (`scripts/`)

- **run_performance_tests.sh** - Performance benchmarks
- **test_coverage.sh** - Coverage analysis with HTML report
- **coverage_analysis.dart** - Detailed coverage breakdown
- **generate_bin_qr_codes.py** - QR code generation (requires Python 3)

### Standard Workflow

1. **Make changes** to code
2. **Regenerate code** if models/providers changed: `dart run build_runner build`
3. **Analyze** for issues: `flutter analyze`
4. **Test**: `flutter test`
5. **Format**: `dart format lib/ test/`
6. **Commit** changes

---

## Code Generation

### Riverpod Code Generation

**When to Regenerate**:
- After modifying any `@riverpod` annotated file
- After adding new providers
- After changing provider signatures
- When getting "part not found" errors

**Generated Files**:
All files with `@riverpod` or `@Riverpod()` generate `.g.dart` files:
- `lib/core/providers/*.dart` → `*.g.dart`
- `lib/core/services/**/*.dart` (with annotation) → `*.g.dart`

**Pattern**:
```dart
// Original: my_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_service.g.dart';  // Declare generated file

@riverpod
class MyService extends _$MyService {  // _$MyService from .g.dart
  @override
  MyService build() {
    // Initialize
    return this;
  }
}

// Generated: my_service.g.dart (auto-created)
// Contains: myServiceProvider, _$MyService base class
```

---

## Dependencies & Integrations

### Core Dependencies

**State Management**:
- `flutter_riverpod: ^2.6.1` - State management
- `riverpod_annotation: ^2.6.1` - Code generation
- `go_router: ^14.6.2` - Routing

**Backend**:
- `supabase_flutter: ^2.8.2` - Supabase SDK
- `google_sign_in: ^6.2.1` - Google OAuth

**Camera & ML**:
- `camera: ^0.11.0+2` - Camera access
- `google_mlkit_object_detection: ^0.15.0` - Object detection
- `google_mlkit_image_labeling: ^0.14.1` - Image labeling
- `hand_landmarker: ^2.1.0` - Hand tracking
- `qr_code_scanner_plus: ^2.0.10+1` - QR scanning

**Location**:
- `geolocator: ^12.0.0` - GPS
- `flutter_map: ^7.0.2` - Maps
- `permission_handler: ^11.3.1` - Permissions

**Storage**:
- `shared_preferences: ^2.5.3` - Local key-value storage
- `flutter_secure_storage: ^9.2.2` - Secure storage

**Development**:
- `build_runner: ^2.4.13` - Code generation
- `riverpod_generator: ^2.6.2` - Riverpod codegen
- `mockito: ^5.4.4` - Mocking
- `golden_toolkit: ^0.15.0` - Golden tests

### Supabase Integration

**Configuration**:
- Service: `lib/core/services/auth/supabase_config_service.dart`
- Singleton pattern with environment variables

**Environment Variables** (`.env`):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

**Database Tables** (inferred):
- `users` - User profiles
- `inventory` - User inventory items
- `category_stats` - Per-category statistics
- `achievements` - User achievements
- `bins` - Waste bin locations

**Row Level Security**:
- All tables use `user_id` for access control
- `DatabaseHelper` auto-injects `user_id`

### ML Kit Integration

**Object Detection**:
- Default ML Kit model
- Configuration: `lib/core/services/camera/ml_config.dart`
- Processing modes: `full`, `cached`
- Minimum confidence: 30%

**Performance Optimization**:
- Background processing via `ml_background_processor.dart`
- Frame skipping during high load
- Memory pressure detection
- Cached mode for low-power devices

---

## Configuration Files

### Environment Setup

**`.env.example`**:
```env
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_PUBLISHABLE_KEY=your_supabase_anon_key_here
ENVIRONMENT=development
DEBUG_MODE=true
```

**Environment Loading**:
- Service: `lib/core/utils/env_config.dart`
- Pattern: Singleton with caching
- Methods: `get()`, `getOrDefault()`, `has()`

### Analysis Options

**`analysis_options.yaml`**:
- Includes `package:flutter_lints/flutter.yaml`
- Uses `riverpod_lint` for Riverpod checks
- Standard Flutter linting rules

### Platform Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Permissions: `CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET`

**iOS** (`ios/Runner/Info.plist`) - UNTESTED:
- Camera, location, photo library usage descriptions

---

## Naming Conventions

### File Naming

**Pattern**: `snake_case.dart`

**Examples**:
- Services: `auth_service.dart`, `inventory_service.dart`
- Models: `user_models.dart`, `waste_models.dart`
- Screens: `login_screen.dart`, `ar_camera_screen.dart`
- Widgets: `glassmorphism_container.dart`
- Generated: `auth_service.g.dart`

### Class Naming

**Pattern**: `PascalCase`

**Examples**:
- Services: `AuthService`, `InventoryService`
- Models: `User`, `DetectedObject`, `BinLocation`
- Widgets: `LoginScreen`, `ARCameraScreen`
- Enums: `WasteCategory`, `AuthStatus`, `CameraMode`

### Variable & Method Naming

**Pattern**: `camelCase`

**Examples**:
- Variables: `currentUser`, `detectedObjects`, `isLoading`
- Methods: `signInWithEmail()`, `addItemFromDetectedObject()`
- Private: `_initializeServices()`, `_handleAuthResponse()`

### Enum Naming

**Pattern**: `PascalCase` for type, `camelCase` for values

```dart
enum WasteCategory {
  recycle,
  organic,
  ewaste,
  hazardous,
}
```

### Import Organization

**Order**: dart, flutter, packages, relative

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cleanclik/core/models/user_models.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
```

---

## Common Tasks

### Adding a New Feature

1. **Create model** in `lib/core/models/`
   - Implement serialization: `fromJson()`, `toJson()`, `fromSupabase()`, `toSupabase()`
   - Add `copyWith()` for immutability

2. **Create service** in `lib/core/services/<domain>/`
   - Use `@riverpod` annotation
   - Implement business logic
   - Add error handling

3. **Create provider** in `lib/core/providers/`
   - Define providers for service and state
   - Use appropriate provider types

4. **Run code generation**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Create UI** in `lib/presentation/`
   - Use `ConsumerWidget` for Riverpod
   - Follow Material 3 design system

6. **Write tests** in `test/`
   - Unit tests for service and model
   - Widget tests for UI
   - Integration tests for workflows

7. **Update documentation** if needed

### Modifying Existing Feature

1. **Locate relevant files**:
   - Service: `lib/core/services/<domain>/`
   - Model: `lib/core/models/`
   - UI: `lib/presentation/`

2. **Make changes**

3. **Regenerate code** if providers/models changed:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Update tests**

5. **Test manually**:
   ```bash
   flutter run
   ```

### Debugging Issues

1. **Check logs**:
   - Look for `debugPrint` statements
   - Use `logging_service.dart` for structured logging

2. **Use Flutter DevTools**:
   - Performance profiling
   - Widget inspector
   - Network inspector

3. **Check Supabase logs**:
   - Backend errors
   - RLS issues
   - Database errors

4. **Common issues**:
   - Missing code generation → Run `dart run build_runner build`
   - Supabase auth errors → Check `.env` configuration
   - ML detection not working → Check camera permissions

### Working with Supabase

**Adding a new table**:
1. Create migration in `database/` directory
2. Update model in `lib/core/models/`
3. Update `DatabaseHelper` if needed
4. Add Supabase methods to relevant service
5. Test with test database

**Updating RLS policies**:
1. Modify policies in Supabase dashboard or migration
2. Test access control
3. Update service methods if needed

---

## Additional Resources

### Internal Documentation

- `/README.md` - Project overview and setup
- `/docs/ENVIRONMENT_SETUP.md` - Detailed environment configuration
- `/docs/supabase-setup.md` - Supabase setup guide
- `/test/TESTING_GUIDE.md` - Testing guidelines
- `/test/ML_PIPELINE_TESTING_GUIDE.md` - ML testing specifics
- `/database/README.md` - Database schema and migrations

### External Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [ML Kit Documentation](https://developers.google.com/ml-kit)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

---

## Project Status & Contribution Notes

### Current State

- ✅ Fully functional on Android
- ❌ iOS untested (code exists but not verified)
- ✅ Comprehensive test suite with 85%+ coverage target
- ⚠️ Performance optimization needed for mid-range devices

### Known Limitations

- iOS support untested
- Performance on low-end Android devices
- Some code may be redundant (AI-generated project)
- Limited internationalization

### Contribution Priorities

1. **iOS testing and fixes** - Test on iOS devices, fix platform-specific issues
2. **Code deletion/refactoring** - Identify and remove unused/redundant code
3. **Performance optimization** - Improve AR detection on various devices
4. **Bug fixes** - Fix issues in current implementation
5. **Feature enhancements** - Add new gamification features

---

## Quick Reference

### File Statistics

- **Source files**: 101 `.dart` files
- **Generated files**: 9 `.g.dart` files
- **Test files**: 70+ test files

### Critical Patterns to Follow

1. **Service Lifecycle**:
   - Services are singletons or Riverpod-managed
   - Always implement `dispose()` for cleanup
   - Use `ref.onDispose()` in Riverpod services

2. **Data Synchronization**:
   - Local-first (immediate UI updates)
   - Background Supabase sync (when authenticated)
   - Offline queue for failed operations

3. **Error Handling**:
   - Comprehensive try-catch in all services
   - User-friendly error messages
   - Retry logic for network operations

4. **Performance**:
   - ML processing modes (full vs cached)
   - Frame skipping during high load
   - Proper resource cleanup

5. **Testing**:
   - Write tests for new features
   - Maintain 85%+ coverage
   - Use golden tests for UI changes

---

**This guide is maintained to help AI assistants understand and work effectively with the CleanClik codebase. For specific implementation details, refer to the source code and inline documentation.**

**Last Updated**: 2025-11-15
