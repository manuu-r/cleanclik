import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/models/detected_object.dart';
import 'package:cleanclik/presentation/widgets/camera/hand_skeleton_painter.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_services.dart';

/// Manages image processing, ML detection, and hand tracking for AR camera
class ARCameraProcessing {
  final ARCameraServices _services;

  // Processing state
  bool _isProcessing = false;
  bool _isProcessingHands = false;
  bool _isProcessingML = false;

  // Processing results
  List<DetectedObject> _detectedObjects = [];
  List<HandLandmark> _handLandmarks = [];

  // Hand persistence with timeout-based approach
  List<HandLandmark> _lastValidHandLandmarks = [];
  DateTime? _lastHandDetectionTime;
  static const Duration _handPersistenceTimeout = Duration(milliseconds: 200);

  // ML persistence
  List<DetectedObject> _lastDetectedObjects = [];
  int _missedObjectFrames = 0;

  // Performance tracking
  double _imageWidth = 0;
  double _imageHeight = 0;
  Size _previewSize = Size.zero;

  // Interpolators for smooth tracking
  final HandLandmarkInterpolator _handInterpolator = HandLandmarkInterpolator();

  // Callbacks for state updates
  VoidCallback? _onStateChanged;
  Function(List<DetectedObject>)? _onObjectsDetected;
  Function(List<HandLandmark>)? _onHandsDetected;

  ARCameraProcessing(this._services);

  // Getters
  bool get isProcessing => _isProcessing;
  bool get isProcessingHands => _isProcessingHands;
  bool get isProcessingML => _isProcessingML;
  List<DetectedObject> get detectedObjects => _detectedObjects;
  List<HandLandmark> get handLandmarks => _handLandmarks;
  double get imageWidth => _imageWidth;
  double get imageHeight => _imageHeight;
  Size get previewSize => _previewSize;

  // Setters for callbacks
  void setStateChangedCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  void setObjectsDetectedCallback(Function(List<DetectedObject>) callback) {
    _onObjectsDetected = callback;
  }

  void setHandsDetectedCallback(Function(List<HandLandmark>) callback) {
    _onHandsDetected = callback;
  }

