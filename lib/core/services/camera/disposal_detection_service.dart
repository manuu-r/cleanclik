import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'qr_bin_service.dart';

/// Service for detecting disposal actions using hand tracking and geometric analysis
class DisposalDetectionService {
  static const String _logTag = 'DISPOSAL_DETECTION';

  // Disposal detection parameters
  static const double _releaseDetectionRadius = 100.0; // pixels
  static const int _releaseConfirmationFrames = 5;
  static const double _handOpenThreshold = 0.7; // Hand openness confidence

  // Points calculation constants
  static const Map<WasteCategory, int> _basePoints = {
    WasteCategory.recycle: 10,
    WasteCategory.organic: 8,
    WasteCategory.ewaste: 15,
    WasteCategory.hazardous: 20,
  };

  // State tracking
  BinInfo? _currentBin;
  List<HandLandmark> _recentHandLandmarks = [];
  int _releaseConfirmationCount = 0;
  DateTime? _lastReleaseDetection;

  // Statistics
  int _consecutiveCorrectDisposals = 0;
  double _sessionAccuracy = 1.0;

  /// Set the current bin being scanned
  void setCurrentBin(BinInfo? binInfo) {
    _currentBin = binInfo;
    print('🗑️ [$_logTag] Current bin set: ${binInfo?.binId ?? 'none'}');
  }

  /// Process hand landmarks for disposal detection
  DisposalResult? processHandLandmarks(
    List<HandLandmark> handLandmarks,
    List<CarriedItem> carriedItems,
  ) {
    if (_currentBin == null || carriedItems.isEmpty) {
      return null;
    }

    // Store recent hand landmarks for temporal analysis
    _recentHandLandmarks = handLandmarks;

    // Check for release gesture
    final releaseDetected = _detectReleaseGesture(handLandmarks);
    if (!releaseDetected) {
      _releaseConfirmationCount = 0;
      return null;
    }

    // Increment confirmation count
    _releaseConfirmationCount++;
    _lastReleaseDetection = DateTime.now();

    // Require multiple frames of confirmation
    if (_releaseConfirmationCount < _releaseConfirmationFrames) {
      print(
        '🗑️ [$_logTag] Release gesture detected, confirmation: $_releaseConfirmationCount/$_releaseConfirmationFrames',
      );
      return null;
    }

    // Check proximity to bin location
    if (!_isNearBin(handLandmarks)) {
      print('⚠️ [$_logTag] Release detected but not near bin location');
      _releaseConfirmationCount = 0;
      return null;
    }

    // Determine which items can be disposed
    final disposableItems = carriedItems
        .where((item) => item.category == _currentBin!.category)
        .toList();

    if (disposableItems.isEmpty) {
      print('⚠️ [$_logTag] Release detected but no matching items to dispose');
      _releaseConfirmationCount = 0;
      return null;
    }

    // Calculate points and create disposal result
    final result = _createDisposalResult(disposableItems);

    // Update statistics
    _updateStatistics(result);

    // Reset confirmation count
    _releaseConfirmationCount = 0;

    print(
      '✅ [$_logTag] Disposal detected: ${result.itemsDisposed.length} items, ${result.pointsEarned} points',
    );

    return result;
  }

  /// Detect release gesture using hand landmark analysis
  bool _detectReleaseGesture(List<HandLandmark> handLandmarks) {
    if (handLandmarks.isEmpty) return false;

    for (final hand in handLandmarks) {
      // Check if hand is open (fingers extended)
      if (_isHandOpen(hand)) {
        return true;
      }
    }

    return false;
  }

  /// Check if hand is in open position using geometric analysis
  bool _isHandOpen(HandLandmark hand) {
    if (hand.landmarks.length < 21) return false;

    // Get key landmarks
    final wrist = hand.landmarks[0];
    final thumbTip = hand.landmarks[4];
    final indexTip = hand.landmarks[8];
    final middleTip = hand.landmarks[12];
    final ringTip = hand.landmarks[16];
    final pinkyTip = hand.landmarks[20];

    // Calculate distances from wrist to fingertips
    final thumbDistance = _calculateDistance(wrist, thumbTip);
    final indexDistance = _calculateDistance(wrist, indexTip);
    final middleDistance = _calculateDistance(wrist, middleTip);
    final ringDistance = _calculateDistance(wrist, ringTip);
    final pinkyDistance = _calculateDistance(wrist, pinkyTip);

    // Calculate average fingertip distance
    final averageDistance =
        (thumbDistance +
            indexDistance +
            middleDistance +
            ringDistance +
            pinkyDistance) /
        5;

    // Check if fingers are sufficiently extended
    // This is a simplified heuristic - in a real implementation you'd use more sophisticated analysis
    final handOpenness = averageDistance / 100.0; // Normalize to 0-1 range

    return handOpenness > _handOpenThreshold;
  }

