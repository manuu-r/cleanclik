import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_screens.dart';

/// Helper function to pump widgets with timeout control
Future<void> pumpWithTimeout(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('Responsive Design Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    group('Phone Layouts', () {
      testGoldens('Phone portrait - ARCameraScreen', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARCameraScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812), // iPhone 13
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ARCameraScreen),
          matchesGoldenFile('phone_portrait_camera.png'),
        );
      });

      testGoldens('Phone landscape - ARCameraScreen', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARCameraScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(812, 375), // iPhone 13 landscape
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ARCameraScreen),
          matchesGoldenFile('phone_landscape_camera.png'),
        );
      });

      testGoldens('Small phone - ProfileScreen', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ProfileScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            userProfileProvider.overrideWith((ref) => const AsyncValue.data({
              'id': '1',
              'username': 'TestUser',
              'email': 'test@example.com',
            })),
            userStatsProvider.overrideWith((ref) => const AsyncValue.data({
              'totalPoints': 1250,
              'level': 5,
              'itemsRecycled': 42,
            })),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(320, 568), // iPhone SE
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ProfileScreen),
          matchesGoldenFile('small_phone_profile.png'),
        );
      });
    });

    group('Tablet Layouts', () {
      testGoldens('Tablet portrait - ARCameraScreen', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARCameraScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(768, 1024), // iPad portrait
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ARCameraScreen),
          matchesGoldenFile('tablet_portrait_camera.png'),
        );
      });

      testGoldens('Tablet landscape - ARCameraScreen', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARCameraScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(1024, 768), // iPad landscape
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ARCameraScreen),
          matchesGoldenFile('tablet_landscape_camera.png'),
        );
      });

      testGoldens('Tablet - Navigation Shell', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARNavigationShell(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            currentNavigationIndexProvider.overrideWith((ref) => 1), // Map tab
            binLocationsProvider.overrideWith((ref) => const AsyncValue.data([
              {'id': 'bin1', 'type': 'recycle', 'lat': 37.7749, 'lng': -122.4194},
            ])),
            userLocationProvider.overrideWith((ref) => const AsyncValue.data({'lat': 37.7749, 'lng': -122.4194})),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(1024, 768),
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('tablet_navigation_shell.png'),
        );
      });
    });

    group('Material 3 Components', () {
      testGoldens('Material 3 buttons and cards - light theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Material 3 Cards
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Material 3 Card'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Material 3 Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Elevated'),
                      ),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Filled'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Outlined'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Material 3 FAB
                  FloatingActionButton.extended(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('material3_components_light.png'),
        );
      });

      testGoldens('Material 3 buttons and cards - dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Material 3 Card'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Elevated'),
                      ),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Filled'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Outlined'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.extended(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan'),
                  ),
                ],
              ),
            ),
          ),
          theme: ThemeData.dark(),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('material3_components_dark.png'),
        );
      });
    });

    group('Accessibility Features', () {
      testGoldens('Large text accessibility', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ProfileScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            userProfileProvider.overrideWith((ref) => const AsyncValue.data({
              'id': '1',
              'username': 'TestUser',
              'email': 'test@example.com',
            })),
            userStatsProvider.overrideWith((ref) => const AsyncValue.data({
              'totalPoints': 1250,
              'level': 5,
              'itemsRecycled': 42,
            })),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
          wrapper: (child) => MediaQuery(
            data: const MediaQueryData(
              textScaleFactor: 2.0, // Extra large text
            ),
            child: child,
          ),
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ProfileScreen),
          matchesGoldenFile('accessibility_large_text.png'),
        );
      });

      testGoldens('High contrast accessibility', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARNavigationShell(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            currentNavigationIndexProvider.overrideWith((ref) => 0),
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
          wrapper: (child) => MediaQuery(
            data: const MediaQueryData(
              highContrast: true,
              boldText: true,
            ),
            child: child,
          ),
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('accessibility_high_contrast.png'),
        );
      });

      testGoldens('Reduced motion accessibility', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARCameraScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
          wrapper: (child) => MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true, // Reduced motion
            ),
            child: child,
          ),
        );
        await pumpWithTimeout(tester);

        await expectLater(
          find.byType(ARCameraScreen),
          matchesGoldenFile('accessibility_reduced_motion.png'),
        );
      });
    });
  });
}