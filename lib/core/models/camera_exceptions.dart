/// Base class for camera-related exceptions
abstract class CameraException implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;

  const CameraException(this.message, {this.details, this.originalError});

  @override
  String toString() {
    if (details != null) {
      return 'CameraException: $message\nDetails: $details';
    }
    return 'CameraException: $message';
  }
}

/// Exception thrown when camera initialization fails
class CameraInitializationException extends CameraException {
  const CameraInitializationException(
    super.message, {
    super.details,
    super.originalError,
  });
}

/// Exception thrown when camera permissions are denied
class CameraPermissionException extends CameraException {
  const CameraPermissionException(
    super.message, {
    super.details,
    super.originalError,
  });
}

/// Exception thrown when camera hardware is unavailable
class CameraHardwareException extends CameraException {
  const CameraHardwareException(
    super.message, {
    super.details,
    super.originalError,
  });
}

/// Exception thrown when camera operations timeout
class CameraTimeoutException extends CameraException {
  const CameraTimeoutException(
    super.message, {
    super.details,
    super.originalError,
  });
}

/// Exception thrown when camera mode switching fails
class CameraModeSwitchException extends CameraException {
  const CameraModeSwitchException(
    super.message, {
    super.details,
    super.originalError,
  });
}

/// Exception thrown when camera resource conflicts occur
class CameraResourceConflictException extends CameraException {
  const CameraResourceConflictException(
    super.message, {
    super.details,
    super.originalError,
  });
}