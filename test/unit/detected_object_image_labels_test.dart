import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/models/camera_models.dart';

void main() {
  group('DetectedObject Image Labels Tests', () {
    test('should merge with image labels correctly', () {
      // Create a detected object
      final detectedObject = DetectedObject(
        trackingId: 'test-123',
        category: 'bottle',
        codeName: 'Plastic Bottle',
        boundingBox: const Rect.fromLTWH(10, 10, 50, 50),
        confidence: 0.85,
        detectedAt: DateTime.now(),
        overlayColor: Colors.blue,
      );

      // Create image labels
      final imageLabels = [
        ImageLabel(text: 'bottle', confidence: 0.95, index: 0),
        ImageLabel(text: 'plastic', confidence: 0.87, index: 1),
      ];

      // Merge with labels
      final mergedObject = detectedObject.mergeWithLabels(imageLabels);

      // Verify merge worked correctly
      expect(mergedObject.imageLabels.length, equals(2));
      expect(mergedObject.hasImageLabels, isTrue);
      expect(mergedObject.mostConfidentImageLabel?.text, equals('bottle'));
      expect(mergedObject.mostConfidentImageLabel?.confidence, equals(0.95));

      // Verify original properties are preserved
      expect(mergedObject.trackingId, equals('test-123'));
      expect(mergedObject.category, equals('bottle'));
      expect(mergedObject.confidence, equals(0.85));
    });

    test('should handle empty image labels gracefully', () {
      final detectedObject = DetectedObject(
        trackingId: 'test-456',
        category: 'can',
        codeName: 'Aluminum Can',
        boundingBox: const Rect.fromLTWH(20, 20, 40, 40),
        confidence: 0.75,
        detectedAt: DateTime.now(),
        overlayColor: Colors.green,
      );

      // Test with empty labels
      expect(detectedObject.hasImageLabels, isFalse);
      expect(detectedObject.mostConfidentImageLabel, isNull);
      expect(detectedObject.imageLabelsDebugString, equals('No image labels'));
    });

    test('should provide correct debug string for image labels', () {
      final imageLabels = [
        ImageLabel(text: 'bottle', confidence: 0.95, index: 0),
        ImageLabel(text: 'plastic', confidence: 0.87, index: 1),
        ImageLabel(text: 'container', confidence: 0.72, index: 2),
      ];

      final detectedObject = DetectedObject(
        trackingId: 'test-789',
        category: 'bottle',
        codeName: 'Test Bottle',
        boundingBox: const Rect.fromLTWH(0, 0, 30, 30),
        confidence: 0.90,
        detectedAt: DateTime.now(),
        overlayColor: Colors.red,
        imageLabels: imageLabels,
      );

      final debugString = detectedObject.imageLabelsDebugString;

      expect(debugString, contains('bottle (95.0%)'));
      expect(debugString, contains('plastic (87.0%)'));
      expect(debugString, contains('container (72.0%)'));
    });

    test('should serialize and deserialize with image labels', () {
      final imageLabels = [
        ImageLabel(text: 'bottle', confidence: 0.95, index: 0),
        ImageLabel(text: 'plastic', confidence: 0.87, index: 1),
      ];

      final original = DetectedObject(
        trackingId: 'test-serialization',
        category: 'bottle',
        codeName: 'Serialization Test',
        boundingBox: const Rect.fromLTWH(5, 5, 25, 25),
        confidence: 0.88,
        detectedAt: DateTime.now(),
        overlayColor: Colors.purple,
        imageLabels: imageLabels,
      );

      // Serialize to JSON
      final json = original.toJson();

      // Deserialize from JSON
      final deserialized = DetectedObject.fromJson(json);

      // Verify image labels are preserved
      expect(deserialized.imageLabels.length, equals(2));
      expect(deserialized.imageLabels[0].text, equals('bottle'));
      expect(deserialized.imageLabels[0].confidence, equals(0.95));
      expect(deserialized.imageLabels[1].text, equals('plastic'));
      expect(deserialized.imageLabels[1].confidence, equals(0.87));
    });
  });
}
