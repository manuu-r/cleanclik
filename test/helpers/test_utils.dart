import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

/// Common test utilities and helper functions
class TestUtils {
  /// Default test timeout duration
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  /// ML processing threshold for performance tests
  static const Duration mlProcessingThreshold = Duration(milliseconds: 100);
  
  /// Camera switching threshold for performance tests
  static const Duration cameraSwitchingThreshold = Duration(milliseconds: 200);
  
  /// Supabase sync threshold for performance tests
  static const Duration supabaseSyncThreshold = Duration(seconds: 5);
  
  /// Coverage thresholds
  static const double coverageThreshold = 0.85;
  static const double serviceCoverageThreshold = 0.85;
  static const double criticalPathCoverageThreshold = 0.90;

  /// Wait for a condition to be true with timeout
  static Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (!condition() && stopwatch.elapsed < timeout) {
      await Future.delayed(interval);
    }
    
    if (!condition()) {
      throw TimeoutException(
        'Condition not met within timeout',
        timeout,
      );
    }
  }

  /// Wait for async operations to complete
  static Future<void> waitForAsyncOperations([
    Duration delay = const Duration(milliseconds: 100),
  ]) async {
    await Future.delayed(delay);
  }

  /// Simulate network delay for realistic testing
  static Future<void> simulateNetworkDelay([
    Duration? delay,
  ]) async {
    final random = Random();
    final networkDelay = delay ?? 
        Duration(milliseconds: 200 + random.nextInt(300));
    await Future.delayed(networkDelay);
  }

  /// Simulate processing delay for ML operations
  static Future<void> simulateMLProcessingDelay([
    Duration? delay,
  ]) async {
    final random = Random();
    final processingDelay = delay ?? 
        Duration(milliseconds: 50 + random.nextInt(100));
    await Future.delayed(processingDelay);
  }

  /// Generate random string for testing
  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Generate random email for testing
  static String generateRandomEmail() {
    return '${generateRandomString(8)}@example.com';
  }

  /// Generate random user ID for testing
  static String generateRandomUserId() {
    return 'user-${generateRandomString(12)}';
  }

  /// Create a completer that resolves after a delay
  static Completer<T> createDelayedCompleter<T>(
    T value, [
    Duration delay = const Duration(milliseconds: 100),
  ]) {
    final completer = Completer<T>();
    Timer(delay, () => completer.complete(value));
    return completer;
  }

  /// Create a stream that emits values with delays
  static Stream<T> createDelayedStream<T>(
    List<T> values, [
    Duration interval = const Duration(milliseconds: 100),
  ]) async* {
    for (final value in values) {
      await Future.delayed(interval);
      yield value;
    }
  }

  /// Verify that a mock was called with specific arguments
  static void verifyMockCall(
    Mock mock,
    String method,
    List<dynamic> arguments,
  ) {
    verify(mock.noSuchMethod(
      Invocation.method(Symbol(method), arguments),
    ));
  }

  /// Reset all mocks in a list
  static void resetMocks(List<Mock> mocks) {
    for (final mock in mocks) {
      reset(mock);
    }
  }

  /// Create a mock method channel for platform testing
  static void setUpMockMethodChannel(
    String channelName,
    Map<String, dynamic> responses,
  ) {
    const channel = MethodChannel('test_channel');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return responses[call.method];
    });
  }

  /// Clean up mock method channels
  static void tearDownMockMethodChannels() {
    // Reset all method channel handlers
    // Note: In newer Flutter versions, this cleanup is handled automatically
  }

  /// Measure execution time of a function
  static Future<Duration> measureExecutionTime(
    Future<void> Function() function,
  ) async {
    final stopwatch = Stopwatch()..start();
    await function();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Verify performance threshold
  static void verifyPerformanceThreshold(
    Duration actualTime,
    Duration threshold,
    String operation,
  ) {
    expect(
      actualTime,
      lessThan(threshold),
      reason: '$operation took ${actualTime.inMilliseconds}ms, '
          'expected less than ${threshold.inMilliseconds}ms',
    );
  }

  /// Create a test-specific random seed for reproducible tests
  static int createTestSeed([String? testName]) {
    if (testName != null) {
      return testName.hashCode;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Set up random seed for reproducible tests
  static void setUpReproducibleRandom(int seed) {
    // This would be used with Random(seed) in test code
  }

  /// Verify that no exceptions were thrown during test
  static void verifyNoExceptions(WidgetTester tester) {
    expect(tester.takeException(), isNull);
  }

  /// Create a test timeout for async operations
  static Timeout createTestTimeout([Duration? duration]) {
    return Timeout(duration ?? defaultTimeout);
  }

  /// Pump widget and wait for animations to complete
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, [
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Simulate user interaction delay
  static Future<void> simulateUserDelay([
    Duration delay = const Duration(milliseconds: 300),
  ]) async {
    await Future.delayed(delay);
  }

  /// Create a mock stream controller for testing
  static StreamController<T> createMockStreamController<T>() {
    return StreamController<T>.broadcast();
  }

  /// Dispose of stream controllers safely
  static Future<void> disposeStreamControllers(
    List<StreamController> controllers,
  ) async {
    for (final controller in controllers) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  /// Verify stream emissions in order
  static Future<void> verifyStreamEmissions<T>(
    Stream<T> stream,
    List<T> expectedValues, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final actualValues = <T>[];
    final subscription = stream.listen(actualValues.add);
    
    await waitForCondition(
      () => actualValues.length >= expectedValues.length,
      timeout: timeout,
    );
    
    await subscription.cancel();
    
    expect(actualValues, equals(expectedValues));
  }

  /// Create a test environment configuration
  static Map<String, dynamic> createTestEnvironment({
    bool enableLogging = false,
    bool enablePerformanceTracking = false,
    String? supabaseUrl,
    String? supabaseKey,
  }) {
    return {
      'enableLogging': enableLogging,
      'enablePerformanceTracking': enablePerformanceTracking,
      'supabaseUrl': supabaseUrl ?? 'https://test.supabase.co',
      'supabaseKey': supabaseKey ?? 'test-key',
    };
  }
}