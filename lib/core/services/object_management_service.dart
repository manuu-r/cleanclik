import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/detected_object.dart';
import 'hand_tracking_service.dart';
import 'hand_coordinate_transformer.dart';
import 'inventory_service.dart';

/// Unified pickup detection service combining simplified grasp detection with proximity analysis
/// Replaces both IntelligentPickupService and GeometricPickupService with a single, optimized solution
class ObjectManagementService {
  // Configuration - IMPROVED thresholds for reliable detection
  static const Duration _graspConfirmationTime = Duration(
    milliseconds: 150,
  ); // Further reduced for faster response
  static const Duration _releaseConfirmationTime = Duration(milliseconds: 150);
  static const Duration _objectStabilityTime = Duration(
    milliseconds: 50,
  ); // Further reduced for faster pickup
  static const int _maxCarriedObjects = 5;
  static const int _stabilityFrames =
      3; // Reduced from complex timing to 3 frames
  static const int _temporalSmoothingFrames =
      3; // Frames for confidence smoothing

  // Test mode for easier testing
  static bool _testMode = true;

  // Proximity zones for better object interaction - IMPROVED THRESHOLDS
  static const double _nearProximityThreshold =
      150.0; // Close enough to pickup (was 80.0)
  static const double _closeProximityThreshold =
      220.0; // Targeting zone (was 120.0)
  static const double _farProximityThreshold =
      300.0; // Ignore beyond this (was 180.0)

  // Grasp detection thresholds - IMPROVED FOR BETTER DETECTION
  static const double _fingerCurlThreshold =
      0.2; // Lowered for easier grasp detection (was 0.3)
  static const double _thumbOppositionThreshold =
      50.0; // Increased distance threshold
  static const double _handClosureThreshold =
      120.0; // Increased for more forgiving grasp detection (was 80.0)

  // State tracking
  final Map<String, _UnifiedObjectState> _objectStates = {};
  final List<DetectedObject> _carriedObjects = [];

  // Stream controllers - maintaining same interface for compatibility
  final StreamController<List<DetectedObject>> _carriedObjectsController =
      StreamController<List<DetectedObject>>.broadcast();
  final StreamController<DetectedObject> _objectPickedUpController =
      StreamController<DetectedObject>.broadcast();
  final StreamController<String> _objectReleasedController =
      StreamController<String>.broadcast();
  final StreamController<PickupEvent> _pickupEventsController =
      StreamController<PickupEvent>.broadcast();

  bool _isInitialized = false;

  // Inventory integration
  InventoryService? _inventoryService;

  // Performance optimization - frame processing limits
  static const int _maxFramesPerSecond = 30;
  static const Duration _minFrameInterval = Duration(
    milliseconds: 33,
  ); // ~30fps
  DateTime _lastFrameProcessTime = DateTime.now();
  int _frameCount = 0;
  int _skippedFrames = 0;

  // Error handling and retry mechanisms
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  final Map<String, int> _inventoryRetryAttempts = {};

  // Coordinate transformation context
  Size? _screenSize;
  Size? _imageSize;

  // Getters - maintaining same interface
  List<DetectedObject> get carriedObjects => List.unmodifiable(_carriedObjects);
  Stream<List<DetectedObject>> get carriedObjectsStream =>
      _carriedObjectsController.stream;
  Stream<DetectedObject> get objectPickedUpStream =>
      _objectPickedUpController.stream;
  Stream<String> get objectReleasedStream => _objectReleasedController.stream;
  Stream<PickupEvent> get pickupEventsStream => _pickupEventsController.stream;

  /// Initialize the unified pickup service with inventory integration
  Future<void> initialize({
    InventoryService? inventoryService,
    bool testMode = false,
  }) async {
    if (_isInitialized) return;

    print('🎯 [PICKUP] Initializing unified pickup detection service...');

    // Set test mode for easier testing
    _testMode = testMode;
    if (_testMode) {
      print('🧪 [PICKUP] Test mode enabled - relaxed thresholds for testing');
    }

    // Set up inventory integration
    _inventoryService = inventoryService;
    if (_inventoryService != null) {
      print('📦 [PICKUP] Inventory integration enabled');

      // Listen to pickup events and automatically add to inventory
      _objectPickedUpController.stream.listen(_onObjectPickedUp);
      _objectReleasedController.stream.listen(_onObjectReleased);
      print(
        '🔗 [PICKUP] Connected to inventory service for automatic item addition and removal',
      );
    } else {
      print(
        '⚠️ [PICKUP] No inventory service provided - items will not be automatically added to inventory',
      );
    }

    _isInitialized = true;
    print('✅ [PICKUP] Unified pickup detection initialized successfully');
    print(
      '🎯 [PICKUP] Improvements: ML confidence=0.5, fast-track for close+grasp, no landfill items',
    );
  }

  /// Set screen and image sizes for coordinate transformation
  void setCoordinateContext(Size screenSize, Size imageSize) {
    _screenSize = screenSize;
    _imageSize = imageSize;
    print(
      '🔧 [PICKUP] Coordinate context set: screen=${screenSize.width.toInt()}x${screenSize.height.toInt()}, '
      'image=${imageSize.width.toInt()}x${imageSize.height.toInt()}',
    );
  }

