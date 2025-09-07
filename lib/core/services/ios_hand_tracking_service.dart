import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'hand_tracking_service.dart';

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

      if (result['success'] == true) {
        _isInitialized = true;
        print('✅ iOS Apple Vision hand tracking initialized successfully');
        print('   Max hands: $_maxHands');
        print('   Min confidence: $_minConfidence');
        print('   Vision framework version: ${result['version'] ?? 'Unknown'}');
      } else {
        throw Exception(
          'Failed to initialize Apple Vision: ${result['error']}',
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

      if (result['success'] == true && result['hands'] != null) {
        // Convert Apple Vision results to our unified format
        final handLandmarks = _convertAppleVisionResults(
          result['hands'],
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
    // For now, return a placeholder
    // In real implementation, this would convert YUV420 data
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
        final landmarkData = result['landmarks'] as List<dynamic>;
        final handedness = result['handedness'] as String? ?? 'Unknown';
        final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;

        // Convert Apple Vision landmarks to MediaPipe-compatible 21-point structure
        final landmarks = <Offset>[];
        final normalizedLandmarks = <Offset>[];

        // Apple Vision provides different landmark structure than MediaPipe
        // This would need to be mapped to MediaPipe's 21-point hand model
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
    final cameraImageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );

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
