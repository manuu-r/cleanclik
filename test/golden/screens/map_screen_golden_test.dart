import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_screens.dart';

void main() {
  group('MapScreen Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    testGoldens('MapScreen renders correctly in light theme', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const MapScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          binLocationsProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': 'bin1', 'type': 'recycle', 'lat': 37.7749, 'lng': -122.4194},
            {'id': 'bin2', 'type': 'organic', 'lat': 37.7849, 'lng': -122.4094},
          ])),
          userLocationProvider.overrideWith((ref) => const AsyncValue.data({'lat': 37.7749, 'lng': -122.4194})),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MapScreen),
        matchesGoldenFile('map_screen_light.png'),
      );
    });

    testGoldens('MapScreen renders correctly in dark theme', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const MapScreen(),
        theme: ThemeData.dark(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          binLocationsProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': 'bin1', 'type': 'recycle', 'lat': 37.7749, 'lng': -122.4194},
            {'id': 'bin2', 'type': 'organic', 'lat': 37.7849, 'lng': -122.4094},
          ])),
          userLocationProvider.overrideWith((ref) => const AsyncValue.data({'lat': 37.7749, 'lng': -122.4194})),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MapScreen),
        matchesGoldenFile('map_screen_dark.png'),
      );
    });

    testGoldens('MapScreen with bin proximity highlighting', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const MapScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          binLocationsProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': 'bin1', 'type': 'recycle', 'lat': 37.7749, 'lng': -122.4194, 'isNearby': true},
            {'id': 'bin2', 'type': 'organic', 'lat': 37.7849, 'lng': -122.4094, 'isNearby': false},
          ])),
          userLocationProvider.overrideWith((ref) => const AsyncValue.data({'lat': 37.7749, 'lng': -122.4194})),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MapScreen),
        matchesGoldenFile('map_screen_proximity.png'),
      );
    });

    testGoldens('MapScreen tablet layout', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const MapScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          binLocationsProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': 'bin1', 'type': 'recycle', 'lat': 37.7749, 'lng': -122.4194},
            {'id': 'bin2', 'type': 'organic', 'lat': 37.7849, 'lng': -122.4094},
            {'id': 'bin3', 'type': 'ewaste', 'lat': 37.7649, 'lng': -122.4294},
          ])),
          userLocationProvider.overrideWith((ref) => const AsyncValue.data({'lat': 37.7749, 'lng': -122.4194})),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(1024, 768),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MapScreen),
        matchesGoldenFile('map_screen_tablet.png'),
      );
    });

    testGoldens('MapScreen with loading state', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const MapScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          binLocationsProvider.overrideWith((ref) => const AsyncValue<List<Map<String, dynamic>>>.loading()),
          userLocationProvider.overrideWith((ref) => const AsyncValue<Map<String, dynamic>>.loading()),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pump(); // Don't settle to capture loading state

      await expectLater(
        find.byType(MapScreen),
        matchesGoldenFile('map_screen_loading.png'),
      );
    });
  });
}