  /// Main processing method - unified logic for each frame with performance optimization
  void processFrame(
    List<DetectedObject> detectedObjects,
    List<HandLandmark> handLandmarks,
  ) {
    if (!_isInitialized) {
      print('❌ [PICKUP] Service not initialized, skipping frame');
      return;
    }

    // Check coordinate context
    if (_screenSize == null || _imageSize == null) {
      print('⚠️ [PICKUP] Coordinate context not set, skipping frame');
      return;
    }

    final now = DateTime.now();
    final frameId =
        now.millisecondsSinceEpoch % 10000; // Short frame ID for tracking

    // PERFORMANCE OPTIMIZATION: Frame rate limiting
    if (now.difference(_lastFrameProcessTime) < _minFrameInterval) {
      _skippedFrames++;
      if (_skippedFrames % 10 == 0) {
        print(
          '⏭️ [PICKUP] Frame rate limiting: skipped $_skippedFrames frames',
        );
      }
      return;
    }
    _lastFrameProcessTime = now;
    _frameCount++;

    // PERFORMANCE OPTIMIZATION: Early exit if no hands detected - skip expensive calculations
    if (handLandmarks.isEmpty) {
      if (detectedObjects.isEmpty) {
        print(
          '⏭️ [PICKUP-$frameId] Empty frame - no objects or hands detected',
        );
        return;
      } else {
        print(
          '⏭️ [PICKUP-$frameId] No hands detected - skipping expensive grasp calculations for ${detectedObjects.length} objects',
        );
        // Still update object detection states but skip grasp analysis
        _updateObjectDetectionOnly(detectedObjects, now);
        return;
      }
    }

    print(
      '🔄 [PICKUP-$frameId] Processing frame: ${detectedObjects.length} objects, ${handLandmarks.length} hands',
    );

    // Log detailed object information
    for (final obj in detectedObjects) {
      final existingState = _objectStates[obj.trackingId];
      print(
        '📦 [PICKUP-$frameId] Object ${obj.codeName} (${obj.trackingId}): '
        'pos=${obj.boundingBox.center.dx.toInt()},${obj.boundingBox.center.dy.toInt()}, '
        'size=${obj.boundingBox.width.toInt()}x${obj.boundingBox.height.toInt()}, '
        'confidence=${obj.confidence.toStringAsFixed(2)}, '
        'existing_state=${existingState != null ? "yes" : "no"}',
      );
    }

    // Log detailed hand information with coordinate transformation
    for (int i = 0; i < handLandmarks.length; i++) {
      final hand = handLandmarks[i];
      final handId = '${hand.handedness}_$i';

      // Transform hand center coordinates
      final transformResult = HandCoordinateTransformer.transformHandCenter(
        hand.normalizedLandmarks,
        _screenSize!,
        _imageSize!,
      );

      // Log coordinate transformation details
      CoordinateDebugger.logRawLandmarks(hand.normalizedLandmarks, handId);
      CoordinateDebugger.logTransformationSteps(
        hand.normalizedLandmarks.isNotEmpty
            ? hand.normalizedLandmarks[0]
            : Offset.zero,
        transformResult.screenCoordinates,
        _screenSize!,
        handId,
      );
      CoordinateDebugger.logValidationResult(
        transformResult.screenCoordinates,
        transformResult.isValid,
        transformResult.errorMessage ?? 'Valid coordinates',
        handId,
      );

      print(
        '🖐️ [PICKUP-$frameId] Hand $i (${hand.handedness}): '
        'transformed_center=${transformResult.screenCoordinates.dx.toInt()},${transformResult.screenCoordinates.dy.toInt()}, '
        'valid=${transformResult.isValid}, '
        'confidence=${hand.confidence.toStringAsFixed(2)}, '
        'landmarks=${hand.landmarks.length}',
      );
    }

    // Update object states with unified analysis
    _updateObjectStates(detectedObjects, handLandmarks, now);

    // Process unified pickup/release logic
    _processUnifiedLogic(now);

    // Clean up old states
    _cleanupOldStates(detectedObjects, now);

    // Frame processing summary
    final targetingObjects = _objectStates.values
        .where((s) => s.isBeingTargeted)
        .length;
    final carriedCount = _carriedObjects.length;

    if (detectedObjects.isNotEmpty || handLandmarks.isNotEmpty) {
      print(
        '📋 [PICKUP-$frameId] Frame summary: '
        'states=${_objectStates.length}, '
        'targeting=$targetingObjects, '
        'carried=$carriedCount, '
        'processing_time=${DateTime.now().difference(now).inMilliseconds}ms',
      );
    }
  }

  /// Update object states with unified grasp + proximity analysis
  void _updateObjectStates(
    List<DetectedObject> detectedObjects,
    List<HandLandmark> handLandmarks,
    DateTime now,
  ) {
    for (final obj in detectedObjects) {
      final state = _objectStates.putIfAbsent(obj.trackingId, () {
        print(
          '🆕 [PICKUP] New unified object state: ${obj.trackingId} (${obj.codeName}) at ${obj.boundingBox.center}',
        );
        return _UnifiedObjectState(obj.trackingId);
      });

      // Update object detection
      state.updateDetection(obj, now);

      // Analyze all hands for this object
      for (int handIndex = 0; handIndex < handLandmarks.length; handIndex++) {
        final hand = handLandmarks[handIndex];

        print(
          '🔍 [PICKUP] Analyzing ${obj.codeName} with Hand $handIndex (${hand.handedness})',
        );

        // Step 1: Calculate object proximity (multi-point analysis)
        final proximityAnalysis = _analyzeObjectProximity(
          obj.boundingBox,
          hand,
          handIndex,
        );
        print(
          '📏 [PICKUP] Proximity analysis: zone=${proximityAnalysis.zone}, '
          'confidence=${proximityAnalysis.confidence.toStringAsFixed(3)}, '
          'min_distance=${proximityAnalysis.minFingertipDistance.toStringAsFixed(1)}px, '
          'hand_orientation=${proximityAnalysis.handOrientation.toStringAsFixed(2)}',
        );

        // Step 2: Analyze hand geometry (simplified grasp detection)
        final graspAnalysis = _analyzeSimplifiedGrasp(hand, handIndex);
        print(
          '🤏 [PICKUP] Grasp analysis: type=${graspAnalysis.graspType}, '
          'confidence=${graspAnalysis.confidence.toStringAsFixed(3)}, '
          'avg_curl=${graspAnalysis.avgFingerCurl.toStringAsFixed(2)}, '
          'thumb_opposition=${graspAnalysis.thumbOpposition.oppositionStrength.toStringAsFixed(2)}, '
          'hand_closure=${graspAnalysis.handClosure.toStringAsFixed(1)}px',
        );

        // Step 3: Combine both analyses
        state.updateUnifiedAnalysis(
          hand,
          proximityAnalysis,
          graspAnalysis,
          now,
        );

        print(
          '🎯 [PICKUP] Combined analysis for ${obj.codeName}: '
          'overall_confidence=${state.overallConfidence.toStringAsFixed(3)}, '
          'targeting=${state.isBeingTargeted}, '
          'carried=${state.isCarried}',
        );
      }
    }
  }

