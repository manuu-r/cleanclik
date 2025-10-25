/// Centralized configuration for all ML components
/// 
/// This file consolidates all ML-related constants, thresholds, timeouts,
/// and processing modes from across the camera services architecture.
/// 
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6
library;

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;

/// Processing modes for ML detection
enum ProcessingMode {
  /// Full processing with object detection and image labeling
  full,

  /// Object detection only - no image labeling
  objectsOnly,

  /// Cached mode - use previous results
  cached,
}

/// Centralized ML configuration for all camera/ML services
class MLConfig {
  // Private constructor to prevent instantiation
  MLConfig._();

  // ============================================================================
  // Object Detection Configuration
  // ============================================================================

  /// Minimum confidence threshold for object detection
  /// Objects with confidence below this value will be filtered out
  static const double objectDetectionConfidence = 0.4;

  /// Detection mode for object detector (stream mode for real-time processing)
  static const mlkit.DetectionMode objectDetectionMode =
      mlkit.DetectionMode.stream;

  /// Whether to classify detected objects
  static const bool classifyObjects = true;

  /// Whether to detect multiple objects in a single frame
  static const bool multipleObjects = true;

  // ============================================================================
  // Image Labeling Configuration
  // ============================================================================

  /// Minimum confidence threshold for image labeling
  /// Labels with confidence below this value will be filtered out
  static const double imageLabelingConfidence = 0.5;

  /// Maximum number of labels to return per image
  static const int maxLabelsPerImage = 10;

  // ============================================================================
  // Processing Configuration
  // ============================================================================

  /// Timeout for ML processing operations
  static const Duration processingTimeout = Duration(seconds: 5);

  /// Timeout for isolate operations
  static const Duration isolateTimeout = Duration(seconds: 10);

  /// Timeout for image labeling operations
  static const Duration imageLabelingTimeout = Duration(seconds: 3);

  /// Timeout for object detection in isolate
  static const Duration isolateObjectDetectionTimeout = Duration(seconds: 2);

  /// Timeout for image labeling in isolate
  static const Duration isolateImageLabelingTimeout = Duration(seconds: 2);

  /// Maximum number of retries for failed operations
  static const int maxRetries = 2;

  /// Maximum number of concurrent processing operations
  static const int maxConcurrentProcessing = 3;

  /// Maximum interval between processing frames
  static const Duration maxProcessingInterval = Duration(milliseconds: 100);

  // ============================================================================
  // Image Processing Configuration
  // ============================================================================

  /// Padding around bounding boxes when cropping (5% of box dimensions)
  static const double boundaryPadding = 0.05;

  /// Minimum crop size in pixels
  static const int minCropSize = 32;

  /// Maximum crop size in pixels
  static const int maxCropSize = 512;

  // ============================================================================
  // Categorization Configuration
  // ============================================================================

  /// Minimum confidence for waste categorization
  static const double minCategorizationConfidence = 0.3;

  /// Confidence threshold for high-confidence results
  static const double highConfidenceThreshold = 0.8;

  // ============================================================================
  // Tracking Configuration
  // ============================================================================

  /// Maximum number of frames to persist objects without detection
  static const int maxPersistenceFrames = 5;

  /// Minimum confidence for object tracking
  static const double minTrackingConfidence = 0.3;

  /// Distance threshold for matching tracked objects (in pixels)
  static const double trackingDistanceThreshold = 100.0;

  /// Maximum age for tracked objects before cleanup
  static const Duration maxTrackedObjectAge = Duration(seconds: 3);

  // ============================================================================
  // Camera Resource Management Configuration
  // ============================================================================

  /// Timeout for camera idle state
  static const Duration cameraIdleTimeout = Duration(seconds: 30);

  /// Timeout for camera initialization
  static const Duration cameraInitTimeout = Duration(seconds: 10);

  /// Timeout for QR scanning stop operation
  static const Duration qrScanningStopTimeout = Duration(seconds: 2);

  /// Timeout for disposal service cleanup
  static const Duration disposalServiceCleanupTimeout = Duration(seconds: 1);

  // ============================================================================
  // Processing Mode Settings
  // ============================================================================

  /// Configuration for different processing modes
  static const Map<ProcessingMode, Map<String, bool>> modeSettings = {
    ProcessingMode.full: {
      'objectDetection': true,
      'imageLabeling': true,
    },
    ProcessingMode.objectsOnly: {
      'objectDetection': true,
      'imageLabeling': false,
    },
    ProcessingMode.cached: {
      'objectDetection': false,
      'imageLabeling': false,
    },
  };

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Check if object detection is enabled for the given mode
  static bool isObjectDetectionEnabled(ProcessingMode mode) {
    return modeSettings[mode]?['objectDetection'] ?? false;
  }

  /// Check if image labeling is enabled for the given mode
  static bool isImageLabelingEnabled(ProcessingMode mode) {
    return modeSettings[mode]?['imageLabeling'] ?? false;
  }

  /// Get the appropriate timeout for a processing operation
  static Duration getProcessingTimeout(ProcessingMode mode) {
    switch (mode) {
      case ProcessingMode.full:
        return processingTimeout;
      case ProcessingMode.objectsOnly:
        return isolateObjectDetectionTimeout;
      case ProcessingMode.cached:
        return Duration.zero;
    }
  }
}
