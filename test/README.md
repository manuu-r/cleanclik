# CleanClik Test Suite

This directory contains the comprehensive test suite for the CleanClik Flutter application, implementing a robust testing strategy for the Supabase-powered waste management app with AR object detection, QR bin scanning, inventory management, leaderboards, and social features.

## 🏗️ Test Architecture

The test suite follows CleanClik's clean architecture with organized test categories:

```
test/
├── unit/                           # Unit tests for services and models
│   ├── auth/                      # Supabase authentication service tests
│   ├── camera/                    # Camera and ML detection service tests
│   ├── business/                  # Business logic service tests
│   ├── data/                      # Database and storage service tests
│   ├── location/                  # Location and mapping service tests
│   ├── social/                    # Social and leaderboard service tests
│   ├── platform/                  # Platform-specific service tests
│   └── models/                    # Data model tests
├── widget/                        # Widget tests for UI components
│   ├── screens/                   # Screen widget tests
│   ├── navigation/                # Navigation component tests
│   └── widgets/                   # Reusable widget tests
├── integration/                   # Integration tests for user flows
├── golden/                        # Golden file tests for UI consistency
├── fixtures/                      # Test data and mock responses
└── helpers/                       # Test utilities and base classes
```

## 🧪 Test Categories

### Unit Tests (`unit/`)
Tests core business logic, services, and data models in isolation:

- **Authentication Tests**: Supabase auth, Google Sign-In, demo mode
- **ML Detection Tests**: Google ML Kit object detection and tracking
- **Inventory Tests**: Local storage, Supabase sync, item lifecycle
- **Location Tests**: GPS handling, bin proximity, geofencing
- **Leaderboard Tests**: Score calculations, rankings, achievements
- **Model Tests**: Data serialization, validation, immutability

### Widget Tests (`widget/`)
Tests UI components with Riverpod providers and Material 3 theming:

- **Screen Tests**: ARCameraScreen, MapScreen, ProfileScreen, LeaderboardScreen
- **Navigation Tests**: GoRouter integration, AuthWrapper protection
- **Component Tests**: AR overlays, camera controls, inventory widgets
- **Responsive Tests**: Phone/tablet layouts, accessibility features

### Integration Tests (`integration/`)
Tests end-to-end user flows with mock Supabase backend:

- **Auth Flow**: Login → Google Sign-In → Email Verification → Demo Mode
- **Camera Flow**: Permission → ML Detection → QR Scanning → Mode Switching
- **Inventory Flow**: Local Storage → Supabase Sync → Offline Handling
- **Map Flow**: Location → Bin Display → Proximity → Disposal Workflow
- **Social Flow**: Leaderboard → Achievements → Sharing → Deep Links

### Golden Tests (`golden/`)
Visual regression tests for UI consistency across themes and devices:

- **Screen Golden Tests**: All main screens in light/dark themes
- **Component Golden Tests**: AR overlays, detection indicators
- **Responsive Golden Tests**: Phone/tablet layouts
- **Theme Golden Tests**: Material 3 component consistency

## 🚀 Running Tests

### Quick Start
```bash
# Install dependencies and generate code
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test

# Run with coverage
./scripts/test_coverage.sh
```

### Specific Test Categories
```bash
# Unit tests only
flutter test test/unit/

# Widget tests only  
flutter test test/widget/

# Integration tests only
flutter test test/integration/

# Golden tests only
flutter test --tags=golden test/golden/

# Exclude integration and golden tests
flutter test --exclude-tags=integration,golden
```

### Coverage Analysis
```bash
# Generate detailed coverage report
./scripts/test_coverage.sh

# Analyze coverage with detailed breakdown
dart run scripts/coverage_analysis.dart

# View HTML coverage report
open coverage/html/index.html
```

### Performance Testing
```bash
# Run performance benchmarks
flutter test test/performance/

# ML detection performance
flutter test test/performance/ml_detection_performance_test.dart

# Memory usage testing
flutter test test/performance/memory_usage_test.dart
```

## 📊 Coverage Requirements

### Thresholds
- **Overall Coverage**: 85% minimum
- **Service Classes**: 85% minimum
- **Supabase Integration**: 90% minimum
- **Data Models**: 95% minimum
- **Critical Paths**: 80% minimum

### Exclusions
- Riverpod generated files (`.g.dart`)
- Flutter generated files
- Platform-specific code
- Test files themselves

