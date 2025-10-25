/// System-level models for the CleanClik system
///
/// This file consolidates all system-related data models including:
/// - Sync management: SyncState, SyncStatus, SyncResult, DetailedSyncStatus, GlobalSyncStatus, ConflictResolution
/// - UI context: UIContext, ActivityState, UIContextData
/// - Camera exceptions: CameraException and all subclasses
/// - Database exceptions: AuthException, DatabaseException, DatabaseResult, AuthResult

/// Represents the synchronization status of data
enum SyncState { idle, syncing, success, error, conflict }

/// Simple sync status enum for backward compatibility
enum SyncStatus { pending, synced, offline, failed }

/// Sync result for operations
class SyncResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const SyncResult({required this.success, this.errorMessage, this.data});

  factory SyncResult.success({Map<String, dynamic>? data}) {
    return SyncResult(success: true, data: data);
  }

  factory SyncResult.failure(String errorMessage) {
    return SyncResult(success: false, errorMessage: errorMessage);
  }

  SyncResult copyWith({
    bool? success,
    String? errorMessage,
    Map<String, dynamic>? data,
  }) {
    return SyncResult(
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
    );
  }
}

/// Conflict resolution strategy
enum ConflictResolution { useLocal, useRemote, merge, manual }

/// Detailed sync status for different data types
class DetailedSyncStatus {
  final SyncState state;
  final DateTime lastSyncAt;
  final String? error;
  final int pendingChanges;
  final Map<String, dynamic>? conflictData;

  const DetailedSyncStatus({
    required this.state,
    required this.lastSyncAt,
    this.error,
    this.pendingChanges = 0,
    this.conflictData,
  });

