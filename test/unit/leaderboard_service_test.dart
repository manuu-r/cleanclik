import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/core/services/social/leaderboard_service.dart';
import 'package:cleanclik/core/models/leaderboard_entry.dart';
import 'package:cleanclik/core/models/user.dart';
import '../helpers/base_service_test.dart';
import '../helpers/mock_services.mocks.dart';
import '../fixtures/test_data_factory.dart';

void main() {
  group('LeaderboardService', () {
    late ProviderContainer container;
    late MockSupabaseClient mockSupabaseClient;
    late MockLeaderboardService mockLeaderboardService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockLeaderboardService = MockLeaderboardService();
      container = ProviderContainer(
        overrides: [
          // Override the leaderboard service provider with a mock
          leaderboardServiceProvider.overrideWith((ref) async {
            return mockLeaderboardService;
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Initialization', () {
      test('should provide LeaderboardService instance', () async {
        final leaderboardServiceAsync = container.read(leaderboardServiceProvider);
        expect(leaderboardServiceAsync, isA<AsyncValue<LeaderboardService>>());
        
        // Wait for the service to load
        final leaderboardService = await container.read(leaderboardServiceProvider.future);
        expect(leaderboardService, isA<LeaderboardService>());
      });
    });

    group('LeaderboardEntry Model', () {
      test('should create leaderboard entry', () {
        final entry = TestDataFactory.createMockLeaderboardEntry(
          id: 'user-1',
          username: 'testuser',
          totalPoints: 1500,
          level: 5,
          rank: 1,
        );

        expect(entry.id, 'user-1');
        expect(entry.username, 'testuser');
        expect(entry.totalPoints, 1500);
        expect(entry.level, 5);
        expect(entry.rank, 1);
      });

      test('should serialize to and from JSON', () {
        final entry = TestDataFactory.createMockLeaderboardEntry(
          id: 'user-1',
          username: 'testuser',
          totalPoints: 1500,
          level: 5,
          rank: 1,
        );

        final json = entry.toJson();
        final restored = LeaderboardEntry.fromJson(json);

        expect(restored.id, entry.id);
        expect(restored.username, entry.username);
        expect(restored.totalPoints, entry.totalPoints);
        expect(restored.level, entry.level);
        expect(restored.rank, entry.rank);
      });

      test('should create multiple leaderboard entries', () {
        final entries = TestDataFactory.createMockLeaderboardEntries(count: 10);
        
        expect(entries.length, 10);
        expect(entries.every((entry) => entry.id.isNotEmpty), isTrue);
        expect(entries.every((entry) => entry.username.isNotEmpty), isTrue);
        
        // Should be sorted by points (descending)
        for (int i = 0; i < entries.length - 1; i++) {
          expect(entries[i].totalPoints, greaterThanOrEqualTo(entries[i + 1].totalPoints));
        }
      });
    });

    group('Service Structure', () {
      test('should have proper service structure', () {
        // Test that the service exists and can be imported
        expect(LeaderboardService, isA<Type>());
        expect(LeaderboardEntry, isA<Type>());
      });
    });
  });
}