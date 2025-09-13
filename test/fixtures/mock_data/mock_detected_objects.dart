import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import '../test_data_factory.dart';
import '../../test_config.dart';

/// Mock detected object data for testing
class MockDetectedObjects {
  /// Create a list of mock detected objects
  static List<Map<String, dynamic>> createMockDetectedObjects({
    int count = 5,
    WasteCategory? category,
    double minConfidence = 0.7,
  }) {
    return List.generate(count, (index) {
      final objectCategory = category ?? WasteCategory.values[index % WasteCategory.values.length];
      final labels = TestConfig.wasteCategories[objectCategory.name] ?? ['Unknown Object'];
      final confidence = minConfidence + (Random().nextDouble() * (1.0 - minConfidence));
      
      final detectedObject = TestDataFactory.createMockDetectedObject(
        id: 'detected-$index',
        category: objectCategory,
        confidence: confidence,
        label: labels[index % labels.length],
        boundingBox: Rect.fromLTWH(
          100.0 + (index * 50),
          100.0 + (index * 50),
          150.0 + (index * 20),
          200.0 + (index * 30),
        ),
        isTracked: index % 2 == 0,
      );
      
      return detectedObject.toJson();
    });
  }

  /// Create mock high-confidence detected objects
  static List<Map<String, dynamic>> createHighConfidenceObjects({
    int count = 3,
  }) {
    return createMockDetectedObjects(
      count: count,
      minConfidence: 0.9,
    );
  }

  /// Create mock low-confidence detected objects
  static List<Map<String, dynamic>> createLowConfidenceObjects({
    int count = 3,
  }) {
    return createMockDetectedObjects(
      count: count,
      minConfidence: 0.5,
    );
  }

  /// Create mock objects for specific category testing
  static List<Map<String, dynamic>> createCategorySpecificObjects({
    required WasteCategory category,
    int count = 5,
  }) {
    final labels = TestConfig.wasteCategories[category.name] ?? ['Unknown Object'];
    
    return List.generate(count, (index) {
      final detectedObject = TestDataFactory.createMockDetectedObject(
        id: 'category-${category.name}-$index',
        category: category,
        confidence: 0.8 + (index * 0.02),
        label: labels[index % labels.length],
        boundingBox: Rect.fromLTWH(
          50.0 + (index * 60),
          50.0 + (index * 80),
          120.0,
          160.0,
        ),
      );
      
      return detectedObject.toJson();
    });
  }

