import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'screens/ar_camera_screen_golden_test.dart' as ar_camera_tests;
import 'screens/map_screen_golden_test.dart' as map_tests;
import 'screens/profile_screen_golden_test.dart' as profile_tests;
import 'screens/leaderboard_screen_golden_test.dart' as leaderboard_tests;
import 'screens/auth_screens_golden_test.dart' as auth_tests;
import 'widgets/ar_overlay_golden_test.dart' as overlay_tests;
import 'widgets/navigation_shell_golden_test.dart' as navigation_tests;
import 'widgets/camera_mode_switching_golden_test.dart' as camera_mode_tests;
import 'widgets/responsive_design_golden_test.dart' as responsive_tests;

/// Comprehensive golden test runner for CleanClik UI consistency
/// 
/// This test suite covers all requirements from task 7:
/// - Main screens in light and dark themes
/// - AR overlay components and detection indicators
/// - Camera mode switching UI
/// - Responsive design across phone and tablet layouts
/// - Authentication screens and navigation shell
/// - Accessibility features
void main() {
  group('CleanClik Golden Tests - Complete UI Consistency Suite', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    group('Main Screens', () {
      ar_camera_tests.main();
      map_tests.main();
      profile_tests.main();
      leaderboard_tests.main();
    });

    group('Authentication Screens', () {
      auth_tests.main();
    });

    group('AR Overlay Components', () {
      overlay_tests.main();
    });

    group('Navigation Components', () {
      navigation_tests.main();
    });

    group('Camera Mode Switching', () {
      camera_mode_tests.main();
    });

    group('Responsive Design & Accessibility', () {
      responsive_tests.main();
    });
  });
}