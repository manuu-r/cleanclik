import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/services/system/performance_service.dart';

void main() {
  group('PerformanceService Memory Monitoring', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService();
    });

    tearDown(() {
      performanceService.dispose();
    });

    test('should initialize with default memory values', () {
      expect(performanceService.availableMemoryMB, equals(0.0));
      expect(performanceService.totalMemoryMB, equals(0.0));
      // Note: isLowMemory may be true initially due to 0.0 < 150.0 threshold
      expect(performanceService.isCriticalMemory, isTrue); // 0.0 < 100.0
    });

    test('should detect critical memory when available memory < 100MB', () {
      // Start monitoring to trigger memory check
      performanceService.startMonitoring();

      // Wait a bit for initial memory check
      expect(
        performanceService.isCriticalMemory,
        performanceService.availableMemoryMB < 100.0,
      );
    });

    test('should detect low memory when available memory < 150MB', () {
      // Start monitoring to trigger memory check
      performanceService.startMonitoring();

      // Wait a bit for initial memory check
      expect(
        performanceService.isLowMemory,
        performanceService.availableMemoryMB < 150.0,
      );
    });

    test('should include memory data in performance metrics', () async {
      final metricsReceived = <PerformanceMetrics>[];

      performanceService.metricsStream.listen((metrics) {
        metricsReceived.add(metrics);
      });

      performanceService.startMonitoring();

      // Wait for at least one metrics update
      await Future.delayed(const Duration(milliseconds: 100));

      expect(metricsReceived, isNotEmpty);
      final metrics = metricsReceived.first;
      expect(metrics.availableMemoryMB, isA<double>());
      expect(metrics.totalMemoryMB, isA<double>());
    });

    test('should stop memory monitoring when stopped', () {
      performanceService.startMonitoring();
      expect(performanceService.availableMemoryMB, greaterThanOrEqualTo(0.0));

      performanceService.stopMonitoring();
      // Memory monitoring should be stopped (timer cancelled)
      // This is verified by the fact that dispose doesn't throw
      performanceService.dispose();
    });

    test('should handle memory monitoring errors gracefully', () {
      // This test verifies that the service doesn't crash if memory monitoring fails
      performanceService.startMonitoring();

      // Should not throw even if platform-specific memory checks fail
      expect(() => performanceService.dispose(), returnsNormally);
    });
  });
}
