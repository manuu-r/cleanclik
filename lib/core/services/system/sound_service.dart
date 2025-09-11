import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for managing environmental audio cues
class SoundService {
  bool _isEnabled = true;
  double _volume = 0.7;

  /// Enable or disable sound effects
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Set volume level (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Play system sound for UI feedback
  void _playSystemSound() {
    if (!_isEnabled || _volume == 0.0) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Sound for object detection
  void objectDetected(String category) {
    if (!_isEnabled) return;

    // Different sounds for different categories
    switch (category.toLowerCase()) {
      case 'recycle':
      case 'ecogems':
        _playRecycleSound();
        break;
      case 'organic':
      case 'fuelshards':
        _playOrganicSound();
        break;
      case 'ewaste':
      case 'sparkcores':
        _playEWasteSound();
        break;
      case 'hazardous':
      case 'toxiccrystals':
        _playHazardousSound();
        break;
      default:
        _playSystemSound();
    }
  }

  /// Sound for pickup confirmation
  void pickupConfirmed() {
    if (!_isEnabled) return;
    _playSystemSound();
  }

  /// Sound for disposal success
  void disposalSuccess(String category) {
    if (!_isEnabled) return;

    // Success sounds based on category
    switch (category.toLowerCase()) {
      case 'recycle':
      case 'ecogems':
        _playRecycleSuccessSound();
        break;
      case 'organic':
      case 'fuelshards':
        _playOrganicSuccessSound();
        break;
      default:
        _playGenericSuccessSound();
    }
  }

  /// Sound for error/warning
  void error() {
    if (!_isEnabled) return;
    SystemSound.play(SystemSoundType.alert);
  }

  /// Sound for achievement unlock
  void achievementUnlocked() {
    if (!_isEnabled) return;
    _playAchievementSound();
  }

  /// Sound for mission complete
  void missionComplete() {
    if (!_isEnabled) return;
    _playMissionCompleteSound();
  }

  /// Sound for navigation
  void navigationTap() {
    if (!_isEnabled) return;
    _playSystemSound();
  }

  // Private methods for specific sound effects
  // In a real implementation, these would play actual audio files

  void _playRecycleSound() {
    // Water drops sound for recycle
    _playSystemSound();
  }

  void _playOrganicSound() {
    // Wind chimes sound for organic
    _playSystemSound();
  }

  void _playEWasteSound() {
    // Electronic beeps for e-waste
    _playSystemSound();
  }

  void _playHazardousSound() {
    // Warning tone for hazardous
    SystemSound.play(SystemSoundType.alert);
  }

  void _playRecycleSuccessSound() {
    // Gentle water sound
    _playSystemSound();
  }

  void _playOrganicSuccessSound() {
    // Nature sound
    _playSystemSound();
  }

  void _playGenericSuccessSound() {
    // Success chime
    _playSystemSound();
  }

  void _playAchievementSound() {
    // Fanfare sound
    _playSystemSound();
  }

  void _playMissionCompleteSound() {
    // Victory sound
    _playSystemSound();
  }
}

/// Provider for sound service
final soundServiceProvider = Provider<SoundService>((ref) {
  return SoundService();
});
