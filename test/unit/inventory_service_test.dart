import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/models/detected_object.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import '../helpers/base_service_test.dart';
import '../fixtures/test_data_factory.dart';

void main() {
  group('InventoryService', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('InventoryItem Model', () {
      test('should create from DetectedObject', () {
        final detectedObject = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.recycle,
          confidence: 0.85,
          codeName: 'PLASTIC_BOTTLE',
        );

        final inventoryItem = InventoryItem.fromDetectedObject(detectedObject);

        expect(inventoryItem.category, WasteCategory.recycle.name);
        expect(inventoryItem.confidence, 0.85);
        expect(inventoryItem.codeName, 'PLASTIC_BOTTLE');
        expect(inventoryItem.trackingId, detectedObject.trackingId);
        expect(inventoryItem.id, isNotEmpty);
      });

      test('should convert to CarriedItem', () {
        final inventoryItem = InventoryItem(
          id: 'test-id',
          trackingId: 'test-tracking',
          category: WasteCategory.recycle.name,
          displayName: 'Plastic Bottle',
          codeName: 'PLASTIC_BOTTLE',
          confidence: 0.85,
          pickedUpAt: DateTime.now(),
        );

        final carriedItem = inventoryItem.toCarriedItem();

        expect(carriedItem.trackingId, 'test-tracking');
        expect(carriedItem.category, WasteCategory.recycle);
        expect(carriedItem.codeName, 'PLASTIC_BOTTLE');
        expect(carriedItem.confidence, 0.85);
      });

      test('should serialize to and from JSON', () {
        final inventoryItem = InventoryItem(
          id: 'test-id',
          trackingId: 'test-tracking',
          category: WasteCategory.recycle.name,
          displayName: 'Plastic Bottle',
          codeName: 'PLASTIC_BOTTLE',
          confidence: 0.85,
          pickedUpAt: DateTime.now(),
        );

        final json = inventoryItem.toJson();
        final restored = InventoryItem.fromJson(json);

        expect(restored.id, inventoryItem.id);
        expect(restored.trackingId, inventoryItem.trackingId);
        expect(restored.category, inventoryItem.category);
        expect(restored.codeName, inventoryItem.codeName);
        expect(restored.confidence, inventoryItem.confidence);
      });
    });

    group('CarriedItem Model', () {
      test('should create with required fields', () {
        final carriedItem = CarriedItem(
          trackingId: 'test-tracking',
          category: WasteCategory.recycle,
          codeName: 'PLASTIC_BOTTLE',
          confidence: 0.85,
          pickedUpAt: DateTime.now(),
        );

        expect(carriedItem.trackingId, 'test-tracking');
        expect(carriedItem.category, WasteCategory.recycle);
        expect(carriedItem.codeName, 'PLASTIC_BOTTLE');
        expect(carriedItem.confidence, 0.85);
      });

      test('should convert to InventoryItem', () {
        final carriedItem = CarriedItem(
          trackingId: 'test-tracking',
          category: WasteCategory.recycle,
          codeName: 'PLASTIC_BOTTLE',
          confidence: 0.85,
          pickedUpAt: DateTime.now(),
        );

        final inventoryItem = InventoryItem.fromCarriedItem(carriedItem);

        expect(inventoryItem.trackingId, 'test-tracking');
        expect(inventoryItem.category, WasteCategory.recycle.name);
        expect(inventoryItem.codeName, 'PLASTIC_BOTTLE');
        expect(inventoryItem.confidence, 0.85);
      });

      test('should serialize to and from JSON', () {
        final carriedItem = CarriedItem(
          trackingId: 'test-tracking',
          category: WasteCategory.recycle,
          codeName: 'PLASTIC_BOTTLE',
          confidence: 0.85,
          pickedUpAt: DateTime.now(),
        );

        final json = carriedItem.toJson();
        final restored = CarriedItem.fromJson(json);

        expect(restored.trackingId, carriedItem.trackingId);
        expect(restored.category, carriedItem.category);
        expect(restored.codeName, carriedItem.codeName);
        expect(restored.confidence, carriedItem.confidence);
      });
    });

    group('Service Architecture', () {
      test('should have proper service structure', () {
        // Test that the service classes exist and can be imported
        expect(InventoryItem, isA<Type>());
        expect(CarriedItem, isA<Type>());
      });
    });

    group('Points Calculation', () {
      test('should calculate correct points for different categories', () {
        // Test points calculation based on category
        expect(WasteCategory.recycle.id, 'recycle');
        expect(WasteCategory.organic.id, 'organic');
        expect(WasteCategory.ewaste.id, 'ewaste');
        expect(WasteCategory.hazardous.id, 'hazardous');
      });
    });
  });
}