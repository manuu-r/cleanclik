# CleanClik Test Organization Guide

This document outlines the organization and naming conventions for the CleanClik test suite, ensuring consistency and maintainability across all test files.

## 📁 Directory Structure

### Unit Tests (`test/unit/`)

Organized by service domain following the CleanClik architecture:

```
test/unit/
├── auth/                          # Authentication & user management
│   ├── auth_service_test.dart
│   ├── supabase_config_service_test.dart
│   └── google_signin_service_test.dart
├── camera/                        # Camera, AR, and ML detection
│   ├── ml_detection_service_test.dart
│   ├── qr_bin_service_test.dart
│   ├── camera_resource_manager_test.dart
│   └── disposal_detection_service_test.dart
├── business/                      # Business logic services
│   ├── inventory_service_test.dart
│   ├── object_management_service_test.dart
│   └── smart_suggestions_service_test.dart
├── data/                          # Database and storage
│   ├── database_service_test.dart
│   ├── sync_service_test.dart
│   ├── local_storage_service_test.dart
│   └── data_migration_service_test.dart
├── location/                      # Location and mapping
│   ├── location_service_test.dart
│   ├── bin_location_service_test.dart
│   └── bin_matching_service_test.dart
├── social/                        # Social and leaderboard
│   ├── leaderboard_service_test.dart
│   ├── social_sharing_service_test.dart
│   └── deep_link_service_test.dart
├── platform/                      # Platform-specific
│   ├── hand_tracking_service_test.dart
│   └── platform_optimizer_test.dart
└── models/                        # Data models
    ├── user_test.dart
    ├── detected_object_test.dart
    ├── waste_category_test.dart
    └── camera_mode_test.dart
```

### Widget Tests (`test/widget/`)

Organized by UI feature and component type:

```
test/widget/
├── screens/                       # Screen widget tests
│   ├── auth/                      # Authentication screens
│   │   ├── login_screen_test.dart
│   │   ├── signup_screen_test.dart
│   │   ├── email_verification_screen_test.dart
│   │   └── auth_wrapper_test.dart
│   ├── camera/                    # AR camera screens
│   │   └── ar_camera_screen_test.dart
│   ├── map/                       # Map screens
│   │   └── map_screen_test.dart
│   ├── profile/                   # Profile screens
│   │   └── profile_screen_test.dart
│   └── leaderboard/               # Leaderboard screens
│       └── leaderboard_screen_test.dart
├── navigation/                    # Navigation components
│   ├── ar_navigation_shell_test.dart
│   └── home_screen_test.dart
└── widgets/                       # Reusable widgets
    ├── camera/                    # Camera-related widgets
    │   ├── enhanced_object_overlay_test.dart
    │   ├── qr_scanner_overlay_test.dart
    │   └── camera_mode_switching_test.dart
    ├── overlays/                  # Overlay widgets
    │   ├── indicator_widget_test.dart
    │   └── disposal_celebration_overlay_test.dart
    ├── inventory/                 # Inventory widgets
    │   └── detail_card_test.dart
    ├── map/                       # Map widgets
    │   └── bin_marker_test.dart
    ├── social/                    # Social widgets
    │   └── leaderboard_components_test.dart
    └── common/                    # Common widgets
        └── loading_indicator_test.dart
```

### Integration Tests (`test/integration/`)

Organized by user flow and feature integration:

```
test/integration/
├── auth_flow_test.dart            # Complete authentication flow
├── camera_detection_flow_test.dart # Camera + ML detection workflow
├── inventory_sync_flow_test.dart   # Inventory + Supabase sync
├── map_navigation_flow_test.dart   # Map + location workflow
└── leaderboard_flow_test.dart      # Social features workflow
```

### Golden Tests (`test/golden/`)

Organized by component type for visual regression testing:

```
test/golden/
├── screens/                       # Screen golden tests
│   ├── ar_camera_screen_golden_test.dart
│   ├── map_screen_golden_test.dart
│   ├── profile_screen_golden_test.dart
│   ├── leaderboard_screen_golden_test.dart
│   └── auth_screens_golden_test.dart
└── widgets/                       # Widget golden tests
    ├── ar_overlay_golden_test.dart
    ├── navigation_shell_golden_test.dart
    ├── camera_mode_switching_golden_test.dart
    └── responsive_design_golden_test.dart
```

## 📝 Naming Conventions

### File Naming
- **Pattern**: `{feature_name}_{type}_test.dart`
- **Examples**:
  - `auth_service_test.dart`
  - `ar_camera_screen_test.dart`
  - `inventory_sync_flow_test.dart`
  - `leaderboard_components_golden_test.dart`

### Class Naming
- **Pattern**: `{FeatureName}{Type}Test`
- **Examples**:
  - `AuthServiceTest`
  - `ARCameraScreenTest`
  - `InventorySyncFlowTest`
  - `LeaderboardComponentsGoldenTest`

### Test Group Naming
- Use descriptive names that match the feature being tested
- Group related tests logically
- Use consistent naming across similar test files

```dart
group('AuthService', () {
  group('signInWithEmail', () {
    test('should authenticate valid user', () {});
    test('should reject invalid credentials', () {});
    test('should handle network errors', () {});
  });
  
  group('signInWithGoogle', () {
    test('should authenticate with Google account', () {});
    test('should handle Google Sign-In cancellation', () {});
  });
});
```

### Test Method Naming
- Use descriptive names that explain the expected behavior
- Follow the pattern: `should {expected_behavior} when {condition}`
- Be specific about the scenario being tested

```dart
test('should return authenticated user when valid credentials provided', () {});
test('should throw AuthException when invalid password provided', () {});
test('should update user profile when valid data submitted', () {});
```

## 🏷️ Test Tags and Categories

