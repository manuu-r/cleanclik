import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/services/business/user_service.dart';

void main() {
  group('UserService', () {
    test('should create user profile correctly', () {
      final profile = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 100,
        level: 2,
        lastActiveAt: DateTime.now(),
      );

      expect(profile.id, equals('test-id'));
      expect(profile.name, equals('Test User'));
      expect(profile.totalPoints, equals(100));
      expect(profile.level, equals(2));
    });

    test('should calculate level correctly based on points', () {
      expect(UserProfile.calculateLevel(0), equals(1));
      expect(UserProfile.calculateLevel(50), equals(1));
      expect(UserProfile.calculateLevel(100), equals(2));
      expect(UserProfile.calculateLevel(500), equals(3));
      expect(UserProfile.calculateLevel(1000), equals(4));
      expect(UserProfile.calculateLevel(2500), equals(5));
      expect(UserProfile.calculateLevel(5000), equals(6));
      expect(UserProfile.calculateLevel(10000), equals(6)); // Max level
    });

    test('should calculate points to next level correctly', () {
      final profile1 = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 50,
        level: 1,
        lastActiveAt: DateTime.now(),
      );
      expect(profile1.pointsToNextLevel, equals(50)); // 100 - 50

      final profile2 = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 300,
        level: 2,
        lastActiveAt: DateTime.now(),
      );
      expect(profile2.pointsToNextLevel, equals(200)); // 500 - 300

      final profile3 = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 5000,
        level: 6,
        lastActiveAt: DateTime.now(),
      );
      expect(profile3.pointsToNextLevel, equals(0)); // Max level reached
    });

    test('should calculate level progress correctly', () {
      final profile1 = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 50,
        level: 1,
        lastActiveAt: DateTime.now(),
      );
      expect(profile1.levelProgress, equals(0.5)); // 50/100

      final profile2 = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 300,
        level: 2,
        lastActiveAt: DateTime.now(),
      );
      expect(
        profile2.levelProgress,
        equals(0.5),
      ); // (300-100)/(500-100) = 200/400 = 0.5

      final profile3 = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 5000,
        level: 6,
        lastActiveAt: DateTime.now(),
      );
      expect(profile3.levelProgress, equals(1.0)); // Max level reached
    });

    test('should serialize and deserialize UserProfile correctly', () {
      final originalProfile = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 150,
        level: 2,
        lastActiveAt: DateTime(2023, 12, 25, 10, 30),
      );

      final json = originalProfile.toJson();
      final deserializedProfile = UserProfile.fromJson(json);

      expect(deserializedProfile.id, equals(originalProfile.id));
      expect(deserializedProfile.name, equals(originalProfile.name));
      expect(
        deserializedProfile.totalPoints,
        equals(originalProfile.totalPoints),
      );
      expect(deserializedProfile.level, equals(originalProfile.level));
      expect(
        deserializedProfile.lastActiveAt,
        equals(originalProfile.lastActiveAt),
      );
    });

    test('should create disposal result correctly', () {
      final successResult = DisposalResult.success(
        pointsEarned: 50,
        disposedItemIds: ['item1', 'item2'],
      );

      expect(successResult.success, isTrue);
      expect(successResult.pointsEarned, equals(50));
      expect(successResult.disposedItemIds, equals(['item1', 'item2']));
      expect(successResult.errorMessage, isNull);

      final failureResult = DisposalResult.failure('Test error');

      expect(failureResult.success, isFalse);
      expect(failureResult.pointsEarned, equals(0));
      expect(failureResult.disposedItemIds, isEmpty);
      expect(failureResult.errorMessage, equals('Test error'));
    });

    test('should define basic achievements correctly', () {
      expect(Achievement.basicAchievements.length, equals(4));

      final firstDisposal = Achievement.basicAchievements.firstWhere(
        (a) => a.id == 'first_disposal',
      );
      expect(firstDisposal.name, equals('First Steps'));
      expect(firstDisposal.pointsRequired, equals(1));

      final ecoWarrior = Achievement.basicAchievements.firstWhere(
        (a) => a.id == 'eco_warrior',
      );
      expect(ecoWarrior.name, equals('Eco Warrior'));
      expect(ecoWarrior.pointsRequired, equals(100));

      final greenChampion = Achievement.basicAchievements.firstWhere(
        (a) => a.id == 'green_champion',
      );
      expect(greenChampion.name, equals('Green Champion'));
      expect(greenChampion.pointsRequired, equals(500));

      final earthGuardian = Achievement.basicAchievements.firstWhere(
        (a) => a.id == 'earth_guardian',
      );
      expect(earthGuardian.name, equals('Earth Guardian'));
      expect(earthGuardian.pointsRequired, equals(1000));
    });

    test('should copy profile with updated fields', () {
      final originalProfile = UserProfile(
        id: 'test-id',
        name: 'Test User',
        email: 'test@example.com',
        totalPoints: 100,
        level: 2,
        lastActiveAt: DateTime(2023, 12, 25),
      );

      final updatedProfile = originalProfile.copyWith(
        totalPoints: 200,
        level: 3,
      );

      expect(updatedProfile.id, equals(originalProfile.id));
      expect(updatedProfile.name, equals(originalProfile.name));
      expect(updatedProfile.totalPoints, equals(200));
      expect(updatedProfile.level, equals(3));
      expect(updatedProfile.lastActiveAt, equals(originalProfile.lastActiveAt));
    });
  });
}
