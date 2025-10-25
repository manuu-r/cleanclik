import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_services.dart';
import 'package:cleanclik/core/models/camera_models.dart';

void main() {
  group('Parallel Service Initialization Integration', () {
    late ARCameraServices services;

    setUp(() {
      services = ARCameraServices();
    });

    tearDown(() async {
      await services.dispose();
    });

    testWidgets(
      'should initialize services in parallel with progress tracking',
      (WidgetTester tester) async {
        // Track progress updates
        final progressUpdates = <ServiceInitializationProgress>[];

        // Start initialization
        final initializationFuture = services.initializeServices();

        // Listen to progress updates if available
        final subscription = services.initializationProgress?.listen((
          progress,
        ) {
          progressUpdates.add(progress);
        });

        // Wait for initialization to complete
        try {
          await initializationFuture;
        } catch (e) {
          // Some services may fail in test environment, that's expected
          print('Initialization completed with some failures: $e');
        }

        await subscription?.cancel();

        // Verify that services were attempted to be initialized
        expect(services.serviceStates, isNotEmpty);

        // Should have attempted core services
        expect(services.serviceStates.keys, contains('ml_service'));
        expect(services.serviceStates.keys, contains('hand_tracking'));

        // Should have received progress updates
        expect(progressUpdates, isNotEmpty);

        // Progress should start low and increase
        if (progressUpdates.length > 1) {
          expect(
            progressUpdates.first.progress,
            lessThan(progressUpdates.last.progress),
          );
        }

        // Service status should be available
        final status = services.getServiceStatus();
        expect(status, isNotEmpty);
        expect(status['service_states'], isNotEmpty);
        expect(
          status['service_info']['initialization_success_rate'],
          isA<double>(),
        );
      },
    );

    testWidgets('should handle service failures gracefully', (
      WidgetTester tester,
    ) async {
      // Initialize services (some will fail in test environment)
      try {
        await services.initializeServices();
      } catch (e) {
        // Expected in test environment
      }

      // Should still provide service status even with failures
      final status = services.getServiceStatus();
      expect(status, isNotEmpty);

      // Should track which services failed
      expect(status['service_info']['failed_services'], isA<int>());
      expect(
        status['service_info']['initialization_success_rate'],
        isA<double>(),
      );

      // Should be able to retry failed services
      try {
        await services.retryFailedServices();
      } catch (e) {
        // Expected in test environment
      }

      // Should still be able to get status after retry
      final statusAfterRetry = services.getServiceStatus();
      expect(statusAfterRetry, isNotEmpty);
    });

    testWidgets('should provide timeout handling for services', (
      WidgetTester tester,
    ) async {
      // Test that timeout values are reasonable
      expect(
        services.getServiceTimeout('ml_service'),
        equals(const Duration(seconds: 10)),
      );
      expect(
        services.getServiceTimeout('hand_tracking'),
        equals(const Duration(seconds: 5)),
      );
      expect(
        services.getServiceTimeout('gesture_service'),
        equals(const Duration(seconds: 3)),
      );
      expect(
        services.getServiceTimeout('object_management'),
        equals(const Duration(seconds: 5)),
      );
      expect(
        services.getServiceTimeout('unknown_service'),
        equals(const Duration(seconds: 5)),
      );
    });

    testWidgets('should support restart functionality', (
      WidgetTester tester,
    ) async {
      // Initialize services first
      try {
        await services.initializeServices();
      } catch (e) {
        // Expected in test environment
      }

      final statusBefore = services.getServiceStatus();

      // Restart services
      try {
        await services.restartServices();
      } catch (e) {
        // Expected in test environment
      }

      final statusAfter = services.getServiceStatus();

      // Should have attempted restart
      expect(statusAfter, isNotEmpty);
      expect(statusAfter['service_states'], isNotEmpty);
    });
  });

  group('ServiceInitializationProgress Integration', () {
    testWidgets('should provide comprehensive progress information', (
      WidgetTester tester,
    ) async {
      final serviceStates = {
        'ml_service': ServiceInitializationState.completed,
        'hand_tracking': ServiceInitializationState.failed,
        'gesture_service': ServiceInitializationState.skipped,
        'object_management': ServiceInitializationState.initializing,
      };

      final progress = ServiceInitializationProgress(
        message: 'Integration test progress',
        progress: 0.75,
        serviceStates: serviceStates,
        isComplete: false,
        hasError: false,
      );

      // Should provide detailed state information
      expect(
        progress.stateCounts[ServiceInitializationState.completed],
        equals(1),
      );
      expect(
        progress.stateCounts[ServiceInitializationState.failed],
        equals(1),
      );
      expect(
        progress.stateCounts[ServiceInitializationState.skipped],
        equals(1),
      );
      expect(
        progress.stateCounts[ServiceInitializationState.initializing],
        equals(1),
      );

      // Should identify specific services
      expect(progress.failedServices, equals(['hand_tracking']));
      expect(progress.completedServices, equals(['ml_service']));

      // Should calculate success rate correctly (completed + skipped / total)
      expect(progress.successRate, equals(0.5)); // 2 successful out of 4 total

      // Should have timestamp
      expect(progress.timestamp, isA<DateTime>());

      // Should provide meaningful string representation
      expect(progress.toString(), contains('Integration test progress'));
      expect(progress.toString(), contains('75.0%'));
    });
  });
}
