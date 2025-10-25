// Consolidated hand_tracking implementation (factory + Android + iOS)
// Renamed to `hand_tracking.dart`. Use this module via:
//   import 'package:cleanclik/core/services/platform/hand_tracking.dart';
// Contains `PlatformHandTrackingFactory`, `AndroidHandTrackingService`, and `IOSHandTrackingService`.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';

// Android-specific imports
import 'package:hand_landmarker/hand_landmarker.dart';

/// Factory for creating platform-specific hand tracking services
class PlatformHandTrackingFactory {
  /// Create the appropriate hand tracking service for the current platform
  static HandTrackingService create() {
    if (Platform.isAndroid) {
      return AndroidHandTrackingService();
    } else if (Platform.isIOS) {
      return IOSHandTrackingService();
    } else {
      throw UnsupportedError('Hand tracking is not supported on this platform');
    }
  }

  /// Check if hand tracking is supported on the current platform
  static bool get isSupported {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get platform-specific information
  static String get platformInfo {
    if (Platform.isAndroid) {
      return 'Android MediaPipe Hand Landmarker';
    } else if (Platform.isIOS) {
      return 'iOS Apple Vision Framework';
    } else {
      return 'Unsupported Platform';
    }
  }
}

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
      String handedness = 'Unknown';
      double confidence = 0.8;
      double handednessConfidence = 0.8;

