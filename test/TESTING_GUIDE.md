# CleanClik Testing Guide

Welcome to the CleanClik testing guide! This comprehensive guide covers everything you need to know about testing the CleanClik Flutter application.

## 📚 Documentation Index

### Core Documentation
- **[README.md](README.md)** - Main test suite overview and quick start guide
- **[TEST_ORGANIZATION.md](TEST_ORGANIZATION.md)** - File organization and naming conventions
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - This comprehensive guide (you are here)

### Configuration Files
- **[coverage_config.yaml](../coverage_config.yaml)** - Coverage collection configuration
- **[test_coverage.yml](../.github/workflows/test_coverage.yml)** - CI/CD workflow configuration
- **[Makefile](../Makefile)** - Development commands and shortcuts

### Test Scripts
- **[test_coverage.sh](../scripts/test_coverage.sh)** - Comprehensive test execution script
- **[coverage_analysis.dart](../scripts/coverage_analysis.dart)** - Detailed coverage analysis tool

## 🎯 Quick Start

### Prerequisites
- Flutter 3.24.0+
- Dart 3.9.0+
- lcov (for coverage reports)

### Setup
```bash
# Clone and setup
git clone <repository>
cd cleanclik
make setup

# Run all tests
make test

# Generate coverage report
make coverage
```

## 🧪 Test Categories Deep Dive

### Unit Tests
**Purpose**: Test individual services, models, and business logic in isolation.

**Key Features**:
- Mock all external dependencies (Supabase, Google ML Kit, etc.)
- Test business logic and edge cases
- Verify error handling and state management
- Ensure Riverpod provider behavior

**Example Services Tested**:
- `AuthService` - Supabase authentication and Google Sign-In
- `MLDetectionService` - Google ML Kit object detection
- `InventoryService` - Local storage and Supabase synchronization
- `LocationService` - GPS handling and geofencing
- `LeaderboardService` - Score calculations and rankings

### Widget Tests
**Purpose**: Test UI components, screens, and user interactions.

**Key Features**:
- Test widget rendering with Riverpod providers
- Verify user interactions and navigation
- Test responsive design and accessibility
- Ensure Material 3 theming consistency

**Example Widgets Tested**:
- `ARCameraScreen` - Camera view and AR overlays
- `MapScreen` - Google Maps integration and bin markers
- `ProfileScreen` - User profile display and editing
- `LeaderboardScreen` - Rankings and social features
- Navigation components and route protection

### Integration Tests
**Purpose**: Test end-to-end user flows and cross-service interactions.

**Key Features**:
- Test complete user journeys
- Verify service integration points
- Test offline/online scenarios
- Ensure data consistency across services

**Example Flows Tested**:
- Authentication flow (login → verification → main app)
- Camera detection flow (permission → detection → categorization)
- Inventory sync flow (local storage → Supabase sync)
- Map navigation flow (location → bins → disposal)
- Social features flow (achievements → sharing → leaderboards)

### Golden Tests
**Purpose**: Visual regression testing for UI consistency.

**Key Features**:
- Capture golden files for visual comparison
- Test across different themes (light/dark)
- Verify responsive design on multiple devices
- Detect unintended UI changes

**Example Golden Tests**:
- All main screens in light and dark themes
- AR overlay components and detection indicators
- Navigation shell and bottom navigation
- Responsive layouts for phone and tablet

### Performance Tests
**Purpose**: Ensure the app meets performance requirements.

**Key Features**:
- ML detection processing time (<100ms)
- Camera mode switching latency (<200ms)
- Supabase sync operation timing (<5 seconds)
- Memory usage monitoring
- Frame rate consistency

## 📊 Coverage Requirements and Analysis

### Coverage Thresholds
```yaml
overall: 85%           # Minimum overall coverage
services: 85%          # Service classes coverage
supabase_integration: 90%  # Database operations coverage
models: 95%            # Data models coverage
critical_paths: 80%    # Performance-critical code
```

### Coverage Exclusions
- Riverpod generated files (`.g.dart`)
- Freezed generated files (`.freezed.dart`)
- Flutter generated files
- Platform-specific code (iOS/Android)
- Test files themselves

### Coverage Analysis Tools

#### Automated Analysis
```bash
# Run comprehensive coverage analysis
make coverage-analyze

# Generate HTML report
make coverage-html

# View coverage summary
cat coverage/coverage_summary.txt
```

#### Manual Analysis
```bash
# Check specific service coverage
lcov --extract coverage/lcov_filtered.info 'lib/core/services/auth/*' --output-file coverage/auth_services.info
lcov --summary coverage/auth_services.info

# Find uncovered lines
lcov --list coverage/lcov_filtered.info | grep -E "0\.0%|[0-4]\.[0-9]%"
```

## 🛠️ Development Workflow

### Daily Development
```bash
# Setup development environment
make setup

# Run tests during development
make test-unit          # Quick feedback loop
make test-widget        # UI component testing
make watch-unit         # Continuous testing

# Before committing
make check              # Run all quality checks
```

### Feature Development
```bash
# 1. Write failing tests first (TDD)
make test-unit

# 2. Implement feature
# ... code changes ...

# 3. Run tests to verify implementation
make test

# 4. Update golden files if UI changed
make update-goldens

# 5. Check coverage
make coverage
```

