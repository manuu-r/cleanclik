import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cleanclik/core/services/business/pickup_config.dart';

/// Utility class for pickup-related calculations
/// 
/// Contains all mathematical calculations for proximity detection,
/// grasp detection, and stability analysis. Extracted from 
/// ObjectManagementService to maintain single responsibility.
class PickupCalculationsUtil {
  // Prevent instantiation
  PickupCalculationsUtil._();

  // ============================================================================
  // PROXIMITY CALCULATIONS
  // ============================================================================

  /// Calculate distance between two points
  static double calculateDistance(Offset point1, Offset point2) {
    final dx = point1.dx - point2.dx;
    final dy = point1.dy - point2.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculate proximity between hand position and object bounding box
  static double calculateProximity(
    Offset handPosition,
    Rect objectBoundingBox,
  ) {
    final objectCenter = objectBoundingBox.center;
    return calculateDistance(handPosition, objectCenter);
  }

  /// Determine proximity zone based on distance
  static ProximityZone getProximityZone(double distance) {
    if (distance < PickupConfig.nearProximityThreshold) {
      return ProximityZone.near;
    } else if (distance < PickupConfig.closeProximityThreshold) {
      return ProximityZone.close;
    } else if (distance < PickupConfig.farProximityThreshold) {
      return ProximityZone.far;
    }
    return ProximityZone.outOfRange;
  }

  /// Calculate proximity confidence score (0.0 to 1.0)
  static double calculateProximityConfidence(
    double distance,
    ProximityZone zone,
    double handOrientation,
  ) {
    double confidence;

    switch (zone) {
      case ProximityZone.near:
        confidence = math.max(
          0.0,
          1.0 - (distance / PickupConfig.nearProximityThreshold),
        );
        break;
      case ProximityZone.close:
        confidence = math.max(
          0.0,
          1.0 - (distance / PickupConfig.closeProximityThreshold),
        ) * 0.7;
        break;
      case ProximityZone.far:
        confidence = math.max(
          0.0,
          1.0 - (distance / PickupConfig.farProximityThreshold),
        ) * 0.3;
        break;
      case ProximityZone.outOfRange:
        confidence = 0.0;
        break;
    }

    // Apply hand orientation bonus
    return confidence * handOrientation;
  }

  /// Calculate minimum distance from fingertips to object center
  static double calculateMinFingertipDistance(
    List<Offset> fingertips,
    Offset objectCenter,
  ) {
    if (fingertips.isEmpty) return double.infinity;

    return fingertips
        .map((tip) => calculateDistance(tip, objectCenter))
        .reduce(math.min);
  }

  /// Calculate average distance from fingertips to object center
  static double calculateAvgFingertipDistance(
    List<Offset> fingertips,
    Offset objectCenter,
  ) {
    if (fingertips.isEmpty) return double.infinity;

    final distances = fingertips
        .map((tip) => calculateDistance(tip, objectCenter))
        .toList();

    return distances.reduce((a, b) => a + b) / distances.length;
  }

  // ============================================================================
  // GRASP DETECTION CALCULATIONS
  // ============================================================================

  /// Detect if a grasp is present based on hand landmarks
  static bool isGraspDetected(List<Offset> landmarks) {
    if (landmarks.length < 21) return false;

    final fingersCurled = _areFingersCurled(landmarks);
    final thumbOpposed = _isThumbOpposed(landmarks);
    final handClosed = _isHandClosed(landmarks);

    return fingersCurled && thumbOpposed && handClosed;
  }

  /// Check if fingers are curled enough for a grasp
  static bool _areFingersCurled(List<Offset> landmarks) {
    final fingerCurls = calculateSimplifiedFingerCurls(landmarks);
    final avgCurl = fingerCurls.values.isNotEmpty
        ? fingerCurls.values.reduce((a, b) => a + b) / fingerCurls.values.length
        : 0.0;

    return avgCurl > PickupConfig.fingerCurlThreshold;
  }

  /// Check if thumb is opposed to fingers
  static bool _isThumbOpposed(List<Offset> landmarks) {
    final thumbOpposition = calculateThumbOpposition(landmarks);
    return thumbOpposition.oppositionStrength > 0.4;
  }

  /// Check if hand is closed enough
  static bool _isHandClosed(List<Offset> landmarks) {
    final handClosure = calculateHandClosure(landmarks);
    return handClosure < PickupConfig.handClosureThreshold;
  }

  /// Calculate simplified finger curls using joint angles
  static Map<String, double> calculateSimplifiedFingerCurls(
    List<Offset> landmarks,
  ) {
    if (landmarks.length < 21) return {};

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
        final baseToTip = calculateDistance(
          landmarks[joints[0]],
          landmarks[joints[3]],
        );
        final expectedStraightDistance =
            calculateDistance(landmarks[joints[0]], landmarks[joints[1]]) +
            calculateDistance(landmarks[joints[1]], landmarks[joints[2]]) +
            calculateDistance(landmarks[joints[2]], landmarks[joints[3]]);

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
  static ThumbOppositionAnalysis calculateThumbOpposition(
    List<Offset> landmarks,
  ) {
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
      distances[fingerNames[i]] = calculateDistance(thumbTip, fingertips[i]);
    }

    final closestEntry = distances.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    final oppositionStrength = math.max(
      0.0,
      1.0 - (closestEntry.value / PickupConfig.thumbOppositionThreshold),
    );

    return ThumbOppositionAnalysis(
      distances: distances,
      closestFinger: closestEntry.key,
      closestDistance: closestEntry.value,
      oppositionStrength: oppositionStrength,
    );
  }

  /// Calculate hand closure (distance between fingertips)
  static double calculateHandClosure(List<Offset> landmarks) {
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
        final distance = calculateDistance(fingertips[i], fingertips[j]);
        maxSpread = math.max(maxSpread, distance);
      }
    }

