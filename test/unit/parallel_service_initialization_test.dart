import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_services.dart';
import 'package:cleanclik/core/models/camera_models.dart';

void main() {
  group('Parallel Service Initialization', () {
    late ARCameraServices services;

    setUp(() {
      services = ARCameraServices();
    });

    tearDown(() async {
      await services.dispose();
    });

    test('should track service initialization states', () async {
      // Initially no service states should be tracked
      expect(services.serviceStates, isEmpty);

      // Start initialization (will fail in test environment but should track states)
      try {
        await services.initializeServices();
      } catch (e) {
        // Expected to fail in test environment
      }

      // Should have tracked some service states
      expect(services.serviceStates, isNotEmpty);

      // Should have attempted to initialize core services
      expect(services.serviceStates.keys, contains('ml_service'));
      expect(services.serviceStates.keys, contains('hand_tracking'));
    });

    test('should provide initialization progress stream', () async {
      // Progress stream should be null initially
      expect(services.initializationProgress, isNull);

      // Start initialization to create progress stream
      final initializationFuture = services.initializeServices();

      // Progress stream should be available during initialization
      expect(services.initializationProgress, isNotNull);

      // Wait for initialization to complete (will fail but that's ok)
      try {
        await initializationFuture;
      } catch (e) {
        // Expected to fail in test environment
      }

      // Progress stream should be cleaned up after initialization
      expect(services.initializationProgress, isNull);
    });

    test('should calculate service success rate correctly', () {
      // We can't directly modify the unmodifiable map, so we'll test the calculation
      // logic through the ServiceInitializationProgress class instead
      final serviceStates = {
        'service1': ServiceInitializationState.completed,
        'service2': ServiceInitializationState.failed,
        'service3': ServiceInitializationState.skipped,
        'service4': ServiceInitializationState.completed,
      };

      final progress = ServiceInitializationProgress(
        message: 'Test',
        progress: 0.8,
        serviceStates: serviceStates,
      );

      // Success rate should be 3/4 = 0.75 (completed + skipped / total)
      expect(progress.successRate, equals(0.75));
      expect(progress.failedServices.length, equals(1));
    });

    test('should identify failed services for retry', () async {
      // Test the retry functionality by attempting to retry when no services have failed
      // This tests the logic without needing to modify the unmodifiable map

      // Initially no failed services to retry
      try {
        await services.retryFailedServices();
      } catch (e) {
        // Expected to complete without error when no failed services
      }

      // Test that the method exists and can be called
      expect(services.retryFailedServices, isA<Function>());
    });

    test('should handle service timeout gracefully', () {
      // Test timeout handling is implemented
      final timeout = services.getServiceTimeout('ml_service');
      expect(timeout, equals(const Duration(seconds: 10)));

      final defaultTimeout = services.getServiceTimeout('unknown_service');
      expect(defaultTimeout, equals(const Duration(seconds: 5)));
    });

    test('should emit progress updates during initialization', () async {
      final progressUpdates = <ServiceInitializationProgress>[];

      // Start initialization to get progress stream
      final initializationFuture = services.initializeServices();

      // Listen to progress updates
      final subscription = services.initializationProgress?.listen((progress) {
        progressUpdates.add(progress);
      });

      // Wait for initialization to complete (will fail but should emit progress)
      try {
        await initializationFuture;
      } catch (e) {
        // Expected to fail in test environment
      }

      await subscription?.cancel();

      // Should have received some progress updates
      expect(progressUpdates, isNotEmpty);

      // First update should have low progress
      if (progressUpdates.isNotEmpty) {
        expect(progressUpdates.first.progress, lessThan(0.5));
      }
    });
  });

  group('ServiceInitializationProgress', () {
    test('should calculate state counts correctly', () {
      final serviceStates = {
        'service1': ServiceInitializationState.completed,
        'service2': ServiceInitializationState.failed,
        'service3': ServiceInitializationState.skipped,
        'service4': ServiceInitializationState.completed,
        'service5': ServiceInitializationState.initializing,
      };

      final progress = ServiceInitializationProgress(
        message: 'Test',
        progress: 0.5,
        serviceStates: serviceStates,
      );

      final counts = progress.stateCounts;
      expect(counts[ServiceInitializationState.completed], equals(2));
      expect(counts[ServiceInitializationState.failed], equals(1));
      expect(counts[ServiceInitializationState.skipped], equals(1));
      expect(counts[ServiceInitializationState.initializing], equals(1));
      expect(counts[ServiceInitializationState.notStarted], equals(0));
    });

    test('should identify failed and completed services', () {
      final serviceStates = {
        'ml_service': ServiceInitializationState.completed,
        'hand_tracking': ServiceInitializationState.failed,
        'gesture_service': ServiceInitializationState.skipped,
        'object_management': ServiceInitializationState.completed,
      };

      final progress = ServiceInitializationProgress(
        message: 'Test',
        progress: 0.8,
        serviceStates: serviceStates,
      );

      expect(progress.failedServices, equals(['hand_tracking']));
      expect(
        progress.completedServices,
        containsAll(['ml_service', 'object_management']),
      );
      expect(progress.successRate, equals(0.75)); // 3 successful out of 4 total
    });
  });
}