  /// Create initial sync status
  factory DetailedSyncStatus.initial() {
    return DetailedSyncStatus(
      state: SyncState.idle,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Create syncing status
  factory DetailedSyncStatus.syncing() {
    return DetailedSyncStatus(
      state: SyncState.syncing,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Create success status
  factory DetailedSyncStatus.success() {
    return DetailedSyncStatus(
      state: SyncState.success,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Create error status
  factory DetailedSyncStatus.error(String error) {
    return DetailedSyncStatus(
      state: SyncState.error,
      lastSyncAt: DateTime.now(),
      error: error,
    );
  }

  /// Create conflict status
  factory DetailedSyncStatus.conflict(Map<String, dynamic> conflictData) {
    return DetailedSyncStatus(
      state: SyncState.conflict,
      lastSyncAt: DateTime.now(),
      conflictData: conflictData,
    );
  }

  /// Check if sync is in progress
  bool get isSyncing => state == SyncState.syncing;

  /// Check if sync has error
  bool get hasError => state == SyncState.error;

  /// Check if sync has conflicts
  bool get hasConflict => state == SyncState.conflict;

  /// Check if sync is successful
  bool get isSuccess => state == SyncState.success;

  /// Check if sync is idle
  bool get isIdle => state == SyncState.idle;

  /// Get time since last sync
  Duration get timeSinceLastSync => DateTime.now().difference(lastSyncAt);

  /// Check if sync is stale (older than threshold)
  bool isStale(Duration threshold) => timeSinceLastSync > threshold;

  /// Create a copy with updated fields
  DetailedSyncStatus copyWith({
    SyncState? state,
    DateTime? lastSyncAt,
    String? error,
    int? pendingChanges,
    Map<String, dynamic>? conflictData,
  }) {
    return DetailedSyncStatus(
      state: state ?? this.state,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error ?? this.error,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      conflictData: conflictData ?? this.conflictData,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'state': state.name,
      'lastSyncAt': lastSyncAt.toIso8601String(),
      'error': error,
      'pendingChanges': pendingChanges,
      'conflictData': conflictData,
    };
  }

  /// Create from JSON
  factory DetailedSyncStatus.fromJson(Map<String, dynamic> json) {
    return DetailedSyncStatus(
      state: SyncState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => SyncState.idle,
      ),
      lastSyncAt: DateTime.parse(json['lastSyncAt'] as String),
      error: json['error'] as String?,
      pendingChanges: json['pendingChanges'] as int? ?? 0,
      conflictData: json['conflictData'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'DetailedSyncStatus(state: $state, lastSync: $lastSyncAt, error: $error)';
  }
}

/// Overall sync status for all data types
class GlobalSyncStatus {
  final Map<String, DetailedSyncStatus> dataTypeStatus;
  final DateTime lastGlobalSync;
  final bool isOnline;

  const GlobalSyncStatus({
    required this.dataTypeStatus,
    required this.lastGlobalSync,
    required this.isOnline,
  });

  /// Create initial global sync status
  factory GlobalSyncStatus.initial() {
    return GlobalSyncStatus(
      dataTypeStatus: {
        'user': DetailedSyncStatus.initial(),
        'inventory': DetailedSyncStatus.initial(),
        'achievements': DetailedSyncStatus.initial(),
        'categoryStats': DetailedSyncStatus.initial(),
      },
      lastGlobalSync: DateTime.now(),
      isOnline: true,
    );
  }

  /// Get sync status for specific data type
  DetailedSyncStatus getStatus(String dataType) {
    return dataTypeStatus[dataType] ?? DetailedSyncStatus.initial();
  }

  /// Update sync status for specific data type
  GlobalSyncStatus updateStatus(String dataType, DetailedSyncStatus status) {
    final updatedStatus = Map<String, DetailedSyncStatus>.from(dataTypeStatus);
    updatedStatus[dataType] = status;

    return GlobalSyncStatus(
      dataTypeStatus: updatedStatus,
      lastGlobalSync: DateTime.now(),
      isOnline: isOnline,
    );
  }

  /// Check if any data type is syncing
  bool get isAnySyncing {
    return dataTypeStatus.values.any((status) => status.isSyncing);
  }

  /// Check if any data type has errors
  bool get hasAnyErrors {
    return dataTypeStatus.values.any((status) => status.hasError);
  }

  /// Check if any data type has conflicts
  bool get hasAnyConflicts {
    return dataTypeStatus.values.any((status) => status.hasConflict);
  }

  /// Get total pending changes across all data types
  int get totalPendingChanges {
    return dataTypeStatus.values
        .map((status) => status.pendingChanges)
        .fold(0, (sum, count) => sum + count);
  }

  /// Update online status
  GlobalSyncStatus updateOnlineStatus(bool online) {
    return GlobalSyncStatus(
      dataTypeStatus: dataTypeStatus,
      lastGlobalSync: lastGlobalSync,
      isOnline: online,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'dataTypeStatus': dataTypeStatus.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'lastGlobalSync': lastGlobalSync.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  /// Create from JSON
  factory GlobalSyncStatus.fromJson(Map<String, dynamic> json) {
    final statusMap = <String, DetailedSyncStatus>{};
    final dataTypeStatusJson = json['dataTypeStatus'] as Map<String, dynamic>;

    for (final entry in dataTypeStatusJson.entries) {
      statusMap[entry.key] = DetailedSyncStatus.fromJson(entry.value);
    }

    return GlobalSyncStatus(
      dataTypeStatus: statusMap,
      lastGlobalSync: DateTime.parse(json['lastGlobalSync'] as String),
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'GlobalSyncStatus(online: $isOnline, syncing: $isAnySyncing, errors: $hasAnyErrors)';
  }
}

/// Represents the current UI context for adaptive interface
enum UIContext { arCamera, map, inventory, social, profile, mission }

/// Represents the current user activity state
enum ActivityState {
  idle,
  scanning,
  tracking,
  carrying,
  approaching,
  disposing,
  celebrating,
}

/// UI context data for adaptive interface
class UIContextData {
  final UIContext context;
  final ActivityState activityState;
  final Map<String, dynamic> contextData;
  final DateTime timestamp;

  const UIContextData({
    required this.context,
    required this.activityState,
    this.contextData = const {},
    required this.timestamp,
  });

  UIContextData copyWith({
    UIContext? context,
    ActivityState? activityState,
    Map<String, dynamic>? contextData,
    DateTime? timestamp,
  }) {
    return UIContextData(
      context: context ?? this.context,
      activityState: activityState ?? this.activityState,
      contextData: contextData ?? this.contextData,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UIContextData &&
        other.context == context &&
        other.activityState == activityState;
  }

  @override
  int get hashCode => Object.hash(context, activityState);

  @override
  String toString() {
    return 'UIContextData(context: $context, activityState: $activityState)';
  }
}

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

/// Authentication error types
enum AuthErrorType {
  invalidCredentials,
  userNotFound,
  emailAlreadyExists,
  weakPassword,
  networkError,
  tokenExpired,
  tokenRefreshFailed,
  signupDisabled,
  emailNotConfirmed,
  tooManyRequests,
  providerError,
  unknown,
}

/// Database error types
enum DatabaseErrorType {
  connectionFailed,
  queryFailed,
  constraintViolation,
  permissionDenied,
  recordNotFound,
  duplicateKey,
  foreignKeyViolation,
  checkConstraintViolation,
  notNullViolation,
  networkTimeout,
  rateLimitExceeded,
  serviceDisposed,
  unknown,
}

/// Authentication exception with detailed error information
class AuthException implements Exception {
  final AuthErrorType type;
  final String message;
  final String? details;
  final dynamic originalError;
  final DateTime timestamp;

  AuthException(
    this.type,
    this.message, {
    this.details,
    this.originalError,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from Supabase AuthException
  factory AuthException.fromSupabase(dynamic error) {
    final message = error?.message as String? ?? 'Authentication failed';
    final statusCode = error?.statusCode as String?;

    AuthErrorType type;
    switch (statusCode) {
      case '400':
        if (message.contains('Invalid login credentials')) {
          type = AuthErrorType.invalidCredentials;
        } else if (message.contains('Password should be')) {
          type = AuthErrorType.weakPassword;
        } else if (message.contains('User already registered')) {
          type = AuthErrorType.emailAlreadyExists;
        } else {
          type = AuthErrorType.unknown;
        }
        break;
      case '401':
        type = AuthErrorType.tokenExpired;
        break;
      case '404':
        type = AuthErrorType.userNotFound;
        break;
      case '422':
        if (message.contains('Email not confirmed')) {
          type = AuthErrorType.emailNotConfirmed;
        } else if (message.contains('Signup is disabled')) {
          type = AuthErrorType.signupDisabled;
        } else {
          type = AuthErrorType.unknown;
        }
        break;
      case '429':
        type = AuthErrorType.tooManyRequests;
        break;
      default:
        if (message.contains('network') || message.contains('connection')) {
          type = AuthErrorType.networkError;
        } else {
          type = AuthErrorType.unknown;
        }
    }

    return AuthException(
      type,
      message,
      details: statusCode != null ? 'Status Code: $statusCode' : null,
      originalError: error,
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case AuthErrorType.invalidCredentials:
        return 'Invalid email or password. Please check your credentials and try again.';
      case AuthErrorType.userNotFound:
        return 'No account found with this email address.';
      case AuthErrorType.emailAlreadyExists:
        return 'An account with this email already exists.';
      case AuthErrorType.weakPassword:
        return 'Password is too weak. Please choose a stronger password.';
      case AuthErrorType.networkError:
        return 'Network connection failed. Please check your internet connection.';
      case AuthErrorType.tokenExpired:
        return 'Your session has expired. Please sign in again.';
      case AuthErrorType.tokenRefreshFailed:
        return 'Failed to refresh session. Please sign in again.';
      case AuthErrorType.signupDisabled:
        return 'Account registration is currently disabled.';
      case AuthErrorType.emailNotConfirmed:
        return 'Please check your email and confirm your account.';
      case AuthErrorType.tooManyRequests:
        return 'Too many attempts. Please wait a moment and try again.';
      case AuthErrorType.providerError:
        return 'Authentication provider error. Please try again.';
      case AuthErrorType.unknown:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  String toString() {
    return 'AuthException(type: $type, message: $message, details: $details)';
  }
}

/// Database exception with detailed error information
class DatabaseException implements Exception {
  final DatabaseErrorType type;
  final String message;
  final String? table;
  final String? operation;
  final String? details;
  final dynamic originalError;
  final DateTime timestamp;

  DatabaseException(
    this.type,
    this.message, {
    this.table,
    this.operation,
    this.details,
    this.originalError,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from Supabase PostgrestException
  factory DatabaseException.fromSupabase(
    dynamic error, {
    String? table,
    String? operation,
  }) {
    final message = error?.message as String? ?? 'Database operation failed';
    final code = error?.code as String?;
    final details = error?.details as String?;
    final hint = error?.hint as String?;

    DatabaseErrorType type;
    switch (code) {
      case '23505': // unique_violation
        type = DatabaseErrorType.duplicateKey;
        break;
      case '23503': // foreign_key_violation
        type = DatabaseErrorType.foreignKeyViolation;
        break;
      case '23514': // check_violation
        type = DatabaseErrorType.checkConstraintViolation;
        break;
      case '23502': // not_null_violation
        type = DatabaseErrorType.notNullViolation;
        break;
      case 'PGRST116': // permission denied
        type = DatabaseErrorType.permissionDenied;
        break;
      case 'PGRST106': // not found
        type = DatabaseErrorType.recordNotFound;
        break;
      case '08000': // connection_exception
      case '08003': // connection_does_not_exist
      case '08006': // connection_failure
        type = DatabaseErrorType.connectionFailed;
        break;
      case '57014': // query_canceled
        type = DatabaseErrorType.networkTimeout;
        break;
      default:
        if (message.contains('rate limit') || message.contains('too many')) {
          type = DatabaseErrorType.rateLimitExceeded;
        } else if (message.contains('network') || message.contains('timeout')) {
          type = DatabaseErrorType.networkTimeout;
        } else {
          type = DatabaseErrorType.queryFailed;
        }
    }

    return DatabaseException(
      type,
      message,
      table: table,
      operation: operation,
      details: [
        details,
        hint,
      ].where((s) => s != null && s.isNotEmpty).join('; '),
      originalError: error,
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case DatabaseErrorType.connectionFailed:
        return 'Unable to connect to the server. Please check your internet connection.';
      case DatabaseErrorType.queryFailed:
        return 'Database operation failed. Please try again.';
      case DatabaseErrorType.constraintViolation:
      case DatabaseErrorType.duplicateKey:
        return 'This data already exists. Please use different values.';
      case DatabaseErrorType.permissionDenied:
        return 'You do not have permission to perform this action.';
      case DatabaseErrorType.recordNotFound:
        return 'The requested data was not found.';
      case DatabaseErrorType.foreignKeyViolation:
        return 'Cannot complete operation due to data dependencies.';
      case DatabaseErrorType.checkConstraintViolation:
        return 'The provided data does not meet requirements.';
      case DatabaseErrorType.notNullViolation:
        return 'Required information is missing.';
      case DatabaseErrorType.networkTimeout:
        return 'Operation timed out. Please try again.';
      case DatabaseErrorType.rateLimitExceeded:
        return 'Too many requests. Please wait a moment and try again.';
      case DatabaseErrorType.serviceDisposed:
        return 'Service is no longer available. Please restart the app.';
      case DatabaseErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  String toString() {
    return 'DatabaseException(type: $type, message: $message, table: $table, operation: $operation)';
  }
}

/// Result wrapper for database operations with error handling
class DatabaseResult<T> {
  final T? data;
  final DatabaseException? error;
  final bool isSuccess;

  const DatabaseResult.success(this.data) : error = null, isSuccess = true;

  const DatabaseResult.failure(this.error) : data = null, isSuccess = false;

  /// Get data or throw exception
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ??
        DatabaseException(
          DatabaseErrorType.unknown,
          'Operation failed with no data or error information',
        );
  }

  /// Transform data if successful
  DatabaseResult<U> map<U>(U Function(T data) transform) {
    if (isSuccess && data != null) {
      try {
        return DatabaseResult.success(transform(data!));
      } catch (e) {
        return DatabaseResult.failure(
          DatabaseException(
            DatabaseErrorType.unknown,
            'Data transformation failed: $e',
            originalError: e,
          ),
        );
      }
    }
    return DatabaseResult.failure(error!);
  }

  /// Handle both success and failure cases
  U fold<U>(
    U Function(DatabaseException error) onFailure,
    U Function(T data) onSuccess,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    }
    return onFailure(error!);
  }
}

/// Result wrapper for authentication operations
class AuthResult<T> {
  final T? data;
  final AuthException? error;
  final bool isSuccess;

  const AuthResult.success(this.data) : error = null, isSuccess = true;

  const AuthResult.failure(this.error) : data = null, isSuccess = false;

  /// Get data or throw exception
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ??
        AuthException(
          AuthErrorType.unknown,
          'Authentication failed with no data or error information',
        );
  }

  /// Transform data if successful
  AuthResult<U> map<U>(U Function(T data) transform) {
    if (isSuccess && data != null) {
      try {
        return AuthResult.success(transform(data!));
      } catch (e) {
        return AuthResult.failure(
          AuthException(
            AuthErrorType.unknown,
            'Data transformation failed: $e',
            originalError: e,
          ),
        );
      }
    }
    return AuthResult.failure(error!);
  }

  /// Handle both success and failure cases
  U fold<U>(
    U Function(AuthException error) onFailure,
    U Function(T data) onSuccess,
  ) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    }
    return onFailure(error!);
  }
}