  /// Analyze object proximity with multi-point distance measurements
  ProximityAnalysis _analyzeObjectProximity(
    Rect objectBounds,
    HandLandmark hand,
    int handIndex,
  ) {
    final stopwatch = Stopwatch()..start();
    final handId = '${hand.handedness}_$handIndex';

    if (hand.normalizedLandmarks.length < 21) {
      print(
        '⚠️ [PICKUP] Invalid hand landmarks: ${hand.normalizedLandmarks.length} (need 21)',
      );
      return ProximityAnalysis.empty();
    }

    final objectCenter = objectBounds.center;
    final objectSize = math.max(objectBounds.width, objectBounds.height);

    // Transform hand coordinates to screen space
    final transformResult = HandCoordinateTransformer.transformHandCenter(
      hand.normalizedLandmarks,
      _screenSize!,
      _imageSize!,
    );

    // Skip analysis if coordinate transformation failed
    if (!transformResult.isValid) {
      print(
        '❌ [PICKUP] Skipping proximity analysis for $handId: ${transformResult.errorMessage}',
      );
      return ProximityAnalysis.empty();
    }

    final handCenter = transformResult.screenCoordinates;

    // Transform all fingertip landmarks to screen coordinates
    final transformedLandmarks =
        HandCoordinateTransformer.transformAllLandmarks(
          hand.normalizedLandmarks,
          _screenSize!,
          _imageSize!,
        );

    final fingertips = [
      transformedLandmarks[4], // Thumb
      transformedLandmarks[8], // Index
      transformedLandmarks[12], // Middle
      transformedLandmarks[16], // Ring
      transformedLandmarks[20], // Pinky
    ];

    // Calculate distances using transformed coordinates
    final handCenterDistance = _calculateDistance(handCenter, objectCenter);
    final fingertipDistances = fingertips
        .map((tip) => _calculateDistance(tip, objectCenter))
        .toList();
    final minFingertipDistance = fingertipDistances.reduce(math.min);
    final avgFingertipDistance =
        fingertipDistances.reduce((a, b) => a + b) / fingertipDistances.length;

    // Log proximity calculation details
    CoordinateDebugger.logProximityCalculation(
      handCenter,
      objectCenter,
      minFingertipDistance,
      handId,
      'object_${objectBounds.center.dx.toInt()}_${objectBounds.center.dy.toInt()}',
    );

    // Object size consideration - larger objects need closer proximity
    final sizeAdjustedThreshold = _nearProximityThreshold + (objectSize * 0.2);

    // Hand orientation awareness - check if hand is facing the object
    final handOrientation = _calculateHandOrientation(
      transformedLandmarks,
      objectCenter,
    );

    // Determine proximity zone
    ProximityZone zone;
    double proximityConfidence;

    if (minFingertipDistance < sizeAdjustedThreshold) {
      zone = ProximityZone.near;
      proximityConfidence = math.max(
        0.0,
        1.0 - (minFingertipDistance / sizeAdjustedThreshold),
      );
    } else if (minFingertipDistance < _closeProximityThreshold) {
      zone = ProximityZone.close;
      proximityConfidence =
          math.max(
            0.0,
            1.0 - (minFingertipDistance / _closeProximityThreshold),
          ) *
          0.7;
    } else if (minFingertipDistance < _farProximityThreshold) {
      zone = ProximityZone.far;
      proximityConfidence =
          math.max(0.0, 1.0 - (minFingertipDistance / _farProximityThreshold)) *
          0.3;
    } else {
      zone = ProximityZone.ignore;
      proximityConfidence = 0.0;
    }

    // Apply hand orientation bonus
    proximityConfidence *= handOrientation;

    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds > 5) {
      print(
        '⏱️ [PICKUP] Proximity analysis took ${stopwatch.elapsedMilliseconds}ms',
      );
    }

