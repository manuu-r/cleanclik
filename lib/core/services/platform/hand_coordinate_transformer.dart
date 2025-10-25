import 'dart:ui';
import 'dart:math' as math;

/// Transforms MediaPipe 3D hand landmarks to Flutter 2D screen coordinates
/// Fixes the critical coordinate mapping failure causing all positions to be (0,0)
class HandCoordinateTransformer {
  // Cache for coordinate transformations
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTimeout = Duration(milliseconds: 100);
  static const int _maxCacheSize = 50; // Prevent memory growth
  /// Transform MediaPipe 3D hand landmarks to Flutter 2D screen coordinates
  static CoordinateTransformationResult transformHandCenter(
    List<Offset> normalizedLandmarks,
    Size screenSize,
    Size imageSize,
  ) {
    try {
      // Generate cache key based on landmarks and screen size
      final cacheKey = _generateCacheKey(
        normalizedLandmarks,
        screenSize,
        imageSize,
      );

      // Check cache first and clean up expired entries
      _cleanupExpiredEntries();
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        // Add cache hit indicator to debug info
        final cachedResult = CoordinateTransformationResult(
          screenCoordinates: cached.result.screenCoordinates,
          isValid: cached.result.isValid,
          errorMessage: cached.result.errorMessage,
          debugInfo: {...cached.result.debugInfo, 'cache_hit': 'true'},
        );
        return cachedResult;
      }

      // Calculate hand center from palm landmarks for stability
      final handCenter = _calculateHandCenterFromPalm(normalizedLandmarks);

      // Check for invalid input before transformation
      if (handCenter == Offset.zero && normalizedLandmarks.isEmpty) {
        final result = CoordinateTransformationResult(
          screenCoordinates: Offset.zero,
          isValid: false,
          errorMessage: 'No valid landmarks provided',
          debugInfo: {
            'error': 'Empty landmarks',
            'cache_hit': cached != null ? 'true' : 'false',
          },
        );

        // Cache the invalid result too
        if (cached == null) {
          _cacheResult(cacheKey, result);
        }

        return result;
      }

      // Transform normalized coordinates to screen coordinates
      final screenCoordinates = _applyTransformation(
        handCenter,
        screenSize,
        imageSize,
      );

      // Validate coordinates
      final isValid = _validateCoordinates(screenCoordinates, screenSize);

      final debugInfo = {
        'normalized_center':
            '${handCenter.dx.toStringAsFixed(3)},${handCenter.dy.toStringAsFixed(3)}',
        'screen_size':
            '${screenSize.width.toInt()}x${screenSize.height.toInt()}',
        'image_size': '${imageSize.width.toInt()}x${imageSize.height.toInt()}',
        'final_coordinates':
            '${screenCoordinates.dx.toInt()},${screenCoordinates.dy.toInt()}',
        'is_valid': isValid.toString(),
        'cache_hit': cached != null ? 'true' : 'false',
      };

      final result = CoordinateTransformationResult(
        screenCoordinates: screenCoordinates,
        isValid: isValid,
        errorMessage: isValid ? null : 'Coordinates out of bounds or invalid',
        debugInfo: debugInfo,
      );

      // Cache the result
      _cacheResult(cacheKey, result);

      return result;
    } catch (e) {
      return CoordinateTransformationResult(
        screenCoordinates: Offset.zero,
        isValid: false,
        errorMessage: 'Transformation failed: $e',
        debugInfo: {'error': e.toString(), 'cache_hit': 'false'},
      );
    }
  }

  /// Transform all hand landmarks to screen coordinates
  static List<Offset> transformAllLandmarks(
    List<Offset> normalizedLandmarks,
    Size screenSize,
    Size imageSize,
  ) {
    return normalizedLandmarks
        .map(
          (landmark) => _applyTransformation(landmark, screenSize, imageSize),
        )
        .toList();
  }

  /// Validate that coordinates are within valid screen bounds
  static bool validateCoordinates(Offset coordinates, Size screenSize) {
    return _validateCoordinates(coordinates, screenSize);
  }

  /// Calculate hand center from palm landmarks (more stable than all landmarks)
  static Offset _calculateHandCenterFromPalm(List<Offset> landmarks) {
    if (landmarks.isEmpty) {
      print('⚠️ [COORD] No landmarks provided');
      return Offset.zero; // This will be caught by validation
    }

    if (landmarks.length < 21) {
      print(
        '⚠️ [COORD] Invalid landmark count: ${landmarks.length}, using fallback',
      );
      // For insufficient landmarks, use average of available landmarks
      double sumX = 0.0;
      double sumY = 0.0;
      for (final landmark in landmarks) {
        sumX += landmark.dx;
        sumY += landmark.dy;
      }
      return Offset(sumX / landmarks.length, sumY / landmarks.length);
    }

    // Use palm landmarks (0, 5, 9, 13, 17) for stable center calculation
    // These are: wrist, index MCP, middle MCP, ring MCP, pinky MCP
    final palmIndices = [0, 5, 9, 13, 17];
    double sumX = 0.0;
    double sumY = 0.0;

    for (final index in palmIndices) {
      if (index < landmarks.length) {
        sumX += landmarks[index].dx;
        sumY += landmarks[index].dy;
      }
    }

    return Offset(sumX / palmIndices.length, sumY / palmIndices.length);
  }

  /// Apply camera/screen transformation matrix
  static Offset _applyTransformation(
    Offset normalizedCoords,
    Size screenSize,
    Size imageSize,
  ) {
    // MediaPipe provides normalized coordinates (0.0-1.0)
    // We need to transform them to screen pixel coordinates

    // Handle potential coordinate system differences
    // MediaPipe Y-axis might be flipped compared to Flutter
    final x = normalizedCoords.dx;
    final y = normalizedCoords.dy;

    // Transform to screen coordinates
    // Account for aspect ratio differences between camera image and screen
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;

    // Use uniform scaling to maintain aspect ratio
    final scale = math.min(scaleX, scaleY);

    // Calculate centered position
    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;
    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;

    // Transform normalized coordinates to screen pixels
    final screenX = offsetX + (x * scaledWidth);
    final screenY = offsetY + (y * scaledHeight);

    return Offset(screenX, screenY);
  }

  /// Validate coordinates are within screen bounds and not (0,0)
  static bool _validateCoordinates(Offset coordinates, Size screenSize) {
    // Check for (0,0) failure case - this indicates coordinate mapping failure
    if (coordinates == Offset.zero) {
      return false;
    }

    // Check bounds with small tolerance for edge cases
    const tolerance = 10.0;
    return coordinates.dx >= -tolerance &&
        coordinates.dx <= screenSize.width + tolerance &&
        coordinates.dy >= -tolerance &&
        coordinates.dy <= screenSize.height + tolerance;
  }

  /// Generate cache key based on landmarks and screen dimensions
  static String _generateCacheKey(
    List<Offset> landmarks,
    Size screenSize,
    Size imageSize,
  ) {
    if (landmarks.isEmpty) {
      return 'empty_${screenSize.width}x${screenSize.height}_${imageSize.width}x${imageSize.height}';
    }

    // Use palm landmarks for key generation (same as center calculation)
    final palmIndices = [0, 5, 9, 13, 17];
    final keyParts = <String>[];

    for (final index in palmIndices) {
      if (index < landmarks.length) {
        final landmark = landmarks[index];
        // Round to 3 decimal places for reasonable cache granularity
        keyParts.add(
          '${landmark.dx.toStringAsFixed(3)},${landmark.dy.toStringAsFixed(3)}',
        );
      }
    }

    return '${keyParts.join('_')}_${screenSize.width}x${screenSize.height}_${imageSize.width}x${imageSize.height}';
  }

  /// Cache transformation result with automatic cleanup
  static void _cacheResult(String key, CoordinateTransformationResult result) {
    // Clean up expired entries and enforce size limit
    _cleanupCache();

    _cache[key] = _CacheEntry(result, DateTime.now());
  }

  /// Clean up expired cache entries only
  static void _cleanupExpiredEntries() {
    final now = DateTime.now();
    _cache.removeWhere(
      (key, entry) => now.difference(entry.timestamp) > _cacheTimeout,
    );
  }

  /// Clean up expired cache entries and enforce size limits
  static void _cleanupCache() {
    _cleanupExpiredEntries();

    // Enforce size limit by removing oldest entries
    if (_cache.length >= _maxCacheSize) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      // Remove oldest 25% of entries
      final entriesToRemove = (_maxCacheSize * 0.25).round();
      for (int i = 0; i < entriesToRemove && i < sortedEntries.length; i++) {
        _cache.remove(sortedEntries[i].key);
      }
    }
  }

  /// Perform aggressive cleanup when memory pressure is detected
  static void performMemoryPressureCleanup() {
    print(
      '🧹 [Coord-GC] Performing aggressive cache cleanup due to memory pressure',
    );

    // Clear all cache entries when under memory pressure
    final clearedCount = _cache.length;
    _cache.clear();

    print(
      '🧹 [Coord-GC] Cleared $clearedCount coordinate transformation cache entries',
    );
  }

  /// Clear all cached transformations (useful for testing)
  static void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int expiredCount = 0;

    for (final entry in _cache.values) {
      if (now.difference(entry.timestamp) > _cacheTimeout) {
        expiredCount++;
      }
    }

    return {
      'total_entries': _cache.length,
      'expired_entries': expiredCount,
      'active_entries': _cache.length - expiredCount,
      'max_size': _maxCacheSize,
      'timeout_ms': _cacheTimeout.inMilliseconds,
    };
  }
}

