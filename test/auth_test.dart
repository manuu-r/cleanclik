import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/models/user_models.dart';
import 'package:cleanclik/core/models/system_models.dart';
import 'fixtures/test_data_factory.dart';

void main() {
  group('Authentication System Tests', () {
    group('User Model', () {
      test('should create mock user correctly', () {
        final user = TestDataFactory.createMockUser();

        expect(user.id, isNotEmpty);
        expect(user.username, isNotEmpty);
        expect(user.email, isNotEmpty);
        expect(user.totalPoints, greaterThanOrEqualTo(0));
        expect(user.level, greaterThanOrEqualTo(1));
        expect(user.achievements, isA<List<String>>());
        expect(user.categoryStats, isA<Map<String, int>>());
        expect(user.isOnline, isA<bool>());
      });

      test('should calculate level correctly based on points', () {
        expect(User.calculateLevel(50), 1);
        expect(User.calculateLevel(150), 2);
        expect(User.calculateLevel(750), 3);
        expect(User.calculateLevel(1500), 4);
        expect(User.calculateLevel(3000), 5);
        expect(User.calculateLevel(6000), 6);
      });

      test('should calculate points to next level correctly', () {
        final user = TestDataFactory.createMockUser().copyWith(
          totalPoints: 150,
          level: User.calculateLevel(150),
        );
        final pointsToNext = user.pointsToNextLevel;
        expect(pointsToNext, 350); // 500 - 150 = 350
      });

      test('should calculate level progress correctly', () {
        final user = TestDataFactory.createMockUser().copyWith(
          totalPoints: 250,
          level: User.calculateLevel(250),
        ); // Level 2
        final progress = user.levelProgress;
        expect(progress, closeTo(0.375, 0.001)); // 150/400 = 0.375
      });

      test('should calculate total items collected', () {
        final user = TestDataFactory.createMockUser();
        final totalItems = user.totalItemsCollected;
        expect(totalItems, greaterThanOrEqualTo(0));
      });

      test('should copy with updated fields correctly', () {
        final user = TestDataFactory.createMockUser();
        final updatedUser = user.copyWith(
          username: 'NewName',
          totalPoints: 2000,
          level: 4,
        );

        expect(updatedUser.username, 'NewName');
        expect(updatedUser.totalPoints, 2000);
        expect(updatedUser.level, 4);
        expect(updatedUser.id, user.id); // Should remain the same
        expect(updatedUser.email, user.email); // Should remain the same
      });

      test('should serialize to and from JSON correctly', () {
        final user = TestDataFactory.createMockUser();
        final json = user.toJson();
        final reconstructedUser = User.fromJson(json);

        expect(reconstructedUser.id, user.id);
        expect(reconstructedUser.username, user.username);
        expect(reconstructedUser.email, user.email);
        expect(reconstructedUser.totalPoints, user.totalPoints);
        expect(reconstructedUser.level, user.level);
        expect(reconstructedUser.isOnline, user.isOnline);
      });

      test('should serialize to and from Supabase format correctly', () {
        final user = TestDataFactory.createMockUser();
        final supabaseData = user.toSupabase();

        expect(supabaseData['id'], user.id);
        expect(supabaseData['auth_id'], user.authId);
        expect(supabaseData['username'], user.username);
        expect(supabaseData['email'], user.email);
        expect(supabaseData['total_points'], user.totalPoints);
        expect(supabaseData['level'], user.level);
        expect(supabaseData['is_online'], user.isOnline);

        // Test reconstruction (without categoryStats and achievements for simplicity)
        final reconstructedUser = User.fromSupabase(supabaseData);
        expect(reconstructedUser.id, user.id);
        expect(reconstructedUser.username, user.username);
        expect(reconstructedUser.email, user.email);
      });

      test('should handle equality correctly', () {
        final user1 = TestDataFactory.createMockUser();
        final user2 = TestDataFactory.createMockUser(id: user1.id); // Same ID
        final user3 = user1.copyWith(username: 'DifferentName');

        expect(user1 == user2, true); // Same ID
        expect(user1 == user3, true); // Same ID, different data
        expect(user1.hashCode, user2.hashCode);
      });
    });

    group('AuthResult', () {
      test('should create success result correctly', () {
        final user = TestDataFactory.createMockUser();
        final result = AuthResult.success(user);

        expect(result.isSuccess, true);
        expect(result.data, user);
        expect(result.error, isNull);
      });

      test('should create failure result correctly', () {
        const errorMessage = 'Authentication failed';
        final authException = AuthException(
          AuthErrorType.invalidCredentials,
          errorMessage,
        );
        final result = AuthResult<User>.failure(authException);

        expect(result.isSuccess, false);
        expect(result.data, isNull);
        expect(result.error?.message, errorMessage);
      });

      test('should create failure result with exception correctly', () {
        const errorMessage = 'Authentication failed';
        final authException = AuthException(
          AuthErrorType.unknown,
          errorMessage,
        );
        final result = AuthResult<User>.failure(authException);

        expect(result.isSuccess, false);
        expect(result.data, isNull);
        expect(result.error?.message, errorMessage);
      });
    });

    group('Level Calculation Logic', () {
      test('should have correct level thresholds', () {
        final testCases = [
          {'points': 0, 'expectedLevel': 1},
          {'points': 99, 'expectedLevel': 1},
          {'points': 100, 'expectedLevel': 2},
          {'points': 499, 'expectedLevel': 2},
          {'points': 500, 'expectedLevel': 3},
          {'points': 999, 'expectedLevel': 3},
          {'points': 1000, 'expectedLevel': 4},
          {'points': 2499, 'expectedLevel': 4},
          {'points': 2500, 'expectedLevel': 5},
          {'points': 4999, 'expectedLevel': 5},
          {'points': 5000, 'expectedLevel': 6},
          {'points': 10000, 'expectedLevel': 6},
        ];

        for (final testCase in testCases) {
          final points = testCase['points'] as int;
          final expectedLevel = testCase['expectedLevel'] as int;
          final actualLevel = User.calculateLevel(points);
          expect(
            actualLevel,
            expectedLevel,
            reason:
                'Points $points should be level $expectedLevel but got $actualLevel',
          );
        }
      });

      test('should calculate progress within level correctly', () {
        // Test user at level 3 (500-999 points range)
        final user = TestDataFactory.createMockUser().copyWith(
          totalPoints: 750,
          level: User.calculateLevel(750),
        );

        expect(user.level, 3);
        expect(user.levelProgress, closeTo(0.5, 0.001)); // 250/500 = 0.5
        expect(user.pointsToNextLevel, 250); // 1000 - 750 = 250
      });

      test('should handle edge cases for level progress', () {
        // Test at exact level boundary
        final userAtBoundary = TestDataFactory.createMockUser().copyWith(
          totalPoints: 1000,
          level: User.calculateLevel(1000),
        );
        expect(userAtBoundary.level, 4);
        expect(userAtBoundary.levelProgress, 0.0);
        expect(userAtBoundary.pointsToNextLevel, 1500); // 2500 - 1000 = 1500

        // Test at max level
        final maxLevelUser = TestDataFactory.createMockUser().copyWith(
          totalPoints: 10000,
          level: User.calculateLevel(10000),
        );
        expect(maxLevelUser.level, 6);
      });
    });

    group('User Data Validation', () {
      test('should handle empty category stats', () {
        final user = TestDataFactory.createMockUser().copyWith(
          categoryStats: {},
        );
        expect(user.totalItemsCollected, 0);
        expect(user.categoryStats.isEmpty, true);
      });

      test('should handle empty achievements', () {
        final user = TestDataFactory.createMockUser().copyWith(
          achievements: [],
        );
        expect(user.achievements.isEmpty, true);
      });

      test('should handle null/empty avatar URL', () {
        final user1 = TestDataFactory.createMockUser().copyWith(
          avatarUrl: null,
        );
        final user2 = TestDataFactory.createMockUser().copyWith(avatarUrl: '');

        expect(user1.avatarUrl, isNull);
        expect(user2.avatarUrl, '');
      });

      test('should maintain data integrity during updates', () {
        final originalUser = TestDataFactory.createMockUser();
        final originalPoints = originalUser.totalPoints;
        final originalLevel = originalUser.level;

        final updatedUser = originalUser.copyWith(
          totalPoints: 3000,
          level: User.calculateLevel(3000),
          lastActiveAt: DateTime.now(),
        );

        // Verify original user unchanged
        expect(originalUser.totalPoints, originalPoints);
        expect(originalUser.level, originalLevel);

        // Verify updated user has new values
        expect(updatedUser.totalPoints, 3000);
        expect(updatedUser.level, 5);
        expect(updatedUser.id, originalUser.id); // ID should remain same
      });
    });

    group('DateTime Handling', () {
      test('should handle date serialization correctly', () {
        final now = DateTime.now();
        final user = TestDataFactory.createMockUser().copyWith(
          createdAt: now,
          lastActiveAt: now,
        );

        final json = user.toJson();
        final reconstructed = User.fromJson(json);

        expect(
          reconstructed.createdAt.millisecondsSinceEpoch,
          closeTo(now.millisecondsSinceEpoch, 1000),
        );
        expect(
          reconstructed.lastActiveAt.millisecondsSinceEpoch,
          closeTo(now.millisecondsSinceEpoch, 1000),
        );
      });
    });

    group('Business Logic', () {
      test('should maintain consistent state during profile updates', () {
        final user = TestDataFactory.createMockUser();

        // Simulate adding points
        final pointsToAdd = 500;
        final newTotalPoints = user.totalPoints + pointsToAdd;
        final newLevel = User.calculateLevel(newTotalPoints);

        final updatedUser = user.copyWith(
          totalPoints: newTotalPoints,
          level: newLevel,
          lastActiveAt: DateTime.now(),
        );

        expect(updatedUser.totalPoints, user.totalPoints + pointsToAdd);
        expect(updatedUser.level, newLevel);
        expect(updatedUser.lastActiveAt.isAfter(user.lastActiveAt), true);
      });

      test('should handle achievement additions correctly', () {
        final user = TestDataFactory.createMockUser();
        final existingAchievements = user.achievements.toList();
        const newAchievement = 'eco_master';

        // Simulate adding achievement
        final updatedAchievements = [...existingAchievements, newAchievement];
        final updatedUser = user.copyWith(achievements: updatedAchievements);

        expect(
          updatedUser.achievements.length,
          existingAchievements.length + 1,
        );
        expect(updatedUser.achievements.contains(newAchievement), true);
        // Check that original achievements are preserved
        for (final achievement in existingAchievements) {
          expect(updatedUser.achievements.contains(achievement), true);
        }
      });
    });
  });
}
