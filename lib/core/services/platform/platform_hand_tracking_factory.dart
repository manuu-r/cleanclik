import 'dart:io';
import 'hand_tracking_service.dart';
import 'android_hand_tracking_service.dart';
import 'ios_hand_tracking_service.dart';

/// Factory for creating platform-specific hand tracking services
class PlatformHandTrackingFactory {
  /// Create the appropriate hand tracking service for the current platform
  static HandTrackingService create() {
    if (Platform.isAndroid) {
      return AndroidHandTrackingService();
    } else if (Platform.isIOS) {
      return IOSHandTrackingService();
    } else {
      throw UnsupportedError('Hand tracking is not supported on this platform');
    }
  }

  /// Check if hand tracking is supported on the current platform
  static bool get isSupported {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get platform-specific information
  static String get platformInfo {
    if (Platform.isAndroid) {
      return 'Android MediaPipe Hand Landmarker';
    } else if (Platform.isIOS) {
      return 'iOS Apple Vision Framework';
    } else {
      return 'Unsupported Platform';
    }
  }
}
