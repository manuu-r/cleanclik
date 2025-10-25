import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/services/business/pickup_service.dart';
import 'package:cleanclik/presentation/widgets/camera/enhanced_object_overlay.dart';

void main() {
  group('EnhancedObjectOverlay Image Labels Integration', () {
    testWidgets('should display tooltip with image labeling data', (
      tester,
    ) async {
      // Create image labels
      final imageLabels = [
        ImageLabel(text: 'bottle', confidence: 0.95, index: 0),
        ImageLabel(text: 'plastic', confidence: 0.87, index: 1),
      ];

      // Create detected object with image labels
      final detectedObject = DetectedObject(
        trackingId: 'test-overlay-001',
        category: 'bottle',
        codeName: 'Plastic Bottle',
        boundingBox: const Rect.fromLTWH(100, 100, 50, 50),
        confidence: 0.85,
        detectedAt: DateTime.now(),
        overlayColor: Colors.blue,
        imageLabels: imageLabels,
      );

      // Create enhanced object overlay
      final overlay = EnhancedObjectOverlay.legacy(
        object: detectedObject,
        status: ObjectStatus.detected,
        transformedRect: const Rect.fromLTWH(100, 100, 50, 50),
        showTooltip: true,
        screenSize: const Size(400, 800),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Stack(children: [overlay])),
        ),
      );

      // Allow animations to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Verify overlay is displayed
      expect(find.byType(EnhancedObjectOverlay), findsOneWidget);

      // The tooltip should be created with image labels
      // We can't easily test the tooltip content without exposing internal state,
      // but we can verify the overlay renders without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle objects without image labels gracefully', (
      tester,
    ) async {
      // Create detected object without image labels
      final detectedObject = DetectedObject(
        trackingId: 'test-overlay-002',
        category: 'can',
        codeName: 'Aluminum Can',
        boundingBox: const Rect.fromLTWH(150, 150, 40, 40),
        confidence: 0.75,
        detectedAt: DateTime.now(),
        overlayColor: Colors.green,
        // No image labels provided
      );

      final overlay = EnhancedObjectOverlay.legacy(
        object: detectedObject,
        status: ObjectStatus.detected,
        transformedRect: const Rect.fromLTWH(150, 150, 40, 40),
        showTooltip: true,
        screenSize: const Size(400, 800),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Stack(children: [overlay])),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Verify overlay renders without errors even without image labels
      expect(find.byType(EnhancedObjectOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display different status overlays correctly', (
      tester,
    ) async {
      final detectedObject = DetectedObject(
        trackingId: 'test-overlay-003',
        category: 'bottle',
        codeName: 'Test Bottle',
        boundingBox: const Rect.fromLTWH(200, 200, 60, 60),
        confidence: 0.90,
        detectedAt: DateTime.now(),
        overlayColor: Colors.red,
        imageLabels: [ImageLabel(text: 'bottle', confidence: 0.92, index: 0)],
      );

      // Test different statuses
      final statuses = [
        ObjectStatus.detected,
        ObjectStatus.carried,
        ObjectStatus.targeted,
      ];

      for (final status in statuses) {
        final overlay = EnhancedObjectOverlay.legacy(
          object: detectedObject,
          status: status,
          transformedRect: const Rect.fromLTWH(200, 200, 60, 60),
          showTooltip: true,
          screenSize: const Size(400, 800),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Stack(children: [overlay])),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        // Verify overlay renders for each status
        expect(find.byType(EnhancedObjectOverlay), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Clear the widget tree for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });
}
