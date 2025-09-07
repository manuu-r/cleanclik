import 'package:camera/camera.dart';

/// Camera operation modes for the AR camera screen
enum CameraMode {
  /// No camera mode active
  none,

  /// QR code scanning mode
  qrScanning,

  /// ML object detection mode (formerly arDetection)
  mlDetection,
}

/// Camera status enumeration
enum CameraStatus {
  /// Camera is not initialized
  uninitialized,

  /// Camera is currently initializing
  initializing,

  /// Camera is ready for use
  ready,

  /// Camera is switching between modes
  switching,

  /// Camera encountered an error
  error,

  /// Camera has been disposed
  disposed,
}

/// Extension to provide string values for camera modes
extension CameraModeExtension on CameraMode {
  /// Convert camera mode to string
  String get value {
    switch (this) {
      case CameraMode.none:
        return 'none';
      case CameraMode.mlDetection:
        return 'ml';
      case CameraMode.qrScanning:
        return 'qr';
    }
  }

  /// Create camera mode from string value
  static CameraMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'qr':
      case 'qrscanning':
        return CameraMode.qrScanning;
      case 'ml':
      case 'mldetection':
      case 'ar':
      case 'ardetection':
        return CameraMode.mlDetection;
      case 'none':
      default:
        return CameraMode.none;
    }
  }
}

/// Camera state model to track current mode and status
class CameraState {
  final CameraMode mode;
  final CameraStatus status;
  final String? errorMessage;
  final bool hasPermission;
  final DateTime lastUpdated;
  final bool isTransitioning;

  const CameraState({
    required this.mode,
    required this.status,
    this.errorMessage,
    required this.hasPermission,
    required this.lastUpdated,
    this.isTransitioning = false,
  });

  /// Check if camera is ready for use
  bool get isReady => status == CameraStatus.ready;

  /// Check if camera can switch modes
  bool get canSwitch =>
      status == CameraStatus.ready || status == CameraStatus.error;

  /// Check if camera is initialized (legacy compatibility)
  bool get isInitialized => status == CameraStatus.ready;

  /// Create a copy with updated values
  CameraState copyWith({
    CameraMode? mode,
    CameraStatus? status,
    String? errorMessage,
    bool? hasPermission,
    DateTime? lastUpdated,
    bool? isTransitioning,
  }) {
    return CameraState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      hasPermission: hasPermission ?? this.hasPermission,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isTransitioning: isTransitioning ?? this.isTransitioning,
    );
  }

  /// Create initial state
  static CameraState initial = CameraState(
    mode: CameraMode.none,
    status: CameraStatus.uninitialized,
    hasPermission: false,
    lastUpdated: DateTime.now(),
  );
}

/// Camera configuration for different modes
class CameraConfiguration {
  final ResolutionPreset resolution;
  final bool enableAudio;
  final CameraLensDirection lensDirection;
  final ImageFormatGroup? imageFormatGroup;

  const CameraConfiguration({
    this.resolution = ResolutionPreset.medium,
    this.enableAudio = false,
    this.lensDirection = CameraLensDirection.back,
    this.imageFormatGroup,
  });

  /// Configuration optimized for QR code scanning
  static const CameraConfiguration forQRScanning = CameraConfiguration(
    resolution: ResolutionPreset.medium,
    enableAudio: false,
    lensDirection: CameraLensDirection.back,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );

  /// Configuration optimized for ML object detection
  static const CameraConfiguration forMLDetection = CameraConfiguration(
    resolution: ResolutionPreset.high,
    enableAudio: false,
    lensDirection: CameraLensDirection.back,
    imageFormatGroup: ImageFormatGroup.nv21,
  );
}
