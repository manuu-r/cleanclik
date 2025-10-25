import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/services/business/user_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/models/camera_models.dart';

void main() {
  group('UserService and InventoryService Integration', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should integrate disposal with points awarding', () async {
      // Get services
      final userService = container.read(userServiceProvider);
      final inventoryService = container.read(inventoryServiceProvider);

      // Create a test user profile
      await userService.createProfile('test-user-id', 'Test User', 'test@example.com');

      // Verify initial state
      expect(userService.currentProfile?.totalPoints, equals(0));
      expect(userService.currentProfile?.level, equals(1));

      // Add a test item to inventory
      final testDetectedObject = DetectedObject(
        trackingId: 'test-tracking-1',
        category: 'recycle',
        codeName: 'plastic bottle',
        confidence: 0.9,
        boundingBox: const Rect.fromLTWH(0.1, 0.1, 0.2, 0.2),
        detectedAt: DateTime.now(),
        overlayColor: Colors.green,
        id: 'test-object-1',
      );

      await inventoryService.addItemFromDetectedObject(testDetectedObject);

      // Verify item was added
      expect(inventoryService.inventory.length, equals(1));
      expect(inventoryService.inventory.first.category, equals('recycle'));

      // Dispose the item (this should award points via UserService integration)
      final disposalResult = await inventoryService.disposeItems([
        inventoryService.inventory.first.id,
      ]);

      // Verify disposal was successful
      expect(disposalResult.success, isTrue);
      expect(
        disposalResult.pointsEarned,
        equals(10),
      ); // recycle category = 10 points

      // Verify inventory is now empty
      expect(inventoryService.inventory.length, equals(0));

      // Verify points were awarded to user
      expect(userService.currentProfile?.totalPoints, equals(10));
      expect(
        userService.currentProfile?.level,
        equals(1),
      ); // Still level 1 (needs 100 points for level 2)

      // Check achievements
      final achievements = await userService.checkAchievements(disposalResult);
      expect(achievements.length, equals(1));
      expect(achievements.first.id, equals('first_disposal'));
    });

    test('should handle multiple disposals and level progression', () async {
      // Get services
      final userService = container.read(userServiceProvider);
      final inventoryService = container.read(inventoryServiceProvider);

      // Create a test user profile
      await userService.createProfile('test-user-id-2', 'Test User 2', 'test2@example.com');

      // Add multiple high-value items (hazardous = 20 points each)
      for (int i = 0; i < 6; i++) {
        final testDetectedObject = DetectedObject(
          trackingId: 'test-tracking-$i',
          category: 'hazardous',
          codeName: 'battery',
          confidence: 0.9,
          boundingBox: const Rect.fromLTWH(0.1, 0.1, 0.2, 0.2),
          detectedAt: DateTime.now(),
          overlayColor: Colors.red,
          id: 'test-object-$i',
        );

        await inventoryService.addItemFromDetectedObject(testDetectedObject);
      }

      // Verify items were added
      expect(inventoryService.inventory.length, equals(6));

      // Dispose all items at once
      final itemIds = inventoryService.inventory
          .map((item) => item.id)
          .toList();
      final disposalResult = await inventoryService.disposeItems(itemIds);

      // Verify disposal was successful
      expect(disposalResult.success, isTrue);
      expect(disposalResult.pointsEarned, equals(120)); // 6 * 20 points

      // Verify inventory is now empty
      expect(inventoryService.inventory.length, equals(0));

      // Verify points were awarded and level increased
      expect(userService.currentProfile?.totalPoints, equals(120));
      expect(
        userService.currentProfile?.level,
        equals(2),
      ); // Should be level 2 (100+ points)

      // Check achievements
      final achievements = await userService.checkAchievements(disposalResult);
      expect(
        achievements.length,
        greaterThanOrEqualTo(2),
      ); // first_disposal + eco_warrior
    });

    test('should handle disposal failure gracefully', () async {
      // Get services
      final userService = container.read(userServiceProvider);
      final inventoryService = container.read(inventoryServiceProvider);

      // Create a test user profile
      await userService.createProfile('test-user-id-3', 'Test User 3', 'test3@example.com');

      // Try to dispose non-existent items
      final disposalResult = await inventoryService.disposeItems([
        'non-existent-id',
      ]);

      // Verify disposal failed
      expect(disposalResult.success, isFalse);
      expect(disposalResult.pointsEarned, equals(0));
      expect(
        disposalResult.errorMessage,
        contains('No items found to dispose'),
      );

      // Verify user points remain unchanged
      expect(userService.currentProfile?.totalPoints, equals(0));
      expect(userService.currentProfile?.level, equals(1));
    });
  });
}
