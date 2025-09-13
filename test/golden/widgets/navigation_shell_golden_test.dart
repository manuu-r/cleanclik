import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_screens.dart';

void main() {
  group('Navigation Shell Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    group('ARNavigationShell', () {
      testGoldens('ARNavigationShell renders correctly in light theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARNavigationShell(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            currentNavigationIndexProvider.overrideWith((ref) => 0), // Camera tab
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('ar_navigation_shell_light.png'),
        );
      });

      testGoldens('ARNavigationShell renders correctly in dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARNavigationShell(),
          theme: ThemeData.dark(),
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
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('ar_navigation_shell_dark.png'),
        );
      });

      testGoldens('ARNavigationShell with map tab selected', (tester) async {
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
          surfaceSize: const Size(375, 812),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('ar_navigation_shell_map_selected.png'),
        );
      });

      testGoldens('ARNavigationShell with profile tab selected', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARNavigationShell(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            currentNavigationIndexProvider.overrideWith((ref) => 2), // Profile tab
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
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('ar_navigation_shell_profile_selected.png'),
        );
      });

      testGoldens('ARNavigationShell with leaderboard tab selected', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARNavigationShell(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            currentNavigationIndexProvider.overrideWith((ref) => 3), // Leaderboard tab
            leaderboardProvider.overrideWith((ref) => const AsyncValue.data([
              {'username': 'EcoChampion', 'points': 5000, 'rank': 1},
              {'username': 'GreenWarrior', 'points': 4500, 'rank': 2},
            ])),
            userRankProvider.overrideWith((ref) => const AsyncValue.data(15)),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('ar_navigation_shell_leaderboard_selected.png'),
        );
      });

      testGoldens('ARNavigationShell tablet layout', (tester) async {
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
          surfaceSize: const Size(1024, 768),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('ar_navigation_shell_tablet.png'),
        );
      });

      testGoldens('ARNavigationShell with notification badge', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const ARNavigationShell(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            currentNavigationIndexProvider.overrideWith((ref) => 0),
            notificationBadgeProvider.overrideWith((ref) => 3), // 3 unread notifications
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(ARNavigationShell),
          matchesGoldenFile('ar_navigation_shell_notification_badge.png'),
        );
      });
    });

    group('HomeScreen', () {
      testGoldens('HomeScreen renders correctly in light theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const HomeScreen(),
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
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(HomeScreen),
          matchesGoldenFile('home_screen_light.png'),
        );
      });

      testGoldens('HomeScreen renders correctly in dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const HomeScreen(),
          theme: ThemeData.dark(),
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
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(HomeScreen),
          matchesGoldenFile('home_screen_dark.png'),
        );
      });

      testGoldens('HomeScreen with demo mode banner', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const HomeScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'demouser'}, 'isDemoMode': true})),
            currentNavigationIndexProvider.overrideWith((ref) => 0),
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(HomeScreen),
          matchesGoldenFile('home_screen_demo_mode.png'),
        );
      });

      testGoldens('HomeScreen tablet layout', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const HomeScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
            currentNavigationIndexProvider.overrideWith((ref) => 0),
            cameraStateProvider.overrideWith((ref) => {'mode': 'ml_detection', 'status': 'active'}),
            detectedObjectsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(1024, 768),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(HomeScreen),
          matchesGoldenFile('home_screen_tablet.png'),
        );
      });

      testGoldens('HomeScreen with accessibility features', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const HomeScreen(),
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
              textScaleFactor: 1.4,
              boldText: true,
              highContrast: true,
            ),
            child: child,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(HomeScreen),
          matchesGoldenFile('home_screen_accessibility.png'),
        );
      });
    });
  });
}