import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cleanclik/core/services/platform/hand_coordinate_transformer.dart';

void main() {
  group('HandCoordinateTransformer Performance', () {
    setUp(() {
      HandCoordinateTransformer.clearCache();
    });

    test('should show performance improvement with caching', () {
      // Arrange
      final landmarks = List.generate(
        21,
        (i) => Offset(0.5 + i * 0.01, 0.5 + i * 0.01),
      );
      const screenSize = Size(800, 600);
      const imageSize = Size(640, 480);
      const iterations = 1000;

      // Measure performance without cache (first call)
      final stopwatch1 = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        HandCoordinateTransformer.clearCache(); // Force cache miss
        HandCoordinateTransformer.transformHandCenter(
          landmarks,
          screenSize,
          imageSize,
        );
      }
      stopwatch1.stop();
      final timeWithoutCache = stopwatch1.elapsedMicroseconds;

      // Measure performance with cache (repeated calls)
      final stopwatch2 = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        HandCoordinateTransformer.transformHandCenter(
          landmarks,
          screenSize,
          imageSize,
        );
      }
      stopwatch2.stop();
      final timeWithCache = stopwatch2.elapsedMicroseconds;

      // Assert performance improvement
      // Debug output for performance analysis
      debugPrint('Time without cache: $timeWithoutCacheμs');
      debugPrint('Time with cache: $timeWithCacheμs');
      debugPrint(
        'Performance improvement: ${(timeWithoutCache / timeWithCache).toStringAsFixed(2)}x',
      );

      // Cache should be significantly faster (at least 2x improvement expected)
      expect(
        timeWithCache < timeWithoutCache / 2,
        isTrue,
        reason: 'Cache should provide at least 2x performance improvement',
      );

      // Verify cache statistics
      final stats = HandCoordinateTransformer.getCacheStats();
      expect(stats['total_entries'], equals(1));
      expect(stats['active_entries'], equals(1));
    });

    test('should maintain performance with different cache keys', () {
      // Arrange
      const screenSize = Size(800, 600);
      const imageSize = Size(640, 480);
      const iterations = 100;

      // Create different landmark sets
      final landmarkSets = List.generate(
        10,
        (i) => List.generate(21, (j) => Offset(0.5 + i * 0.01, 0.5 + j * 0.01)),
      );

      // Measure performance with multiple cache entries
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        for (final landmarks in landmarkSets) {
          HandCoordinateTransformer.transformHandCenter(
            landmarks,
            screenSize,
            imageSize,
          );
        }
      }
      stopwatch.stop();

      // Verify cache contains all entries
      final stats = HandCoordinateTransformer.getCacheStats();
      expect(stats['total_entries'], equals(10));
      expect(stats['active_entries'], equals(10));

      debugPrint(
        'Time for ${iterations * landmarkSets.length} transformations: ${stopwatch.elapsedMicroseconds}μs',
      );
      debugPrint(
        'Average time per transformation: ${(stopwatch.elapsedMicroseconds / (iterations * landmarkSets.length)).toStringAsFixed(2)}μs',
      );
    });
  });
}
