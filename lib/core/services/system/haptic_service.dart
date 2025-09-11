import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for managing haptic feedback patterns
class HapticService {
  bool _isEnabled = true;

  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Light impact for UI interactions
  void lightImpact() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact for confirmations
  void mediumImpact() {
    if (!_isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for important actions
  void heavyImpact() {
    if (!_isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Selection click for navigation
  void selectionClick() {
    if (!_isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Vibrate for object detection
  void objectDetected() {
    lightImpact();
  }

  /// Vibrate for pickup confirmation
  void pickupConfirmed() {
    mediumImpact();
  }

  /// Vibrate for disposal success
  void disposalSuccess() {
    heavyImpact();
  }

  /// Vibrate for error/warning
  void error() {
    // Double tap pattern
    heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isEnabled) heavyImpact();
    });
  }

  /// Vibrate for achievement unlock
  void achievementUnlocked() {
    // Triple tap pattern
    mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isEnabled) mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_isEnabled) heavyImpact();
    });
  }

  /// Vibrate for mission complete
  void missionComplete() {
    // Celebration pattern
    heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_isEnabled) lightImpact();
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_isEnabled) heavyImpact();
    });
  }
}

/// Provider for haptic service
final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService();
});
