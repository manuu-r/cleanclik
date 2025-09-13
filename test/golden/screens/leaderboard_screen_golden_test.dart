import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_screens.dart';

void main() {
  group('LeaderboardScreen Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    testGoldens('LeaderboardScreen renders correctly in light theme', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const LeaderboardScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          leaderboardProvider.overrideWith((ref) => const AsyncValue.data([
            {'username': 'EcoChampion', 'points': 5000, 'rank': 1},
            {'username': 'GreenWarrior', 'points': 4500, 'rank': 2},
            {'username': 'RecycleKing', 'points': 4000, 'rank': 3},
            {'username': 'EcoFriendly', 'points': 3500, 'rank': 4},
            {'username': 'testuser', 'points': 1250, 'rank': 15},
          ])),
          userRankProvider.overrideWith((ref) => const AsyncValue.data(15)),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LeaderboardScreen),
        matchesGoldenFile('leaderboard_screen_light.png'),
      );
    });

    testGoldens('LeaderboardScreen renders correctly in dark theme', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const LeaderboardScreen(),
        theme: ThemeData.dark(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          leaderboardProvider.overrideWith((ref) => const AsyncValue.data([
            {'username': 'EcoChampion', 'points': 5000, 'rank': 1},
            {'username': 'GreenWarrior', 'points': 4500, 'rank': 2},
            {'username': 'RecycleKing', 'points': 4000, 'rank': 3},
          ])),
          userRankProvider.overrideWith((ref) => const AsyncValue.data(15)),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LeaderboardScreen),
        matchesGoldenFile('leaderboard_screen_dark.png'),
      );
    });

    testGoldens('LeaderboardScreen with user in top 3', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const LeaderboardScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          leaderboardProvider.overrideWith((ref) => const AsyncValue.data([
            {'username': 'EcoChampion', 'points': 5000, 'rank': 1},
            {'username': 'testuser', 'points': 4500, 'rank': 2},
            {'username': 'RecycleKing', 'points': 4000, 'rank': 3},
          ])),
          userRankProvider.overrideWith((ref) => const AsyncValue.data(2)),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LeaderboardScreen),
        matchesGoldenFile('leaderboard_screen_top_rank.png'),
      );
    });

    testGoldens('LeaderboardScreen tablet layout', (tester) async {
      await loadAppFonts();
      
      final widget = baseTest.createTestWidget(
        const LeaderboardScreen(),
        overrides: [
          authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_in', 'user': {'id': '1', 'username': 'testuser'}})),
          leaderboardProvider.overrideWith((ref) => const AsyncValue.data([
            {'username': 'EcoChampion', 'points': 5000, 'rank': 1},
            {'username': 'GreenWarrior', 'points': 4500, 'rank': 2},
            {'username': 'RecycleKing', 'points': 4000, 'rank': 3},
            {'username': 'EcoFriendly', 'points': 3500, 'rank': 4},
            {'username': 'GreenThumb', 'points': 3000, 'rank': 5},
          ])),
          userRankProvider.overrideWith((ref) => const AsyncValue.data(8)),
        ],
      );

      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(1024, 768),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LeaderboardScreen),
        matchesGoldenFile('leaderboard_screen_tablet.png'),
      );
    });
  });
}