  /// Calculate distance between two points
  double _calculateDistance(Offset point1, Offset point2) {
    final dx = point1.dx - point2.dx;
    final dy = point1.dy - point2.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Check if hand is near the bin location
  bool _isNearBin(List<HandLandmark> handLandmarks) {
    if (handLandmarks.isEmpty || _currentBin == null) return false;

    // For this implementation, we assume the bin is in the center of the screen
    // In a real implementation, you'd use the actual bin location from AR tracking
    final screenCenter = const Offset(200, 300); // Approximate screen center

    for (final hand in handLandmarks) {
      if (hand.landmarks.isNotEmpty) {
        final handCenter = hand.landmarks[0]; // Use wrist as hand center
        final distance = _calculateDistance(handCenter, screenCenter);

        if (distance <= _releaseDetectionRadius) {
          return true;
        }
      }
    }

    return false;
  }

  /// Create disposal result with points calculation
  DisposalResult _createDisposalResult(List<CarriedItem> disposableItems) {
    final category = _currentBin!.category;
    final basePoints = _basePoints[category] ?? 5;

    // Calculate total points with bonuses
    int totalPoints = 0;

    for (final item in disposableItems) {
      int itemPoints = basePoints;

      // Perfect match bonus (all items match bin category)
      if (disposableItems.length > 0) {
        itemPoints = (itemPoints * 1.5).round();
      }

      // Streak bonus
      if (_consecutiveCorrectDisposals > 0) {
        final streakMultiplier = 1.0 + (_consecutiveCorrectDisposals * 0.1);
        itemPoints = (itemPoints * streakMultiplier).round();
      }

      // Speed bonus (if disposed quickly after scanning)
      final timeSinceScan = DateTime.now().difference(item.pickedUpAt);
      if (timeSinceScan.inSeconds <= 30) {
        itemPoints = (itemPoints * 1.2).round();
      }

      totalPoints += itemPoints;
    }

    return DisposalResult(
      binInfo: _currentBin!,
      itemsDisposed: disposableItems,
      pointsEarned: totalPoints,
      streakCount: _consecutiveCorrectDisposals + 1,
      accuracy: _sessionAccuracy,
      disposalTime: DateTime.now(),
      bonusMultiplier: _calculateBonusMultiplier(),
    );
  }

  /// Calculate bonus multiplier based on current performance
  double _calculateBonusMultiplier() {
    double multiplier = 1.0;

    // Streak bonus
    if (_consecutiveCorrectDisposals >= 5) {
      multiplier += 1.0; // 5x multiplier
    } else if (_consecutiveCorrectDisposals >= 3) {
      multiplier += 0.5; // 3x multiplier
    } else if (_consecutiveCorrectDisposals >= 2) {
      multiplier += 0.2; // 2x multiplier
    }

    // Accuracy bonus
    if (_sessionAccuracy >= 0.9) {
      multiplier += 0.3;
    } else if (_sessionAccuracy >= 0.8) {
      multiplier += 0.1;
    }

    return multiplier;
  }

  /// Update session statistics
  void _updateStatistics(DisposalResult result) {
    _consecutiveCorrectDisposals++;

    // Update accuracy (simplified calculation)
    // In a real implementation, you'd track failed attempts as well
    _sessionAccuracy = (_sessionAccuracy + 1.0) / 2.0;
  }

  /// Reset disposal detection state
  void reset() {
    _currentBin = null;
    _recentHandLandmarks.clear();
    _releaseConfirmationCount = 0;
    _lastReleaseDetection = null;
  }

  /// Get current disposal detection status
  DisposalDetectionStatus getStatus() {
    return DisposalDetectionStatus(
      hasBin: _currentBin != null,
      binCategory: _currentBin?.category,
      releaseConfirmationCount: _releaseConfirmationCount,
      requiredConfirmations: _releaseConfirmationFrames,
      consecutiveCorrectDisposals: _consecutiveCorrectDisposals,
      sessionAccuracy: _sessionAccuracy,
    );
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'current_bin': _currentBin?.binId,
      'bin_category': _currentBin?.category.id,
      'release_confirmation_count': _releaseConfirmationCount,
      'required_confirmations': _releaseConfirmationFrames,
      'consecutive_correct_disposals': _consecutiveCorrectDisposals,
      'session_accuracy': _sessionAccuracy,
      'recent_hand_landmarks_count': _recentHandLandmarks.length,
      'last_release_detection': _lastReleaseDetection?.toIso8601String(),
    };
  }

  /// Dispose resources and clean up
  void dispose() {
    print('🗑️ [$_logTag] Disposing disposal detection service...');
    reset();
    print('✅ [$_logTag] Disposal detection service disposed');
  }
}

/// Result of a disposal detection
class DisposalResult {
  final BinInfo binInfo;
  final List<CarriedItem> itemsDisposed;
  final int pointsEarned;
  final int streakCount;
  final double accuracy;
  final DateTime disposalTime;
  final double bonusMultiplier;

  const DisposalResult({
    required this.binInfo,
    required this.itemsDisposed,
    required this.pointsEarned,
    required this.streakCount,
    required this.accuracy,
    required this.disposalTime,
    required this.bonusMultiplier,
  });

  @override
  String toString() {
    return 'DisposalResult(bin: ${binInfo.binId}, items: ${itemsDisposed.length}, points: $pointsEarned, streak: $streakCount)';
  }
}

/// Current status of disposal detection
class DisposalDetectionStatus {
  final bool hasBin;
  final WasteCategory? binCategory;
  final int releaseConfirmationCount;
  final int requiredConfirmations;
  final int consecutiveCorrectDisposals;
  final double sessionAccuracy;

  const DisposalDetectionStatus({
    required this.hasBin,
    required this.binCategory,
    required this.releaseConfirmationCount,
    required this.requiredConfirmations,
    required this.consecutiveCorrectDisposals,
    required this.sessionAccuracy,
  });

  /// Check if disposal detection is ready
  bool get isReady => hasBin && binCategory != null;

  /// Get confirmation progress (0.0 to 1.0)
  double get confirmationProgress =>
      releaseConfirmationCount / requiredConfirmations;

  @override
  String toString() {
    return 'DisposalDetectionStatus(ready: $isReady, confirmations: $releaseConfirmationCount/$requiredConfirmations)';
  }
}
