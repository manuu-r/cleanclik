# Testing Strategy Design Document

## Overview

This design outlines a comprehensive testing strategy for the CleanClik Flutter app, covering unit tests, widget tests, integration tests, performance tests, and golden tests. The strategy is tailored for the actual CleanClik architecture using Supabase backend, Riverpod state management, GoRouter navigation, Google ML Kit object detection, and Material 3 theming.

## Architecture

### Test Structure Organization
```
test/
├── unit/                           # Unit tests for services and models
│   ├── auth/                      # Supabase authentication service tests
│   │   ├── auth_service_test.dart
│   │   └── supabase_config_service_test.dart
│   ├── camera/                    # Camera and ML detection service tests
│   │   ├── ml_detection_service_test.dart
│   │   ├── qr_bin_service_test.dart
│   │   ├── camera_resource_manager_test.dart
│   │   └── disposal_detection_service_test.dart
│   ├── business/                  # Business logic service tests
│   │   ├── inventory_service_test.dart
│   │   ├── object_management_service_test.dart
│   │   └── smart_suggestions_service_test.dart
│   ├── data/                      # Database and storage service tests
│   │   ├── database_service_test.dart
│   │   ├── sync_service_test.dart
│   │   ├── local_storage_service_test.dart
│   │   └── data_migration_service_test.dart
│   ├── location/                  # Location and mapping service tests
│   │   ├── location_service_test.dart
│   │   ├── bin_location_service_test.dart
│   │   └── bin_matching_service_test.dart
│   ├── social/                    # Social and leaderboard service tests
│   │   ├── leaderboard_service_test.dart
│   │   ├── social_sharing_service_test.dart
│   │   └── deep_link_service_test.dart
│   ├── platform/                  # Platform-specific service tests
│   │   ├── hand_tracking_service_test.dart
│   │   └── platform_optimizer_test.dart
│   └── models/                    # Data model tests
│       ├── user_test.dart
│       ├── detected_object_test.dart
│       ├── waste_category_test.dart
│       └── camera_mode_test.dart
├── widget/                        # Widget tests for UI components
│   ├── screens/                   # Screen widget tests
│   │   ├── auth/                  # Authentication screen tests
│   │   ├── camera/                # AR camera screen tests
│   │   ├── map/                   # Map screen tests
│   │   ├── profile/               # Profile screen tests
│   │   └── leaderboard/           # Leaderboard screen tests
│   ├── navigation/                # Navigation component tests
│   │   ├── ar_navigation_shell_test.dart
│   │   └── home_screen_test.dart
│   └── widgets/                   # Reusable widget tests
│       ├── camera/                # Camera widget tests
│       ├── overlays/              # AR overlay widget tests
│       ├── inventory/             # Inventory widget tests
│       └── common/                # Common widget tests
├── integration/                   # Integration tests for user flows
│   ├── auth_flow_test.dart       # Supabase auth + Google Sign-In flow
│   ├── camera_detection_flow_test.dart # ML detection + QR scanning workflow
│   ├── inventory_sync_flow_test.dart   # Local + Supabase inventory sync
│   ├── map_navigation_flow_test.dart   # Map + bin location workflow
│   └── leaderboard_flow_test.dart      # Social features + sharing workflow
├── performance/                   # Performance and benchmark tests
│   ├── ml_detection_performance_test.dart  # ML Kit processing speed
│   ├── camera_switching_performance_test.dart # Mode switching latency
│   ├── supabase_sync_performance_test.dart    # Database sync performance
│   └── memory_usage_test.dart              # Memory leak detection
├── golden/                        # Golden file tests for UI consistency
│   ├── screens/                   # Screen golden tests
│   │   ├── ar_camera_screen_golden_test.dart
│   │   ├── map_screen_golden_test.dart
│   │   ├── profile_screen_golden_test.dart
│   │   └── leaderboard_screen_golden_test.dart
│   └── widgets/                   # Widget golden tests
│       ├── ar_overlay_golden_test.dart
│       └── navigation_shell_golden_test.dart
├── fixtures/                      # Test data and mock responses
│   ├── mock_data/                 # Mock domain objects
│   │   ├── mock_users.dart
│   │   ├── mock_inventory_items.dart
│   │   ├── mock_detected_objects.dart
│   │   └── mock_bin_locations.dart
│   ├── test_images/               # Test images for ML detection
│   │   ├── recyclable_objects/
│   │   ├── organic_waste/
│   │   └── edge_cases/
│   └── supabase_responses/        # Mock Supabase API responses
│       ├── auth_responses.dart
│       ├── database_responses.dart
│       └── storage_responses.dart
└── helpers/                       # Test utilities and helpers
    ├── mock_services.dart         # Riverpod provider mocks
    ├── supabase_test_client.dart  # Mock Supabase client
    ├── test_utils.dart            # Common test utilities
    └── widget_test_helpers.dart   # Widget testing with ProviderScope
```

