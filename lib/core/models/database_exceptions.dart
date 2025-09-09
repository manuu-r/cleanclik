/// Database and authentication exception types for Supabase integration
/// Following patterns from supabase-security-guidelines

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
      details: [details, hint].where((s) => s != null && s.isNotEmpty).join('; '),
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

  const DatabaseResult.success(this.data)
      : error = null,
        isSuccess = true;

  const DatabaseResult.failure(this.error)
      : data = null,
        isSuccess = false;

  /// Get data or throw exception
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? DatabaseException(
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

  const AuthResult.success(this.data)
      : error = null,
        isSuccess = true;

  const AuthResult.failure(this.error)
      : data = null,
        isSuccess = false;

  /// Get data or throw exception
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? AuthException(
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