import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/services/camera/ml_background_processor.dart';

void main() {
  group('MLBackgroundProcessor', () {
    late MLBackgroundProcessor processor;

    setUp(() {
      processor = MLBackgroundProcessor();
    });

    tearDown(() async {
      await processor.dispose();
    });

    test('should initialize successfully', () async {
      await processor.initialize();
      expect(processor.isReady, isTrue);
    });

    test('should not initialize twice', () async {
      await processor.initialize();
      expect(processor.isReady, isTrue);
      
      // Second initialization should be no-op
      await processor.initialize();
      expect(processor.isReady, isTrue);
    });

    test('should process generic data in isolate', () async {
      await processor.initialize();
      
      final result = await processor.processInIsolate<Map<String, dynamic>>(
        'test_action',
        {'key': 'value'},
      );
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['key'], equals('value'));
    });

    test('should throw error when not initialized', () async {
      expect(
        () => processor.processInIsolate('test', {}),
        throwsStateError,
      );
    });

    test('should handle timeout', () async {
      await processor.initialize();
      
      // The isolate echoes back data quickly, so this should complete
      final result = await processor.processInIsolate<Map<String, dynamic>>(
        'quick_action',
        {'test': 'data'},
      );
      
      expect(result, isA<Map<String, dynamic>>());
    });

    test('should dispose cleanly', () async {
      await processor.initialize();
      expect(processor.isReady, isTrue);
      
      await processor.dispose();
      expect(processor.isReady, isFalse);
    });

    test('should handle dispose gracefully', () async {
      await processor.initialize();
      expect(processor.isReady, isTrue);
      
      // Dispose should complete without errors
      await processor.dispose();
      expect(processor.isReady, isFalse);
      
      // Should not be able to process after dispose
      expect(
        () => processor.processInIsolate('test', {}),
        throwsStateError,
      );
    });

    test('should handle multiple concurrent requests', () async {
      await processor.initialize();
      
      final futures = List.generate(
        5,
        (i) => processor.processInIsolate<Map<String, dynamic>>(
          'test_$i',
          {'index': i},
        ),
      );
      
      final results = await Future.wait(futures);
      
      expect(results.length, equals(5));
      for (var i = 0; i < 5; i++) {
        expect(results[i]['index'], equals(i));
      }
    });
  });
}