    return ProximityAnalysis(
      zone: zone,
      confidence: proximityConfidence,
      handCenterDistance: handCenterDistance,
      minFingertipDistance: minFingertipDistance,
      avgFingertipDistance: avgFingertipDistance,
      handOrientation: handOrientation,
    );
  }

  /// Analyze simplified grasp using finger curl and hand closure
  GraspAnalysis _analyzeSimplifiedGrasp(HandLandmark hand, int handIndex) {
    final stopwatch = Stopwatch()..start();

    if (hand.normalizedLandmarks.length < 21) {
      print(
        '⚠️ [PICKUP] Invalid hand landmarks for grasp analysis: ${hand.normalizedLandmarks.length}',
      );
      return GraspAnalysis.empty();
    }

    // Transform landmarks to screen coordinates for consistent measurements
    final transformedLandmarks =
        HandCoordinateTransformer.transformAllLandmarks(
          hand.normalizedLandmarks,
          _screenSize!,
          _imageSize!,
        );

    // Simplified finger curl calculation using joint angles
    final fingerCurls = _calculateSimplifiedFingerCurls(transformedLandmarks);
    final avgFingerCurl = fingerCurls.values.isNotEmpty
        ? fingerCurls.values.reduce((a, b) => a + b) / fingerCurls.values.length
        : 0.0;

    // Thumb opposition detection with adaptive thresholds
    final thumbOpposition = _calculateThumbOpposition(transformedLandmarks);

    // Hand closure measurement (distance between fingertips)
    final handClosure = _calculateHandClosure(transformedLandmarks);

    // Determine grasp type and confidence
    GraspType graspType;
    double graspConfidence = 0.0;

    // Improved grasp classification - more forgiving for real-world usage
    if (thumbOpposition.oppositionStrength > 0.4 && // Lowered from 0.6
        handClosure < _handClosureThreshold) {
      if (avgFingerCurl < 0.3) {
        graspType = GraspType.pinch;
        graspConfidence =
            thumbOpposition.oppositionStrength * 0.8 +
            (1.0 - handClosure / 150.0) *
                0.2; // More forgiving closure calculation
      } else {
        graspType = GraspType.precisionGrip;
        graspConfidence =
            (thumbOpposition.oppositionStrength + avgFingerCurl) *
            0.6; // Increased multiplier
      }
    } else if (avgFingerCurl > _fingerCurlThreshold &&
        handClosure < _handClosureThreshold) {
      graspType = GraspType.powerGrip;
      graspConfidence =
          avgFingerCurl * 0.8 +
          thumbOpposition.oppositionStrength *
              0.2; // Increased finger curl weight
    } else if (avgFingerCurl >=
            0.1 && // Lowered from 0.2 to catch partial grasps
        handClosure < _handClosureThreshold * 1.2) {
      // More forgiving closure threshold
      graspType = GraspType.partialGrasp; // New grasp type for partial grasps
      graspConfidence = (avgFingerCurl * 2.0 + (1.0 - handClosure / 200.0))
          .clamp(0.0, 0.8); // Better confidence for partial grasps
    } else if (avgFingerCurl < 0.1 &&
        handClosure > _handClosureThreshold * 1.5) {
      graspType = GraspType.openPalm;
      graspConfidence = 0.1; // Low confidence for open palm
    } else {
      graspType = GraspType.unknown;
      graspConfidence = math.max(
        0.0,
        avgFingerCurl * 0.5,
      ); // Give some confidence based on finger curl
    }

    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds > 5) {
      print(
        '⏱️ [PICKUP] Grasp analysis took ${stopwatch.elapsedMilliseconds}ms',
      );
    }

    return GraspAnalysis(
      graspType: graspType,
      confidence: graspConfidence,
      fingerCurls: fingerCurls,
      avgFingerCurl: avgFingerCurl,
      thumbOpposition: thumbOpposition,
      handClosure: handClosure,
    );
  }

  /// Calculate simplified finger curls using joint angles (faster processing)
  Map<String, double> _calculateSimplifiedFingerCurls(List<Offset> landmarks) {
    final fingerJoints = {
      'thumb': [1, 2, 3, 4],
      'index': [5, 6, 7, 8],
      'middle': [9, 10, 11, 12],
      'ring': [13, 14, 15, 16],
      'pinky': [17, 18, 19, 20],
    };

    final fingerCurls = <String, double>{};

    for (final entry in fingerJoints.entries) {
      final fingerName = entry.key;
      final joints = entry.value;

      if (joints.length >= 4) {
        // Simplified curl calculation using distance ratios
        final baseToTip = _calculateDistance(
          landmarks[joints[0]],
          landmarks[joints[3]],
        );
        final expectedStraightDistance =
            _calculateDistance(landmarks[joints[0]], landmarks[joints[1]]) +
            _calculateDistance(landmarks[joints[1]], landmarks[joints[2]]) +
            _calculateDistance(landmarks[joints[2]], landmarks[joints[3]]);

        // Curl factor: 0.0 = straight, 1.0 = fully curled
        final curlFactor = math.max(
          0.0,
          math.min(1.0, 1.0 - (baseToTip / expectedStraightDistance)),
        );

        fingerCurls[fingerName] = curlFactor;
      }
    }

    return fingerCurls;
  }

  /// Calculate thumb opposition with adaptive thresholds
  ThumbOppositionAnalysis _calculateThumbOpposition(List<Offset> landmarks) {
    if (landmarks.length < 21) return ThumbOppositionAnalysis.empty();

    final thumbTip = landmarks[4];
    final fingertips = [
      landmarks[8], // Index
      landmarks[12], // Middle
      landmarks[16], // Ring
      landmarks[20], // Pinky
    ];

    final distances = <String, double>{};
    final fingerNames = ['index', 'middle', 'ring', 'pinky'];

    for (int i = 0; i < fingertips.length; i++) {
      distances[fingerNames[i]] = _calculateDistance(thumbTip, fingertips[i]);
    }

    final closestEntry = distances.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    final oppositionStrength = math.max(
      0.0,
      1.0 - (closestEntry.value / _thumbOppositionThreshold),
    );

    return ThumbOppositionAnalysis(
      distances: distances,
      closestFinger: closestEntry.key,
      closestDistance: closestEntry.value,
      oppositionStrength: oppositionStrength,
    );
  }

  /// Calculate hand closure (distance between fingertips)
  double _calculateHandClosure(List<Offset> landmarks) {
    if (landmarks.length < 21) return double.infinity;

    final fingertips = [
      landmarks[4], // Thumb
      landmarks[8], // Index
      landmarks[12], // Middle
      landmarks[16], // Ring
      landmarks[20], // Pinky
    ];

    // Calculate maximum spread between fingertips
    double maxSpread = 0.0;
    for (int i = 0; i < fingertips.length; i++) {
      for (int j = i + 1; j < fingertips.length; j++) {
        final distance = _calculateDistance(fingertips[i], fingertips[j]);
        maxSpread = math.max(maxSpread, distance);
      }
    }

    return maxSpread;
  }

  /// Calculate hand orientation relative to object
  double _calculateHandOrientation(
    List<Offset> landmarks,
    Offset objectCenter,
  ) {
    if (landmarks.length < 21) return 0.5; // Neutral orientation

    final wrist = landmarks[0];
    final middleMcp = landmarks[9];

    // Calculate hand direction vector
    final handDirection = Offset(
      middleMcp.dx - wrist.dx,
      middleMcp.dy - wrist.dy,
    );
    final handToObject = Offset(
      objectCenter.dx - wrist.dx,
      objectCenter.dy - wrist.dy,
    );

    // Calculate dot product to determine if hand is facing object
    final handMag = math.sqrt(
      handDirection.dx * handDirection.dx + handDirection.dy * handDirection.dy,
    );
    final objectMag = math.sqrt(
      handToObject.dx * handToObject.dx + handToObject.dy * handToObject.dy,
    );

    if (handMag == 0 || objectMag == 0) return 0.5;

    final dotProduct =
        (handDirection.dx * handToObject.dx +
            handDirection.dy * handToObject.dy) /
        (handMag * objectMag);

    // Convert to orientation score (0.0 = facing away, 1.0 = facing towards)
    return math.max(
      0.3,
      (dotProduct + 1.0) / 2.0,
    ); // Minimum 0.3 to avoid complete rejection
  }

  /// Process unified pickup and release logic with object prioritization
  void _processUnifiedLogic(DateTime now) {
    // First, collect all eligible objects for pickup
    final eligiblePickups = <_UnifiedObjectState>[];

    for (final state in _objectStates.values) {
      final obj = state.lastDetectedObject;
      if (obj == null) continue;

      // Check for unified pickup eligibility
      if (!state.isCarried && state.shouldPickupUnified(now)) {
        eligiblePickups.add(state);
      }
      // Check for unified release
      else if (state.isCarried && state.shouldReleaseUnified(now)) {
        _releaseObject(obj.trackingId, state, now);
      }
    }

    // If multiple objects are eligible for pickup, prioritize the best candidate
    if (eligiblePickups.isNotEmpty) {
      final bestCandidate = _selectBestPickupCandidate(eligiblePickups);
      if (bestCandidate != null) {
        final obj = bestCandidate.lastDetectedObject!;
        print(
          '🎯 [PICKUP] 🎯 PRIORITIZED: Selected ${obj.codeName} from ${eligiblePickups.length} candidates',
        );
        _pickupObject(obj, bestCandidate, now);
      }
    }
  }

  /// Select the best pickup candidate from multiple eligible objects
  /// Prioritizes based on proximity, grasp confidence, and object confidence
  _UnifiedObjectState? _selectBestPickupCandidate(
    List<_UnifiedObjectState> candidates,
  ) {
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    print(
      '🎯 [PICKUP] 🤔 SELECTION: Choosing from ${candidates.length} eligible objects:',
    );

    // Score each candidate based on multiple factors
    double bestScore = -1.0;
    _UnifiedObjectState? bestCandidate;

    for (final candidate in candidates) {
      final obj = candidate.lastDetectedObject!;
      final proximityAnalysis = candidate.currentProximityAnalysis;
      final graspAnalysis = candidate.currentGraspAnalysis;

      if (proximityAnalysis == null || graspAnalysis == null) continue;

      // Calculate composite score (0.0 to 1.0)
      double score = 0.0;

      // Factor 1: Proximity (40% weight) - closer is better
      double proximityScore = 0.0;
      if (proximityAnalysis.minFingertipDistance < _nearProximityThreshold) {
        proximityScore =
            1.0 -
            (proximityAnalysis.minFingertipDistance / _nearProximityThreshold);
      }
      score += proximityScore * 0.4;

      // Factor 2: Grasp confidence (35% weight)
      score += graspAnalysis.confidence * 0.35;

      // Factor 3: Object detection confidence (15% weight)
      score += obj.confidence * 0.15;

      // Factor 4: Overall pickup confidence (10% weight)
      score += candidate.overallConfidence * 0.1;

      print(
        '   📊 ${obj.codeName}: proximity=${proximityAnalysis.minFingertipDistance.toStringAsFixed(1)}px, '
        'grasp=${graspAnalysis.confidence.toStringAsFixed(3)}, '
        'detect=${obj.confidence.toStringAsFixed(3)}, '
        'overall=${candidate.overallConfidence.toStringAsFixed(3)}, '
        'SCORE=${score.toStringAsFixed(3)}',
      );

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = candidate;
      }
    }

    if (bestCandidate != null) {
      final bestObj = bestCandidate.lastDetectedObject!;
      print(
        '🎯 [PICKUP] 🏆 WINNER: ${bestObj.codeName} with score ${bestScore.toStringAsFixed(3)}',
      );

      // Mark other candidates as not ready to prevent confusion
      for (final candidate in candidates) {
        if (candidate != bestCandidate) {
          final obj = candidate.lastDetectedObject!;
          print('🎯 [PICKUP] ⏸️ DEFERRED: ${obj.codeName} (score too low)');
        }
      }
    }

    return bestCandidate;
  }

  /// Pickup an object using unified validation with comprehensive debug logging
  void _pickupObject(
    DetectedObject obj,
    _UnifiedObjectState state,
    DateTime now,
  ) {
    print(
      '🎯 [PICKUP] 🔄 ATTEMPTING PICKUP: ${obj.codeName} (${obj.trackingId})',
    );

    if (_carriedObjects.length >= _maxCarriedObjects) {
      print(
        '🚫 [PICKUP] ❌ PICKUP FAILED: ${obj.codeName} - carrying too many objects (${_carriedObjects.length}/$_maxCarriedObjects)',
      );
      return;
    }

    if (_carriedObjects.any(
      (carried) => carried.trackingId == obj.trackingId,
    )) {
      print('🚫 [PICKUP] ❌ PICKUP FAILED: ${obj.codeName} - already carried');
      return; // Already carried
    }

    // Log detailed pickup analysis
    print('🎯 [PICKUP] 📊 PICKUP ANALYSIS for ${obj.codeName}:');
    print(
      '   🔍 Detection: confidence=${obj.confidence.toStringAsFixed(3)}, category=${obj.category}',
    );
    print(
      '   🤏 Grasp: type=${state.currentGraspAnalysis?.graspType}, confidence=${state.currentGraspAnalysis?.confidence.toStringAsFixed(3)}',
    );
    print(
      '   📏 Proximity: zone=${state.currentProximityAnalysis?.zone}, distance=${state.currentProximityAnalysis?.minFingertipDistance.toStringAsFixed(1)}px',
    );
    print(
      '   🎯 Overall: confidence=${state.overallConfidence.toStringAsFixed(3)}, targeting_frames=${state.stableTargetingCount}',
    );

    state.isCarried = true;
    state.pickupTime = now;
    _carriedObjects.add(obj);

    _carriedObjectsController.add(List.from(_carriedObjects));
    _objectPickedUpController.add(obj);
    _pickupEventsController.add(
      PickupEvent(
        type: PickupEventType.pickup,
        object: obj,
        confidence: state.overallConfidence,
        graspType: state.currentGraspAnalysis?.graspType ?? GraspType.unknown,
        timestamp: now,
      ),
    );

    print(
      '🎯 [PICKUP] ✅ PICKUP SUCCESS: ${obj.codeName} (${obj.trackingId}) 🎉',
    );
    print(
      '   📊 Final Stats: confidence=${state.overallConfidence.toStringAsFixed(3)}, '
      'grasp=${state.currentGraspAnalysis?.graspType}, '
      'proximity=${state.currentProximityAnalysis?.zone}',
    );
    print(
      '   ⏱️ Timing: targeting_duration=${state.targetingStartTime != null ? now.difference(state.targetingStartTime!).inMilliseconds : 0}ms, '
      'stability_frames=${state.stableTargetingCount}',
    );
    print(
      '   🎒 Inventory: now_carrying=${_carriedObjects.length}/$_maxCarriedObjects objects',
    );
    print(
      '   📦 Inventory integration: ${_inventoryService != null ? "enabled" : "disabled"}',
    );
  }

  /// Release an object using unified validation
  void _releaseObject(
    String trackingId,
    _UnifiedObjectState state,
    DateTime now,
  ) {
    final obj = _carriedObjects.firstWhere(
      (carried) => carried.trackingId == trackingId,
      orElse: () => state.lastDetectedObject!,
    );

    state.isCarried = false;
    state.releaseTime = now;
    _carriedObjects.removeWhere((carried) => carried.trackingId == trackingId);

    _carriedObjectsController.add(List.from(_carriedObjects));
    _objectReleasedController.add(trackingId);
    _pickupEventsController.add(
      PickupEvent(
        type: PickupEventType.release,
        object: obj,
        confidence: state.overallConfidence,
        graspType: state.currentGraspAnalysis?.graspType ?? GraspType.unknown,
        timestamp: now,
      ),
    );

    print('📦 [PICKUP] ❌ RELEASED: ${obj.codeName} (${obj.trackingId})');
    print(
      '   📊 Final Stats: confidence=${state.overallConfidence.toStringAsFixed(3)}, '
      'proximity=${state.currentProximityAnalysis?.zone}',
    );
    print(
      '   ⏱️ Timing: release_duration=${state.targetingEndTime != null ? now.difference(state.targetingEndTime!).inMilliseconds : 0}ms',
    );
    print(
      '   🎒 Inventory: now_carrying=${_carriedObjects.length}/$_maxCarriedObjects objects',
    );
  }

  /// Clean up old object states
  void _cleanupOldStates(List<DetectedObject> detectedObjects, DateTime now) {
    final activeIds = detectedObjects.map((obj) => obj.trackingId).toSet();
    final initialStateCount = _objectStates.length;
    final initialCarriedCount = _carriedObjects.length;

    // Clean up object states
    final removedStates = <String>[];
    _objectStates.removeWhere((id, state) {
      // Keep carried objects even if not currently detected
      if (state.isCarried) return false;

      // Remove states for objects not seen recently
      final shouldRemove =
          !activeIds.contains(id) &&
          now.difference(state.lastSeenTime).inSeconds > 5;
      if (shouldRemove) {
        removedStates.add(id);
        print(
          '🗑️ [PICKUP] Cleaned up old state: $id (last seen ${now.difference(state.lastSeenTime).inSeconds}s ago)',
        );
      }
      return shouldRemove;
    });

    // Remove carried objects that haven't been detected for too long
    final autoReleasedObjects = <String>[];
    _carriedObjects.removeWhere((carried) {
      final hasState = _objectStates.containsKey(carried.trackingId);
      final recentlyDetected = activeIds.contains(carried.trackingId);

      if (!hasState && !recentlyDetected) {
        autoReleasedObjects.add(carried.codeName);
        print(
          '🗑️ [PICKUP] 🔄 AUTO-RELEASED lost object: ${carried.codeName} (${carried.trackingId})',
        );
        _objectReleasedController.add(carried.trackingId);
        return true;
      }
      return false;
    });

    // Log cleanup summary if anything was cleaned
    if (removedStates.isNotEmpty || autoReleasedObjects.isNotEmpty) {
      print('🧹 [PICKUP] Cleanup summary:');
      print(
        '   States: $initialStateCount → ${_objectStates.length} (removed: ${removedStates.length})',
      );
      print(
        '   Carried: $initialCarriedCount → ${_carriedObjects.length} (auto-released: ${autoReleasedObjects.length})',
      );
      if (autoReleasedObjects.isNotEmpty) {
        print('   Auto-released objects: ${autoReleasedObjects.join(", ")}');
      }
    }
  }

  /// INVENTORY INTEGRATION: Automatically add picked up objects to inventory with retry mechanism
  Future<void> _onObjectPickedUp(DetectedObject obj) async {
    if (_inventoryService == null) {
      print(
        '⚠️ [PICKUP] No inventory service - cannot add ${obj.codeName} to inventory',
      );
      return;
    }

    await _addToInventoryWithRetry(obj, 1);
  }

  /// INVENTORY INTEGRATION: Automatically remove released objects from inventory with retry mechanism
  Future<void> _onObjectReleased(String trackingId) async {
    if (_inventoryService == null) {
      print(
        '⚠️ [PICKUP] No inventory service - cannot remove $trackingId from inventory',
      );
      return;
    }

    try {
      final item = _carriedObjects.firstWhere(
        (item) => item.trackingId == trackingId,
      );
      await _removeFromInventoryWithRetry(item, 1);
    } catch (e) {
      print(
        '⚠️ [PICKUP] Could not find carried object $trackingId for inventory removal: $e',
      );
    }
  }

  /// Add item to inventory with retry mechanism and error handling
  Future<void> _addToInventoryWithRetry(DetectedObject obj, int attempt) async {
    final retryKey = obj.trackingId;

    try {
      print(
        '📦 [INVENTORY] 🔄 Adding ${obj.codeName} to inventory (attempt $attempt/$_maxRetryAttempts)',
      );

      // Add detected object to consolidated inventory service
      final success = await _inventoryService!.addItemFromDetectedObject(obj);

      if (!success) {
        throw Exception('Failed to add item to inventory');
      }

      // Success - clear retry attempts and log success
      _inventoryRetryAttempts.remove(retryKey);

      print('📦 [INVENTORY] ✅ Successfully added ${obj.codeName} to inventory');
      print(
        '📊 [INVENTORY] Total items: ${_inventoryService!.inventory.length}',
      );
      print('🏆 [INVENTORY] Total points: ${_inventoryService!.totalPoints}');
      print(
        '📈 [INVENTORY] Categories: ${_inventoryService!.carriedCategories.join(", ")}',
      );
    } catch (e) {
      print(
        '❌ [INVENTORY] Failed to add ${obj.codeName} to inventory (attempt $attempt): $e',
      );

      // Track retry attempts
      _inventoryRetryAttempts[retryKey] = attempt;

      if (attempt < _maxRetryAttempts) {
        print(
          '🔄 [INVENTORY] Scheduling retry ${attempt + 1}/$_maxRetryAttempts for ${obj.codeName} in ${_retryDelay.inMilliseconds}ms',
        );

        // Schedule retry with exponential backoff
        final retryDelay = Duration(
          milliseconds: _retryDelay.inMilliseconds * attempt,
        );
        Timer(retryDelay, () => _addToInventoryWithRetry(obj, attempt + 1));
      } else {
        print(
          '💥 [INVENTORY] ❌ FINAL FAILURE: Could not add ${obj.codeName} to inventory after $_maxRetryAttempts attempts',
        );
        print('💥 [INVENTORY] Error details: $e');
        _inventoryRetryAttempts.remove(retryKey);

        // Fallback: item remains in detected state for potential retry
      }
    }
  }

  /// Remove item from inventory with retry mechanism and error handling
  Future<void> _removeFromInventoryWithRetry(
    DetectedObject obj,
    int attempt,
  ) async {
    final retryKey = obj.trackingId;

    try {
      print(
        '📦 [INVENTORY] 🔄 Removing ${obj.codeName} from inventory (attempt $attempt/$_maxRetryAttempts)',
      );

      // Remove by tracking ID using consolidated service method
      final success = await _inventoryService!.removeItemByTrackingId(
        obj.trackingId,
      );

      if (!success) {
        throw Exception('Item not found in inventory');
      }

      // Success - clear retry attempts and log success
      _inventoryRetryAttempts.remove(retryKey);

      print(
        '📦 [INVENTORY] ✅ Successfully removed ${obj.codeName} from inventory',
      );
      print(
        '📊 [INVENTORY] Total items: ${_inventoryService!.inventory.length}',
      );
      print('🏆 [INVENTORY] Total points: ${_inventoryService!.totalPoints}');
      print(
        '📈 [INVENTORY] Categories: ${_inventoryService!.carriedCategories.join(", ")}',
      );
    } catch (e) {
      print(
        '❌ [INVENTORY] Failed to remove ${obj.codeName} from inventory (attempt $attempt): $e',
      );

      // Track retry attempts
      _inventoryRetryAttempts[retryKey] = attempt;

      if (attempt < _maxRetryAttempts) {
        print(
          '🔄 [INVENTORY] Scheduling retry ${attempt + 1}/$_maxRetryAttempts for ${obj.codeName} in ${_retryDelay.inMilliseconds}ms',
        );

        // Schedule retry with exponential backoff
        final retryDelay = Duration(
          milliseconds: _retryDelay.inMilliseconds * attempt,
        );
        Timer(
          retryDelay,
          () => _removeFromInventoryWithRetry(obj, attempt + 1),
        );
      } else {
        print(
          '💥 [INVENTORY] ❌ FINAL FAILURE: Could not remove ${obj.codeName} from inventory after $_maxRetryAttempts attempts',
        );
        print('💥 [INVENTORY] Error details: $e');
        _inventoryRetryAttempts.remove(retryKey);

        // Fallback: item remains in inventory for manual cleanup
      }
    }
  }

  /// PERFORMANCE OPTIMIZATION: Update only object detection states without grasp analysis
  void _updateObjectDetectionOnly(
    List<DetectedObject> detectedObjects,
    DateTime now,
  ) {
    for (final obj in detectedObjects) {
      final state = _objectStates.putIfAbsent(obj.trackingId, () {
        print(
          '🆕 [PICKUP] New object state (detection only): ${obj.trackingId} (${obj.codeName})',
        );
        return _UnifiedObjectState(obj.trackingId);
      });

      // Update object detection without hand analysis
      state.updateDetection(obj, now);

      print(
        '📦 [PICKUP] Object ${obj.codeName}: detection_only_mode, confidence=${obj.confidence.toStringAsFixed(2)}',
      );
    }

    // Clean up old states
    _cleanupOldStates(detectedObjects, now);
  }

  /// Calculate distance between two points
  double _calculateDistance(Offset point1, Offset point2) {
    final dx = point1.dx - point2.dx;
    final dy = point1.dy - point2.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Interface compatibility methods
  bool isObjectCarried(String trackingId) {
    return _carriedObjects.any((obj) => obj.trackingId == trackingId);
  }

  bool isObjectTargeted(String trackingId) {
    final state = _objectStates[trackingId];
    return state?.isBeingTargeted ?? false;
  }

  ObjectStatus getObjectStatus(DetectedObject obj) {
    final state = _objectStates[obj.trackingId];
    if (state == null) return ObjectStatus.detected;

    if (state.isCarried) return ObjectStatus.carried;
    if (state.isBeingTargeted) return ObjectStatus.targeted;
    return ObjectStatus.detected;
  }

  double getPickupConfidence(String trackingId) {
    return _objectStates[trackingId]?.overallConfidence ?? 0.0;
  }

  void reset() {
    _objectStates.clear();
    _carriedObjects.clear();
    _carriedObjectsController.add([]);
  }

  Future<void> dispose() async {
    await _carriedObjectsController.close();
    await _objectPickedUpController.close();
    await _objectReleasedController.close();
    await _pickupEventsController.close();

    _objectStates.clear();
    _carriedObjects.clear();
    _isInitialized = false;
  }
}