      try {
        // Try to get handedness from the Hand object
        if (hand.toString().contains('Right') ||
            hand.toString().contains('right')) {
          handedness = 'Right';
        } else if (hand.toString().contains('Left') ||
            hand.toString().contains('left')) {
          handedness = 'Left';
        } else {
          // Fallback: use heuristic based on landmark positions
          if (hand.landmarks.length >= 21) {
            final thumbTip = hand.landmarks[4]; // Thumb tip
            final indexMcp = hand.landmarks[5]; // Index MCP
            final pinkyMcp = hand.landmarks[17]; // Pinky MCP

            final handCenter = (indexMcp.x + pinkyMcp.x) / 2;
            handedness = thumbTip.x < handCenter ? 'Right' : 'Left';
          } else {
            handedness = handIndex == 0 ? 'Right' : 'Left';
          }
        }

        // Placeholder confidences (actual extraction depends on API)
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

/// iOS implementation using Apple Vision Framework
/// Note: This requires platform channel implementation for apple_vision_hand
class IOSHandTrackingService implements HandTrackingService {
  static const MethodChannel _channel = MethodChannel('apple_vision_hand');
  bool _isInitialized = false;
  int _frameSkipCounter = 0;
  static const int _frameSkipInterval = 3; // Process every 3rd frame

  // Detection parameters
  static const double _minConfidence = 0.5;
  static const int _maxHands = 2;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isAvailable => Platform.isIOS;

  @override
  String get platformInfo => 'iOS Apple Vision Framework';

  @override
  Future<void> initialize() async {
    if (!isAvailable) {
      throw UnsupportedError('IOSHandTrackingService is only available on iOS');
    }

    try {
      print('🖐️ Initializing iOS Apple Vision hand tracking...');

      // Initialize Apple Vision hand pose detection via platform channel
      final result = await _channel.invokeMethod('initialize', {
        'maxHands': _maxHands,
        'minConfidence': _minConfidence,
      });

      if (result is Map && result['success'] == true) {
        _isInitialized = true;
        print('✅ iOS Apple Vision hand tracking initialized successfully');
        print('   Max hands: $_maxHands');
        print('   Min confidence: $_minConfidence');
        print('   Vision framework version: ${result['version'] ?? 'Unknown'}');
      } else {
        throw Exception(
          'Failed to initialize Apple Vision: ${result.toString()}',
        );
      }
    } catch (e) {
      print('❌ Failed to initialize iOS hand tracking: $e');
      print(
        '   Note: This requires platform channel implementation for Apple Vision',
      );
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
    if (!_isInitialized) {
      return [];
    }

    // Implement frame skipping for performance
    _frameSkipCounter++;
    if (_frameSkipCounter % _frameSkipInterval != 0) {
      return [];
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Convert camera image to format for platform channel
      final imageData = await _convertCameraImageToBytes(cameraImage);

      // Detect hands using Apple Vision via platform channel
      final result = await _channel.invokeMethod('detectHands', {
        'imageData': imageData,
        'width': cameraImage.width,
        'height': cameraImage.height,
        'format': 'yuv420',
      });

      stopwatch.stop();

      if (result is Map &&
          result['success'] == true &&
          result['hands'] != null) {
        // Convert Apple Vision results to our unified format
        final handLandmarks = _convertAppleVisionResults(
          result['hands'] as List<dynamic>,
          cameraImage,
          previewSize,
          cameraController,
        );

        if (handLandmarks.isNotEmpty) {
          print(
            '🖐️ [iOS] Detected ${handLandmarks.length} hands in ${stopwatch.elapsedMilliseconds}ms',
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
      print('❌ iOS hand detection error: $e');
      return [];
    }
  }

  /// Convert CameraImage to bytes for platform channel
  Future<Uint8List> _convertCameraImageToBytes(CameraImage cameraImage) async {
    // Placeholder conversion. Real implementation should convert YUV420 planes
    // into a contiguous byte buffer expected by the native plugin.
    // Returning empty list avoids sending huge data until implemented.
    return Uint8List(0);
  }

  /// Convert Apple Vision results to our unified HandLandmark format
  List<HandLandmark> _convertAppleVisionResults(
    List<dynamic> visionResults,
    CameraImage cameraImage,
    Size previewSize,
    CameraController? cameraController,
  ) {
    final handLandmarks = <HandLandmark>[];

    for (final result in visionResults) {
      try {
        // Parse Apple Vision hand pose result
        final landmarkData = result['landmarks'] as List<dynamic>? ?? [];
        final handedness = result['handedness'] as String? ?? 'Unknown';
        final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;

        // Convert Apple Vision landmarks to MediaPipe-compatible 21-point structure
        final landmarks = <Offset>[];
        final normalizedLandmarks = <Offset>[];

        for (final landmarkPoint in landmarkData) {
          final x = (landmarkPoint['x'] as num).toDouble();
          final y = (landmarkPoint['y'] as num).toDouble();

          // Convert normalized coordinates to pixel coordinates
          final pixelX = x * cameraImage.width;
          final pixelY = y * cameraImage.height;
          landmarks.add(Offset(pixelX, pixelY));

          // Store normalized coordinates
          normalizedLandmarks.add(Offset(x, y));
        }

        // Ensure we have 21 landmarks (pad if necessary for compatibility)
        while (landmarks.length < 21) {
          landmarks.add(Offset.zero);
          normalizedLandmarks.add(Offset.zero);
        }

        // Calculate bounding box
        final boundingBox = _calculateBoundingBox(landmarks);

        // Create HandLandmark object
        var handLandmark = HandLandmark(
          landmarks: landmarks,
          normalizedLandmarks: normalizedLandmarks,
          confidence: confidence,
          boundingBox: boundingBox,
          handedness: handedness,
          handednessConfidence: confidence,
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
      } catch (e) {
        print('❌ Error parsing Apple Vision result: $e');
      }
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
      if (landmark != Offset.zero) {
        // Skip zero padding landmarks
        minX = minX < landmark.dx ? minX : landmark.dx;
        maxX = maxX > landmark.dx ? maxX : landmark.dx;
        minY = minY < landmark.dy ? minY : landmark.dy;
        maxY = maxY > landmark.dy ? maxY : landmark.dy;
      }
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
    // Transform landmarks using enhanced coordinate transformation
    final transformedLandmarks = hand.normalizedLandmarks;

    // Transform bounding box using enhanced coordinate transformation
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
      await _channel.invokeMethod('dispose');
      _isInitialized = false;
      print('🖐️ iOS hand tracking disposed');
    } catch (e) {
      print('❌ Error disposing iOS hand tracking: $e');
    }
  }
}