### Coverage Reports
```bash
# Generate coverage with filtering
flutter test --coverage
lcov --remove coverage/lcov.info '**/*.g.dart' '**/*.freezed.dart' --output-file coverage/lcov_filtered.info

# HTML report generation
genhtml coverage/lcov_filtered.info --output-directory coverage/html
```

## 🛠️ Key Features

### Base Test Classes

- **BaseServiceTest**: Provides common setup for service unit tests with Riverpod provider mocking
- **BaseWidgetTest**: Handles widget testing with Material 3 theming and GoRouter integration
- **BaseIntegrationTest**: Sets up full app integration testing environment

### Mock Services

- Generated mocks using Mockito for all CleanClik services
- Simplified Supabase client mocking for database operations
- Mock data factories for consistent test data generation

### Test Data Factory

The `TestDataFactory` class provides methods to create mock objects for:
- Users with various activity levels
- Detected objects with different confidence levels
- Bin locations with geospatial data
- Inventory items with sync states
- Leaderboard entries and achievements
- Category statistics and analytics

### Test Configuration

- Performance thresholds for ML detection (<100ms)
- Camera switching latency requirements (<200ms)
- Supabase sync operation limits (<5 seconds)
- Coverage requirements (85% overall, 90% for critical paths)

## Usage

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test categories
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/

# Run with coverage
flutter test --coverage

# Run performance tests
flutter test test/performance/
```

### Creating New Tests

#### Service Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_service_test.dart';
import '../fixtures/test_data_factory.dart';

class MyServiceTest extends BaseServiceTest {
  void main() {
    group('MyService', () {
      setUp(() {
        setUpMocks();
        setUpRiverpodContainer();
      });

      tearDown(() {
        tearDownMocks();
      });

      test('should perform operation correctly', () {
        // Test implementation
      });
    });
  }
}
```

#### Widget Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_widget_test.dart';
import '../helpers/widget_test_helpers.dart';

class MyWidgetTest extends BaseWidgetTest {
  void main() {
    group('MyWidget', () {
      setUp(() {
        setUpWidgetTest();
      });

      tearDown(() {
        tearDownWidgetTest();
      });

      testWidgets('should render correctly', (tester) async {
        await WidgetTestHelpers.pumpTestWidget(
          tester,
          MyWidget(),
        );

        WidgetTestHelpers.expectWidgetExists<MyWidget>();
      });
    });
  }
}
```

### Mock Data Generation

```dart
// Create mock users
final users = TestDataFactory.createMockUsers(count: 10);

// Create mock detected objects
final objects = TestDataFactory.createMockDetectedObjects(
  count: 5,
  category: WasteCategory.recycle,
);

// Create mock bin locations
final bins = TestDataFactory.createMockBinLocations(
  count: 20,
  centerLat: 37.7749,
  centerLng: -122.4194,
);
```

## Testing Strategy

This infrastructure supports the comprehensive testing strategy with:

1. **Unit Tests**: Service logic, data models, and business rules
2. **Widget Tests**: UI components, navigation, and user interactions
3. **Integration Tests**: End-to-end user flows with Supabase integration
4. **Performance Tests**: ML detection speed, camera switching, sync operations
5. **Golden Tests**: UI consistency across themes and device sizes

## Dependencies

- `flutter_test`: Core Flutter testing framework
- `mockito`: Mock generation and verification
- `flutter_riverpod`: State management testing
- `golden_toolkit`: UI regression testing
- `integration_test`: End-to-end testing

## Coverage Requirements

- Overall: 85% minimum
- Services: 85% minimum  
- Supabase integration: 90% minimum
- Camera/ML detection: 80% minimum
- Critical business logic: 90% minimum

## Performance Thresholds

- ML object detection: <100ms per frame
- Camera mode switching: <200ms
- Supabase sync operations: <5 seconds
- Memory usage: <100MB during camera sessions
- Maximum simultaneous objects: 10

The testing infrastructure is designed to be maintainable, scalable, and aligned with CleanClik's architecture using Supabase, Riverpod, and Material 3.
## ✍️ 
Writing Tests

### Unit Test Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../helpers/base_service_test.dart';
import '../fixtures/test_data_factory.dart';

class AuthServiceTest extends BaseServiceTest {
  late AuthService authService;

  @override
  void setUp() {
    super.setUp();
    authService = AuthService(mockSupabaseClient);
  }

  @override
  void main() {
    group('AuthService', () {
      test('should authenticate user with Supabase', () async {
        // Arrange
        final mockUser = TestDataFactory.createMockUser();
        when(mockSupabaseClient.auth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => AuthResponse(user: mockUser));

        // Act
        final result = await authService.signInWithEmail(
          'test@example.com', 
          'password123'
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.user?.email, 'test@example.com');
      });
    });
  }
}
```