/// Unified object tracking state with enhanced validation
class _UnifiedObjectState {
  final String objectId;
  DetectedObject? lastDetectedObject;
  DateTime lastSeenTime = DateTime.now();
  DateTime firstSeenTime = DateTime.now();

  // Unified analysis state
  ProximityAnalysis? currentProximityAnalysis;
  GraspAnalysis? currentGraspAnalysis;
  DateTime? targetingStartTime;
  DateTime? targetingEndTime;

  // State flags
  bool isCarried = false;
  bool isBeingTargeted = false;
  DateTime? pickupTime;
  DateTime? releaseTime;

  // Confidence tracking with temporal smoothing
  double overallConfidence = 0.0;
  List<double> confidenceHistory = [];
  int stableDetectionCount = 0;
  int stableTargetingCount = 0;

  _UnifiedObjectState(this.objectId);

  /// Update object detection
  void updateDetection(DetectedObject obj, DateTime now) {
    lastDetectedObject = obj;
    lastSeenTime = now;
    stableDetectionCount++;
  }

  /// Update unified analysis combining grasp and proximity
  void updateUnifiedAnalysis(
    HandLandmark hand,
    ProximityAnalysis proximityAnalysis,
    GraspAnalysis graspAnalysis,
    DateTime now,
  ) {
    currentProximityAnalysis = proximityAnalysis;
    currentGraspAnalysis = graspAnalysis;

    // Combine both analyses for overall confidence
    overallConfidence = _calculateOverallConfidence(
      proximityAnalysis,
      graspAnalysis,
    );

    // Apply temporal smoothing
    confidenceHistory.add(overallConfidence);
    if (confidenceHistory.length >
        ObjectManagementService._temporalSmoothingFrames) {
      confidenceHistory.removeAt(0);
    }

    // Calculate smoothed confidence
    final smoothedConfidence =
        confidenceHistory.reduce((a, b) => a + b) / confidenceHistory.length;
    overallConfidence = smoothedConfidence;

    // SIMPLIFIED TARGETING: Just check if hand is near object
    final wasTargeting = isBeingTargeted;
    isBeingTargeted = proximityAnalysis.zone == ProximityZone.near;

    // Track targeting timing
    if (isBeingTargeted && !wasTargeting) {
      targetingStartTime = now;
      stableTargetingCount = 1;
      print('🎯 [PICKUP] ▶️ STARTED TARGETING $objectId:');
      print(
        '   📊 Confidence: ${overallConfidence.toStringAsFixed(3)} (proximity=${proximityAnalysis.confidence.toStringAsFixed(3)}, grasp=${graspAnalysis.confidence.toStringAsFixed(3)})',
      );
      print(
        '   🤏 Grasp: ${graspAnalysis.graspType} (curl=${graspAnalysis.avgFingerCurl.toStringAsFixed(2)}, thumb=${graspAnalysis.thumbOpposition.oppositionStrength.toStringAsFixed(2)})',
      );
      print(
        '   📏 Proximity: ${proximityAnalysis.zone} (distance=${proximityAnalysis.minFingertipDistance.toStringAsFixed(1)}px, orientation=${proximityAnalysis.handOrientation.toStringAsFixed(2)})',
      );
    } else if (isBeingTargeted && wasTargeting) {
      stableTargetingCount++;
      if (stableTargetingCount % 5 == 0) {
        // Log every 5 frames while targeting
        print(
          '🎯 [PICKUP] 🔄 TARGETING $objectId (frame $stableTargetingCount): confidence=${overallConfidence.toStringAsFixed(3)}',
        );
      }
    } else if (!isBeingTargeted && wasTargeting) {
      targetingEndTime = now;
      final targetingDuration = targetingStartTime != null
          ? now.difference(targetingStartTime!).inMilliseconds
          : 0;
      stableTargetingCount = 0;
      print('🎯 [PICKUP] ⏹️ STOPPED TARGETING $objectId:');
      print(
        '   ⏱️ Duration: ${targetingDuration}ms, confidence_drop: ${overallConfidence.toStringAsFixed(3)}',
      );
      print(
        '   📊 Final: proximity=${proximityAnalysis.zone}, grasp=${graspAnalysis.graspType}',
      );
    }
  }

