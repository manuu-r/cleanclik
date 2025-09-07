import 'dart:ui';
import 'package:camera/camera.dart';

/// Abstract interface for cross-platform hand tracking
abstract class HandTrackingService {
  /// Initialize the hand tracking service
  Future<void> initialize();

  /// Detect hands in camera image
  Future<List<HandLandmark>> detectHands(
    CameraImage cameraImage,
    Size previewSize, [
    CameraController? cameraController,
  ]);

  /// Check if the service is initialized
  bool get isInitialized;

  /// Check if the service is available on current platform
  bool get isAvailable;

  /// Get platform-specific information
  String get platformInfo;

  /// Clean up resources
  Future<void> dispose();
}

/// Unified hand landmark data structure
class HandLandmark {
  /// 21 landmark points in pixel coordinates
  final List<Offset> landmarks;

  /// 21 landmark points in normalized coordinates (0.0-1.0)
  final List<Offset> normalizedLandmarks;

  /// Overall detection confidence (0.0-1.0)
  final double confidence;

  /// Bounding box around the hand
  final Rect boundingBox;

  /// Hand classification (Left/Right)
  final String handedness;

  /// Handedness classification confidence (0.0-1.0)
  final double handednessConfidence;

  /// Timestamp when this landmark was detected
  final DateTime timestamp;

  HandLandmark({
    required this.landmarks,
    required this.normalizedLandmarks,
    required this.confidence,
    required this.boundingBox,
    required this.handedness,
    required this.handednessConfidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convenience getters for key landmarks (MediaPipe standard indices)
  Offset get wrist => landmarks.isNotEmpty ? landmarks[0] : Offset.zero;
  Offset get thumbTip => landmarks.length > 4 ? landmarks[4] : Offset.zero;
  Offset get indexTip => landmarks.length > 8 ? landmarks[8] : Offset.zero;
  Offset get middleTip => landmarks.length > 12 ? landmarks[12] : Offset.zero;
  Offset get ringTip => landmarks.length > 16 ? landmarks[16] : Offset.zero;
  Offset get pinkyTip => landmarks.length > 20 ? landmarks[20] : Offset.zero;

  // Normalized coordinate getters
  Offset get normalizedWrist =>
      normalizedLandmarks.isNotEmpty ? normalizedLandmarks[0] : Offset.zero;
  Offset get normalizedThumbTip =>
      normalizedLandmarks.length > 4 ? normalizedLandmarks[4] : Offset.zero;
  Offset get normalizedIndexTip =>
      normalizedLandmarks.length > 8 ? normalizedLandmarks[8] : Offset.zero;

  @override
  String toString() {
    return 'HandLandmark(handedness: $handedness, confidence: ${confidence.toStringAsFixed(2)}, '
        'landmarks: ${landmarks.length}, timestamp: $timestamp)';
  }
}

/// MediaPipe hand landmark indices for reference
class HandLandmarkIndex {
  static const int wrist = 0;
  static const int thumbCmc = 1;
  static const int thumbMcp = 2;
  static const int thumbIp = 3;
  static const int thumbTip = 4;
  static const int indexFingerMcp = 5;
  static const int indexFingerPip = 6;
  static const int indexFingerDip = 7;
  static const int indexFingerTip = 8;
  static const int middleFingerMcp = 9;
  static const int middleFingerPip = 10;
  static const int middleFingerDip = 11;
  static const int middleFingerTip = 12;
  static const int ringFingerMcp = 13;
  static const int ringFingerPip = 14;
  static const int ringFingerDip = 15;
  static const int ringFingerTip = 16;
  static const int pinkyMcp = 17;
  static const int pinkyPip = 18;
  static const int pinkyDip = 19;
  static const int pinkyTip = 20;
}
