import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import '../fixtures/test_data_factory.dart';
import '../helpers/test_utils.dart';

void main() {
  group('DetectedObject Integration Tests', () {
    group('Real-world Usage Scenarios', () {
      test('should handle AR detection workflow', () {
        // Simulate AR detection creating objects with tracking
        final detectedObjects = <DetectedObject>[];

        // First detection - object appears
        final initialDetection = DetectedObject(
          trackingId: 'ar-track-001',
          category: 'recycle',
          codeName: 'PLASTIC_BOTTLE',
          boundingBox: const Rect.fromLTWH(100, 100, 150, 200),
          confidence: 0.75,
          detectedAt: DateTime.now(),
          overlayColor: const Color(0xFF4CAF50),
          isTracked: false,
        );
        detectedObjects.add(initialDetection);

        // Object gets tracked
        final trackedDetection = initialDetection.copyWith(
          confidence: 0.85,
          isTracked: true,
          label: 'Confirmed Plastic Bottle',
        );
        detectedObjects[0] = trackedDetection;

        // Object moves (bounding box changes)
        final movedDetection = trackedDetection.copyWith(
          boundingBox: const Rect.fromLTWH(120, 110, 150, 200),
          confidence: 0.90,
          detectedAt: DateTime.now(),
        );
        detectedObjects[0] = movedDetection;

        expect(detectedObjects.length, equals(1));
        expect(detectedObjects[0].isTracked, isTrue);
        expect(detectedObjects[0].confidence, equals(0.90));
        expect(detectedObjects[0].label, equals('Confirmed Plastic Bottle'));
        expect(detectedObjects[0].boundingBox.left, equals(120));
      });

      test('should handle inventory management workflow', () {
        // Create detected object from camera
        final cameraDetection = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.ewaste,
          codeName: 'SMARTPHONE',
          confidence: 0.92,
          id: 'inventory-item-001',
          label: 'Old Smartphone',
        );

        // Convert to inventory item (simulated)
        final inventoryData = cameraDetection.toJson();
        inventoryData['addedToInventory'] = true;
        inventoryData['inventoryTimestamp'] = DateTime.now().toIso8601String();

        // Later retrieve from storage
        final retrievedDetection = DetectedObject.fromJson(inventoryData);

        expect(retrievedDetection.category, equals('ewaste'));
        expect(retrievedDetection.codeName, equals('SMARTPHONE'));
        expect(retrievedDetection.id, equals('inventory-item-001'));
        expect(retrievedDetection.label, equals('Old Smartphone'));
        expect(inventoryData['addedToInventory'], isTrue);
      });

      test('should handle leaderboard scoring workflow', () {
        final detectedObjects = [
          TestDataFactory.createMockDetectedObject(
            category: WasteCategory.recycle,
            confidence: 0.95,
            id: 'score-001',
            isTracked: true,
          ),
          TestDataFactory.createMockDetectedObject(
            category: WasteCategory.organic,
            confidence: 0.88,
            id: 'score-002',
            isTracked: true,
          ),
          TestDataFactory.createMockDetectedObject(
            category: WasteCategory.hazardous,
            confidence: 0.92,
            id: 'score-003',
            isTracked: true,
          ),
        ];

        // Calculate scores based on category and confidence
        final scores = detectedObjects.map((obj) {
          final baseScore = _getCategoryScore(obj.category);
          final confidenceMultiplier = obj.confidence;
          final trackingBonus = obj.isTracked ? 1.2 : 1.0;
          return (baseScore * confidenceMultiplier * trackingBonus).round();
        }).toList();

        expect(scores.length, equals(3));
        expect(scores.every((score) => score > 0), isTrue);

        // Verify high-value categories get higher scores
        final recycleScore = scores[0];
        final organicScore = scores[1];
        final hazardousScore = scores[2];

        expect(
          hazardousScore,
          greaterThan(recycleScore),
        ); // Hazardous should score higher
        expect(recycleScore, greaterThan(0));
        expect(organicScore, greaterThan(0));
      });

      test('should handle social sharing workflow', () {
        final sharedDetection = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.recycle,
          codeName: 'ALUMINUM_CAN',
          confidence: 0.94,
          id: 'share-001',
          label: 'Recycled Aluminum Can',
          isTracked: true,
        );

        // Create shareable data
        final shareData = {
          'object': sharedDetection.toJson(),
          'achievement': 'Recycling Champion',
          'points': 150,
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Simulate receiving shared data
        final receivedObjectData = shareData['object'] as Map<String, dynamic>;
        final receivedDetection = DetectedObject.fromJson(receivedObjectData);

        expect(receivedDetection.category, equals('recycle'));
        expect(receivedDetection.codeName, equals('ALUMINUM_CAN'));
        expect(receivedDetection.label, equals('Recycled Aluminum Can'));
        expect(receivedDetection.isTracked, isTrue);
        expect(shareData['achievement'], equals('Recycling Champion'));
      });
    });

    group('Performance and Memory Tests', () {
      test('should handle large numbers of detected objects efficiently', () {
        final stopwatch = Stopwatch()..start();

        // Create 1000 detected objects
        final detectedObjects = List.generate(1000, (index) {
          return TestDataFactory.createMockDetectedObject(
            trackingId: 'perf-test-$index',
            category: WasteCategory.values[index % WasteCategory.values.length],
            id: 'perf-id-$index',
            label: 'Performance Test Object $index',
            isTracked: index % 2 == 0,
          );
        });

        stopwatch.stop();

        expect(detectedObjects.length, equals(1000));
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
        ); // Should complete in under 1 second

        // Test serialization performance
        final serializationStopwatch = Stopwatch()..start();
        final jsonList = detectedObjects.map((obj) => obj.toJson()).toList();
        serializationStopwatch.stop();

        expect(jsonList.length, equals(1000));
        expect(
          serializationStopwatch.elapsedMilliseconds,
          lessThan(2000),
        ); // Should serialize quickly

        // Test deserialization performance
        final deserializationStopwatch = Stopwatch()..start();
        final deserializedObjects = jsonList
            .map((json) => DetectedObject.fromJson(json))
            .toList();
        deserializationStopwatch.stop();

        expect(deserializedObjects.length, equals(1000));
        expect(
          deserializationStopwatch.elapsedMilliseconds,
          lessThan(2000),
        ); // Should deserialize quickly
      });

      test('should handle rapid object updates efficiently', () {
        var detectedObject = TestDataFactory.createMockDetectedObject(
          trackingId: 'rapid-update-test',
          id: 'rapid-001',
          isTracked: false,
        );

        final stopwatch = Stopwatch()..start();

        // Simulate 100 rapid updates (like AR tracking)
        for (int i = 0; i < 100; i++) {
          detectedObject = detectedObject.copyWith(
            boundingBox: Rect.fromLTWH(
              100 + (i * 2.0), // Moving object
              100 + (i * 1.5),
              150,
              200,
            ),
            confidence: 0.7 + (i * 0.003), // Increasing confidence
            detectedAt: DateTime.now(),
            isTracked: i > 10, // Becomes tracked after 10 updates
          );
        }

        stopwatch.stop();

        expect(
          detectedObject.boundingBox.left,
          equals(298.0),
        ); // 100 + (99 * 2)
        expect(
          detectedObject.confidence,
          closeTo(0.997, 0.001),
        ); // 0.7 + (99 * 0.003)
        expect(detectedObject.isTracked, isTrue);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
        ); // Should be very fast
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle malformed JSON gracefully', () {
        final malformedJson = {
          'trackingId': 'test-id',
          'category': 'recycle',
          'codeName': 'PLASTIC_BOTTLE',
          'boundingBox': {
            'left': 'invalid', // String instead of double
            'top': 100.0,
            'right': 300.0,
            'bottom': 400.0,
          },
          'confidence': 0.85,
          'detectedAt': 'invalid-date', // Invalid date format
          'overlayColor': 4294967295,
        };

        expect(
          () => DetectedObject.fromJson(malformedJson),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle missing required fields in JSON', () {
        final incompleteJson = {
          'trackingId': 'test-id',
          'category': 'recycle',
          // Missing codeName, boundingBox, confidence, detectedAt, overlayColor
        };

        expect(
          () => DetectedObject.fromJson(incompleteJson),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle extreme values gracefully', () {
        final extremeObject = DetectedObject(
          trackingId: 'extreme-test',
          category: 'recycle',
          codeName: 'EXTREME_OBJECT',
          boundingBox: const Rect.fromLTWH(-1000, -1000, 10000, 10000),
          confidence: 1.0,
          detectedAt: DateTime.fromMillisecondsSinceEpoch(0), // Unix epoch
          overlayColor: const Color(0xFFFFFFFF), // White
          id: 'x' * 1000, // Very long ID
          label: 'L' * 1000, // Very long label
          isTracked: true,
        );

        expect(extremeObject.boundingBox.left, equals(-1000));
        expect(extremeObject.boundingBox.width, equals(10000));
        expect(extremeObject.id?.length, equals(1000));
        expect(extremeObject.label?.length, equals(1000));

        // Should still serialize/deserialize correctly
        final json = extremeObject.toJson();
        final deserializedObject = DetectedObject.fromJson(json);

        expect(deserializedObject.trackingId, equals(extremeObject.trackingId));
        expect(deserializedObject.id, equals(extremeObject.id));
        expect(deserializedObject.label, equals(extremeObject.label));
      });
    });

    group('Compatibility with Existing Systems', () {
      test('should work with existing mock data patterns', () {
        // Test with existing TestDataFactory patterns
        final mockObjects = TestDataFactory.createMockDetectedObjects(count: 5);

        expect(mockObjects.length, equals(5));

        for (final obj in mockObjects) {
          expect(obj.trackingId, isNotEmpty);
          expect(obj.category, isNotEmpty);
          expect(obj.codeName, isNotEmpty);
          expect(obj.confidence, greaterThan(0.0));
          expect(obj.confidence, lessThanOrEqualTo(1.0));
          expect(obj.boundingBox.width, greaterThan(0));
          expect(obj.boundingBox.height, greaterThan(0));

          // New properties should have default values when not specified
          expect(obj.id, isNull);
          expect(obj.label, isNull);
          expect(obj.isTracked, isFalse);
        }
      });

      test('should maintain equality behavior with existing code', () {
        final obj1 = TestDataFactory.createMockDetectedObject(
          trackingId: 'same-id',
          category: WasteCategory.recycle,
        );

        final obj2 = TestDataFactory.createMockDetectedObject(
          trackingId: 'same-id',
          category: WasteCategory.organic, // Different category
          id: 'different-id', // Different optional properties
          label: 'Different Label',
          isTracked: true,
        );

        // Should still be equal based on trackingId only
        expect(obj1, equals(obj2));
        expect(obj1.hashCode, equals(obj2.hashCode));
      });

      test('should work with existing stream processing', () {
        // Simulate stream of detected objects
        final objectStream = Stream.fromIterable([
          TestDataFactory.createMockDetectedObject(
            trackingId: 'stream-1',
            id: 'stream-id-1',
            isTracked: false,
          ),
          TestDataFactory.createMockDetectedObject(
            trackingId: 'stream-2',
            id: 'stream-id-2',
            isTracked: true,
          ),
          TestDataFactory.createMockDetectedObject(
            trackingId: 'stream-3',
            id: 'stream-id-3',
            isTracked: false,
          ),
        ]);

        final processedObjects = <DetectedObject>[];

        return objectStream
            .listen((obj) {
              processedObjects.add(obj);
            })
            .asFuture()
            .then((_) {
              expect(processedObjects.length, equals(3));
              expect(processedObjects[0].id, equals('stream-id-1'));
              expect(processedObjects[1].isTracked, isTrue);
              expect(processedObjects[2].isTracked, isFalse);
            });
      });
    });
  });
}

// Helper function for scoring simulation
int _getCategoryScore(String category) {
  switch (category) {
    case 'recycle':
      return 100;
    case 'organic':
      return 80;
    case 'ewaste':
      return 150;
    case 'hazardous':
      return 200;
    case 'landfill':
      return 50;
    default:
      return 10;
  }
}