### Tag Usage
Use tags to categorize tests for selective execution:

```dart
@Tags(['unit', 'auth'])
void main() {
  // Auth service unit tests
}

@Tags(['widget', 'camera'])
void main() {
  // Camera widget tests
}

@Tags(['integration', 'critical'])
void main() {
  // Critical user flow tests
}

@Tags(['golden', 'ui'])
void main() {
  // UI regression tests
}

@Tags(['performance', 'ml'])
void main() {
  // ML performance tests
}
```

### Available Tags
- **`unit`**: Unit tests for services and models
- **`widget`**: Widget and UI component tests
- **`integration`**: End-to-end integration tests
- **`golden`**: Golden file visual regression tests
- **`performance`**: Performance and benchmark tests
- **`auth`**: Authentication-related tests
- **`camera`**: Camera and ML detection tests
- **`supabase`**: Supabase integration tests
- **`critical`**: Critical path tests that must always pass
- **`slow`**: Tests that take longer to execute

### Running Tagged Tests
```bash
# Run only unit tests
flutter test --tags=unit

# Run auth-related tests
flutter test --tags=auth

# Exclude slow tests
flutter test --exclude-tags=slow

# Run critical tests only
flutter test --tags=critical
```

## 📋 Test File Templates

### Unit Test Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../helpers/base_service_test.dart';
import '../fixtures/test_data_factory.dart';

@Tags(['unit', 'feature_tag'])
class FeatureServiceTest extends BaseServiceTest {
  late FeatureService featureService;

  @override
  void setUp() {
    super.setUp();
    featureService = FeatureService(
      mockSupabaseClient,
      // other dependencies
    );
  }

  void main() {
    group('FeatureService', () {
      group('methodName', () {
        test('should perform expected behavior when valid input provided', () async {
          // Arrange
          final mockData = TestDataFactory.createMockData();
          when(mockDependency.method()).thenReturn(mockData);

          // Act
          final result = await featureService.methodName();

          // Assert
          expect(result, isNotNull);
          verify(mockDependency.method()).called(1);
        });

        test('should handle error when invalid input provided', () async {
          // Arrange
          when(mockDependency.method()).thenThrow(Exception('Test error'));

          // Act & Assert
          expect(
            () => featureService.methodName(),
            throwsA(isA<FeatureException>()),
          );
        });
      });
    });
  }
}
```

### Widget Test Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/base_widget_test.dart';
import '../fixtures/test_data_factory.dart';

@Tags(['widget', 'feature_tag'])
class FeatureWidgetTest extends BaseWidgetTest {
  void main() {
    group('FeatureWidget', () {
      setUp(() {
        setUpWidgetTest();
      });

      tearDown(() {
        tearDownWidgetTest();
      });

      testWidgets('should render correctly with default state', (tester) async {
        // Arrange
        final mockState = TestDataFactory.createMockState();

        await tester.pumpWidget(
          createTestWidget(
            ProviderScope(
              overrides: [
                featureProvider.overrideWith((ref) => mockState),
              ],
              child: const FeatureWidget(),
            ),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(FeatureWidget), findsOneWidget);
        expect(find.text('Expected Text'), findsOneWidget);
      });

      testWidgets('should handle user interaction correctly', (tester) async {
        // Test user interactions
      });
    });
  }
}
```

### Integration Test Template
```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_integration_test.dart';

@Tags(['integration', 'feature_tag'])
class FeatureFlowTest extends BaseIntegrationTest {
  void main() {
    group('Feature Flow', () {
      setUp(() async {
        await setUpIntegrationTest();
      });

      tearDown(() async {
        await tearDownIntegrationTest();
      });

      testWidgets('should complete feature workflow successfully', (tester) async {
        // Arrange
        await initializeTestEnvironment();

        // Act & Assert - Step by step flow verification
        // Step 1: Initial state
        expect(find.byType(InitialScreen), findsOneWidget);

        // Step 2: User action
        await tester.tap(find.byKey(const Key('action_button')));
        await tester.pumpAndSettle();

        // Step 3: Verify result
        expect(find.byType(ResultScreen), findsOneWidget);
      });
    });
  }
}
```

### Golden Test Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import '../helpers/base_widget_test.dart';

@Tags(['golden', 'ui'])
class FeatureGoldenTest extends BaseWidgetTest {
  void main() {
    group('Feature Golden Tests', () {
      testGoldens('should match golden files across themes and devices', (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [
            Device.phone,
            Device.iphone11,
            Device.tabletPortrait,
          ])
          ..addScenario(
            widget: const FeatureWidget(),
            name: 'light_theme',
          )
          ..addScenario(
            widget: Theme(
              data: ThemeData.dark(),
              child: const FeatureWidget(),
            ),
            name: 'dark_theme',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'feature_widget');
      });
    });
  }
}
```

## 🔍 Test Discovery and Maintenance

### Automated Test Discovery
The test organization follows predictable patterns that enable:

1. **Automatic test discovery** by CI/CD systems
2. **Parallel test execution** by category
3. **Selective test running** during development
4. **Coverage analysis** by feature domain

### Maintenance Guidelines

#### Adding New Tests
1. Follow the directory structure for the appropriate test type
2. Use consistent naming conventions
3. Apply appropriate tags for categorization
4. Extend the appropriate base test class
5. Update this documentation if adding new categories

#### Refactoring Tests
1. Maintain the same file organization structure
2. Update test names to reflect new functionality
3. Preserve test tags and categories
4. Update related documentation

#### Removing Tests
1. Ensure no other tests depend on the removed test
2. Update coverage expectations if necessary
3. Remove related mock data and fixtures
4. Update documentation references

This organization ensures the CleanClik test suite remains maintainable, discoverable, and aligned with the application's architecture as it evolves.