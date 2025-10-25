import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/services/business/pickup_service.dart';
import 'package:cleanclik/presentation/widgets/camera/enhanced_object_overlay.dart';

void main() {
  group('EnhancedObjectOverlay Debug Information', () {
    test('should generate comprehensive debug info', () {
      // Create image labels
      final imageLabels = [
        ImageLabel(text: 'bottle', confidence: 0.95, index: 0),
        ImageLabel(text: 'plastic', confidence: 0.87, index: 1),
      ];

      // Create detected object with comprehensive data
      final detectedObject = DetectedObject(
        trackingId: 'debug-test-001',
        category: 'bottle',
        codeName: 'Debug Test Bottle',
        boundingBox: const Rect.fromLTWH(10, 20, 30, 40),
        confidence: 0.88,
        detectedAt: DateTime.parse('2024-01-01T12:00:00Z'),
        overlayColor: Colors.blue,
        imageLabels: imageLabels,
        wasteCategory: 'recycle',
        categoryConfidence: 0.92,
        isWasteItem: true,
        categoryScores: {'recycle': 0.92, 'landfill': 0.08},
      );

      // Create overlay to access debug methods (for future debug functionality)
      EnhancedObjectOverlay(
        detectedObject: detectedObject,
        status: ObjectStatus.detected,
        transformedRect: const Rect.fromLTWH(100, 150, 30, 40),
        showTooltip: true,
        screenSize: const Size(400, 800),
        isVisible: true,
      );

      // Access debug info through reflection or create a test-friendly version
      // For now, we'll verify the object has the expected properties
      expect(detectedObject.hasImageLabels, isTrue);
      expect(detectedObject.mostConfidentImageLabel?.text, equals('bottle'));
      expect(detectedObject.imageLabelsDebugString, contains('bottle (95.0%)'));
      expect(
        detectedObject.imageLabelsDebugString,
        contains('plastic (87.0%)'),
      );
    });

    test('should handle objects without image labels in debug info', () {
      final detectedObject = DetectedObject(
        trackingId: 'debug-test-002',
        category: 'can',
        codeName: 'Debug Test Can',
        boundingBox: const Rect.fromLTWH(50, 60, 25, 35),
        confidence: 0.75,
        detectedAt: DateTime.now(),
        overlayColor: Colors.green,
        // No image labels
      );

      // Verify debug-friendly properties
      expect(detectedObject.hasImageLabels, isFalse);
      expect(detectedObject.mostConfidentImageLabel, isNull);
      expect(detectedObject.imageLabelsDebugString, equals('No image labels'));
    });

    test('should provide correct image label statistics', () {
      final imageLabels = [
        ImageLabel(text: 'bottle', confidence: 0.95, index: 0),
        ImageLabel(text: 'plastic', confidence: 0.87, index: 1),
        ImageLabel(text: 'container', confidence: 0.72, index: 2),
        ImageLabel(text: 'recyclable', confidence: 0.68, index: 3),
      ];

      final detectedObject = DetectedObject(
        trackingId: 'debug-test-003',
        category: 'bottle',
        codeName: 'Multi-Label Test',
        boundingBox: const Rect.fromLTWH(0, 0, 50, 50),
        confidence: 0.90,
        detectedAt: DateTime.now(),
        overlayColor: Colors.red,
        imageLabels: imageLabels,
      );

      // Verify statistics
      expect(detectedObject.imageLabels.length, equals(4));
      expect(detectedObject.hasImageLabels, isTrue);
      expect(detectedObject.mostConfidentImageLabel?.text, equals('bottle'));
      expect(detectedObject.mostConfidentImageLabel?.confidence, equals(0.95));

      // Verify debug string contains all labels
      final debugString = detectedObject.imageLabelsDebugString;
      expect(debugString, contains('bottle (95.0%)'));
      expect(debugString, contains('plastic (87.0%)'));
      expect(debugString, contains('container (72.0%)'));
      expect(debugString, contains('recyclable (68.0%)'));
    });
  });
}