### Pull Request Workflow
```bash
# Before creating PR
make ci-test            # Run CI test suite locally
make coverage           # Ensure coverage thresholds met
make analyze            # Check code quality

# After PR feedback
make test               # Verify changes
make update-goldens     # Update UI tests if needed
```

## 🚨 Troubleshooting Common Issues

### Riverpod Provider Testing
```dart
// ❌ Wrong - Direct provider access
test('should update state', () {
  final provider = ref.read(myProvider);
  // This won't work in tests
});

// ✅ Correct - Use ProviderContainer
test('should update state', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  
  final provider = container.read(myProvider);
  // This works correctly
});
```

### Supabase Mock Setup
```dart
// ❌ Wrong - Incomplete mock setup
when(mockSupabaseClient.auth).thenReturn(mockAuth);

// ✅ Correct - Complete mock chain
when(mockSupabaseClient.auth.currentUser).thenReturn(mockUser);
when(mockSupabaseClient.from('table')).thenReturn(mockQueryBuilder);
when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
```

### Widget Test Async Issues
```dart
// ❌ Wrong - Not waiting for async operations
testWidgets('should load data', (tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Data'), findsOneWidget); // May fail
});

// ✅ Correct - Wait for async operations
testWidgets('should load data', (tester) async {
  await tester.pumpWidget(MyWidget());
  await tester.pumpAndSettle(); // Wait for animations/async
  expect(find.text('Data'), findsOneWidget);
});
```

### Golden Test Failures
```bash
# View golden test differences
flutter test --update-goldens test/golden/specific_test.dart

# Update all golden files (use carefully)
make update-goldens

# Compare golden files manually
diff test/golden/goldens/old_file.png test/golden/goldens/new_file.png
```

### Coverage Issues
```bash
# Check which files are missing coverage
dart run scripts/coverage_analysis.dart

# Generate detailed coverage report
make coverage-html

# Exclude specific files from coverage (if needed)
# Add to coverage_config.yaml exclude section
```

## 🔧 Advanced Testing Techniques

### Custom Matchers
```dart
// Create custom matchers for domain objects
Matcher isValidUser() => predicate<User>((user) {
  return user.id.isNotEmpty && 
         user.email.contains('@') &&
         user.createdAt != null;
}, 'is a valid user');

// Usage in tests
expect(result.user, isValidUser());
```

### Test Data Builders
```dart
// Use builder pattern for complex test data
class UserBuilder {
  String _id = 'test-id';
  String _email = 'test@example.com';
  
  UserBuilder withId(String id) {
    _id = id;
    return this;
  }
  
  UserBuilder withEmail(String email) {
    _email = email;
    return this;
  }
  
  User build() => User(id: _id, email: _email);
}

// Usage
final user = UserBuilder()
  .withEmail('admin@cleanclik.com')
  .withId('admin-123')
  .build();
```

### Performance Testing
```dart
// Measure execution time
test('should process ML detection quickly', () async {
  final stopwatch = Stopwatch()..start();
  
  await mlDetectionService.detectObjects(testImage);
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});

// Memory usage testing
test('should not leak memory during camera session', () async {
  final initialMemory = await getMemoryUsage();
  
  // Simulate camera session
  for (int i = 0; i < 100; i++) {
    await cameraService.processFrame(testFrame);
  }
  
  final finalMemory = await getMemoryUsage();
  expect(finalMemory - initialMemory, lessThan(10 * 1024 * 1024)); // 10MB
});
```

## 📈 Continuous Integration

### GitHub Actions Workflow
The CI/CD pipeline runs:
1. **Code Quality**: Flutter analyze, format check
2. **Unit Tests**: All service and model tests
3. **Widget Tests**: UI component tests
4. **Integration Tests**: End-to-end flow tests
5. **Golden Tests**: Visual regression tests
6. **Coverage Analysis**: Threshold verification
7. **Performance Tests**: Benchmark validation

### Quality Gates
- All tests must pass
- Coverage thresholds must be met
- No decrease in coverage percentage
- Golden tests must pass or be explicitly updated
- Performance benchmarks must meet requirements

### Coverage Reporting
- Codecov integration for coverage tracking
- Coverage badges in README
- PR comments with coverage changes
- Detailed coverage reports in artifacts

## 🎓 Best Practices

### Test Organization
- Group related tests logically
- Use descriptive test names
- Follow the AAA pattern (Arrange, Act, Assert)
- Keep tests focused and independent

### Mock Management
- Use consistent mock data across tests
- Create reusable mock factories
- Mock at the service boundary
- Verify mock interactions when important

### Performance Considerations
- Mock heavy operations (camera, ML detection)
- Use `pumpAndSettle()` judiciously
- Dispose resources in tearDown methods
- Avoid unnecessary widget rebuilds in tests

### Maintenance
- Update tests when refactoring code
- Keep test documentation current
- Review test coverage regularly
- Remove obsolete tests promptly

This comprehensive testing guide ensures CleanClik maintains high quality, performance, and reliability while supporting efficient development workflows.