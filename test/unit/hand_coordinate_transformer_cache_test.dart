import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/services/platform/hand_coordinate_transformer.dart';

void main() {
  group('HandCoordinateTransformer Caching', () {
    setUp(() {
      // Clear cache before each test
      HandCoordinateTransformer.clearCache();
    });

    test('should cache transformation results', () {
      // Arrange
      final landmarks = [
        const Offset(0.5, 0.5), // wrist
        const Offset(0.4, 0.4),
        const Offset(0.3, 0.3),
        const Offset(0.2, 0.2),
        const Offset(0.1, 0.1),
        const Offset(0.6, 0.4), // index MCP
        const Offset(0.7, 0.3),
        const Offset(0.8, 0.2),
        const Offset(0.9, 0.1),
        const Offset(0.5, 0.6), // middle MCP
        const Offset(0.4, 0.7),
        const Offset(0.3, 0.8),
        const Offset(0.2, 0.9),
        const Offset(0.6, 0.6), // ring MCP
        const Offset(0.7, 0.7),
        const Offset(0.8, 0.8),
        const Offset(0.9, 0.9),
        const Offset(0.4, 0.6), // pinky MCP
        const Offset(0.3, 0.7),
        const Offset(0.2, 0.8),
        const Offset(0.1, 0.9),
      ];
      const screenSize = Size(800, 600);
      const imageSize = Size(640, 480);

      // Act - First call
      final result1 = HandCoordinateTransformer.transformHandCenter(
        landmarks,
        screenSize,
        imageSize,
      );

      // Act - Second call with same parameters
      final result2 = HandCoordinateTransformer.transformHandCenter(
        landmarks,
        screenSize,
        imageSize,
      );

      // Assert
      expect(result1.screenCoordinates, equals(result2.screenCoordinates));
      expect(result1.isValid, equals(result2.isValid));
      expect(result2.debugInfo['cache_hit'], equals('true'));

      final stats = HandCoordinateTransformer.getCacheStats();
      expect(stats['total_entries'], equals(1));
      expect(stats['active_entries'], equals(1));
    });

    test('should generate different cache keys for different landmarks', () {
      // Arrange
      final landmarks1 = [
        const Offset(0.5, 0.5), // Different landmarks
        const Offset(0.4, 0.4),
        const Offset(0.3, 0.3),
        const Offset(0.2, 0.2),
        const Offset(0.1, 0.1),
        const Offset(0.6, 0.4),
        const Offset(0.7, 0.3),
        const Offset(0.8, 0.2),
        const Offset(0.9, 0.1),
        const Offset(0.5, 0.6),
        const Offset(0.4, 0.7),
        const Offset(0.3, 0.8),
        const Offset(0.2, 0.9),
        const Offset(0.6, 0.6),
        const Offset(0.7, 0.7),
        const Offset(0.8, 0.8),
        const Offset(0.9, 0.9),
        const Offset(0.4, 0.6),
        const Offset(0.3, 0.7),
        const Offset(0.2, 0.8),
        const Offset(0.1, 0.9),
      ];

      final landmarks2 = [
        const Offset(0.6, 0.6), // Different landmarks
        const Offset(0.5, 0.5),
        const Offset(0.4, 0.4),
        const Offset(0.3, 0.3),
        const Offset(0.2, 0.2),
        const Offset(0.7, 0.5),
        const Offset(0.8, 0.4),
        const Offset(0.9, 0.3),
        const Offset(1.0, 0.2),
        const Offset(0.6, 0.7),
        const Offset(0.5, 0.8),
        const Offset(0.4, 0.9),
        const Offset(0.3, 1.0),
        const Offset(0.7, 0.7),
        const Offset(0.8, 0.8),
        const Offset(0.9, 0.9),
        const Offset(1.0, 1.0),
        const Offset(0.5, 0.7),
        const Offset(0.4, 0.8),
        const Offset(0.3, 0.9),
        const Offset(0.2, 1.0),
      ];

      const screenSize = Size(800, 600);
      const imageSize = Size(640, 480);

      // Act
      HandCoordinateTransformer.transformHandCenter(
        landmarks1,
        screenSize,
        imageSize,
      );
      HandCoordinateTransformer.transformHandCenter(
        landmarks2,
        screenSize,
        imageSize,
      );

      // Assert
      final stats = HandCoordinateTransformer.getCacheStats();
      expect(stats['total_entries'], equals(2)); // Two different cache entries
    });

    test('should generate different cache keys for different screen sizes', () {
      // Arrange
      final landmarks = List.generate(
        21,
        (i) => Offset(0.5 + i * 0.01, 0.5 + i * 0.01),
      );
      const screenSize1 = Size(800, 600);
      const screenSize2 = Size(1024, 768);
      const imageSize = Size(640, 480);

      // Act
      HandCoordinateTransformer.transformHandCenter(
        landmarks,
        screenSize1,
        imageSize,
      );
      HandCoordinateTransformer.transformHandCenter(
        landmarks,
        screenSize2,
        imageSize,
      );

      // Assert
      final stats = HandCoordinateTransformer.getCacheStats();
      expect(stats['total_entries'], equals(2)); // Two different cache entries
    });

    test('should expire cache entries after timeout', () async {
      // Arrange
      final landmarks = List.generate(21, (i) => Offset(0.5, 0.5));
      const screenSize = Size(800, 600);
      const imageSize = Size(640, 480);

      // Act - First call
      final result1 = HandCoordinateTransformer.transformHandCenter(
        landmarks,
        screenSize,
        imageSize,
      );

      // Wait for cache to expire (100ms + buffer)
      await Future.delayed(const Duration(milliseconds: 150));

      // Act - Second call after expiration
      final result2 = HandCoordinateTransformer.transformHandCenter(
        landmarks,
        screenSize,
        imageSize,
      );

      // Assert
      expect(result1.screenCoordinates, equals(result2.screenCoordinates));
      expect(
        result2.debugInfo['cache_hit'],
        equals('false'),
      ); // Cache miss due to expiration
    });

    test('should handle empty landmarks gracefully', () {
      // Arrange
      final emptyLandmarks = <Offset>[];
      const screenSize = Size(800, 600);
      const imageSize = Size(640, 480);

      // Act
      final result1 = HandCoordinateTransformer.transformHandCenter(
        emptyLandmarks,
        screenSize,
        imageSize,
      );
      final result2 = HandCoordinateTransformer.transformHandCenter(
        emptyLandmarks,
        screenSize,
        imageSize,
      );

      // Assert
      expect(result1.isValid, isFalse);
      expect(result2.isValid, isFalse);
      expect(
        result2.debugInfo['cache_hit'],
        equals('true'),
      ); // Should still cache invalid results
    });

    test('should enforce cache size limits', () {
      // Arrange
      const screenSize = Size(800, 600);
      const imageSize = Size(640, 480);

      // Act - Create more cache entries than the limit (50)
      for (int i = 0; i < 60; i++) {
        final landmarks = List.generate(
          21,
          (j) => Offset(0.5 + i * 0.001, 0.5 + j * 0.001),
        );
        HandCoordinateTransformer.transformHandCenter(
          landmarks,
          screenSize,
          imageSize,
        );
      }

      // Assert
      final stats = HandCoordinateTransformer.getCacheStats();
      expect(
        stats['total_entries'],
        lessThanOrEqualTo(50),
      ); // Should not exceed max size
    });

    test('should provide accurate cache statistics', () {
      // Arrange
      final landmarks = List.generate(21, (i) => Offset(0.5, 0.5));
      const screenSize = Size(800, 600);
      const imageSize = Size(640, 480);

      // Act
      HandCoordinateTransformer.transformHandCenter(
        landmarks,
        screenSize,
        imageSize,
      );
      final stats = HandCoordinateTransformer.getCacheStats();

      // Assert
      expect(stats['total_entries'], equals(1));
      expect(stats['active_entries'], equals(1));
      expect(stats['expired_entries'], equals(0));
      expect(stats['max_size'], equals(50));
      expect(stats['timeout_ms'], equals(100));
    });
  });
}