## Components and Interfaces

### Test Base Classes

#### BaseServiceTest
```dart
abstract class BaseServiceTest {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoRouter mockRouter;
  late ProviderContainer container;
  
  void setUpMocks();
  void tearDownMocks();
  void setUpRiverpodContainer();
}
```

#### BaseWidgetTest
```dart
abstract class BaseWidgetTest {
  late MockGoRouter mockRouter;
  late ProviderContainer container;
  
  Widget createTestWidget(Widget child);
  Future<void> pumpAndSettle(WidgetTester tester);
  void overrideProviders(List<Override> overrides);
}
```

#### BaseIntegrationTest
```dart
abstract class BaseIntegrationTest {
  late IntegrationTestWidgetsFlutterBinding binding;
  late MockSupabaseClient mockSupabaseClient;
  
  Future<void> setUpIntegrationTest();
  Future<void> tearDownIntegrationTest();
  Future<void> initializeSupabaseMocks();
}
```

### Mock Service Layer

#### MockSupabaseClient
- Simulates Supabase authentication, database, and storage operations
- Provides controllable auth states and user sessions
- Handles offline/online scenarios and network errors

#### MockMLDetectionService
- Simulates Google ML Kit object detection responses
- Provides controllable detection results for different waste categories
- Handles camera frame processing and object tracking

#### MockInventoryService
- Manages test inventory states with Supabase schema compatibility
- Simulates local storage and Supabase synchronization
- Provides predictable CRUD operations and sync conflicts

#### MockLocationService
- Simulates GPS location updates and permission states
- Provides mock bin locations and proximity calculations
- Controls geofencing behavior and location accuracy

#### MockLeaderboardService
- Simulates real-time leaderboard updates via Supabase
- Provides mock user rankings and achievement data
- Handles social sharing and deep link scenarios

### Test Data Management

#### TestDataFactory
```dart
class TestDataFactory {
  static User createMockUser({String? id, String? email, String? username});
  static DetectedObject createMockDetectedObject({WasteCategory? category, double? confidence});
  static BinLocation createMockBinLocation({LatLng? coordinates, String? binId});
  static InventoryItem createMockInventoryItem({String? category, DateTime? pickedUpAt});
  static AuthState createMockAuthState({AuthStatus? status, User? user, bool? isDemoMode});
  static CameraState createMockCameraState({CameraMode? mode, CameraStatus? status});
}
```

#### TestImageAssets
- Curated test images for Google ML Kit detection testing
- Images representing each waste category (recycle, organic, landfill, ewaste, hazardous)
- Edge case images (blurry, dark, multiple objects, QR codes)
- Organized by waste category for systematic testing

## Data Models

### Test Configuration
```dart
class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration mlProcessingThreshold = Duration(milliseconds: 100);
  static const Duration cameraSwitchingThreshold = Duration(milliseconds: 200);
  static const Duration supabaseSyncThreshold = Duration(seconds: 5);
  static const double coverageThreshold = 0.85;
  static const double serviceCoverageThreshold = 0.85;
  static const double criticalPathCoverageThreshold = 0.90;
}
```

### Performance Metrics
```dart
class PerformanceMetrics {
  final Duration mlProcessingTime;
  final Duration cameraSwitchingTime;
  final Duration supabaseSyncTime;
  final int memoryUsageMB;
  final int simultaneousObjectsHandled;
  final bool meetsRequirements;
}
```

### Test Results
```dart
class TestResults {
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final double coveragePercentage;
  final List<TestFailure> failures;
  final PerformanceMetrics? performanceMetrics;
  final Map<String, double> serviceCoverage;
  final List<String> uncoveredRiverpodProviders;
}
```

## Error Handling

### Test Error Categories
1. **Supabase Errors**: Connection failures, authentication errors, RLS policy violations, real-time subscription failures
2. **ML Kit Errors**: Object detection failures, camera permission issues, processing timeouts
3. **UI Errors**: Widget rendering failures, GoRouter navigation issues, Riverpod provider errors
4. **Integration Errors**: End-to-end flow failures, state synchronization between local and Supabase storage

### Error Recovery Strategies
- Automatic retry for flaky Supabase connection tests
- Graceful degradation testing for offline scenarios with local storage fallback
- Error boundary testing for Riverpod provider failures
- Resource cleanup verification for camera and ML Kit resources

### Test Isolation
- Each test runs with fresh ProviderContainer and mock Supabase client
- Riverpod providers reset between tests using container.dispose()
- No shared state between test cases
- Proper cleanup of camera resources, ML Kit detectors, and Supabase subscriptions

## Testing Tools and Dependencies

### Core Testing Framework
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  golden_toolkit: ^0.15.0
  flutter_riverpod: ^2.4.0    # For provider testing
