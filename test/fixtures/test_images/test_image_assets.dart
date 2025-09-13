import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import 'test_image_metadata.dart';
import '../../test_config.dart';

/// Helper class for managing test image assets
class TestImageAssets {
  static final Map<String, Uint8List> _imageCache = {};
  static bool _cacheEnabled = true;

  /// Enable or disable image caching
  static void setCacheEnabled(bool enabled) {
    _cacheEnabled = enabled;
    if (!enabled) {
      _imageCache.clear();
    }
  }

  /// Get the full path to a test image
  static String getImagePath(String imageKey) {
    final metadata = TestImageMetadata.getImageMetadata(imageKey);
    if (metadata == null) {
      throw ArgumentError('Image metadata not found for key: $imageKey');
    }
    
    final fileName = metadata['fileName'] as String;
    return '${TestConfig.testImagesPath}/$fileName';
  }

  /// Load image bytes from assets or file system
  static Future<Uint8List> loadImageBytes(String imageKey) async {
    if (_cacheEnabled && _imageCache.containsKey(imageKey)) {
      return _imageCache[imageKey]!;
    }

    final imagePath = getImagePath(imageKey);
    Uint8List bytes;

    try {
      // Try loading from assets first (for bundled test images)
      bytes = (await rootBundle.load('assets/test_images/${TestImageMetadata.getImageMetadata(imageKey)!['fileName']}')).buffer.asUint8List();
    } catch (e) {
      // Fallback to file system (for generated test images)
      final file = File(imagePath);
      if (await file.exists()) {
        bytes = await file.readAsBytes();
      } else {
        // Generate a placeholder image if file doesn't exist
        bytes = await _generatePlaceholderImage(imageKey);
      }
    }

    if (_cacheEnabled) {
      _imageCache[imageKey] = bytes;
    }

    return bytes;
  }

  /// Preload multiple images into cache
  static Future<void> preloadImages(List<String> imageKeys) async {
    final futures = imageKeys.map((key) => loadImageBytes(key));
    await Future.wait(futures);
  }

  /// Preload all images for a specific category
  static Future<void> preloadCategory(String category) async {
    final imageKeys = TestImageMetadata.getImagesByCategory(category);
    await preloadImages(imageKeys);
  }

  /// Preload comprehensive test suite images
  static Future<void> preloadComprehensiveTestSuite() async {
    final imageKeys = TestImageMetadata.getComprehensiveTestSuite();
    await preloadImages(imageKeys);
  }

  /// Get expected ML detection result for an image
  static Map<String, dynamic> getExpectedMLResult(String imageKey) {
    final metadata = TestImageMetadata.getImageMetadata(imageKey);
    if (metadata == null) {
      throw ArgumentError('Image metadata not found for key: $imageKey');
    }

    return {
      'imageKey': imageKey,
      'category': metadata['category'],
      'expectedLabels': TestImageMetadata.getExpectedLabels(imageKey),
      'expectedConfidence': TestImageMetadata.getExpectedConfidence(imageKey),
      'boundingBox': TestImageMetadata.getExpectedBoundingBox(imageKey),
      'isEdgeCase': TestImageMetadata.isEdgeCase(imageKey),
      'edgeCaseType': TestImageMetadata.getEdgeCaseType(imageKey),
      'difficulty': metadata['difficulty'],
      'lighting': metadata['lighting'],
      'background': metadata['background'],
      'angle': metadata['angle'],
    };
  }

  /// Get expected QR scan result for a QR code image
  static Map<String, dynamic>? getExpectedQRResult(String imageKey) {
    final metadata = TestImageMetadata.getImageMetadata(imageKey);
    if (metadata == null || metadata['category'] != 'qr_code') {
      return null;
    }

    return {
      'imageKey': imageKey,
      'expectedData': metadata['expectedData'],
      'qrCodeType': metadata['qrCodeType'],
      'isReadable': metadata['expectedData'] != null,
      'difficulty': metadata['difficulty'],
      'isEdgeCase': TestImageMetadata.isEdgeCase(imageKey),
      'edgeCaseType': TestImageMetadata.getEdgeCaseType(imageKey),
    };
  }

  /// Get test images for performance benchmarking
  static List<String> getPerformanceTestImages({
    int maxCount = 50,
    String? category,
    String difficulty = 'easy',
  }) {
    var images = TestImageMetadata.getPerformanceTestImages();
    
    if (category != null) {
      images = images.where((key) {
        final metadata = TestImageMetadata.getImageMetadata(key);
        return metadata?['category'] == category;
      }).toList();
    }

    images = images.where((key) {
      final metadata = TestImageMetadata.getImageMetadata(key);
      return metadata?['difficulty'] == difficulty;
    }).toList();

    return images.take(maxCount).toList();
  }

  /// Get test images for edge case testing
  static List<String> getEdgeCaseTestImages({
    String? edgeCaseType,
  }) {
    var images = TestImageMetadata.getEdgeCaseImages();
    
    if (edgeCaseType != null) {
      images = images.where((key) {
        return TestImageMetadata.getEdgeCaseType(key) == edgeCaseType;
      }).toList();
    }

    return images;
  }

  /// Get test images for accuracy testing (covers all categories and difficulties)
  static List<String> getAccuracyTestImages() {
    return TestImageMetadata.getComprehensiveTestSuite();
  }

