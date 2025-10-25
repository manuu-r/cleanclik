import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/services/business/pickup_service.dart';
import 'package:cleanclik/presentation/widgets/camera/enhanced_object_overlay.dart';

// Helper function to create legacy overlay for tests
Widget createLegacyOverlay(DetectedObject object, {bool showTooltip = false}) {
  return EnhancedObjectOverlay.legacy(
    object: object,
    status: ObjectStatus.detected,
    transformedRect: const Rect.fromLTWH(100, 100, 50, 50),
    showTooltip: showTooltip,
    screenSize: const Size(400, 800),
  );
}

void main() {
  group('Enhanced Object Overlay Tests', () {
    testWidgets('should display waste category label', (
      WidgetTester tester,
    ) async {
      // Create a detected object with waste category information
      final detectedObject = DetectedObject(
        trackingId: 'test-123',
        category: 'bottle',
        codeName: 'Plastic Bottle',
        boundingBox: const Rect.fromLTWH(100, 100, 50, 50),
        confidence: 0.85,
        detectedAt: DateTime.now(),
        overlayColor: Colors.green,
        wasteCategory: 'recycle',
        categoryConfidence: 0.92,
        isWasteItem: true,
        imageLabels: [
          ImageLabel(text: 'bottle', confidence: 0.9, index: 0),
          ImageLabel(text: 'plastic', confidence: 0.8, index: 1),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                createLegacyOverlay(detectedObject, showTooltip: true),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify waste category label is displayed
      expect(find.text('RECYCLE'), findsOneWidget);
      expect(find.byIcon(Icons.recycling), findsWidgets);
    });

    testWidgets('should show confidence indicator for low confidence', (
      WidgetTester tester,
    ) async {
      final detectedObject = DetectedObject(
        trackingId: 'test-456',
        category: 'unknown',
        codeName: 'Unknown Item',
        boundingBox: const Rect.fromLTWH(100, 100, 50, 50),
        confidence: 0.75,
        detectedAt: DateTime.now(),
        overlayColor: Colors.grey,
        wasteCategory: 'recycle',
        categoryConfidence: 0.55, // Low confidence
        isWasteItem: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [createLegacyOverlay(detectedObject)]),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show confidence indicator for low confidence
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('should show manual correction UI for very low confidence', (
      WidgetTester tester,
    ) async {
      final detectedObject = DetectedObject(
        trackingId: 'test-789',
        category: 'unknown',
        codeName: 'Uncertain Item',
        boundingBox: const Rect.fromLTWH(100, 100, 50, 50),
        confidence: 0.70,
        detectedAt: DateTime.now(),
        overlayColor: Colors.grey,
        wasteCategory: 'recycle',
        categoryConfidence: 0.45, // Very low confidence
        isWasteItem: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [createLegacyOverlay(detectedObject)]),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show manual correction UI
      expect(find.text('TAP TO CORRECT'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('should handle objects without waste category data', (
      WidgetTester tester,
    ) async {
      final legacyObject = DetectedObject(
        trackingId: 'legacy-test',
        category: 'bottle',
        codeName: 'Legacy Bottle',
        boundingBox: const Rect.fromLTWH(100, 100, 50, 50),
        confidence: 0.80,
        detectedAt: DateTime.now(),
        overlayColor: Colors.blue,
        // No waste category data
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [createLegacyOverlay(legacyObject)]),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should fall back to legacy category mapping
      expect(find.text('RECYCLE'), findsOneWidget); // bottle -> recycle
    });

    testWidgets('should render overlay without errors', (
      WidgetTester tester,
    ) async {
      final testObject = DetectedObject(
        trackingId: 'render-test',
        category: 'bottle',
        codeName: 'Test Bottle',
        boundingBox: const Rect.fromLTWH(100, 100, 50, 50),
        confidence: 0.85,
        detectedAt: DateTime.now(),
        overlayColor: Colors.green,
        wasteCategory: 'recycle',
        categoryConfidence: 0.88,
        isWasteItem: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [createLegacyOverlay(testObject)]),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify overlay renders without errors
      expect(find.byType(EnhancedObjectOverlay), findsOneWidget);
    });
  });
}
