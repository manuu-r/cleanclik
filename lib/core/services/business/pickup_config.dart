import 'package:flutter/foundation.dart';

class PickupConfig {
  PickupConfig._();

  static const Duration releaseConfirmationTime = Duration(milliseconds: 150);

  static const Duration objectStabilityTime = Duration(milliseconds: 50);

  static const int stabilityFrames = 3;

  static const int releaseFramesThreshold = 5;

  static const int temporalSmoothingFrames = 3;

  static const Duration minFrameInterval = Duration(milliseconds: 33);

  static const int maxPickedUpObjects = 5;

  static const double nearProximityThreshold = 150.0;

  static const double closeProximityThreshold = 220.0;

  static const double farProximityThreshold = 300.0;

  static const double fingerCurlThreshold = 0.2;

  static const double thumbOppositionThreshold = 50.0;

  static const double handClosureThreshold = 120.0;

  static const int maxRetryAttempts = 3;

  static const Duration retryDelay = Duration(milliseconds: 500);

  static bool testMode = false;

  static double getSizeAdjustedThreshold(double objectSize) {
    return nearProximityThreshold + (objectSize * 0.2);
  }

  static Duration getRetryDelay(int attemptNumber) {
    return Duration(milliseconds: retryDelay.inMilliseconds * attemptNumber);
  }

  static void printConfiguration() {
    if (kDebugMode) {
      print('🎯 [PICKUP CONFIG] Current Configuration:');
      print('   Timing:');
      print(
        '     - Release confirmation: ${releaseConfirmationTime.inMilliseconds}ms',
      );
      print('     - Object stability: ${objectStabilityTime.inMilliseconds}ms');
      print('     - Stability frames: $stabilityFrames');
      print('     - Release frames threshold: $releaseFramesThreshold');
      print('     - Temporal smoothing: $temporalSmoothingFrames frames');
      print('     - Min frame interval: ${minFrameInterval.inMilliseconds}ms');
      print('   Limits:');
      print('     - Max picked up objects: $maxPickedUpObjects');
      print('   Proximity Zones:');
      print('     - Near: ${nearProximityThreshold}px');
      print('     - Close: ${closeProximityThreshold}px');
      print('     - Far: ${farProximityThreshold}px');
      print('   Grasp Detection:');
      print('     - Finger curl threshold: $fingerCurlThreshold');
      print('     - Thumb opposition: ${thumbOppositionThreshold}px');
      print('     - Hand closure: ${handClosureThreshold}px');
      print('   Retry:');
      print('     - Max attempts: $maxRetryAttempts');
      print('     - Base delay: ${retryDelay.inMilliseconds}ms');
      print('   Test Mode: ${testMode ? "ENABLED" : "DISABLED"}');
    }
  }
}
