import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_screens.dart';

void main() {
  group('ARCameraScreen Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    testGoldens('ARCameraScreen renders correctly in light theme', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ARCameraScreen(),
        overrides: [
          cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          detectedObjectsProvider.overrideWith((ref) => [{'category': 'recycle', 'confidence': 0.95}]),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812), // iPhone 13 size
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ARCameraScreen),
        matchesGoldenFile('ar_camera_screen_light.png'),
      );
    });

    testGoldens('ARCameraScreen renders correctly in dark theme', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ARCameraScreen(),
        theme: ThemeData.dark(),
        overrides: [
          cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          detectedObjectsProvider.overrideWith((ref) => [{'category': 'recycle', 'confidence': 0.95}]),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ARCameraScreen),
        matchesGoldenFile('ar_camera_screen_dark.png'),
      );
    });

    testGoldens('ARCameraScreen QR scanning mode', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ARCameraScreen(),
        overrides: [
          cameraStateProvider.overrideWith((ref) => {'mode': 'qr_scanning', 'status': 'active'}),
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ARCameraScreen),
        matchesGoldenFile('ar_camera_screen_qr_mode.png'),
      );
    });

    testGoldens('ARCameraScreen tablet layout', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ARCameraScreen(),
        overrides: [
          cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          detectedObjectsProvider.overrideWith((ref) => [{'category': 'organic', 'confidence': 0.87}]),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(1024, 768), // iPad size
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ARCameraScreen),
        matchesGoldenFile('ar_camera_screen_tablet.png'),
      );
    });

    testGoldens('ARCameraScreen with accessibility features', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ARCameraScreen(),
        overrides: [
          cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          detectedObjectsProvider.overrideWith((ref) => [{'category': 'ewaste', 'confidence': 0.92}]),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
        wrapper: (child) => MediaQuery(
          data: const MediaQueryData(
            textScaleFactor: 1.5, // Large text accessibility
            boldText: true,
          ),
          child: child,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ARCameraScreen),
        matchesGoldenFile('ar_camera_screen_accessibility.png'),
      );
    });
  });
}