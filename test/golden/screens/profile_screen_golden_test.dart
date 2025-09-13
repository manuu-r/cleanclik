import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_screens.dart';

void main() {
  group('ProfileScreen Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    testGoldens('ProfileScreen renders correctly in light theme', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ProfileScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          userProfileProvider.overrideWith((ref) => const AsyncValue.data({
            'id': '1',
            'username': 'EcoWarrior',
            'email': 'eco@example.com',
            'avatarUrl': null,
          })),
          userInventoryProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': '1', 'category': 'recycle', 'points': 50},
            {'id': '2', 'category': 'organic', 'points': 30},
          ])),
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
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_light.png'),
      );
    });

    testGoldens('ProfileScreen renders correctly in dark theme', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ProfileScreen(),
        theme: ThemeData.dark(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          userProfileProvider.overrideWith((ref) => const AsyncValue.data({
            'id': '1',
            'username': 'EcoWarrior',
            'email': 'eco@example.com',
            'avatarUrl': null,
          })),
          userInventoryProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': '1', 'category': 'recycle', 'points': 50},
            {'id': '2', 'category': 'organic', 'points': 30},
          ])),
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
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_dark.png'),
      );
    });

    testGoldens('ProfileScreen with achievements and badges', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ProfileScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          userProfileProvider.overrideWith((ref) => const AsyncValue.data({
            'id': '1',
            'username': 'EcoMaster',
            'email': 'ecomaster@example.com',
            'avatarUrl': null,
          })),
          userInventoryProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': '1', 'category': 'recycle', 'points': 50},
            {'id': '2', 'category': 'organic', 'points': 30},
            {'id': '3', 'category': 'ewaste', 'points': 100},
          ])),
          userStatsProvider.overrideWith((ref) => const AsyncValue.data({
            'totalPoints': 5000,
            'level': 12,
            'itemsRecycled': 150,
          })),
          userAchievementsProvider.overrideWith((ref) => const AsyncValue.data([
            'First Recycler',
            'Eco Warrior',
            'Organic Expert',
            'E-waste Champion',
          ])),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_achievements.png'),
      );
    });

    testGoldens('ProfileScreen tablet layout', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ProfileScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          userProfileProvider.overrideWith((ref) => const AsyncValue.data({
            'id': '1',
            'username': 'EcoWarrior',
            'email': 'eco@example.com',
            'avatarUrl': null,
          })),
          userInventoryProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': '1', 'category': 'recycle', 'points': 50},
          ])),
          userStatsProvider.overrideWith((ref) => const AsyncValue.data({
            'totalPoints': 1250,
            'level': 5,
            'itemsRecycled': 42,
          })),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(1024, 768),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_tablet.png'),
      );
    });

    testGoldens('ProfileScreen with accessibility features', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const ProfileScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          userProfileProvider.overrideWith((ref) => const AsyncValue.data({
            'id': '1',
            'username': 'EcoWarrior',
            'email': 'eco@example.com',
            'avatarUrl': null,
          })),
          userInventoryProvider.overrideWith((ref) => const AsyncValue.data([
            {'id': '1', 'category': 'recycle', 'points': 50},
          ])),
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
            textScaleFactor: 1.3,
            boldText: true,
            highContrast: true,
          ),
          child: child,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_accessibility.png'),
      );
    });
  });
}