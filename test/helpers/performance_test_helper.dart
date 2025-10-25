import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/services/data/performance_monitor.dart';

/// Helper class for testing performance monitoring functionality
class PerformanceTestHelper {
  static const Duration defaultOperationDuration = Duration(milliseconds: 100);
  static const Duration slowOperationDuration = Duration(milliseconds: 600);
  static const Duration fastOperationDuration = Duration(milliseconds: 20);

  /// Create a mock operation metrics with specified parameters
  static OperationMetrics createMockOperationMetrics({
    String operation = 'test_operation',
    String table = 'test_table',
    Duration? duration,
    bool success = true,
    String? errorType,
    int? retryCount,
    bool cacheHit = false,
    int? resultSize,
  }) {
    final startTime = DateTime.now();
    final endTime = startTime.add(duration ?? defaultOperationDuration);

    return OperationMetrics(
      operation: operation,
      table: table,
      startTime: startTime,
      endTime: endTime,
      success: success,
      errorType: errorType,
      retryCount: retryCount,
      cacheHit: cacheHit,
      resultSize: resultSize,
    );
  }

  /// Create multiple operation metrics with varying characteristics
  static List<OperationMetrics> createMockOperationBatch({
    int count = 10,
    String operation = 'batch_operation',
    String table = 'batch_table',
    double successRate = 1.0,
    double cacheHitRate = 0.5,
    Duration? baseDuration,
  }) {
    final operations = <OperationMetrics>[];
    final random = Random();
    final baseMs = (baseDuration ?? defaultOperationDuration).inMilliseconds;

    for (int i = 0; i < count; i++) {
      final isSuccess = random.nextDouble() < successRate;
      final isCacheHit = random.nextDouble() < cacheHitRate;
      final variationMs = random.nextInt(50) - 25; // ±25ms variation
      final duration = Duration(milliseconds: baseMs + variationMs);

      operations.add(
        createMockOperationMetrics(
          operation: operation,
          table: table,
          duration: duration,
          success: isSuccess,
          errorType: isSuccess ? null : 'test_error',
          cacheHit: isCacheHit,
          resultSize: random.nextInt(100) + 1,
        ),
      );
    }

    return operations;
  }

  /// Simulate a realistic user session with various operations
  static List<OperationMetrics> createUserSessionOperations(String userId) {
    final operations = <OperationMetrics>[];

    // User profile load (usually cached after first load)
    operations.add(
      createMockOperationMetrics(
        operation: 'getUserProfile',
        table: 'profiles',
        duration: const Duration(milliseconds: 150),
        cacheHit: false,
      ),
    );

    // Subsequent profile access (cache hit)
    operations.add(
      createMockOperationMetrics(
        operation: 'getUserProfile',
        table: 'profiles',
        duration: const Duration(milliseconds: 10),
        cacheHit: true,
      ),
    );

    // Load user inventory
    operations.add(
      createMockOperationMetrics(
        operation: 'getInventoryByUserId',
        table: 'inventory',
        duration: const Duration(milliseconds: 200),
        cacheHit: false,
        resultSize: 15,
      ),
    );

    // Load leaderboard
    operations.add(
      createMockOperationMetrics(
        operation: 'getLeaderboard',
        table: 'leaderboard_view',
        duration: const Duration(milliseconds: 300),
        cacheHit: false,
        resultSize: 50,
      ),
    );

    // Add new inventory item
    operations.add(
      createMockOperationMetrics(
        operation: 'create',
        table: 'inventory',
        duration: const Duration(milliseconds: 120),
        cacheHit: false,
        resultSize: 1,
      ),
    );

    // Get user rank
    operations.add(
      createMockOperationMetrics(
        operation: 'getUserRank',
        table: 'leaderboard_view',
        duration: const Duration(milliseconds: 80),
        cacheHit: true,
        resultSize: 1,
      ),
    );

    return operations;
  }

  /// Simulate high-load scenario with many concurrent operations
  static List<OperationMetrics> createHighLoadOperations({
    int operationCount = 100,
    double errorRate = 0.05,
  }) {
    final operations = <OperationMetrics>[];
    final random = Random();
    final tables = ['users', 'inventory', 'achievements', 'leaderboard_view'];
    final operationTypes = ['findById', 'create', 'update', 'query'];

    for (int i = 0; i < operationCount; i++) {
      final table = tables[random.nextInt(tables.length)];
      final operation = operationTypes[random.nextInt(operationTypes.length)];
      final isError = random.nextDouble() < errorRate;

      // Simulate varying load - some operations are slower under load
      final baseLatency = 50 + random.nextInt(200);
      final loadFactor = 1.0 + (i / operationCount) * 0.5; // Increasing load
      final duration = Duration(
        milliseconds: (baseLatency * loadFactor).round(),
      );

      operations.add(
        createMockOperationMetrics(
          operation: operation,
          table: table,
          duration: duration,
          success: !isError,
          errorType: isError ? 'load_error' : null,
          cacheHit: random.nextBool(),
          resultSize: random.nextInt(50) + 1,
        ),
      );
    }

    return operations;
  }