```

### Specialized Testing Tools
```yaml
dev_dependencies:
  network_image_mock: ^2.1.1  # Mock network images
  patrol: ^2.0.0              # Advanced integration testing
  flutter_driver:             # Performance testing
    sdk: flutter
  test_coverage: ^0.2.0       # Coverage reporting
```

### Mock Generation and Strategy
- Use Mockito for service mocking with Riverpod provider overrides
- Generate mocks with build_runner for Supabase client and services
- Create custom mocks for Google ML Kit object detection responses
- Mock Supabase real-time subscriptions and database operations
- Use ProviderContainer.overrideWith for Riverpod provider testing

## Testing Strategy

### Unit Testing Approach

#### Riverpod Provider Testing
- Test each Riverpod provider independently using ProviderContainer
- Mock Supabase client and external dependencies (Google ML Kit, location services)
- Verify provider state changes and async operations
- Test provider dependencies and overrides
- Validate error handling in provider notifiers

#### Service Testing
- Test AuthService with mock Supabase auth and Google Sign-In
- Test MLDetectionService with mock Google ML Kit responses
- Test InventoryService with mock local storage and Supabase sync
- Test LocationService with mock GPS and geofencing
- Test LeaderboardService with mock Supabase real-time subscriptions

#### Model Testing
- Test User, DetectedObject, InventoryItem serialization with Supabase schema
- Verify WasteCategory enum and CameraMode enum functionality
- Test CameraState and AuthState immutability and copyWith methods
- Validate model equality and hashCode implementations

### Widget Testing Approach

#### Screen Testing with Riverpod
- Test ARCameraScreen with mock camera and ML detection providers
- Test MapScreen with mock location and bin data providers
- Test ProfileScreen with mock auth and user data providers
- Test LeaderboardScreen with mock leaderboard data providers
- Verify GoRouter navigation and AuthWrapper protection

#### Component Testing
- Test AR overlay widgets with mock detected objects
- Test inventory widgets with mock InventoryItem data
- Test navigation shell with mock route state
- Validate Material 3 theme application and responsive design
- Check accessibility features and semantic labels

### Integration Testing Approach

#### Critical User Flows
1. **Supabase Authentication Flow**: Login → Google Sign-In → Email Verification → Demo Mode
2. **Camera Detection Flow**: Camera Permission → ML Detection → QR Scanning → Mode Switching
3. **Inventory Sync Flow**: Local Storage → Supabase Sync → Offline Handling → Conflict Resolution
4. **Map Navigation Flow**: Location Permission → Bin Display → Proximity Detection → Disposal Workflow
5. **Social Features Flow**: Leaderboard Updates → Achievement Unlock → Social Sharing → Deep Links

#### Cross-Platform Testing
- Test on iOS and Android with platform-specific camera implementations
- Verify Supabase authentication across platforms
- Test Google ML Kit performance on different devices
- Validate Material 3 theming and responsive layouts

### Performance Testing Approach

#### ML Detection Performance
- Measure Google ML Kit object detection processing time (<100ms target)
- Test camera mode switching latency (<200ms target)
- Monitor memory usage during extended ML detection sessions
- Verify performance with multiple simultaneous objects (up to 10)

#### Supabase Sync Performance
- Measure inventory synchronization time (<5 seconds target)
- Test real-time leaderboard update latency
- Monitor network usage and offline handling
- Verify performance under poor network conditions

### Golden Testing Approach

#### Material 3 Visual Regression
- Capture golden files for all main screens in light and dark themes
- Test AR overlay components and detection indicators
- Verify responsive design across phone and tablet layouts
- Test navigation shell and bottom navigation consistency
- Monitor for unintended visual changes in Material 3 components

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: CleanClik Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test --coverage --exclude-tags=integration
      - run: flutter test integration_test/ --tags=integration
      - uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

### Test Execution Strategy
1. **Pre-commit**: Run unit tests and Riverpod provider tests locally
2. **CI Pipeline**: Full test suite including Riverpod code generation verification
3. **Release**: Extended integration tests with mock Supabase environments
4. **Nightly**: Performance benchmarks and golden test updates

### Coverage Requirements
- Minimum 85% overall coverage (excluding .g.dart generated files)
- 85% coverage for service classes and Riverpod providers
- 90% coverage for Supabase integration and critical business logic
- 80% coverage for camera/ML detection performance-critical paths
- 95% coverage for data models and utility classes

### Quality Gates
- All Riverpod providers must have corresponding unit tests
- No decrease in coverage percentage allowed
- Performance tests must pass latency thresholds
- Golden tests must pass or be explicitly updated
- Supabase integration tests must use mock clients only

This comprehensive testing strategy ensures the CleanClik app maintains high quality, performance, and reliability across all Supabase integration, Riverpod state management, Google ML Kit detection, and Material 3 UI features while supporting continuous development and deployment practices.