/// Coordinate debugging utility
class CoordinateDebugger {
  static bool _debugEnabled = true;

  static void setDebugEnabled(bool enabled) {
    _debugEnabled = enabled;
  }

  /// Log raw MediaPipe landmark data
  static void logRawLandmarks(List<Offset> landmarks, String handId) {
    if (!_debugEnabled) return;

    if (landmarks.length >= 21) {
      final wrist = landmarks[0];
      final indexTip = landmarks[8];
      final thumbTip = landmarks[4];

      print('🔍 [COORD] Raw landmarks for $handId:');
      print(
        '   Wrist: ${wrist.dx.toStringAsFixed(3)},${wrist.dy.toStringAsFixed(3)}',
      );
      print(
        '   Thumb tip: ${thumbTip.dx.toStringAsFixed(3)},${thumbTip.dy.toStringAsFixed(3)}',
      );
      print(
        '   Index tip: ${indexTip.dx.toStringAsFixed(3)},${indexTip.dy.toStringAsFixed(3)}',
      );
    } else {
      print(
        '⚠️ [COORD] Invalid landmark count for $handId: ${landmarks.length}',
      );
    }
  }

  /// Log coordinate transformation steps
  static void logTransformationSteps(
    Offset raw,
    Offset transformed,
    Size screenSize,
    String handId,
  ) {
    if (!_debugEnabled) return;

    print('🔄 [COORD] Transformation for $handId:');
    print('   Raw: ${raw.dx.toStringAsFixed(3)},${raw.dy.toStringAsFixed(3)}');
    print(
      '   Transformed: ${transformed.dx.toInt()},${transformed.dy.toInt()}',
    );
    print(
      '   Screen: ${screenSize.width.toInt()}x${screenSize.height.toInt()}',
    );
  }

