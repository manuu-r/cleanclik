/// User-friendly error messages service for disposal process failures
///
/// This service provides clear, actionable error messages for users when
/// disposal processes fail, with suggestions for resolution and recovery.
///
/// Requirements: 6.3, 6.4

import 'package:flutter/foundation.dart';
// Simplified error handling without validation framework

/// User-friendly error message with action suggestions
class UserFriendlyError {
  final String title;
  final String message;
  final String? suggestion;
  final List<String> actions;
  final ErrorSeverityLevel severity;
  final String? helpUrl;
  final bool canRetry;
  final bool canSkip;

  const UserFriendlyError({
    required this.title,
    required this.message,
    this.suggestion,
    this.actions = const [],
    this.severity = ErrorSeverityLevel.error,
    this.helpUrl,
    this.canRetry = true,
    this.canSkip = false,
  });

  /// Convert to map for UI display
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'suggestion': suggestion,
      'actions': actions,
      'severity': severity.name,
      'helpUrl': helpUrl,
      'canRetry': canRetry,
      'canSkip': canSkip,
    };
  }

  @override
  String toString() {
    return '$title: $message${suggestion != null ? ' - $suggestion' : ''}';
  }
}

/// Error severity levels for user display
enum ErrorSeverityLevel {
  /// Information message
  info,

  /// Warning that doesn't prevent operation
  warning,

  /// Error that prevents operation but is recoverable
  error,

  /// Critical error that requires immediate attention
  critical,
}

/// Context for error message generation
class ErrorContext {
  final String operation;
  final String? component;
  final Map<String, dynamic>? data;
  final String? userId;
  final DateTime timestamp;

