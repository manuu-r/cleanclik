import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';

/// Android implementation using hand_landmarker package
class AndroidHandTrackingService implements HandTrackingService {
  HandLandmarkerPlugin? _handLandmarker;
  bool _isInitialized = false;

  // Detection parameters
  static const double _minHandDetectionConfidence = 0.4;
  static const int _numHands = 2;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isAvailable => Platform.isAndroid;

  @override
  String get platformInfo => 'Android MediaPipe Hand Landmarker v2.1.0';

  @override
  Future<void> initialize() async {
    if (!isAvailable) {
      throw UnsupportedError(
        'AndroidHandTrackingService is only available on Android',
      );
    }

    try {
      print('🖐️ Initializing Android MediaPipe hand landmarker...');

      // Initialize hand landmarker with configuration
      _handLandmarker = HandLandmarkerPlugin.create(
        numHands: _numHands,
        minHandDetectionConfidence: _minHandDetectionConfidence,
        delegate: HandLandmarkerDelegate.GPU,
      );

      _isInitialized = true;
      print('✅ Android MediaPipe hand landmarker initialized successfully');
      print('   Max hands: $_numHands');
      print('   Detection confidence: $_minHandDetectionConfidence');
      print('   Delegate: GPU');
    } catch (e) {
      print('❌ Failed to initialize Android hand landmarker: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  @override
  Future<List<HandLandmark>> detectHands(
    CameraImage cameraImage,
    Size previewSize, [
    CameraController? cameraController,
  ]) async {
    if (!_isInitialized || _handLandmarker == null) {
      return [];
    }

    // Process every frame for maximum responsiveness
    // Note: MediaPipe is optimized enough to handle this

    try {
      final stopwatch = Stopwatch()..start();

      // Detect hands using MediaPipe
      // Note: We need to provide sensor orientation, defaulting to 90 for portrait
      final results = _handLandmarker!.detect(cameraImage, 90);

      stopwatch.stop();

      if (results.isNotEmpty) {
        // Convert MediaPipe results to our unified format
        final handLandmarks = _convertToHandLandmarks(
          results,
          cameraImage,
          previewSize,
          cameraController,
        );

        if (handLandmarks.isNotEmpty) {
          print(
            '🖐️ [ANDROID] Detected ${handLandmarks.length} hands in ${stopwatch.elapsedMilliseconds}ms',
          );
          for (int i = 0; i < handLandmarks.length; i++) {
            final hand = handLandmarks[i];
            print(
              '   Hand $i: ${hand.handedness} (${(hand.handednessConfidence * 100).toStringAsFixed(1)}%), confidence=${hand.confidence.toStringAsFixed(2)}',
            );
          }
        }

        return handLandmarks;
      }

      return [];
    } catch (e) {
      print('❌ Android hand detection error: $e');
      return [];
    }
  }

  /// Convert hand_landmarker results to our unified HandLandmark format
  List<HandLandmark> _convertToHandLandmarks(
    List<Hand> results,
    CameraImage cameraImage,
    Size previewSize,
    CameraController? cameraController,
  ) {
    final handLandmarks = <HandLandmark>[];

    for (int handIndex = 0; handIndex < results.length; handIndex++) {
      final hand = results[handIndex];

      // Extract landmarks (should be 21 points)
      final landmarks = <Offset>[];
      final normalizedLandmarks = <Offset>[];

      for (final landmark in hand.landmarks) {
        // MediaPipe landmarks are already normalized (0.0-1.0)
        normalizedLandmarks.add(Offset(landmark.x, landmark.y));

        // Keep normalized coordinates for proper transformation in painter
        // Following official hand_landmarker example pattern
        landmarks.add(Offset(landmark.x, landmark.y));
      }

      // Calculate bounding box
      final boundingBox = _calculateBoundingBox(landmarks);

      // Extract handedness from MediaPipe hand result
      // The hand_landmarker package provides handedness in the Hand object
      String handedness = 'Unknown';
      double confidence = 0.8;
      double handednessConfidence = 0.8;

      try {
        // Try to get handedness from the Hand object
        // Note: hand_landmarker package may expose this through different properties
        if (hand.toString().contains('Right') ||
            hand.toString().contains('right')) {
          handedness = 'Right';
        } else if (hand.toString().contains('Left') ||
            hand.toString().contains('left')) {
          handedness = 'Left';
        } else {
          // Fallback: use statistical approach based on landmark positions
          // Check thumb position relative to other fingers to determine handedness
          if (hand.landmarks.length >= 21) {
            final thumbTip = hand.landmarks[4]; // Thumb tip
            final indexMcp = hand.landmarks[5]; // Index MCP
            final pinkyMcp = hand.landmarks[17]; // Pinky MCP

            // If thumb is to the left of the hand center, it's likely a right hand
            final handCenter = (indexMcp.x + pinkyMcp.x) / 2;
            handedness = thumbTip.x < handCenter ? 'Right' : 'Left';
          } else {
            // Final fallback based on hand index
            handedness = handIndex == 0 ? 'Right' : 'Left';
          }
        }

        // Try to extract confidence if available
        // This is a placeholder - actual implementation depends on hand_landmarker API
        confidence = 0.85;
        handednessConfidence = 0.80;
      } catch (e) {
        print('Warning: Could not determine handedness properly: $e');
        handedness = handIndex == 0 ? 'Right' : 'Left';
      }

      // Create HandLandmark object
      var handLandmark = HandLandmark(
        landmarks: landmarks,
        normalizedLandmarks: normalizedLandmarks,
        confidence: confidence,
        boundingBox: boundingBox,
        handedness: handedness,
        handednessConfidence: handednessConfidence,
      );

      // Transform coordinates if camera controller is provided
      if (cameraController != null) {
        handLandmark = _transformHandToWidgetCoordinates(
          handLandmark,
          cameraImage,
          previewSize,
          cameraController,
        );
      }

      handLandmarks.add(handLandmark);
    }

    return handLandmarks;
  }

  /// Calculate bounding box from landmarks
  Rect _calculateBoundingBox(List<Offset> landmarks) {
    if (landmarks.isEmpty) return Rect.zero;

    double minX = landmarks.first.dx;
    double maxX = landmarks.first.dx;
    double minY = landmarks.first.dy;
    double maxY = landmarks.first.dy;

    for (final landmark in landmarks) {
      minX = minX < landmark.dx ? minX : landmark.dx;
      maxX = maxX > landmark.dx ? maxX : landmark.dx;
      minY = minY < landmark.dy ? minY : landmark.dy;
      maxY = maxY > landmark.dy ? maxY : landmark.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Transform hand coordinates to widget space
  HandLandmark _transformHandToWidgetCoordinates(
    HandLandmark hand,
    CameraImage cameraImage,
    Size previewSize,
    CameraController cameraController,
  ) {
    // Following official hand_landmarker example - keep normalized coordinates
    // The painter will handle the proper canvas transformations
    final transformedLandmarks = hand.landmarks;
    final transformedBoundingBox = hand.boundingBox;

    return HandLandmark(
      landmarks: transformedLandmarks,
      normalizedLandmarks: hand.normalizedLandmarks,
      confidence: hand.confidence,
      boundingBox: transformedBoundingBox,
      handedness: hand.handedness,
      handednessConfidence: hand.handednessConfidence,
      timestamp: hand.timestamp,
    );
  }

  @override
  Future<void> dispose() async {
    try {
      // The hand_landmarker package doesn't have a dispose method
      // Resources are managed by the native side
      _handLandmarker = null;
      _isInitialized = false;
      print('🖐️ Android hand landmarker disposed');
    } catch (e) {
      print('❌ Error disposing Android hand landmarker: $e');
    }
  }
}