  /// Setup a performance monitor with realistic data
  static DataServicePerformanceMonitor setupRealisticPerformanceMonitor({
    bool includeUserSession = true,
    bool includeHighLoad = false,
    bool includeCacheMetrics = true,
    bool includeConnectionMetrics = true,
  }) {
    final monitor = DataServicePerformanceMonitor(autoReport: false);

    if (includeUserSession) {
      final sessionOps = createUserSessionOperations('test_user_123');
      for (final op in sessionOps) {
        monitor.recordOperation(op);
      }
    }

    if (includeHighLoad) {
      final loadOps = createHighLoadOperations(operationCount: 50);
      for (final op in loadOps) {
        monitor.recordOperation(op);
      }
    }

    if (includeCacheMetrics) {
      // Simulate realistic cache behavior
      for (int i = 0; i < 20; i++) {
        monitor.recordCacheHit();
      }
      for (int i = 0; i < 5; i++) {
        monitor.recordCacheMiss();
      }
      monitor.recordCacheEviction();
      monitor.recordCacheExpiration();
      monitor.updateCacheSize(40, 50);
    }

    if (includeConnectionMetrics) {
      // Simulate connection activity
      for (int i = 0; i < 10; i++) {
        monitor.recordConnection(Duration(milliseconds: 30 + i * 5));
      }
      monitor.recordConnectionFailure();
      monitor.recordTimeout();
      monitor.recordDisconnection();
    }

    return monitor;
  }

  /// Assert that performance metrics meet expected thresholds
  static void assertPerformanceThresholds(
    Map<String, dynamic> report, {
    double minSuccessRate = 0.95,
    double minCacheHitRate = 0.7,
    double maxFailureRate = 0.05,
    double maxAverageLatencyMs = 500.0,
  }) {
    final operations = report['operations'] as Map<String, dynamic>;
    final cache = report['cache'] as Map<String, dynamic>;
    final connections = report['connections'] as Map<String, dynamic>;
    final performance = report['performance'] as Map<String, dynamic>;

    // Check operation success rate
    final successRate = operations['successRate'] as double;
    expect(
      successRate,
      greaterThanOrEqualTo(minSuccessRate),
      reason: 'Success rate $successRate is below threshold $minSuccessRate',
    );

    // Check cache hit rate (if cache data exists)
    if (cache['hits'] != null && cache['misses'] != null) {
      final hitRate = cache['hitRate'] as double;
      expect(
        hitRate,
        greaterThanOrEqualTo(minCacheHitRate),
        reason: 'Cache hit rate $hitRate is below threshold $minCacheHitRate',
      );
    }

    // Check connection failure rate (if connection data exists)
    if (connections['totalConnections'] != null &&
        (connections['totalConnections'] as int) > 0) {
      final failureRate = connections['failureRate'] as double;
      expect(
        failureRate,
        lessThanOrEqualTo(maxFailureRate),
        reason:
            'Connection failure rate $failureRate exceeds threshold $maxFailureRate',
      );
    }

    // Check average latency
    final avgLatency = performance['averageLatencyMs'] as double;
    expect(
      avgLatency,
      lessThanOrEqualTo(maxAverageLatencyMs),
      reason:
          'Average latency ${avgLatency}ms exceeds threshold ${maxAverageLatencyMs}ms',
    );
  }

  /// Assert that performance is healthy according to monitor's criteria
  static void assertHealthyPerformance(DataServicePerformanceMonitor monitor) {
    expect(
      monitor.isHealthy,
      isTrue,
      reason: 'Performance monitor indicates unhealthy state',
    );
  }

  /// Assert that performance is unhealthy (for testing degradation scenarios)
  static void assertUnhealthyPerformance(
    DataServicePerformanceMonitor monitor,
  ) {
    expect(
      monitor.isHealthy,
      isFalse,
      reason: 'Performance monitor should indicate unhealthy state',
    );
  }

  /// Create a performance monitor with poor metrics for testing
  static DataServicePerformanceMonitor setupPoorPerformanceMonitor() {
    final monitor = DataServicePerformanceMonitor(autoReport: false);

    // Add operations with poor success rate
    for (int i = 0; i < 10; i++) {
      monitor.recordOperation(
        createMockOperationMetrics(
          success: i < 8, // 80% success rate (below 95% threshold)
          duration: slowOperationDuration, // Slow operations
          errorType: i >= 8 ? 'performance_error' : null,
        ),
      );
    }

    // Poor cache performance
    for (int i = 0; i < 10; i++) {
      monitor.recordCacheMiss(); // All misses (0% hit rate)
    }

    // Connection issues
    for (int i = 0; i < 5; i++) {
      monitor.recordConnectionFailure();
    }
    monitor.recordConnection(const Duration(milliseconds: 100));

    return monitor;
  }