  ErrorContext({
    required this.operation,
    this.component,
    this.data,
    this.userId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service for generating user-friendly error messages
class UserFriendlyErrorService {
  static final UserFriendlyErrorService _instance =
      UserFriendlyErrorService._internal();
  factory UserFriendlyErrorService() => _instance;
  UserFriendlyErrorService._internal();

  /// Generate user-friendly error from generic error
  UserFriendlyError fromGenericError(
    String errorType,
    String message, {
    String? field,
    String? details,
    ErrorContext? context,
  }) {
    switch (errorType.toLowerCase()) {
      case 'missing_field':
        return _handleMissingFieldError(field ?? 'field', message, context);

      case 'invalid_format':
        return _handleInvalidFormatError(field ?? 'field', message, context);

      case 'out_of_range':
        return _handleOutOfRangeError(field ?? 'field', message, context);

      case 'data_corruption':
        return _handleDataCorruptionError(message, context);

      case 'metadata_parsing':
        return _handleMetadataParsingError(message, context);

      case 'detection_pipeline':
        return _handleDetectionPipelineError(message, context);

      case 'database_operation':
        return _handleDatabaseOperationError(message, context);

      case 'service_integration':
        return _handleServiceIntegrationError(message, context);

      case 'user_input':
        return _handleUserInputError(field ?? 'field', message, context);

      case 'resource_constraint':
        return _handleResourceConstraintError(message, context);

      default:
        return UserFriendlyError(
          title: 'Error',
          message: message,
          suggestion:
              'Please try again or contact support if the problem continues.',
          actions: ['Try again', 'Contact support'],
          severity: ErrorSeverityLevel.error,
          canRetry: true,
        );
    }
  }

  /// Generate error for detection pipeline failures
  UserFriendlyError detectionPipelineFailure({
    String? details,
    ErrorContext? context,
  }) {
    return UserFriendlyError(
      title: 'Object Detection Failed',
      message: 'We couldn\'t detect the object you\'re trying to scan.',
      suggestion:
          'Try moving your camera closer to the object and ensure good lighting.',
      actions: [
        'Move closer to the object',
        'Improve lighting conditions',
        'Clean your camera lens',
        'Try scanning a different angle',
        'Manually categorize the item',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Generate error for inventory management failures
  UserFriendlyError inventoryManagementFailure({
    String? operation,
    String? details,
    ErrorContext? context,
  }) {
    final operationName = operation ?? 'inventory operation';

    return UserFriendlyError(
      title: 'Inventory Error',
      message: 'There was a problem with your $operationName.',
      suggestion: 'This might be a temporary issue. Please try again.',
      actions: [
        'Try again',
        'Check your internet connection',
        'Restart the app if the problem persists',
      ],
      severity: ErrorSeverityLevel.error,
      canRetry: true,
      canSkip: false,
    );
  }

  /// Generate error for disposal process failures
  UserFriendlyError disposalProcessFailure({
    String? stage,
    String? details,
    ErrorContext? context,
  }) {
    final stageName = stage ?? 'disposal';

    return UserFriendlyError(
      title: 'Disposal Failed',
      message: 'We couldn\'t complete the $stageName process.',
      suggestion:
          'Your items are still in your inventory. You can try disposing of them again.',
      actions: [
        'Try disposing again',
        'Check if you\'re near the correct bin',
        'Verify the items are properly categorized',
        'Contact support if the problem continues',
      ],
      severity: ErrorSeverityLevel.error,
      canRetry: true,
      canSkip: false,
    );
  }

  /// Generate error for database operation failures
  UserFriendlyError databaseOperationFailure({
    String? operation,
    String? details,
    ErrorContext? context,
  }) {
    return UserFriendlyError(
      title: 'Connection Problem',
      message: 'We\'re having trouble saving your data right now.',
      suggestion:
          'Your progress is saved locally and will sync when the connection is restored.',
      actions: [
        'Check your internet connection',
        'Try again in a few moments',
        'Continue using the app offline',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Generate error for camera/AR failures
  UserFriendlyError cameraFailure({String? details, ErrorContext? context}) {
    return UserFriendlyError(
      title: 'Camera Not Available',
      message: 'We can\'t access your camera right now.',
      suggestion:
          'Make sure CleanClik has camera permission and your camera isn\'t being used by another app.',
      actions: [
        'Check app permissions in Settings',
        'Close other camera apps',
        'Restart CleanClik',
        'Restart your device if needed',
      ],
      severity: ErrorSeverityLevel.critical,
      canRetry: true,
      canSkip: false,
    );
  }

  /// Generate error for network connectivity issues
  UserFriendlyError networkFailure({String? details, ErrorContext? context}) {
    return UserFriendlyError(
      title: 'No Internet Connection',
      message: 'CleanClik needs an internet connection to sync your progress.',
      suggestion:
          'You can continue using the app offline. Your data will sync when you\'re back online.',
      actions: [
        'Check your WiFi or mobile data',
        'Try moving to an area with better signal',
        'Continue offline',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Generate error for location/GPS failures
  UserFriendlyError locationFailure({String? details, ErrorContext? context}) {
    return UserFriendlyError(
      title: 'Location Not Available',
      message: 'We need your location to find nearby disposal bins.',
      suggestion:
          'Enable location services for CleanClik to find bins near you.',
      actions: [
        'Enable location services',
        'Check app permissions',
        'Try refreshing your location',
        'Manually search for bins',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Generate error for authentication failures
  UserFriendlyError authenticationFailure({
    String? details,
    ErrorContext? context,
  }) {
    return UserFriendlyError(
      title: 'Sign In Required',
      message: 'You need to sign in to save your progress and earn points.',
      suggestion: 'Sign in with your existing account or create a new one.',
      actions: [
        'Sign in to your account',
        'Create a new account',
        'Continue as guest (limited features)',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Generate error for storage/memory issues
  UserFriendlyError storageFailure({String? details, ErrorContext? context}) {
    return UserFriendlyError(
      title: 'Storage Full',
      message: 'Your device is running low on storage space.',
      suggestion:
          'Free up some space on your device to continue using CleanClik.',
      actions: [
        'Delete unused apps or files',
        'Clear app cache',
        'Move photos/videos to cloud storage',
        'Restart the app',
      ],
      severity: ErrorSeverityLevel.error,
      canRetry: true,
      canSkip: false,
    );
  }

  /// Generate error for permission issues
  UserFriendlyError permissionFailure({
    String? permission,
    String? details,
    ErrorContext? context,
  }) {
    final permissionName = permission ?? 'required permission';

    return UserFriendlyError(
      title: 'Permission Required',
      message: 'CleanClik needs $permissionName to work properly.',
      suggestion: 'Grant the permission in your device settings to continue.',
      actions: [
        'Open app settings',
        'Grant required permissions',
        'Restart CleanClik',
      ],
      severity: ErrorSeverityLevel.critical,
      canRetry: true,
      canSkip: false,
    );
  }

  /// Handle missing field validation errors
  UserFriendlyError _handleMissingFieldError(
    String field,
    String message,
    ErrorContext? context,
  ) {
    final fieldName = _humanizeFieldName(field);

    return UserFriendlyError(
      title: 'Missing Information',
      message: 'The $fieldName is required but wasn\'t provided.',
      suggestion:
          'This might be due to a detection issue. Try scanning the object again.',
      actions: [
        'Scan the object again',
        'Manually enter the information',
        'Skip this item for now',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Handle invalid format validation errors
  UserFriendlyError _handleInvalidFormatError(
    String field,
    String message,
    ErrorContext? context,
  ) {
    final fieldName = _humanizeFieldName(field);

    return UserFriendlyError(
      title: 'Invalid Data Format',
      message: 'The $fieldName has an invalid format.',
      suggestion: 'This is likely a temporary issue with object detection.',
      actions: [
        'Try scanning again',
        'Restart the detection process',
        'Report this issue',
      ],
      severity: ErrorSeverityLevel.error,
      canRetry: true,
      canSkip: false,
    );
  }

  /// Handle out of range validation errors
  UserFriendlyError _handleOutOfRangeError(
    String field,
    String message,
    ErrorContext? context,
  ) {
    final fieldName = _humanizeFieldName(field);

    return UserFriendlyError(
      title: 'Invalid Value',
      message: 'The $fieldName value is outside the expected range.',
      suggestion: 'This might indicate a detection accuracy issue.',
      actions: [
        'Try scanning with better lighting',
        'Move closer to the object',
        'Clean your camera lens',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Handle data corruption validation errors
  UserFriendlyError _handleDataCorruptionError(
    String message,
    ErrorContext? context,
  ) {
    return UserFriendlyError(
      title: 'Data Error',
      message: 'Some of your data appears to be corrupted.',
      suggestion:
          'This is usually temporary. Restarting the app often fixes this issue.',
      actions: [
        'Restart the app',
        'Clear app cache',
        'Try the operation again',
        'Contact support if it persists',
      ],
      severity: ErrorSeverityLevel.error,
      canRetry: true,
      canSkip: false,
    );
  }

  /// Handle metadata parsing validation errors
  UserFriendlyError _handleMetadataParsingError(
    String message,
    ErrorContext? context,
  ) {
    return UserFriendlyError(
      title: 'Data Processing Error',
      message: 'We couldn\'t process some of the object information.',
      suggestion: 'The object was detected but some details might be missing.',
      actions: [
        'Continue with available information',
        'Scan the object again for complete details',
        'Manually add missing information',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Handle detection pipeline validation errors
  UserFriendlyError _handleDetectionPipelineError(
    String message,
    ErrorContext? context,
  ) {
    return detectionPipelineFailure(details: message, context: context);
  }

  /// Handle database operation validation errors
  UserFriendlyError _handleDatabaseOperationError(
    String message,
    ErrorContext? context,
  ) {
    return databaseOperationFailure(details: message, context: context);
  }

  /// Handle service integration validation errors
  UserFriendlyError _handleServiceIntegrationError(
    String message,
    ErrorContext? context,
  ) {
    return UserFriendlyError(
      title: 'Service Error',
      message: 'One of our services is temporarily unavailable.',
      suggestion: 'This is usually a temporary issue that resolves quickly.',
      actions: [
        'Try again in a few moments',
        'Check your internet connection',
        'Restart the app if needed',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Handle user input validation errors
  UserFriendlyError _handleUserInputError(
    String field,
    String message,
    ErrorContext? context,
  ) {
    final fieldName = _humanizeFieldName(field);

    return UserFriendlyError(
      title: 'Input Error',
      message: 'There\'s an issue with the $fieldName you entered.',
      suggestion: 'Please check your input and try again.',
      actions: [
        'Check your input',
        'Try a different value',
        'Use the suggested format',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: false,
    );
  }

  /// Handle resource constraint validation errors
  UserFriendlyError _handleResourceConstraintError(
    String message,
    ErrorContext? context,
  ) {
    return UserFriendlyError(
      title: 'System Busy',
      message: 'Your device is running low on resources.',
      suggestion: 'Close other apps to free up memory and processing power.',
      actions: [
        'Close other apps',
        'Restart CleanClik',
        'Try again in a moment',
        'Reduce detection quality in settings',
      ],
      severity: ErrorSeverityLevel.warning,
      canRetry: true,
      canSkip: true,
    );
  }

  /// Convert technical field names to human-readable names
  String _humanizeFieldName(String field) {
    final humanNames = {
      'trackingId': 'tracking ID',
      'objectId': 'object ID',
      'detectionSource': 'detection method',
      'imageLabels': 'image labels',
      'boundingBox': 'object boundaries',
      'confidence': 'detection confidence',
      'detectedAt': 'detection time',
      'categorizationReasoning': 'categorization reason',
      'detectionMetadata': 'detection details',
      'metadata.detection': 'detection information',
      'metadata.categorization': 'categorization information',
      'metadata.system': 'system information',
      'metadata.disposal': 'disposal information',
      'pickedUpAt': 'pickup time',
      'displayName': 'item name',
      'category': 'waste category',
    };

    return humanNames[field] ?? field.replaceAll('_', ' ').toLowerCase();
  }

  /// Get error message for common disposal scenarios
  UserFriendlyError getDisposalScenarioError(String scenario) {
    switch (scenario.toLowerCase()) {
      case 'bin_not_found':
        return UserFriendlyError(
          title: 'Bin Not Found',
          message: 'We couldn\'t find a disposal bin near your location.',
          suggestion:
              'Try moving closer to a bin or check if you\'re in the right area.',
          actions: [
            'Move closer to a bin',
            'Refresh your location',
            'Check the bin map',
            'Report a missing bin',
          ],
          severity: ErrorSeverityLevel.warning,
          canRetry: true,
          canSkip: true,
        );

      case 'wrong_bin_type':
        return UserFriendlyError(
          title: 'Wrong Bin Type',
          message: 'This item doesn\'t belong in this type of bin.',
          suggestion: 'Find the correct bin type for this item to earn points.',
          actions: [
            'Find the correct bin',
            'Check item categorization',
            'View disposal guide',
            'Ask for help',
          ],
          severity: ErrorSeverityLevel.warning,
          canRetry: true,
          canSkip: false,
        );

      case 'bin_full':
        return UserFriendlyError(
          title: 'Bin is Full',
          message: 'This bin appears to be full and can\'t accept more items.',
          suggestion:
              'Find another bin of the same type or report this full bin.',
          actions: [
            'Find another bin',
            'Report full bin',
            'Try again later',
            'Check nearby alternatives',
          ],
          severity: ErrorSeverityLevel.warning,
          canRetry: true,
          canSkip: true,
        );

      case 'qr_scan_failed':
        return UserFriendlyError(
          title: 'QR Code Scan Failed',
          message: 'We couldn\'t read the QR code on this bin.',
          suggestion:
              'Make sure the QR code is clean and well-lit, then try again.',
          actions: [
            'Clean the QR code',
            'Improve lighting',
            'Try a different angle',
            'Manually select bin type',
          ],
          severity: ErrorSeverityLevel.warning,
          canRetry: true,
          canSkip: true,
        );

      default:
        return UserFriendlyError(
          title: 'Disposal Error',
          message: 'Something went wrong during the disposal process.',
          suggestion:
              'Please try again or contact support if the problem continues.',
          actions: [
            'Try again',
            'Check your connection',
            'Restart the app',
            'Contact support',
          ],
          severity: ErrorSeverityLevel.error,
          canRetry: true,
          canSkip: false,
        );
    }
  }

  /// Get contextual help message
  String getContextualHelp(String context) {
    final helpMessages = {
      'detection':
          'For best results, ensure good lighting and hold your device steady while scanning objects.',
      'categorization':
          'If an item is categorized incorrectly, you can manually correct it by tapping on the category.',
      'disposal':
          'Make sure you\'re within 10 meters of the correct bin type and that the QR code is visible.',
      'inventory':
          'Your inventory shows all items you\'ve picked up. Tap any item to see more details.',
      'points':
          'You earn points for correctly disposing of items. Bonus points are awarded for streaks and challenges.',
    };

    return helpMessages[context] ??
        'Need help? Check the help section in the app menu.';
  }
}