    return maxSpread;
  }

  // ============================================================================
  // STABILITY CALCULATIONS
  // ============================================================================

  /// Check if object is stable based on recent positions
  static bool isObjectStable(
    List<Offset> recentPositions,
    double stabilityThreshold,
  ) {
    if (recentPositions.length < 2) return false;

    // Calculate position variance
    final variance = calculatePositionVariance(recentPositions);
    return variance < stabilityThreshold;
  }

  /// Calculate position variance for stability detection
  static double calculatePositionVariance(List<Offset> positions) {
    if (positions.isEmpty) return double.infinity;

    // Calculate mean position
    final meanX = positions.map((p) => p.dx).reduce((a, b) => a + b) / 
        positions.length;
    final meanY = positions.map((p) => p.dy).reduce((a, b) => a + b) / 
        positions.length;

    // Calculate variance
    final variance = positions.map((p) {
      final dx = p.dx - meanX;
      final dy = p.dy - meanY;
      return dx * dx + dy * dy;
    }).reduce((a, b) => a + b) / positions.length;

    return variance;
  }

  // ============================================================================
  // MOVEMENT DETECTION
  // ============================================================================

  /// Check if object has moved significantly
  static bool hasObjectMoved(
    Offset previousPosition,
    Offset currentPosition,
    double movementThreshold,
  ) {
    final distance = calculateDistance(previousPosition, currentPosition);
    return distance > movementThreshold;
  }

  // ============================================================================
  // HAND ORIENTATION CALCULATIONS
  // ============================================================================

  /// Calculate hand orientation relative to object
  static double calculateHandOrientation(
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
      handDirection.dx * handDirection.dx + 
      handDirection.dy * handDirection.dy,
    );
    final objectMag = math.sqrt(
      handToObject.dx * handToObject.dx + 
      handToObject.dy * handToObject.dy,
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
}

// ============================================================================
// SUPPORTING ENUMS AND CLASSES
// ============================================================================

/// Proximity zones for object interaction
enum ProximityZone {
  /// Very close - ready for pickup
  near,
  
  /// Close - targeting zone
  close,
  
  /// Far - awareness zone
  far,
  
  /// Out of range - ignore
  outOfRange,
}

/// Thumb opposition analysis result
class ThumbOppositionAnalysis {
  final Map<String, double> distances;
  final String closestFinger;
  final double closestDistance;
  final double oppositionStrength;

  const ThumbOppositionAnalysis({
    required this.distances,
    required this.closestFinger,
    required this.closestDistance,
    required this.oppositionStrength,
  });

  factory ThumbOppositionAnalysis.empty() {
    return const ThumbOppositionAnalysis(
      distances: {},
      closestFinger: '',
      closestDistance: double.infinity,
      oppositionStrength: 0.0,
    );
  }
}