  /// Main image processing pipeline
  Future<void> processImage(
    CameraImage image,
    CameraController? cameraController,
    BuildContext? context,
  ) async {
    if (_isProcessing || !_services.isInitialized) return;

    _isProcessing = true;
    _notifyStateChanged();

    try {
      // Update image dimensions
      _imageWidth = image.width.toDouble();
      _imageHeight = image.height.toDouble();

      // Calculate preview size if context available
      if (context != null) {
        final screenSize = MediaQuery.of(context).size;
        _previewSize = screenSize;
      }

      // Start performance monitoring
      final stopwatch = Stopwatch()..start();

      // Process ML detection and hand tracking concurrently for better performance
      final futures = <Future>[];

      if (_services.hasMLService) {
        futures.add(_processMLDetection(image, cameraController));
      }

      if (_services.hasHandService) {
        futures.add(_processHandTracking(image, cameraController, context));
      }

      // Wait for both processing tasks to complete
      await Future.wait(futures);

      stopwatch.stop();

      // Log performance metrics
      if (kDebugMode && stopwatch.elapsedMilliseconds > 50) {
        print(
          '🎯 [PROCESSING] Frame processed in ${stopwatch.elapsedMilliseconds}ms '
          '(${_detectedObjects.length} objects, ${_handLandmarks.length} hands)',
        );
      }

      // Track performance with service if available
      if (_services.performanceService != null) {
        // Performance service doesn't have recordFrameProcessingTime method
        // Just log the performance for now
        print('🎯 [PROCESSING] Frame time: ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      print('❌ [PROCESSING] Image processing error: $e');
    } finally {
      _isProcessing = false;
      _notifyStateChanged();
    }
  }

  /// Process ML object detection
  Future<void> _processMLDetection(
    CameraImage image,
    CameraController? cameraController,
  ) async {
    if (_isProcessingML ||
        !_services.hasMLService ||
        cameraController == null) {
      return;
    }

    _isProcessingML = true;

    try {
      // Use unified ML service directly and get results
      final newObjects = await _services.mlService!.processImage(
        image,
        cameraController,
      );

      // Update detected objects with enhanced filtering and persistence
      _updateDetectedObjectsWithPersistence(newObjects);

      if (newObjects.isNotEmpty) {
        print('🎯 [PROCESSING] ML detected ${newObjects.length} objects');
      }
    } catch (e) {
      print('❌ [PROCESSING] ML detection failed: $e');
      _updateDetectedObjectsWithPersistence([]);
    } finally {
      _isProcessingML = false;
    }
  }

  /// Process hand tracking
  Future<void> _processHandTracking(
    CameraImage image,
    CameraController? cameraController,
    BuildContext? context,
  ) async {
    if (_isProcessingHands || !_services.hasHandService) return;

    _isProcessingHands = true;

    try {
      // Calculate accurate preview size for coordinate transformation
      Size screenSize = _previewSize;
      if (context != null) {
        screenSize = MediaQuery.of(context).size;
        _previewSize = screenSize;
      }

      // Detect hands with MediaPipe using actual screen size for coordinate transformation
      final hands = await _services.handService!.detectHands(
        image,
        screenSize,
        cameraController,
      );

      // Apply smoothing interpolation for better visual experience
      final smoothedHands = _handInterpolator.interpolate(hands);

      // Analyze gestures if service is available
      if (_services.hasGestureService) {
        try {
          final gestureResults = _services.enhancedGestureService!
              .analyzeGestures(smoothedHands);

          if (kDebugMode && gestureResults.isNotEmpty) {
            print('🤏 [PROCESSING] Analyzed ${gestureResults.length} gestures');
          }
        } catch (e) {
          print('⚠️ [PROCESSING] Gesture analysis failed: $e');
        }
      }

      // Update hand landmarks with timeout-based persistence
      _updateHandLandmarksWithPersistence(smoothedHands);
    } catch (e) {
      print('❌ [PROCESSING] Hand processing error: $e');
      _updateHandLandmarksWithPersistence([]);
    } finally {
      _isProcessingHands = false;
    }
  }

  /// Update detected objects with enhanced filtering and persistence
  void _updateDetectedObjectsWithPersistence(List<DetectedObject> newObjects) {
    List<DetectedObject> filteredObjects = newObjects;

    if (filteredObjects.isNotEmpty) {
      _detectedObjects = filteredObjects;
      _lastDetectedObjects = List<DetectedObject>.from(filteredObjects);
      _missedObjectFrames = 0;
    } else {
      _missedObjectFrames++;
      if (_missedObjectFrames < 3) {
        // Keep last detected objects for a few frames to reduce flickering
        _detectedObjects = List<DetectedObject>.from(_lastDetectedObjects);
      } else {
        _detectedObjects = [];
        _lastDetectedObjects = [];
        _missedObjectFrames = 0;
      }
    }

    _onObjectsDetected?.call(_detectedObjects);
  }

  /// Update hand landmarks with proper timeout-based persistence
  void _updateHandLandmarksWithPersistence(List<HandLandmark> newHands) {
    final now = DateTime.now();

    if (newHands.isNotEmpty) {
      // We have valid new hand detections
      _lastValidHandLandmarks = List<HandLandmark>.from(newHands);
      _lastHandDetectionTime = now;

      _handLandmarks = newHands;

      if (kDebugMode) {
        print(
          '🖐️ [PROCESSING] Updated with ${newHands.length} fresh hand landmarks',
        );
      }
    } else {
      // No new hands detected, check if we should use persisted ones
      if (_lastHandDetectionTime != null &&
          _lastValidHandLandmarks.isNotEmpty) {
        final timeSinceLastDetection = now.difference(_lastHandDetectionTime!);

        if (timeSinceLastDetection < _handPersistenceTimeout) {
          // Use persisted hands - they're still recent enough
          _handLandmarks = List<HandLandmark>.from(_lastValidHandLandmarks);

          if (kDebugMode) {
            print(
              '🖐️ [PROCESSING] Using persisted hand landmarks (${timeSinceLastDetection.inMilliseconds}ms old)',
            );
          }
        } else {
          // Timeout exceeded, clear hands
          _handLandmarks = [];
          _lastValidHandLandmarks.clear();
          _lastHandDetectionTime = null;

          if (kDebugMode) {
            print(
              '🖐️ [PROCESSING] Hand persistence timeout exceeded, clearing landmarks',
            );
          }
        }
      } else {
        // No previous valid hands or already cleared
        _handLandmarks = [];
      }
    }

    _onHandsDetected?.call(_handLandmarks);
  }

  /// Process unified pickup detection if services are available
  Future<void> processPickupDetection() async {
    if (!_services.hasObjectManagementService) {
      return;
    }

    try {
      // Set coordinate context for proper hand coordinate transformation
      final screenSize = _previewSize;
      final imageSize = Size(_imageWidth, _imageHeight);

      if (screenSize.width > 0 &&
          screenSize.height > 0 &&
          imageSize.width > 0 &&
          imageSize.height > 0) {
        _services.objectManagementService!.setCoordinateContext(
          screenSize,
          imageSize,
        );
      }

      // Unified pickup service can work with empty hands/objects
      // It will handle the empty cases internally
      _services.objectManagementService!.processFrame(
        _detectedObjects,
        _handLandmarks,
      );

      if (kDebugMode &&
          (_handLandmarks.isNotEmpty || _detectedObjects.isNotEmpty)) {
        print(
          '🎯 [PROCESSING] Unified pickup analysis: ${_detectedObjects.length} objects, ${_handLandmarks.length} hands',
        );
      }
    } catch (e) {
      print('⚠️ [PROCESSING] Unified pickup detection failed: $e');
    }
  }

  /// Reset all processing state
  void reset() {
    _detectedObjects.clear();
    _handLandmarks.clear();
    _lastValidHandLandmarks.clear();
    _lastDetectedObjects.clear();
    _lastHandDetectionTime = null;
    _missedObjectFrames = 0;
    _handInterpolator.reset();
    _isProcessing = false;
    _isProcessingHands = false;
    _isProcessingML = false;

    _notifyStateChanged();
  }

  /// Get processing performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'is_processing': _isProcessing,
      'is_processing_hands': _isProcessingHands,
      'is_processing_ml': _isProcessingML,
      'detected_objects_count': _detectedObjects.length,
      'hand_landmarks_count': _handLandmarks.length,
      'missed_object_frames': _missedObjectFrames,
      'has_persisted_hands': _lastValidHandLandmarks.isNotEmpty,
      'hand_persistence_age_ms': _lastHandDetectionTime != null
          ? DateTime.now().difference(_lastHandDetectionTime!).inMilliseconds
          : null,
      'image_dimensions': '${_imageWidth.toInt()}x${_imageHeight.toInt()}',
      'preview_size':
          '${_previewSize.width.toInt()}x${_previewSize.height.toInt()}',
    };
  }

  /// Notify state change callback
  void _notifyStateChanged() {
    _onStateChanged?.call();
  }

  /// Dispose resources
  void dispose() {
    print('🎯 [PROCESSING] Disposing AR camera processing...');

    // Reset all state
    reset();

    // Clear callbacks
    _onStateChanged = null;
    _onObjectsDetected = null;
    _onHandsDetected = null;

    // Dispose interpolator
    _handInterpolator.dispose();

    print('✅ [PROCESSING] AR camera processing disposed');
  }
}
