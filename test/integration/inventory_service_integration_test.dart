import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/data/data_service.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';
import '../helpers/base_integration_test.dart';
import '../fixtures/test_data_factory.dart';
import '../test_environment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('InventoryService Integration Tests', () {
    late ProviderContainer container;
    late String testUserId;

    setUpAll(() async {
      await TestEnvironment.initialize();
      testUserId =
          'inventory_integration_test_${DateTime.now().millisecondsSinceEpoch}';
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('DataService Integration', () {
      testWidgets(
        'should integrate with DataService for inventory operations',
        (tester) async {
          final inventoryService = container.read(inventoryServiceProvider);

          // Ensure service is loaded
          await inventoryService.ensureLoaded();

          // Test initial state
          expect(inventoryService.inventory, isEmpty);
          expect(inventoryService.totalPoints, 0);
          expect(inventoryService.isEmpty, true);

          // Create test inventory item
          final testItem = InventoryItem(
            id: 'integration-test-item',
            trackingId: 'integration-tracking',
            category: 'recycle',
            displayName: 'Integration Test Item',
            codeName: 'INTEGRATION_ITEM',
            confidence: 0.9,
            pickedUpAt: DateTime.now(),
          );

          // Add item to inventory
          final addResult = await inventoryService.addItem(testItem);
          expect(addResult, true);
          expect(inventoryService.inventory.length, 1);
          expect(inventoryService.hasItems, true);

          // Test inventory analysis methods
          final recycleItems = inventoryService.getItemsByCategory('recycle');
          expect(recycleItems.length, 1);

          final categoryCounts = inventoryService.categoryCounts;
          expect(categoryCounts['recycle'], 1);

          final inventoryValue = inventoryService.calculateInventoryValue();
          expect(inventoryValue, 10); // Recycle items are worth 10 points

          // Test inventory methods
          final inventoryItems = inventoryService.inventory;
          expect(inventoryItems.length, 1);
          expect(inventoryItems.first.category, 'recycle');

          final wasteCategories = inventoryService
              .getInventoryWasteCategories();
          expect(wasteCategories, contains(WasteCategory.recycle));

          // Test item removal
          await inventoryService.removeItem(testItem.id);
          expect(inventoryService.inventory, isEmpty);
          expect(inventoryService.sessionStats.totalItemsDisposed, 1);
        },
      );

      testWidgets('should handle DetectedObject integration', (tester) async {
        final inventoryService = container.read(inventoryServiceProvider);
        await inventoryService.ensureLoaded();

        // Create DetectedObject from test factory
        final detectedObject = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.organic,
          confidence: 0.85,
          codeName: 'BANANA_PEEL',
        );

        // Add item from DetectedObject
        final result = await inventoryService.addItemFromDetectedObject(
          detectedObject,
        );
        expect(result, true);
        expect(inventoryService.inventory.length, 1);

        final addedItem = inventoryService.inventory.first;
        expect(addedItem.category, WasteCategory.organic.id);
        expect(addedItem.confidence, 0.85);
        expect(addedItem.codeName, 'BANANA_PEEL');
        expect(addedItem.trackingId, detectedObject.trackingId);
      });

      testWidgets('should handle points calculation and disposal', (
        tester,
      ) async {
        final inventoryService = container.read(inventoryServiceProvider);
        await inventoryService.ensureLoaded();

        // Create diverse items for bonus calculation
        final items = [
          InventoryItem(
            id: 'recycle-item',
            trackingId: 'recycle-tracking',
            category: 'recycle',
            displayName: 'Plastic Bottle',
            codeName: 'PLASTIC_BOTTLE',
            confidence: 0.9,
            pickedUpAt: DateTime.now(),
          ),
          InventoryItem(
            id: 'organic-item',
            trackingId: 'organic-tracking',
            category: 'organic',
            displayName: 'Apple Core',
            codeName: 'APPLE_CORE',
            confidence: 0.95,
            pickedUpAt: DateTime.now(),
          ),
          InventoryItem(
            id: 'ewaste-item',
            trackingId: 'ewaste-tracking',
            category: 'ewaste',
            displayName: 'Old Phone',
            codeName: 'SMARTPHONE',
            confidence: 0.88,
            pickedUpAt: DateTime.now(),
          ),
        ];

        // Award points for disposal
        await inventoryService.awardPointsForDisposal(items);

        // Check points calculation
        // Base points: 10 (recycle) + 8 (organic) + 15 (ewaste) = 33
        // Diversity bonus: 3 categories * 5 = 15
        // High confidence bonus: 2 items * 2 = 4 (confidence >= 0.9)
        // Total: 33 + 15 + 4 = 52
        expect(inventoryService.totalPoints, 52);
        expect(inventoryService.sessionStats.totalPointsEarned, 52);
        expect(inventoryService.sessionStats.totalItemsDisposed, 3);
      });

      testWidgets('should handle session statistics correctly', (tester) async {
        final inventoryService = container.read(inventoryServiceProvider);
        await inventoryService.ensureLoaded();

        // Initial session stats
        expect(inventoryService.sessionStats.totalItemsPickedUp, 0);
        expect(inventoryService.sessionStats.totalItemsDisposed, 0);
        expect(inventoryService.sessionStats.totalPointsEarned, 0);

        // Add items
        final item1 = InventoryItem(
          id: 'session-item-1',
          trackingId: 'session-tracking-1',
          category: 'recycle',
          displayName: 'Session Item 1',
          codeName: 'SESSION_ITEM_1',
          confidence: 0.8,
          pickedUpAt: DateTime.now(),
        );

        final item2 = InventoryItem(
          id: 'session-item-2',
          trackingId: 'session-tracking-2',
          category: 'organic',
          displayName: 'Session Item 2',
          codeName: 'SESSION_ITEM_2',
          confidence: 0.9,
          pickedUpAt: DateTime.now(),
        );

        await inventoryService.addItem(item1);
        await inventoryService.addItem(item2);

        expect(inventoryService.sessionStats.totalItemsPickedUp, 2);

        // Award points for one item
        await inventoryService.awardPointsForDisposal([item1]);

        expect(inventoryService.sessionStats.totalItemsDisposed, 1);
        expect(inventoryService.sessionStats.totalPointsEarned, 10);

        // Calculate disposal efficiency
        final efficiency = inventoryService.getDisposalEfficiency();
        expect(efficiency, 50.0); // 1 disposed out of 2 picked up
      });

      testWidgets('should handle inventory capacity and limits', (
        tester,
      ) async {
        final inventoryService = container.read(inventoryServiceProvider);
        await inventoryService.ensureLoaded();

        // Test capacity checking
        expect(inventoryService.isInventoryAtCapacity(maxItems: 5), false);

        // Add items up to capacity
        for (int i = 0; i < 5; i++) {
          final item = InventoryItem(
            id: 'capacity-item-$i',
            trackingId: 'capacity-tracking-$i',
            category: 'recycle',
            displayName: 'Capacity Item $i',
            codeName: 'CAPACITY_ITEM_$i',
            confidence: 0.8,
            pickedUpAt: DateTime.now(),
          );
          await inventoryService.addItem(item);
        }

        expect(inventoryService.isInventoryAtCapacity(maxItems: 5), true);
        expect(inventoryService.inventory.length, 5);

        // Test inventory diversity
        final diversity = inventoryService.getInventoryDiversity();
        expect(diversity, 1); // All items are recycle category

        // Test inventory balance
        expect(inventoryService.isInventoryBalanced(minCategories: 3), false);
      });
    });

    group('Error Handling Integration', () {
      testWidgets('should handle offline mode gracefully', (tester) async {
        final inventoryService = container.read(inventoryServiceProvider);
        await inventoryService.ensureLoaded();

        // Service should work even without network connectivity
        final testItem = InventoryItem(
          id: 'offline-item',
          trackingId: 'offline-tracking',
          category: 'recycle',
          displayName: 'Offline Item',
          codeName: 'OFFLINE_ITEM',
          confidence: 0.8,
          pickedUpAt: DateTime.now(),
        );

        final result = await inventoryService.addItem(testItem);
        expect(result, true);
        expect(inventoryService.inventory, contains(testItem));
      });

      testWidgets('should handle invalid categories', (tester) async {
        final inventoryService = container.read(inventoryServiceProvider);
        await inventoryService.ensureLoaded();

        // Create DetectedObject with invalid category
        final invalidDetectedObject = DetectedObject(
          trackingId: 'invalid-tracking',
          category: 'invalid_category',
          codeName: 'INVALID_ITEM',
          confidence: 0.8,
          detectedAt: DateTime.now(),
          boundingBox: const [0, 0, 100, 100],
          overlayColor: 0xFF00FF00,
        );

        final result = await inventoryService.addItemFromDetectedObject(
          invalidDetectedObject,
        );
        expect(result, false);
        expect(inventoryService.inventory, isEmpty);
      });
    });

    group('Performance Integration', () {
      testWidgets('should handle bulk operations efficiently', (tester) async {
        final inventoryService = container.read(inventoryServiceProvider);
        await inventoryService.ensureLoaded();

        final stopwatch = Stopwatch()..start();

        // Add multiple items
        final items = List.generate(
          20,
          (i) => InventoryItem(
            id: 'bulk-item-$i',
            trackingId: 'bulk-tracking-$i',
            category: WasteCategory.values[i % WasteCategory.values.length].id,
            displayName: 'Bulk Item $i',
            codeName: 'BULK_ITEM_$i',
            confidence: 0.8 + (i % 2) * 0.1,
            pickedUpAt: DateTime.now(),
          ),
        );

        for (final item in items) {
          await inventoryService.addItem(item);
        }

        stopwatch.stop();

        expect(inventoryService.inventory.length, 20);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
        ); // Should complete in reasonable time

        // Test bulk removal
        final trackingIds = items
            .take(10)
            .map((item) => item.trackingId)
            .toList();
        await inventoryService.removeItems(trackingIds);

        expect(inventoryService.inventory.length, 10);
        expect(inventoryService.sessionStats.totalItemsDisposed, 10);
      });
    });
  });
}