  /// Calculate overall confidence combining grasp and proximity
  double _calculateOverallConfidence(
    ProximityAnalysis proximity,
    GraspAnalysis grasp,
  ) {
    double confidence = 0.0;

    // Proximity confidence (50% weight)
    confidence += proximity.confidence * 0.50;

    // Grasp confidence (40% weight)
    confidence += grasp.confidence * 0.40;

    // Stability bonus (10% weight)
    final stabilityScore = _calculateStabilityScore();
    confidence += stabilityScore * 0.10;

    return math.max(0.0, math.min(1.0, confidence));
  }

  /// Calculate stability score based on confidence history
  double _calculateStabilityScore() {
    if (confidenceHistory.length < 2) return 0.0;

    // Calculate variance in confidence over recent frames
    final avg =
        confidenceHistory.reduce((a, b) => a + b) / confidenceHistory.length;
    final variance =
        confidenceHistory
            .map((c) => (c - avg) * (c - avg))
            .reduce((a, b) => a + b) /
        confidenceHistory.length;

    // Lower variance = higher stability
    return math.max(0.0, 1.0 - variance);
  }

  /// Check if object has been stable long enough
  bool isStableForPickup(DateTime now) {
    final stabilityDuration = now.difference(firstSeenTime);
    return stabilityDuration >= ObjectManagementService._objectStabilityTime &&
        stableDetectionCount >= ObjectManagementService._stabilityFrames;
  }

