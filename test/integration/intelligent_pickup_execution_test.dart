import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/services/camera/ml_background_processor.dart'
    show ProcessingMode;
import 'package:cleanclik/presentation/screens/camera/ar_camera_services.dart';

void main() {
  group('Intelligent Pickup Service Execution Integration', () {
    late ARCameraServices services;
    late DetectedObject testObject;
    late HandLandmark testHand;

    setUp(() {
      services = ARCameraServices();

      testObject = DetectedObject(
        trackingId: 'test-object-1',
        category: 'recycle',
        codeName: 'plastic_bottle',
        boundingBox: const Rect.fromLTWH(100, 100, 50, 50),
        confidence: 0.8,
        detectedAt: DateTime.now(),
        overlayColor: Colors.green,
      );

      testHand = HandLandmark(
        landmarks: List.generate(21, (i) => Offset(i * 10.0, i * 10.0)),
        normalizedLandmarks: List.generate(
          21,
          (i) => Offset(i * 0.05, i * 0.05),
        ),
        boundingBox: const Rect.fromLTWH(0, 0, 200, 200),
        handedness: 'Right',
        handednessConfidence: 0.95,
        confidence: 0.9,
        timestamp: DateTime.now(),
      );
    });

    group('shouldExecutePickupService', () {
      test(
        'should return false when no objects detected (Requirement 3.1)',
        () {
          final result = services.shouldExecutePickupService(
            [], // No objects
            [testHand],
          );

          expect(result, false);
        },
      );

      test('should return false when no hands detected (Requirement 3.2)', () {
        final result = services.shouldExecutePickupService(
          [testObject],
          [], // No hands
        );

        expect(result, false);
      });

      test(
        'should return true when both objects and hands present (Requirement 3.3)',
        () {
          final result = services.shouldExecutePickupService(
            [testObject],
            [testHand],
          );

          expect(result, true);
        },
      );

      test('should handle multiple objects and hands correctly', () {
        final multipleObjects = [
          testObject,
          testObject.copyWith(trackingId: 'test-object-2'),
        ];

        final multipleHands = [
          testHand,
          HandLandmark(
            landmarks: List.generate(21, (i) => Offset(i * 15.0, i * 15.0)),
            normalizedLandmarks: List.generate(
              21,
              (i) => Offset(i * 0.07, i * 0.07),
            ),
            boundingBox: const Rect.fromLTWH(50, 50, 200, 200),
            handedness: 'Left',
            handednessConfidence: 0.90,
            confidence: 0.85,
            timestamp: DateTime.now(),
          ),
        ];

        final result = services.shouldExecutePickupService(
          multipleObjects,
          multipleHands,
        );

        expect(result, true);
      });

      test('should return false for empty lists', () {
        final result = services.shouldExecutePickupService([], []);
        expect(result, false);
      });
    });

    group('ServiceExecutionContext integration', () {
      test('should create context with correct processing mode fallback', () {
        // When ML service is not available, should use ProcessingMode.full as fallback
        final context = ServiceExecutionContext(
          detectedObjects: [testObject],
          handLandmarks: [testHand],
          currentMode:
              ProcessingMode.full, // Fallback when ML service unavailable
          isMemoryPressure: false,
          timestamp: DateTime.now(),
        );

        expect(context.shouldExecutePickupService(), true);
        expect(context.currentMode, ProcessingMode.full);
      });

      test('should handle memory pressure correctly', () {
        final context = ServiceExecutionContext(
          detectedObjects: [testObject],
          handLandmarks: [testHand],
          currentMode: ProcessingMode.full,
          isMemoryPressure: true, // Memory pressure
          timestamp: DateTime.now(),
        );

        expect(context.shouldExecutePickupService(), false);
        expect(context.getExecutionReason(), 'memory_pressure');
      });

      test('should handle cached mode correctly (Requirement 3.4)', () {
        final context = ServiceExecutionContext(
          detectedObjects: [testObject],
          handLandmarks: [testHand],
          currentMode: ProcessingMode.cached, // Cached mode
          isMemoryPressure: false,
          timestamp: DateTime.now(),
        );

        expect(context.shouldExecutePickupService(), false);
        expect(context.getExecutionReason(), 'cached_mode_active');
      });
    });

    group('Logging control verification (Requirement 3.5)', () {
      test(
        'should provide appropriate execution reasons for logging control',
        () {
          // Test different scenarios that should prevent logging
          final scenarios = [
            {
              'objects': <DetectedObject>[],
              'hands': [testHand],
              'expectedReason': 'no_objects_detected',
            },
            {
              'objects': [testObject],
              'hands': <HandLandmark>[],
              'expectedReason': 'no_hands_detected',
            },
            {
              'objects': [testObject],
              'hands': [testHand],
              'mode': ProcessingMode.cached,
              'expectedReason': 'cached_mode_active',
            },
            {
              'objects': [testObject],
              'hands': [testHand],
              'memoryPressure': true,
              'expectedReason': 'memory_pressure',
            },
          ];

          for (final scenario in scenarios) {
            final context = ServiceExecutionContext(
              detectedObjects: scenario['objects'] as List<DetectedObject>,
              handLandmarks: scenario['hands'] as List<HandLandmark>,
              currentMode:
                  scenario['mode'] as ProcessingMode? ?? ProcessingMode.full,
              isMemoryPressure: scenario['memoryPressure'] as bool? ?? false,
              timestamp: DateTime.now(),
            );

            expect(context.shouldExecutePickupService(), false);
            expect(context.getExecutionReason(), scenario['expectedReason']);
          }
        },
      );

      test('should return conditions_met when pickup should execute', () {
        final context = ServiceExecutionContext(
          detectedObjects: [testObject],
          handLandmarks: [testHand],
          currentMode: ProcessingMode.full,
          isMemoryPressure: false,
          timestamp: DateTime.now(),
        );

        expect(context.shouldExecutePickupService(), true);
        expect(context.getExecutionReason(), 'conditions_met');
      });
    });
  });
}