  /// Get QR code test images
  static List<String> getQRCodeTestImages({
    bool includeEdgeCases = true,
  }) {
    var images = TestImageMetadata.getQRCodeImages();
    
    if (!includeEdgeCases) {
      images = images.where((key) => !TestImageMetadata.isEdgeCase(key)).toList();
    }

    return images;
  }

  /// Get calibration images for camera/ML setup
  static List<String> getCalibrationImages() {
    return TestImageMetadata.getCalibrationImages();
  }

  /// Validate that all referenced images exist or can be generated
  static Future<Map<String, bool>> validateImageAvailability() async {
    final allKeys = TestImageMetadata.getAllImageKeys();
    final results = <String, bool>{};

    for (final key in allKeys) {
      try {
        await loadImageBytes(key);
        results[key] = true;
      } catch (e) {
        results[key] = false;
      }
    }

    return results;
  }

  /// Get image statistics for test planning
  static Map<String, dynamic> getImageStatistics() {
    final allKeys = TestImageMetadata.getAllImageKeys();
    final categories = <String, int>{};
    final difficulties = <String, int>{};
    final edgeCases = <String, int>{};
    var totalSize = 0;

    for (final key in allKeys) {
      final metadata = TestImageMetadata.getImageMetadata(key)!;
      
      // Count by category
      final category = metadata['category'] as String;
      categories[category] = (categories[category] ?? 0) + 1;
      
      // Count by difficulty
      final difficulty = metadata['difficulty'] as String;
      difficulties[difficulty] = (difficulties[difficulty] ?? 0) + 1;
      
      // Count edge cases
      if (TestImageMetadata.isEdgeCase(key)) {
        final edgeCaseType = TestImageMetadata.getEdgeCaseType(key) ?? 'unknown';
        edgeCases[edgeCaseType] = (edgeCases[edgeCaseType] ?? 0) + 1;
      }
      
      // Sum file sizes
      totalSize += metadata['fileSize'] as int? ?? 0;
    }

    return {
      'totalImages': allKeys.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'categoryCounts': categories,
      'difficultyCounts': difficulties,
      'edgeCaseCounts': edgeCases,
      'averageFileSizeKB': ((totalSize / allKeys.length) / 1024).toStringAsFixed(1),
    };
  }

  /// Clear image cache
  static void clearCache() {
    _imageCache.clear();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStatistics() {
    var totalCacheSize = 0;
    for (final bytes in _imageCache.values) {
      totalCacheSize += bytes.length;
    }

    return {
      'cachedImages': _imageCache.length,
      'totalCacheSizeBytes': totalCacheSize,
      'totalCacheSizeMB': (totalCacheSize / 1024 / 1024).toStringAsFixed(2),
      'cacheEnabled': _cacheEnabled,
    };
  }

  /// Generate a placeholder image for testing when actual image is not available
  static Future<Uint8List> _generatePlaceholderImage(String imageKey) async {
    final metadata = TestImageMetadata.getImageMetadata(imageKey);
    if (metadata == null) {
      throw ArgumentError('Cannot generate placeholder: metadata not found for $imageKey');
    }

    // Create a simple colored rectangle as placeholder
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Set color based on category
    final category = metadata['category'] as String;
    switch (category) {
      case 'recycle':
        paint.color = const Color(0xFF4CAF50);
        break;
      case 'organic':
        paint.color = const Color(0xFF8BC34A);
        break;
      case 'landfill':
        paint.color = const Color(0xFF9E9E9E);
        break;
      case 'ewaste':
        paint.color = const Color(0xFFFF9800);
        break;
      case 'hazardous':
        paint.color = const Color(0xFFF44336);
        break;
      case 'qr_code':
        paint.color = const Color(0xFF000000);
        break;
      default:
        paint.color = const Color(0xFF607D8B);
    }

    // Draw placeholder rectangle
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 300), paint);

    // Add text label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'PLACEHOLDER\n$imageKey',
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 130));

    final picture = recorder.endRecording();
    final image = await picture.toImage(400, 300);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  /// Create test image sets for different testing scenarios
  static Map<String, List<String>> createTestImageSets() {
    return {
      'smoke_test': [
        'plastic_bottle_001',
        'apple_core_001',
        'smartphone_001',
        'bin_qr_recycle_001',
      ],
      'accuracy_test': TestImageMetadata.getComprehensiveTestSuite(),
      'performance_test': getPerformanceTestImages(maxCount: 20),
      'edge_case_test': getEdgeCaseTestImages(),
      'qr_code_test': getQRCodeTestImages(),
      'calibration_test': getCalibrationImages(),
      'category_recycle': TestImageMetadata.getImagesByCategory('recycle'),
      'category_organic': TestImageMetadata.getImagesByCategory('organic'),
      'category_landfill': TestImageMetadata.getImagesByCategory('landfill'),
      'category_ewaste': TestImageMetadata.getImagesByCategory('ewaste'),
      'category_hazardous': TestImageMetadata.getImagesByCategory('hazardous'),
      'difficulty_easy': TestImageMetadata.getImagesByDifficulty('easy'),
      'difficulty_medium': TestImageMetadata.getImagesByDifficulty('medium'),
      'difficulty_hard': TestImageMetadata.getImagesByDifficulty('hard'),
      'difficulty_very_hard': TestImageMetadata.getImagesByDifficulty('very_hard'),
    };
  }

  /// Get recommended test images for a specific test type
  static List<String> getRecommendedImages(String testType) {
    final testSets = createTestImageSets();
    return testSets[testType] ?? [];
  }
}