  /// IMPROVED PICKUP LOGIC: Fast-track for close objects with good grasp
  /// Enhanced rule: Object close to hand + Hand is grasping = Pickup (with fast-track for very close objects)
  bool shouldPickupUnified(DateTime now) {
    if (isCarried) return false;

    // Basic proximity and grasp checks
    final isCloseToHand = currentProximityAnalysis?.zone == ProximityZone.near;
    final isGrasping =
        (currentGraspAnalysis?.confidence ?? 0.0) >
        0.2; // Lowered from 0.3 for easier pickup detection

    // Always log for debugging with improved thresholds info
    print('🎯 [PICKUP] 🔍 IMPROVED PICKUP CHECK for $objectId:');
    print(
      '   📏 Close to hand: ${isCloseToHand ? "✅" : "❌"} (zone: ${currentProximityAnalysis?.zone}, distance: ${currentProximityAnalysis?.minFingertipDistance.toStringAsFixed(1)}px)',
    );
    print(
      '   🤏 Grasping: ${isGrasping ? "✅" : "❌"} (confidence: ${currentGraspAnalysis?.confidence.toStringAsFixed(2)}, type: ${currentGraspAnalysis?.graspType})',
    );
    print(
      '   🎯 Thresholds: near<${ObjectManagementService._nearProximityThreshold}px, grasp>${0.2}',
    );

    final willPickup = isCloseToHand && isGrasping;
    print('   🎯 DECISION: ${willPickup ? "🟢 PICKUP!" : "🔴 NOT READY"}');

    return willPickup;
  }