  /// Wait for async operations to complete in tests
  static Future<void> waitForAsyncOperations() async {
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Create a timer-based test scenario
  static Future<void> simulateTimeBasedScenario(
    DataServicePerformanceMonitor monitor,
    Duration duration,
    int operationsPerSecond,
  ) async {
    final totalOperations = (duration.inSeconds * operationsPerSecond);
    final intervalMs = 1000 ~/ operationsPerSecond;

    for (int i = 0; i < totalOperations; i++) {
      monitor.recordOperation(
        createMockOperationMetrics(operation: 'timed_operation_$i'),
      );

      if (i < totalOperations - 1) {
        await Future.delayed(Duration(milliseconds: intervalMs));
      }
    }
  }

  /// Validate that metrics are within expected ranges
  static void validateMetricRanges(Map<String, dynamic> report) {
    final operations = report['operations'] as Map<String, dynamic>;
    final cache = report['cache'] as Map<String, dynamic>;
    final performance = report['performance'] as Map<String, dynamic>;

    // Validate operation metrics
    expect(operations['total'], isA<int>());
    expect(operations['successful'], isA<int>());
    expect(operations['failed'], isA<int>());
    expect(operations['successRate'], isA<double>());
    expect(operations['successRate'], inInclusiveRange(0.0, 1.0));

    // Validate cache metrics
    expect(cache['hits'], isA<int>());
    expect(cache['misses'], isA<int>());
    expect(cache['hitRate'], isA<double>());
    expect(cache['hitRate'], inInclusiveRange(0.0, 1.0));
    expect(cache['utilization'], isA<double>());
    expect(cache['utilization'], inInclusiveRange(0.0, 1.0));

    // Validate performance metrics
    expect(performance['averageLatencyMs'], isA<double>());
    expect(performance['averageLatencyMs'], greaterThanOrEqualTo(0.0));
    expect(performance['p95LatencyMs'], isA<int>());
    expect(performance['p95LatencyMs'], greaterThanOrEqualTo(0));
    expect(performance['p99LatencyMs'], isA<int>());
    expect(performance['p99LatencyMs'], greaterThanOrEqualTo(0));
  }

  /// Create test data for specific scenarios
  static Map<String, dynamic> createTestScenario(String scenarioName) {
    switch (scenarioName) {
      case 'healthy_system':
        return {
          'operations': createMockOperationBatch(
            count: 100,
            successRate: 0.98,
            cacheHitRate: 0.85,
          ),
          'expectedHealth': true,
        };

      case 'degraded_performance':
        return {
          'operations': createMockOperationBatch(
            count: 100,
            successRate: 0.92,
            cacheHitRate: 0.60,
            baseDuration: slowOperationDuration,
          ),
          'expectedHealth': false,
        };

      case 'cache_thrashing':
        return {
          'operations': createMockOperationBatch(
            count: 100,
            successRate: 0.96,
            cacheHitRate: 0.20, // Very poor cache performance
          ),
          'expectedHealth': false,
        };

      case 'connection_issues':
        return {
          'operations': createMockOperationBatch(
            count: 50,
            successRate: 0.85, // Many connection failures
          ),
          'expectedHealth': false,
        };

      default:
        throw ArgumentError('Unknown test scenario: $scenarioName');
    }
  }
}

/// Extension methods for easier testing
extension PerformanceMonitorTestExtensions on DataServicePerformanceMonitor {
  /// Add a batch of test operations
  void addTestOperations(List<OperationMetrics> operations) {
    for (final operation in operations) {
      recordOperation(operation);
    }
  }

  /// Add realistic cache activity
  void addTestCacheActivity({
    int hits = 10,
    int misses = 3,
    int evictions = 1,
    int expirations = 0,
    int currentSize = 25,
    int maxSize = 50,
  }) {
    for (int i = 0; i < hits; i++) {
      recordCacheHit();
    }
    for (int i = 0; i < misses; i++) {
      recordCacheMiss();
    }
    for (int i = 0; i < evictions; i++) {
      recordCacheEviction();
    }
    for (int i = 0; i < expirations; i++) {
      recordCacheExpiration();
    }
    updateCacheSize(currentSize, maxSize);
  }

  /// Add test connection activity
  void addTestConnectionActivity({
    int connections = 5,
    int failures = 1,
    int timeouts = 0,
    Duration avgConnectionTime = const Duration(milliseconds: 50),
  }) {
    for (int i = 0; i < connections; i++) {
      final variation = Duration(milliseconds: i * 10);
      recordConnection(avgConnectionTime + variation);
    }
    for (int i = 0; i < failures; i++) {
      recordConnectionFailure();
    }
    for (int i = 0; i < timeouts; i++) {
      recordTimeout();
    }
  }
}
