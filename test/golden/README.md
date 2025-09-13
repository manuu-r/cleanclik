# Golden Tests for CleanClik UI Consistency

This directory contains comprehensive golden tests for the CleanClik Flutter app, ensuring UI consistency across all screens, components, and device configurations.

## Overview

Golden tests capture screenshots of UI components and compare them against reference images to detect visual regressions. This test suite covers all requirements from task 7 of the comprehensive testing strategy:

- ✅ Main screens (ARCameraScreen, MapScreen, ProfileScreen, LeaderboardScreen) in light and dark themes
- ✅ AR overlay components, detection indicators, and camera mode switching UI  
- ✅ Responsive design across phone and tablet layouts with Material 3 components
- ✅ Authentication screens, navigation shell, and accessibility features

## Test Structure

```
test/golden/
├── screens/                          # Main screen golden tests
│   ├── ar_camera_screen_golden_test.dart
│   ├── map_screen_golden_test.dart
│   ├── profile_screen_golden_test.dart
│   ├── leaderboard_screen_golden_test.dart
│   └── auth_screens_golden_test.dart
├── widgets/                          # Component golden tests
│   ├── ar_overlay_golden_test.dart
│   ├── navigation_shell_golden_test.dart
│   ├── camera_mode_switching_golden_test.dart
│   └── responsive_design_golden_test.dart
├── mock_providers.dart               # Mock Riverpod providers
├── mock_screens.dart                 # Mock screen implementations
├── mock_widgets.dart                 # Mock widget implementations
├── golden_test_config.dart           # Test configuration utilities
├── golden_test_runner.dart           # Complete test suite runner
└── README.md                         # This file
```

## Running Golden Tests

### Prerequisites

1. Ensure you have the `golden_toolkit` dependency in your `pubspec.yaml`:
```yaml
dev_dependencies:
  golden_toolkit: ^0.15.0
```

2. Load app fonts before running tests:
```dart
await loadAppFonts();
```

### Running All Golden Tests

```bash
# Run the complete golden test suite
flutter test test/golden/golden_test_runner.dart

# Run specific test groups
flutter test test/golden/screens/
flutter test test/golden/widgets/
```

### Running Individual Test Files

```bash
# Main screens
flutter test test/golden/screens/ar_camera_screen_golden_test.dart
flutter test test/golden/screens/map_screen_golden_test.dart
flutter test test/golden/screens/profile_screen_golden_test.dart
flutter test test/golden/screens/leaderboard_screen_golden_test.dart
flutter test test/golden/screens/auth_screens_golden_test.dart

# Components and widgets
flutter test test/golden/widgets/ar_overlay_golden_test.dart
flutter test test/golden/widgets/navigation_shell_golden_test.dart
flutter test test/golden/widgets/camera_mode_switching_golden_test.dart
flutter test test/golden/widgets/responsive_design_golden_test.dart
```

### Updating Golden Files

When UI changes are intentional, update the golden files:

```bash
# Update all golden files
flutter test test/golden/ --update-goldens

# Update specific test golden files
flutter test test/golden/screens/ar_camera_screen_golden_test.dart --update-goldens
```

## Test Coverage

### Main Screens
- **ARCameraScreen**: ML detection mode, QR scanning mode, light/dark themes, tablet layout, accessibility
- **MapScreen**: Bin locations, proximity highlighting, loading states, light/dark themes, tablet layout
- **ProfileScreen**: User stats, achievements, demo mode, light/dark themes, tablet layout, accessibility
- **LeaderboardScreen**: Rankings, top users, period selection, light/dark themes, tablet layout

### Authentication Screens
- **LoginScreen**: Light/dark themes, loading states, error states
- **SignUpScreen**: Light/dark themes, tablet layout
- **EmailVerificationScreen**: Verification flow, resend confirmation
- **AuthWrapper**: Authentication state handling, loading states

### AR Overlay Components
- **EnhancedObjectOverlay**: Different waste categories, confidence levels, light/dark themes
- **IndicatorWidget**: Category indicators, animations, positioning
- **DisposalCelebrationOverlay**: Success states, achievements, streak multipliers, light/dark themes

### Navigation Components
- **ARNavigationShell**: Tab selection, notification badges, light/dark themes, tablet layout
- **HomeScreen**: Demo mode banner, light/dark themes, tablet layout, accessibility

### Camera Components
- **CameraModeSwitching**: ML detection mode, QR scanning mode, transitions, light/dark themes, tablet layout
- **QRScannerOverlay**: Active scanning, detected codes, error states, light/dark themes

### Responsive Design
- **Phone Layouts**: Portrait (375x812), landscape (812x375), small phones (320x568)
- **Tablet Layouts**: Portrait (768x1024), landscape (1024x768)
- **Material 3 Components**: Buttons, cards, navigation, light/dark themes
- **Accessibility**: Large text (2.0x scale), high contrast, reduced motion

## Device Configurations

The tests cover multiple device sizes and orientations:

- **iPhone SE**: 320x568 (small phone)
- **iPhone 13**: 375x812 (standard phone)
- **iPhone 13 Landscape**: 812x375
- **iPad Portrait**: 768x1024
- **iPad Landscape**: 1024x768

## Accessibility Testing

Golden tests include accessibility configurations:

- **Text Scaling**: 1.3x, 1.5x, 2.0x scale factors
- **Bold Text**: Enhanced text weight for readability
- **High Contrast**: Improved color contrast ratios
- **Reduced Motion**: Disabled animations for motion sensitivity

## Mock Data

The golden tests use mock implementations to ensure consistent, predictable UI states:

- **Mock Providers**: Riverpod providers with controlled state
- **Mock Screens**: Simplified screen implementations for testing
- **Mock Widgets**: AR overlay and component mocks
- **Test Data**: Consistent user profiles, inventory items, and bin locations

## Troubleshooting

### Common Issues

1. **Font Loading Errors**
   ```bash
   # Ensure fonts are loaded in test setup
   await loadAppFonts();
   ```

2. **Golden File Mismatches**
   ```bash
   # Check for unintended UI changes
   flutter test test/golden/ --reporter=expanded
   
   # Update if changes are intentional
   flutter test test/golden/ --update-goldens
   ```

3. **Platform Differences**
   - Golden files are platform-specific
   - Run tests on the same platform used for CI/CD
   - Consider using Docker for consistent environments

### Best Practices

1. **Consistent Environment**: Run golden tests in the same environment as CI/CD
2. **Incremental Updates**: Update golden files only when UI changes are intentional
3. **Review Changes**: Always review golden file diffs before committing
4. **Test Coverage**: Ensure new UI components have corresponding golden tests

## Integration with CI/CD

Add golden tests to your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Run Golden Tests
  run: flutter test test/golden/ --reporter=github
  
- name: Upload Golden Failures
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: golden-failures
    path: test/golden/failures/
```

## Requirements Compliance

This golden test suite fulfills all requirements from task 7:

- ✅ **8.1**: Golden files for all main screens in light and dark themes
- ✅ **8.2**: Visual difference detection for Material 3 theme changes
- ✅ **8.3**: Responsive design verification for phone and tablet layouts
- ✅ **8.4**: AR overlay component visual consistency testing
- ✅ **8.5**: Navigation shell and route transition consistency verification

The tests ensure that any visual changes to the CleanClik app are intentional and maintain consistency across all supported devices and accessibility configurations.