  /// Create mock objects for tracking performance testing
  static List<Map<String, dynamic>> createTrackingPerformanceObjects({
    int count = 10,
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      
      return {
        ...TestDataFactory.createMockDetectedObject(
          id: 'tracking-$index',
          category: category,
          confidence: 0.85,
          isTracked: true,
        ).toJson(),
        'trackingId': index,
        'trackingHistory': List.generate(5, (historyIndex) => {
          'timestamp': DateTime.now().subtract(Duration(milliseconds: historyIndex * 100)).toIso8601String(),
          'boundingBox': {
            'left': 100.0 + (historyIndex * 5),
            'top': 100.0 + (historyIndex * 3),
            'right': 250.0 + (historyIndex * 5),
            'bottom': 300.0 + (historyIndex * 3),
          },
          'confidence': 0.85 + (historyIndex * 0.01),
        }),
        'velocity': {
          'x': Random().nextDouble() * 10 - 5, // -5 to 5 pixels per frame
          'y': Random().nextDouble() * 10 - 5,
        },
        'stability': 0.8 + (Random().nextDouble() * 0.2), // 0.8 to 1.0
      };
    });
  }

  /// Create mock objects for edge case testing
  static List<Map<String, dynamic>> createEdgeCaseObjects() {
    return [
      // Object at screen edge
      {
        ...TestDataFactory.createMockDetectedObject(
          id: 'edge-left',
          category: WasteCategory.recycle,
          confidence: 0.75,
          boundingBox: const Rect.fromLTWH(0, 100, 50, 100),
        ).toJson(),
        'edgeCase': 'screen_edge_left',
      },
      
      // Very small object
      {
        ...TestDataFactory.createMockDetectedObject(
          id: 'tiny-object',
          category: WasteCategory.ewaste,
          confidence: 0.65,
          boundingBox: const Rect.fromLTWH(200, 200, 20, 20),
        ).toJson(),
        'edgeCase': 'very_small',
      },
      
      // Very large object
      {
        ...TestDataFactory.createMockDetectedObject(
          id: 'large-object',
          category: WasteCategory.landfill,
          confidence: 0.9,
          boundingBox: const Rect.fromLTWH(50, 50, 300, 400),
        ).toJson(),
        'edgeCase': 'very_large',
      },
      
      // Overlapping objects
      {
        ...TestDataFactory.createMockDetectedObject(
          id: 'overlap-1',
          category: WasteCategory.organic,
          confidence: 0.8,
          boundingBox: const Rect.fromLTWH(150, 150, 100, 100),
        ).toJson(),
        'edgeCase': 'overlapping',
      },
      {
        ...TestDataFactory.createMockDetectedObject(
          id: 'overlap-2',
          category: WasteCategory.recycle,
          confidence: 0.7,
          boundingBox: const Rect.fromLTWH(180, 180, 100, 100),
        ).toJson(),
        'edgeCase': 'overlapping',
      },
      
      // Low confidence object
      {
        ...TestDataFactory.createMockDetectedObject(
          id: 'low-confidence',
          category: WasteCategory.hazardous,
          confidence: 0.3,
          boundingBox: const Rect.fromLTWH(100, 300, 80, 120),
        ).toJson(),
        'edgeCase': 'low_confidence',
      },
    ];
  }

  /// Create mock ML Kit detection results
  static List<Map<String, dynamic>> createMLKitResults({
    int count = 3,
    double minConfidence = 0.7,
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      final labels = TestConfig.wasteCategories[category.name] ?? ['Unknown'];
      
      return {
        'trackingId': index,
        'labels': [
          {
            'text': labels[index % labels.length],
            'confidence': minConfidence + (Random().nextDouble() * (1.0 - minConfidence)),
          }
        ],
        'boundingBox': {
          'left': 100.0 + (index * 50),
          'top': 100.0 + (index * 50),
          'right': 250.0 + (index * 50),
          'bottom': 350.0 + (index * 50),
        },
      };
    });
  }

  /// Create mock detection session data
  static Map<String, dynamic> createDetectionSession({
    String? sessionId,
    int objectCount = 5,
  }) {
    return {
      'sessionId': sessionId ?? 'session-${DateTime.now().millisecondsSinceEpoch}',
      'startTime': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      'endTime': DateTime.now().toIso8601String(),
      'totalObjects': objectCount,
      'uniqueObjects': objectCount - 1, // Some duplicates
      'averageConfidence': 0.82,
      'processingTime': {
        'total': 5000, // milliseconds
        'average': 1000, // per object
        'min': 800,
        'max': 1200,
      },
      'categoryBreakdown': {
        'recycle': 2,
        'organic': 1,
        'landfill': 1,
        'ewaste': 1,
        'hazardous': 0,
      },
      'performance': {
        'fps': 28.5,
        'memoryUsage': 45.2, // MB
        'cpuUsage': 35.8, // percentage
        'batteryDrain': 2.1, // percentage
      },
      'errors': [],
      'warnings': [
        {
          'type': 'low_light',
          'message': 'Detection accuracy may be reduced in low light conditions',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        }
      ],
    };
  }

  /// Create mock detection statistics
  static Map<String, dynamic> createDetectionStatistics({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'period': 'last_30_days',
      'totalDetections': 450,
      'uniqueObjects': 380,
      'averageConfidence': 0.84,
      'categoryAccuracy': {
        'recycle': 0.92,
        'organic': 0.88,
        'landfill': 0.75,
        'ewaste': 0.95,
        'hazardous': 0.98,
      },
      'detectionTrends': {
        'daily': List.generate(30, (day) => {
          'date': DateTime.now().subtract(Duration(days: day)).toIso8601String().split('T')[0],
          'detections': 10 + Random().nextInt(20),
          'accuracy': 0.8 + (Random().nextDouble() * 0.2),
        }),
        'hourly': List.generate(24, (hour) => {
          'hour': hour,
          'detections': 5 + Random().nextInt(15),
          'accuracy': 0.75 + (Random().nextDouble() * 0.25),
        }),
      },
      'performanceMetrics': {
        'averageProcessingTime': 950, // milliseconds
        'averageFPS': 29.2,
        'memoryEfficiency': 0.88,
        'batteryEfficiency': 0.92,
      },
      'errorAnalysis': {
        'totalErrors': 12,
        'errorTypes': {
          'camera_error': 3,
          'ml_processing_error': 5,
          'low_confidence': 4,
        },
        'errorRate': 0.027, // 2.7%
      },
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock real-time detection stream data
  static Stream<List<Map<String, dynamic>>> createDetectionStream({
    Duration interval = const Duration(milliseconds: 100),
    int maxObjects = 5,
  }) async* {
    while (true) {
      final objectCount = Random().nextInt(maxObjects + 1);
      yield createMockDetectedObjects(count: objectCount);
      await Future.delayed(interval);
    }
  }

  /// Create mock detection calibration data
  static Map<String, dynamic> createDetectionCalibration() {
    return {
      'calibrationId': 'calibration-${DateTime.now().millisecondsSinceEpoch}',
      'deviceModel': 'iPhone 14',
      'cameraSpecs': {
        'resolution': '1920x1080',
        'focalLength': 4.25,
        'aperture': 1.5,
        'sensorSize': '1/2.55"',
      },
      'environmentalFactors': {
        'lightingConditions': 'indoor_fluorescent',
        'backgroundComplexity': 'medium',
        'distanceToObject': 0.5, // meters
      },
      'calibrationResults': {
        'optimalConfidenceThreshold': 0.75,
        'recommendedProcessingInterval': 150, // milliseconds
        'maxSimultaneousObjects': 8,
        'categorySpecificThresholds': {
          'recycle': 0.7,
          'organic': 0.8,
          'landfill': 0.6,
          'ewaste': 0.85,
          'hazardous': 0.9,
        },
      },
      'performanceBenchmarks': {
        'processingTime': 890, // milliseconds
        'accuracy': 0.89,
        'falsePositiveRate': 0.05,
        'falseNegativeRate': 0.08,
      },
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}