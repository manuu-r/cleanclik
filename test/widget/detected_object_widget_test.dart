import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/presentation/widgets/camera/enhanced_object_overlay.dart';
import 'package:cleanclik/presentation/widgets/camera/coordinate_debug_widget.dart';
import 'package:cleanclik/presentation/widgets/camera/coordinate_diagnostic_overlay.dart';

import '../fixtures/test_data_factory.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('DetectedObject Widget Tests', () {
    group('EnhancedObjectOverlay', () {
      testWidgets('should display detected object with required properties', (
        tester,
      ) async {
        final detectedObject = DetectedObject(
          trackingId: 'test-overlay-001',
          category: 'recycle',
          codeName: 'PLASTIC_BOTTLE',
          boundingBox: const Rect.fromLTWH(100, 100, 150, 200),
          confidence: 0.85,
          detectedAt: DateTime.now(),
          overlayColor: const Color(0xFF4CAF50),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EnhancedObjectOverlay(
                  legacyObject: detectedObject,
                  status: ObjectStatus.detected,
                  transformedRect: detectedObject.boundingBox,
                  screenSize: const Size(400, 800),
                ),
              ),
            ),
          ),
        );

        // Verify the overlay is rendered
        expect(find.byType(EnhancedObjectOverlay), findsOneWidget);

        // The overlay should be positioned according to the bounding box
        final overlay = tester.widget<EnhancedObjectOverlay>(
          find.byType(EnhancedObjectOverlay),
        );
        expect(overlay.legacyObject?.trackingId, equals('test-overlay-001'));
        expect(overlay.legacyObject?.category, equals('recycle'));
        expect(overlay.legacyObject?.confidence, equals(0.85));
      });

      testWidgets('should display detected object with optional properties', (
        tester,
      ) async {
        final detectedObject = DetectedObject(
          trackingId: 'test-overlay-002',
          category: 'organic',
          codeName: 'BANANA_PEEL',
          boundingBox: const Rect.fromLTWH(50, 50, 100, 150),
          confidence: 0.92,
          detectedAt: DateTime.now(),
          overlayColor: const Color(0xFFFF9800),
          id: 'overlay-id-002',
          label: 'Organic Waste Item',
          isTracked: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EnhancedObjectOverlay(
                  legacyObject: detectedObject,
                  status: ObjectStatus.tracked,
                  transformedRect: detectedObject.boundingBox,
                  screenSize: const Size(400, 800),
                ),
              ),
            ),
          ),
        );

        final overlay = tester.widget<EnhancedObjectOverlay>(
          find.byType(EnhancedObjectOverlay),
        );
        expect(overlay.legacyObject?.trackingId, equals('overlay-id-002'));
        expect(overlay.legacyObject?.category, equals('Organic Waste Item'));
        expect(overlay.status, equals(ObjectStatus.tracked));
      });

      testWidgets('should handle different object statuses', (tester) async {
        final detectedObject = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.ewaste,
          isTracked: true,
        );

        for (final status in ObjectStatus.values) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: EnhancedObjectOverlay(
                    legacyObject: detectedObject,
                    status: status,
                    transformedRect: detectedObject.boundingBox,
                    screenSize: const Size(400, 800),
                  ),
                ),
              ),
            ),
          );

          expect(find.byType(EnhancedObjectOverlay), findsOneWidget);

          final overlay = tester.widget<EnhancedObjectOverlay>(
            find.byType(EnhancedObjectOverlay),
          );
          expect(overlay.status, equals(status));
        }
      });
    });

    group('CoordinateDebugWidget', () {
      testWidgets('should display detected objects count', (tester) async {
        final detectedObjects = [
          TestDataFactory.createMockDetectedObject(
            trackingId: 'debug-001',
            id: 'debug-id-001',
            isTracked: false,
          ),
          TestDataFactory.createMockDetectedObject(
            trackingId: 'debug-002',
            id: 'debug-id-002',
            isTracked: true,
          ),
          TestDataFactory.createMockDetectedObject(
            trackingId: 'debug-003',
            id: 'debug-id-003',
            isTracked: false,
          ),
        ];

        final filteredObjects = detectedObjects
            .where((obj) => obj.isTracked)
            .toList();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDebugWidget(
                handLandmarks: const [],
                detectedObjects: detectedObjects,
                filteredObjects: filteredObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
              ),
            ),
          ),
        );

        // Should show the count of detected objects and filtered objects
        expect(find.textContaining('H:0 O:3→1'), findsOneWidget);
        expect(find.textContaining('Objects (3→1)'), findsOneWidget);
      });

      testWidgets('should handle empty detected objects list', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDebugWidget(
                handLandmarks: const [],
                detectedObjects: const [],
                filteredObjects: const [],
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
              ),
            ),
          ),
        );

        expect(find.textContaining('H:0 O:0→0'), findsOneWidget);
        expect(find.textContaining('Objects (0→0)'), findsOneWidget);
      });

      testWidgets('should update when detected objects change', (tester) async {
        var detectedObjects = [
          TestDataFactory.createMockDetectedObject(trackingId: 'update-001'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDebugWidget(
                handLandmarks: const [],
                detectedObjects: detectedObjects,
                filteredObjects: detectedObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        expect(find.textContaining('O:1→1'), findsOneWidget);

        // Add more objects
        detectedObjects = [
          ...detectedObjects,
          TestDataFactory.createMockDetectedObject(trackingId: 'update-002'),
          TestDataFactory.createMockDetectedObject(trackingId: 'update-003'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDebugWidget(
                handLandmarks: const [],
                detectedObjects: detectedObjects,
                filteredObjects: detectedObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        expect(find.textContaining('O:3→3'), findsOneWidget);
      });
    });

    group('CoordinateDiagnosticOverlay', () {
      testWidgets('should render diagnostic overlay with detected objects', (
        tester,
      ) async {
        final detectedObjects = [
          TestDataFactory.createMockDetectedObject(
            trackingId: 'diagnostic-001',
            boundingBox: const Rect.fromLTWH(100, 100, 150, 200),
            confidence: 0.85,
          ),
          TestDataFactory.createMockDetectedObject(
            trackingId: 'diagnostic-002',
            boundingBox: const Rect.fromLTWH(300, 150, 120, 180),
            confidence: 0.92,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDiagnosticOverlay(
                handLandmarks: const [],
                detectedObjects: detectedObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        expect(find.byType(CoordinateDiagnosticOverlay), findsOneWidget);
        expect(find.byType(CustomPaint), findsOneWidget);

        final overlay = tester.widget<CoordinateDiagnosticOverlay>(
          find.byType(CoordinateDiagnosticOverlay),
        );
        expect(overlay.detectedObjects.length, equals(2));
        expect(overlay.detectedObjects[0].confidence, equals(0.85));
        expect(overlay.detectedObjects[1].confidence, equals(0.92));
      });

      testWidgets('should handle objects with new optional properties', (
        tester,
      ) async {
        final detectedObjects = [
          TestDataFactory.createMockDetectedObject(
            trackingId: 'diagnostic-with-props-001',
            id: 'diag-id-001',
            label: 'Diagnostic Test Object',
            isTracked: true,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDiagnosticOverlay(
                handLandmarks: const [],
                detectedObjects: detectedObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        final overlay = tester.widget<CoordinateDiagnosticOverlay>(
          find.byType(CoordinateDiagnosticOverlay),
        );
        expect(overlay.detectedObjects[0].id, equals('diag-id-001'));
        expect(
          overlay.detectedObjects[0].label,
          equals('Diagnostic Test Object'),
        );
        expect(overlay.detectedObjects[0].isTracked, isTrue);
      });

      testWidgets('should handle empty detected objects list', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDiagnosticOverlay(
                handLandmarks: const [],
                detectedObjects: const [],
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        expect(find.byType(CoordinateDiagnosticOverlay), findsOneWidget);

        final overlay = tester.widget<CoordinateDiagnosticOverlay>(
          find.byType(CoordinateDiagnosticOverlay),
        );
        expect(overlay.detectedObjects, isEmpty);
      });

      testWidgets('should handle large numbers of detected objects', (
        tester,
      ) async {
        final detectedObjects = List.generate(50, (index) {
          return TestDataFactory.createMockDetectedObject(
            trackingId: 'large-test-$index',
            boundingBox: Rect.fromLTWH(
              (index % 10) * 40.0,
              (index ~/ 10) * 50.0,
              30,
              40,
            ),
            id: 'large-id-$index',
            isTracked: index % 3 == 0,
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDiagnosticOverlay(
                handLandmarks: const [],
                detectedObjects: detectedObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        expect(find.byType(CoordinateDiagnosticOverlay), findsOneWidget);

        final overlay = tester.widget<CoordinateDiagnosticOverlay>(
          find.byType(CoordinateDiagnosticOverlay),
        );
        expect(overlay.detectedObjects.length, equals(50));

        // Verify some objects are tracked
        final trackedCount = overlay.detectedObjects
            .where((obj) => obj.isTracked)
            .length;
        expect(trackedCount, greaterThan(0));
      });
    });

    group('Widget Performance Tests', () {
      testWidgets(
        'should handle rapid object updates without performance issues',
        (tester) async {
          var detectedObjects = [
            TestDataFactory.createMockDetectedObject(trackingId: 'perf-001'),
          ];

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CoordinateDebugWidget(
                  handLandmarks: const [],
                  detectedObjects: detectedObjects,
                  filteredObjects: detectedObjects,
                  cameraImageSize: const Size(1920, 1080),
                  widgetSize: const Size(400, 600),
                isVisible: true,
                ),
              ),
            ),
          );

          final stopwatch = Stopwatch()..start();

          // Simulate 20 rapid updates
          for (int i = 0; i < 20; i++) {
            detectedObjects = [
              TestDataFactory.createMockDetectedObject(
                trackingId: 'perf-001',
                boundingBox: Rect.fromLTWH(
                  100 + (i * 5.0),
                  100 + (i * 3.0),
                  150,
                  200,
                ),
                confidence: 0.7 + (i * 0.01),
                isTracked: i > 5,
              ),
            ];

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: CoordinateDebugWidget(
                    handLandmarks: const [],
                    detectedObjects: detectedObjects,
                    filteredObjects: detectedObjects,
                    cameraImageSize: const Size(1920, 1080),
                    widgetSize: const Size(400, 600),
                isVisible: true,
                  ),
                ),
              ),
            );

            await tester.pump();
          }

          stopwatch.stop();

          // Should complete updates quickly
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));
          expect(find.byType(CoordinateDebugWidget), findsOneWidget);
        },
      );

      testWidgets('should handle memory efficiently with many objects', (
        tester,
      ) async {
        final manyObjects = List.generate(100, (index) {
          return TestDataFactory.createMockDetectedObject(
            trackingId: 'memory-test-$index',
            id: 'memory-id-$index',
            label: 'Memory Test Object $index',
            isTracked: index % 2 == 0,
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDiagnosticOverlay(
                handLandmarks: const [],
                detectedObjects: manyObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        expect(find.byType(CoordinateDiagnosticOverlay), findsOneWidget);

        // Widget should render without issues
        await tester.pumpAndSettle();

        final overlay = tester.widget<CoordinateDiagnosticOverlay>(
          find.byType(CoordinateDiagnosticOverlay),
        );
        expect(overlay.detectedObjects.length, equals(100));
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle objects with extreme bounding boxes', (
        tester,
      ) async {
        final extremeObjects = [
          DetectedObject(
            trackingId: 'extreme-small',
            category: 'recycle',
            codeName: 'TINY_OBJECT',
            boundingBox: const Rect.fromLTWH(0, 0, 1, 1),
            confidence: 0.5,
            detectedAt: DateTime.now(),
            overlayColor: const Color(0xFF4CAF50),
          ),
          DetectedObject(
            trackingId: 'extreme-large',
            category: 'landfill',
            codeName: 'HUGE_OBJECT',
            boundingBox: const Rect.fromLTWH(-1000, -1000, 5000, 5000),
            confidence: 0.95,
            detectedAt: DateTime.now(),
            overlayColor: const Color(0xFFFF5722),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDiagnosticOverlay(
                handLandmarks: const [],
                detectedObjects: extremeObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        expect(find.byType(CoordinateDiagnosticOverlay), findsOneWidget);

        final overlay = tester.widget<CoordinateDiagnosticOverlay>(
          find.byType(CoordinateDiagnosticOverlay),
        );
        expect(overlay.detectedObjects.length, equals(2));
        expect(overlay.detectedObjects[0].boundingBox.width, equals(1.0));
        expect(overlay.detectedObjects[1].boundingBox.width, equals(5000.0));
      });

      testWidgets('should handle objects with extreme confidence values', (
        tester,
      ) async {
        final extremeConfidenceObjects = [
          TestDataFactory.createMockDetectedObject(
            trackingId: 'zero-confidence',
            confidence: 0.0,
          ),
          TestDataFactory.createMockDetectedObject(
            trackingId: 'max-confidence',
            confidence: 1.0,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoordinateDebugWidget(
                handLandmarks: const [],
                detectedObjects: extremeConfidenceObjects,
                filteredObjects: extremeConfidenceObjects,
                cameraImageSize: const Size(1920, 1080),
                widgetSize: const Size(400, 600),
                isVisible: true,
              ),
            ),
          ),
        );

        expect(find.byType(CoordinateDebugWidget), findsOneWidget);
        expect(find.textContaining('O:2→2'), findsOneWidget);
      });
    });
  });
}

// Mock enums and classes that might be needed
enum ObjectStatus { detected, tracked, confirmed, lost }
