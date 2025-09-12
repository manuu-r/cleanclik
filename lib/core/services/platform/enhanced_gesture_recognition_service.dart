import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';

/// Enhanced gesture recognition using MediaPipe hand landmarks
class EnhancedGestureRecognitionService {
  bool _isInitialized = false;

  // Motion tracking
  double _currentMotionIntensity = 0.0;
  double _stillnessThreshold = 0.5; // m/s²

  // Gesture detection parameters
  static const double _pinchThreshold = 0.05; // Normalized distance threshold
  static const double _grabThreshold = 0.08; // Threshold for grab gesture
  static const double _confidenceThreshold = 0.7;

  // Gesture state tracking
  final Map<String, GestureState> _handGestureStates = {};

  bool get isInitialized => _isInitialized;
  double get currentMotionIntensity => _currentMotionIntensity;

  /// Initialize the enhanced gesture recognition service
  Future<void> initialize() async {
    try {
      print('🤏 Initializing enhanced gesture recognition...');

      // Start motion tracking
      _startMotionTracking();

      _isInitialized = true;
      print('✅ Enhanced gesture recognition initialized');
    } catch (e) {
      print('❌ Failed to initialize enhanced gesture recognition: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Start motion tracking using device sensors
  void _startMotionTracking() {
    // Listen to accelerometer for motion detection
    accelerometerEvents.listen((AccelerometerEvent event) {
      final intensity = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      _currentMotionIntensity = intensity;
    });
  }

  /// Analyze gestures from hand landmarks
  List<GestureResult> analyzeGestures(List<HandLandmark> hands) {
    if (!_isInitialized || hands.isEmpty) {
      return [];
    }

    final results = <GestureResult>[];

    for (int i = 0; i < hands.length; i++) {
      final hand = hands[i];
      final handId = '${hand.handedness}_$i';

      // Get or create gesture state for this hand
      _handGestureStates[handId] ??= GestureState();
      final gestureState = _handGestureStates[handId]!;

      // Analyze various gestures
      final gestureResult = _analyzeHandGestures(hand, gestureState);
      if (gestureResult != null) {
        results.add(gestureResult);
      }
    }

    return results;
  }

  /// Analyze gestures for a single hand
  GestureResult? _analyzeHandGestures(HandLandmark hand, GestureState state) {
    if (hand.landmarks.length < 21) return null;

    // Calculate various gesture metrics
    final pinchDistance = _calculatePinchDistance(hand);
    final grabStrength = _calculateGrabStrength(hand);
    final fingerExtensions = _calculateFingerExtensions(hand);
    final handOpenness = _calculateHandOpenness(hand);

    // Determine primary gesture
    GestureType primaryGesture = GestureType.none;
    double gestureConfidence = 0.0;

    // Check for pinch gesture (thumb-index proximity)
    if (pinchDistance < _pinchThreshold) {
      primaryGesture = GestureType.pinch;
      gestureConfidence = math.max(
        0.0,
        1.0 - (pinchDistance / _pinchThreshold),
      );
    }
    // Check for grab gesture (all fingers curled)
    else if (grabStrength > _grabThreshold) {
      primaryGesture = GestureType.grab;
      gestureConfidence = math.min(1.0, grabStrength / 0.3);
    }
    // Check for open hand
    else if (handOpenness > 0.7) {
      primaryGesture = GestureType.open;
      gestureConfidence = handOpenness;
    }
    // Check for pointing gesture (index extended, others curled)
    else if (_isPointingGesture(fingerExtensions)) {
      primaryGesture = GestureType.pointing;
      gestureConfidence = fingerExtensions[1]; // Index finger extension
    }

    // Apply confidence threshold
    if (gestureConfidence < _confidenceThreshold) {
      primaryGesture = GestureType.none;
      gestureConfidence = 0.0;
    }

    // Update gesture state
    state.updateGesture(primaryGesture, gestureConfidence);

    // Calculate motion correlation
    final motionCorrelation = _calculateMotionCorrelation(hand, state);

    // Determine if this is a pickup/release action
    final actionType = _determineActionType(
      primaryGesture,
      gestureConfidence,
      motionCorrelation,
      state,
    );

    return GestureResult(
      handId: '${hand.handedness}_${hand.hashCode}',
      handedness: hand.handedness,
      primaryGesture: primaryGesture,
      gestureConfidence: gestureConfidence,
      pinchDistance: pinchDistance,
      grabStrength: grabStrength,
      handOpenness: handOpenness,
      fingerExtensions: fingerExtensions,
      motionCorrelation: motionCorrelation,
      actionType: actionType,
      wristPosition: hand.wrist,
      indexTipPosition: hand.indexTip,
      thumbTipPosition: hand.thumbTip,
    );
  }

  /// Calculate distance between thumb tip and index finger tip
  double _calculatePinchDistance(HandLandmark hand) {
    if (hand.normalizedLandmarks.length <= HandLandmarkIndex.indexFingerTip) {
      return 1.0; // Max distance if landmarks missing
    }

    final thumbTip = hand.normalizedLandmarks[HandLandmarkIndex.thumbTip];
    final indexTip = hand.normalizedLandmarks[HandLandmarkIndex.indexFingerTip];

    final distance = math.sqrt(
      math.pow(thumbTip.dx - indexTip.dx, 2) +
          math.pow(thumbTip.dy - indexTip.dy, 2),
    );

    return distance;
  }

  /// Calculate grab strength based on finger curl
  double _calculateGrabStrength(HandLandmark hand) {
    if (hand.normalizedLandmarks.length < 21) return 0.0;

    // Calculate curl for each finger (except thumb)
    final fingerCurls = <double>[];

    // Index finger curl
    fingerCurls.add(
      _calculateFingerCurl(hand, [
        HandLandmarkIndex.indexFingerMcp,
        HandLandmarkIndex.indexFingerPip,
        HandLandmarkIndex.indexFingerDip,
        HandLandmarkIndex.indexFingerTip,
      ]),
    );

    // Middle finger curl
    fingerCurls.add(
      _calculateFingerCurl(hand, [
        HandLandmarkIndex.middleFingerMcp,
        HandLandmarkIndex.middleFingerPip,
        HandLandmarkIndex.middleFingerDip,
        HandLandmarkIndex.middleFingerTip,
      ]),
    );

    // Ring finger curl
    fingerCurls.add(
      _calculateFingerCurl(hand, [
        HandLandmarkIndex.ringFingerMcp,
        HandLandmarkIndex.ringFingerPip,
        HandLandmarkIndex.ringFingerDip,
        HandLandmarkIndex.ringFingerTip,
      ]),
    );

    // Pinky curl
    fingerCurls.add(
      _calculateFingerCurl(hand, [
        HandLandmarkIndex.pinkyMcp,
        HandLandmarkIndex.pinkyPip,
        HandLandmarkIndex.pinkyDip,
        HandLandmarkIndex.pinkyTip,
      ]),
    );

    // Average curl strength
    return fingerCurls.isNotEmpty
        ? fingerCurls.reduce((a, b) => a + b) / fingerCurls.length
        : 0.0;
  }

  /// Calculate finger curl based on joint angles
  double _calculateFingerCurl(HandLandmark hand, List<int> jointIndices) {
    if (jointIndices.length < 4) return 0.0;

    final landmarks = hand.normalizedLandmarks;
    if (landmarks.length <= jointIndices.last) return 0.0;

    // Calculate angles between consecutive joints
    double totalCurl = 0.0;
    int validAngles = 0;

    for (int i = 0; i < jointIndices.length - 2; i++) {
      final p1 = landmarks[jointIndices[i]];
      final p2 = landmarks[jointIndices[i + 1]];
      final p3 = landmarks[jointIndices[i + 2]];

      final angle = _calculateAngle(p1, p2, p3);
      if (angle.isFinite) {
        // Convert angle to curl strength (smaller angle = more curl)
        totalCurl += math.max(0.0, (math.pi - angle) / math.pi);
        validAngles++;
      }
    }

    return validAngles > 0 ? totalCurl / validAngles : 0.0;
  }

  /// Calculate angle between three points
  double _calculateAngle(Offset p1, Offset p2, Offset p3) {
    final v1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
    final v2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);

    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = math.sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
    final mag2 = math.sqrt(v2.dx * v2.dx + v2.dy * v2.dy);

    if (mag1 == 0 || mag2 == 0) return 0.0;

    final cosAngle = dot / (mag1 * mag2);
    return math.acos(cosAngle.clamp(-1.0, 1.0));
  }

  /// Calculate finger extensions (how extended each finger is)
  List<double> _calculateFingerExtensions(HandLandmark hand) {
    final extensions = <double>[];

    if (hand.normalizedLandmarks.length < 21) {
      return List.filled(5, 0.0); // Return zeros if insufficient landmarks
    }

    // Thumb extension (different calculation due to thumb orientation)
    extensions.add(_calculateThumbExtension(hand));

    // Other fingers extension
    extensions.add(
      1.0 -
          _calculateFingerCurl(hand, [
            HandLandmarkIndex.indexFingerMcp,
            HandLandmarkIndex.indexFingerPip,
            HandLandmarkIndex.indexFingerDip,
            HandLandmarkIndex.indexFingerTip,
          ]),
    );

    extensions.add(
      1.0 -
          _calculateFingerCurl(hand, [
            HandLandmarkIndex.middleFingerMcp,
            HandLandmarkIndex.middleFingerPip,
            HandLandmarkIndex.middleFingerDip,
            HandLandmarkIndex.middleFingerTip,
          ]),
    );

    extensions.add(
      1.0 -
          _calculateFingerCurl(hand, [
            HandLandmarkIndex.ringFingerMcp,
            HandLandmarkIndex.ringFingerPip,
            HandLandmarkIndex.ringFingerDip,
            HandLandmarkIndex.ringFingerTip,
          ]),
    );

    extensions.add(
      1.0 -
          _calculateFingerCurl(hand, [
            HandLandmarkIndex.pinkyMcp,
            HandLandmarkIndex.pinkyPip,
            HandLandmarkIndex.pinkyDip,
            HandLandmarkIndex.pinkyTip,
          ]),
    );

    return extensions;
  }

  /// Calculate thumb extension
  double _calculateThumbExtension(HandLandmark hand) {
    if (hand.normalizedLandmarks.length <= HandLandmarkIndex.thumbTip) {
      return 0.0;
    }

    final wrist = hand.normalizedLandmarks[HandLandmarkIndex.wrist];
    final thumbTip = hand.normalizedLandmarks[HandLandmarkIndex.thumbTip];
    final thumbMcp = hand.normalizedLandmarks[HandLandmarkIndex.thumbMcp];

    // Calculate distance from wrist to thumb tip vs wrist to thumb MCP
    final wristToTip = math.sqrt(
      math.pow(thumbTip.dx - wrist.dx, 2) + math.pow(thumbTip.dy - wrist.dy, 2),
    );

    final wristToMcp = math.sqrt(
      math.pow(thumbMcp.dx - wrist.dx, 2) + math.pow(thumbMcp.dy - wrist.dy, 2),
    );

    // Extension ratio
    return wristToMcp > 0 ? (wristToTip / wristToMcp).clamp(0.0, 1.0) : 0.0;
  }

  /// Calculate overall hand openness
  double _calculateHandOpenness(HandLandmark hand) {
    final extensions = _calculateFingerExtensions(hand);
    return extensions.isNotEmpty
        ? extensions.reduce((a, b) => a + b) / extensions.length
        : 0.0;
  }

  /// Check if gesture is pointing (index extended, others curled)
  bool _isPointingGesture(List<double> fingerExtensions) {
    if (fingerExtensions.length < 5) return false;

    // Index finger should be extended
    final indexExtended = fingerExtensions[1] > 0.7;

    // Other fingers should be curled
    final othersCarled =
        fingerExtensions[2] < 0.3 &&
        fingerExtensions[3] < 0.3 &&
        fingerExtensions[4] < 0.3;

    return indexExtended && othersCarled;
  }

  /// Calculate motion correlation with hand movement
  double _calculateMotionCorrelation(HandLandmark hand, GestureState state) {
    // Update hand position history
    state.updateHandPosition(hand.wrist);

    // Calculate motion correlation based on hand movement and device motion
    final handMotion = state.getHandMotionIntensity();
    final deviceMotion = _currentMotionIntensity;

    // Correlation between hand movement and device movement
    final motionCorrelation = _calculateCorrelation(handMotion, deviceMotion);

    return motionCorrelation.clamp(0.0, 1.0);
  }

  /// Calculate correlation between two motion values
  double _calculateCorrelation(double handMotion, double deviceMotion) {
    // Simple correlation based on motion similarity
    final motionDifference = (handMotion - deviceMotion).abs();
    final maxMotion = math.max(handMotion, deviceMotion);

    if (maxMotion == 0) return 0.0;

    return 1.0 - (motionDifference / maxMotion).clamp(0.0, 1.0);
  }

  /// Determine action type based on gesture analysis
  ActionType _determineActionType(
    GestureType gesture,
    double confidence,
    double motionCorrelation,
    GestureState state,
  ) {
    // Check for pickup action
    if (_isPickupAction(gesture, confidence, motionCorrelation, state)) {
      return ActionType.pickup;
    }

    // Check for release action
    if (_isReleaseAction(gesture, confidence, motionCorrelation, state)) {
      return ActionType.release;
    }

    // Check for hold action
    if (_isHoldAction(gesture, confidence, state)) {
      return ActionType.hold;
    }

    return ActionType.none;
  }

  /// Check if current gesture indicates pickup action
  bool _isPickupAction(
    GestureType gesture,
    double confidence,
    double motionCorrelation,
    GestureState state,
  ) {
    // Pickup: transition from open/none to pinch/grab with motion
    final wasOpen =
        state.previousGesture == GestureType.open ||
        state.previousGesture == GestureType.none;
    final nowGrasping =
        gesture == GestureType.pinch || gesture == GestureType.grab;
    final hasMotion = motionCorrelation > 0.3;
    final highConfidence = confidence > 0.8;

    return wasOpen && nowGrasping && hasMotion && highConfidence;
  }

  /// Check if current gesture indicates release action
  bool _isReleaseAction(
    GestureType gesture,
    double confidence,
    double motionCorrelation,
    GestureState state,
  ) {
    // Release: transition from pinch/grab to open with motion
    final wasGrasping =
        state.previousGesture == GestureType.pinch ||
        state.previousGesture == GestureType.grab;
    final nowOpen = gesture == GestureType.open;
    final hasMotion = motionCorrelation > 0.3;
    final highConfidence = confidence > 0.7;

    return wasGrasping && nowOpen && hasMotion && highConfidence;
  }

  /// Check if current gesture indicates hold action
  bool _isHoldAction(
    GestureType gesture,
    double confidence,
    GestureState state,
  ) {
    // Hold: stable pinch/grab gesture
    final isGrasping =
        gesture == GestureType.pinch || gesture == GestureType.grab;
    final wasGrasping =
        state.previousGesture == GestureType.pinch ||
        state.previousGesture == GestureType.grab;
    final stable = confidence > 0.7;
    final lowMotion = _currentMotionIntensity < _stillnessThreshold;

    return isGrasping && wasGrasping && stable && lowMotion;
  }

  /// Clean up resources
  Future<void> dispose() async {
    _isInitialized = false;
    _handGestureStates.clear();
    print('🤏 Enhanced gesture recognition disposed');
  }
}

/// Gesture types that can be recognized
enum GestureType { none, open, pinch, grab, pointing }

/// Action types derived from gesture analysis
enum ActionType { none, pickup, release, hold }

/// Gesture analysis result
class GestureResult {
  final String handId;
  final String handedness;
  final GestureType primaryGesture;
  final double gestureConfidence;
  final double pinchDistance;
  final double grabStrength;
  final double handOpenness;
  final List<double> fingerExtensions;
  final double motionCorrelation;
  final ActionType actionType;
  final Offset wristPosition;
  final Offset indexTipPosition;
  final Offset thumbTipPosition;

  GestureResult({
    required this.handId,
    required this.handedness,
    required this.primaryGesture,
    required this.gestureConfidence,
    required this.pinchDistance,
    required this.grabStrength,
    required this.handOpenness,
    required this.fingerExtensions,
    required this.motionCorrelation,
    required this.actionType,
    required this.wristPosition,
    required this.indexTipPosition,
    required this.thumbTipPosition,
  });

  @override
  String toString() {
    return 'GestureResult(hand: $handedness, gesture: $primaryGesture, '
        'confidence: ${gestureConfidence.toStringAsFixed(2)}, '
        'action: $actionType)';
  }
}

/// Gesture state tracking for a single hand
class GestureState {
  GestureType _currentGesture = GestureType.none;
  GestureType _previousGesture = GestureType.none;
  double _currentConfidence = 0.0;
  final List<Offset> _handPositionHistory = [];
  static const int _maxHistoryLength = 10;

  GestureType get currentGesture => _currentGesture;
  GestureType get previousGesture => _previousGesture;
  double get currentConfidence => _currentConfidence;

  /// Update gesture state
  void updateGesture(GestureType gesture, double confidence) {
    _previousGesture = _currentGesture;
    _currentGesture = gesture;
    _currentConfidence = confidence;
  }

  /// Update hand position history
  void updateHandPosition(Offset position) {
    _handPositionHistory.add(position);

    // Keep history within limits
    if (_handPositionHistory.length > _maxHistoryLength) {
      _handPositionHistory.removeAt(0);
    }
  }

  /// Get hand motion intensity based on position history
  double getHandMotionIntensity() {
    if (_handPositionHistory.length < 2) return 0.0;

    double totalMotion = 0.0;
    for (int i = 1; i < _handPositionHistory.length; i++) {
      final prev = _handPositionHistory[i - 1];
      final curr = _handPositionHistory[i];

      final distance = math.sqrt(
        math.pow(curr.dx - prev.dx, 2) + math.pow(curr.dy - prev.dy, 2),
      );

      totalMotion += distance;
    }

    return totalMotion / (_handPositionHistory.length - 1);
  }

  /// Reset gesture state
  void reset() {
    _currentGesture = GestureType.none;
    _previousGesture = GestureType.none;
    _currentConfidence = 0.0;
    _handPositionHistory.clear();
  }
}
