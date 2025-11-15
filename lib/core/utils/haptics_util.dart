import 'package:flutter/services.dart';

/// Haptic feedback utilities for various user interactions
class HapticsUtil {
  /// Light haptic feedback (10ms) - for subtle interactions
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback (30ms) - for confirmations
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback (100ms) - for important events
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click - for UI selections
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Level up pattern - special celebration vibration
  static Future<void> levelUpPattern() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Success pattern - for successful actions
  static Future<void> successPattern() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Error pattern - for errors or failures
  static Future<void> errorPattern() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