### Widget Test Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/base_widget_test.dart';
import '../fixtures/test_data_factory.dart';

class ARCameraScreenTest extends BaseWidgetTest {
  @override
  void main() {
    group('ARCameraScreen', () {
      testWidgets('should display camera view and AR overlays', (tester) async {
        // Arrange
        final mockCameraState = TestDataFactory.createMockCameraState();
        
        await tester.pumpWidget(
          createTestWidget(
            ProviderScope(
              overrides: [
                cameraStateProvider.overrideWith((ref) => mockCameraState),
              ],
              child: const ARCameraScreen(),
            ),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CameraPreview), findsOneWidget);
        expect(find.byType(AROverlayWidget), findsOneWidget);
        expect(find.byType(DetectionIndicator), findsWidgets);
      });
    });
  }
}
```

### Integration Test Example
```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_integration_test.dart';

class AuthFlowTest extends BaseIntegrationTest {
  @override
  void main() {
    group('Authentication Flow', () {
      testWidgets('should complete full auth flow', (tester) async {
        // Arrange
        await setUpIntegrationTest();
        
        // Act & Assert
        // 1. Start at login screen
        expect(find.byType(LoginScreen), findsOneWidget);
        
        // 2. Tap Google Sign-In
        await tester.tap(find.byKey(const Key('google_signin_button')));
        await tester.pumpAndSettle();
        
        // 3. Verify navigation to main app
        expect(find.byType(ARNavigationShell), findsOneWidget);
        expect(find.byType(ARCameraScreen), findsOneWidget);
      });
    });
  }
}
```

### Golden Test Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import '../helpers/base_widget_test.dart';

class ARCameraScreenGoldenTest extends BaseWidgetTest {
  @override
  void main() {
    group('ARCameraScreen Golden Tests', () {
      testGoldens('should match golden files across themes', (tester) async {
        final builder = DeviceBuilder()
          ..overrideDevicesForAllScenarios(devices: [
            Device.phone,
            Device.iphone11,
            Device.tabletPortrait,
          ])
          ..addScenario(
            widget: const ARCameraScreen(),
            name: 'light_theme',
          )
          ..addScenario(
            widget: Theme(
              data: ThemeData.dark(),
              child: const ARCameraScreen(),
            ),
            name: 'dark_theme',
          );

        await tester.pumpDeviceBuilder(builder);
        await screenMatchesGolden(tester, 'ar_camera_screen');
      });
    });
  }
}
```

## 🔧 Configuration Files

### Coverage Configuration (`coverage_config.yaml`)
Defines coverage collection rules and thresholds.

### Test Scripts
- `scripts/test_coverage.sh`: Comprehensive test execution with coverage
- `scripts/coverage_analysis.dart`: Detailed coverage analysis and reporting

## 🚨 Troubleshooting

### Common Issues

#### Riverpod Provider Tests
```dart
// Always use ProviderContainer for provider testing
final container = ProviderContainer();
addTearDown(container.dispose);

// Override providers for testing
final container = ProviderContainer(
  overrides: [
    authServiceProvider.overrideWith((ref) => mockAuthService),
  ],
);
```

#### Supabase Mock Setup
```dart
// Use MockSupabaseClient for all Supabase interactions
when(mockSupabaseClient.auth.currentUser).thenReturn(mockUser);
when(mockSupabaseClient.from('table')).thenReturn(mockQueryBuilder);
```

#### Golden Test Updates
```bash
# Update golden files when UI changes are intentional
flutter test --update-goldens test/golden/
```

### Performance Considerations
- Use `pumpAndSettle()` sparingly in widget tests
- Mock heavy operations (ML detection, camera)
- Dispose resources properly in tearDown methods
- Use `addTearDown()` for cleanup in tests

## 📈 Continuous Integration

### GitHub Actions Integration
```yaml
- name: Run Tests with Coverage
  run: |
    flutter test --coverage --exclude-tags=integration
    ./scripts/coverage_analysis.dart

- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    file: coverage/lcov_filtered.info
```

### Quality Gates
- All tests must pass
- Coverage thresholds must be met
- No decrease in coverage percentage
- Riverpod providers must have tests
- Golden tests must pass or be updated

This comprehensive test suite ensures CleanClik maintains high quality, performance, and reliability across all features while supporting continuous development and deployment practices.