  /// Log validation results
  static void logValidationResult(
    Offset coordinates,
    bool isValid,
    String reason,
    String handId,
  ) {
    if (!_debugEnabled) return;

    final status = isValid ? '✅' : '❌';
    print(
      '$status [COORD] Validation for $handId: ${coordinates.dx.toInt()},${coordinates.dy.toInt()} - $reason',
    );
  }

  /// Log proximity calculation details
  static void logProximityCalculation(
    Offset handPos,
    Offset objectPos,
    double distance,
    String handId,
    String objectId,
  ) {
    if (!_debugEnabled) return;

    print('📏 [COORD] Proximity $handId → $objectId:');
    print('   Hand: ${handPos.dx.toInt()},${handPos.dy.toInt()}');
    print('   Object: ${objectPos.dx.toInt()},${objectPos.dy.toInt()}');
    print('   Distance: ${distance.toStringAsFixed(1)}px');
  }
}

/// Result of coordinate transformation with validation
class CoordinateTransformationResult {
  final Offset screenCoordinates;
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic> debugInfo;

  const CoordinateTransformationResult({
    required this.screenCoordinates,
    required this.isValid,
    this.errorMessage,
    required this.debugInfo,
  });
}

/// Cache entry for coordinate transformation results
class _CacheEntry {
  final CoordinateTransformationResult result;
  final DateTime timestamp;

  _CacheEntry(this.result, this.timestamp);

  bool get isExpired {
    final now = DateTime.now();
    final elapsed = now.difference(timestamp);
    return elapsed > HandCoordinateTransformer._cacheTimeout;
  }
}