  /// Check if object should be released using unified analysis
  bool shouldReleaseUnified(DateTime now) {
    if (!isCarried || targetingEndTime == null) return false;

    final releaseDuration = now.difference(targetingEndTime!);
    final hasBeenReleased =
        releaseDuration >= ObjectManagementService._releaseConfirmationTime;
    final lowConfidence = overallConfidence < 0.3;
    final farFromHand =
        currentProximityAnalysis?.zone == ProximityZone.far ||
        currentProximityAnalysis?.zone == ProximityZone.ignore;

    return hasBeenReleased && (lowConfidence || farFromHand);
  }
}

/// Data classes for unified analysis

class ProximityAnalysis {
  final ProximityZone zone;
  final double confidence;
  final double handCenterDistance;
  final double minFingertipDistance;
  final double avgFingertipDistance;
  final double handOrientation;

  ProximityAnalysis({
    required this.zone,
    required this.confidence,
    required this.handCenterDistance,
    required this.minFingertipDistance,
    required this.avgFingertipDistance,
    required this.handOrientation,
  });

  factory ProximityAnalysis.empty() {
    return ProximityAnalysis(
      zone: ProximityZone.ignore,
      confidence: 0.0,
      handCenterDistance: double.infinity,
      minFingertipDistance: double.infinity,
      avgFingertipDistance: double.infinity,
      handOrientation: 0.0,
    );
  }
}

class GraspAnalysis {
  final GraspType graspType;
  final double confidence;
  final Map<String, double> fingerCurls;
  final double avgFingerCurl;
  final ThumbOppositionAnalysis thumbOpposition;
  final double handClosure;

  GraspAnalysis({
    required this.graspType,
    required this.confidence,
    required this.fingerCurls,
    required this.avgFingerCurl,
    required this.thumbOpposition,
    required this.handClosure,
  });

  factory GraspAnalysis.empty() {
    return GraspAnalysis(
      graspType: GraspType.unknown,
      confidence: 0.0,
      fingerCurls: {},
      avgFingerCurl: 0.0,
      thumbOpposition: ThumbOppositionAnalysis.empty(),
      handClosure: double.infinity,
    );
  }
}

class ThumbOppositionAnalysis {
  final Map<String, double> distances;
  final String closestFinger;
  final double closestDistance;
  final double oppositionStrength;

  ThumbOppositionAnalysis({
    required this.distances,
    required this.closestFinger,
    required this.closestDistance,
    required this.oppositionStrength,
  });

  factory ThumbOppositionAnalysis.empty() {
    return ThumbOppositionAnalysis(
      distances: {},
      closestFinger: 'none',
      closestDistance: double.infinity,
      oppositionStrength: 0.0,
    );
  }
}

/// Enums and event classes for compatibility

enum ProximityZone { near, close, far, ignore }

enum GraspType {
  pinch,
  powerGrip,
  precisionGrip,
  partialGrasp,
  openPalm,
  unknown,
}

enum ObjectStatus { detected, targeted, carried }

enum PickupEventType { pickup, release, target, untarget }

class PickupEvent {
  final PickupEventType type;
  final DetectedObject object;
  final double confidence;
  final GraspType graspType;
  final DateTime timestamp;

  PickupEvent({
    required this.type,
    required this.object,
    required this.confidence,
    required this.graspType,
    required this.timestamp,
  });
}
