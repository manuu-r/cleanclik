import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide User, AuthState, AuthException;
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase
    show User, AuthState, AuthException;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cleanclik/core/models/user_models.dart';
import 'package:cleanclik/core/models/system_models.dart';
import 'package:cleanclik/core/services/auth/supabase_config_service.dart';
part 'auth_service.g.dart';

/// Abstract base class for authentication credentials
abstract class AuthCredentials {
  const AuthCredentials();
}

/// Email and password credentials for sign in
class EmailCredentials extends AuthCredentials {
  final String email;
  final String password;

  const EmailCredentials({required this.email, required this.password});
}

/// Google OAuth credentials
class GoogleCredentials extends AuthCredentials {
  const GoogleCredentials();
}

/// Sign up credentials with email, password, and username
class SignUpCredentials extends AuthCredentials {
  final String email;
  final String password;
  final String username;

  const SignUpCredentials({
    required this.email,
    required this.password,
    required this.username,
  });
}

/// Authentication status enumeration
enum AuthStatus {
  loading, // Initial load or authentication in progress
  authenticated, // User is signed in
  unauthenticated, // User is not signed in
  error, // Authentication error occurred
}

/// Unified authentication state
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({required this.status, this.user, this.error});

  // Convenience getters
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.username}, error: $error)';
  }
}

/// Simplified authentication service that consolidates all auth operations
class AuthService {
  final SupabaseClient _supabase;

  // Simple singleton pattern
  static AuthService? _instance;

  // State management
  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  AuthState _currentState = const AuthState(status: AuthStatus.loading);
  StreamSubscription<supabase.AuthState>? _authSubscription;
  bool _isSigningOut = false;
  bool _isDisposed = false;

  // Private constructor for singleton pattern
  AuthService._internal(this._supabase) {
    _initializeAuthState();
  }

  /// Simple factory constructor that enforces singleton pattern
  factory AuthService(SupabaseClient supabase) {
    if (_instance != null && !_instance!._isDisposed) {
      return _instance!;
    }

    _instance = AuthService._internal(supabase);
    return _instance!;
  }

  /// Check if an instance exists and is not disposed
  static bool get hasValidInstance =>
      _instance != null && !_instance!._isDisposed;

  /// Get disposal state (for testing)
  bool get isDisposed => _isDisposed;

  /// Stream of authentication state changes
  Stream<AuthState> get authStateStream async* {
    // Emit current state immediately
    yield _currentState;
    // Then yield all future updates
    yield* _stateController.stream;
  }

  /// Get current authentication state
  AuthState get currentState => _currentState;

  /// Get current user
  User? get currentUser => _currentState.user;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentState.isAuthenticated;

  /// Initialize authentication service
  Future<void> initialize() async {
    if (_isDisposed) return;

    try {
      await _refreshSession();
    } catch (e) {
      _logError('Failed to initialize authentication', e);
      if (!_isDisposed) {
        _updateState(
          status: AuthStatus.error,
          error: 'Failed to initialize authentication: $e',
        );
      }
    }
  }

  /// Refresh authentication state (call when app resumes or on deep links)
  Future<void> refreshAuthState() async {
    await _refreshSession();
  }

  /// Handle Supabase auth callback from deep link
  Future<void> handleAuthCallback(String url) async {
    await _processSessionCallback(url);
  }

  /// Sign in with email and password
  Future<AuthResult<User>> signInWithEmail(
    String email,
    String password,
  ) async {
    return _executeAuthOperation(() async {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return _handleAuthResponse(response, 'sign in');
    });
  }

  /// Sign in with Google
  Future<AuthResult<User>> signInWithGoogle() async {
    return _executeAuthOperation(() async {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return _processAuthFailure(
          AuthErrorType.unknown,
          'Google sign in was cancelled by user',
          AuthStatus.unauthenticated,
        );
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        return _processAuthFailure(
          AuthErrorType.unknown,
          'Failed to get Google authentication tokens',
          AuthStatus.unauthenticated,
        );
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return _handleAuthResponse(response, 'sign in');
    });
  }

  /// Sign up with email and password
  Future<AuthResult<User>> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    return _executeAuthOperation(() async {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      return _handleAuthResponse(response, 'sign up', username: username);
    });
  }

  /// Sign out user
  Future<void> signOut() async {
    if (_isDisposed) return;

    try {
      // Set flag to prevent auth state listener from interfering
      _isSigningOut = true;

      // Update state to unauthenticated immediately
      _updateState(status: AuthStatus.unauthenticated);

      // Sign out from Supabase (this may cause expected errors)
      try {
        await _supabase.auth.signOut();
      } catch (e) {
        // Expected errors during signout (real-time disconnections, etc.)
        // No logging needed for expected behavior
      }

      // Reset the flag after successful logout
      _isSigningOut = false;
    } catch (e) {
      _logError('Error during sign out', e);
      // Ensure local state is cleared even if there are errors
      _updateState(status: AuthStatus.unauthenticated);
      _isSigningOut = false;
    }
  }

  /// Handle email verification completion (call this when app resumes or on deep link)
  Future<void> handleEmailVerificationComplete() async {
    await _refreshSession();
  }

  /// Initialize authentication state and listen to auth changes
  void _initializeAuthState() {
    try {
      // Listen to Supabase auth state changes
      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        // Skip processing auth events if we're in the middle of signing out
        if (_isSigningOut && event != AuthChangeEvent.signedOut) {
          return;
        }

        switch (event) {
          case AuthChangeEvent.signedIn:
            if (session != null &&
                !_currentState.isAuthenticated &&
                !_isSigningOut) {
              await _handleSignIn(session);
            }
            break;
          case AuthChangeEvent.signedOut:
            if (!_isSigningOut) {
              _updateState(status: AuthStatus.unauthenticated);
            } else {
              _isSigningOut = false;
            }
            break;
          case AuthChangeEvent.tokenRefreshed:
            // Token refresh is handled automatically by Supabase client
            break;
          case AuthChangeEvent.userUpdated:
            // User metadata updated - no action needed for basic auth service
            break;
          default:
            break;
        }
      });

      // Check if user is already authenticated on startup
      _refreshSession();
    } catch (e) {
      _logError('Failed to initialize auth state', e);
      _updateState(
        status: AuthStatus.error,
        error: 'Failed to initialize authentication: $e',
      );
    }
  }

  /// Handle successful sign in - simplified to focus only on authentication
  Future<void> _handleSignIn(Session session) async {
    if (_isDisposed) return;

    try {
      // Create minimal user object from Supabase session data
      final user = _createUserFromSession(session);

      // Update current state
      _updateState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      _logError('Failed to process sign in', e);
      _updateState(
        status: AuthStatus.error,
        error: 'Failed to process sign in: $e',
      );
    }
  }

  // User creation helper methods

  /// Create user object from Supabase session
  User _createUserFromSession(Session session) {
    return _createUserFromSupabaseUser(session.user);
  }

  /// Create user object from auth response with optional username override
  User _createUserFromAuthResponse(AuthResponse response, String? username) {
    final supabaseUser = response.user!;
    return _createUserFromSupabaseUser(supabaseUser, username: username);
  }

  /// Create user object from Supabase user data
  User _createUserFromSupabaseUser(
    supabase.User supabaseUser, {
    String? username,
  }) {
    return User(
      id: supabaseUser.id,
      authId: supabaseUser.id,
      username:
          username ??
          supabaseUser.userMetadata?['username'] as String? ??
          supabaseUser.email?.split('@').first ??
          'User${DateTime.now().millisecondsSinceEpoch}',
      email: supabaseUser.email ?? '',
      avatarUrl: supabaseUser.userMetadata?['avatar_url'] as String?,
      totalPoints: 0,
      level: 1,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      categoryStats: const {},
      achievements: const [],
      isOnline: true,
    );
  }

  // Authentication response handling methods

  /// Handle sign up response when user needs email verification
  AuthResult<User> _handleSignUpResponse(supabase.User user) {
    _updateState(status: AuthStatus.unauthenticated);

    // Check if user already exists using Supabase response indicators
    final bool userAlreadyExists = user.identities?.isEmpty ?? true;
    final bool confirmationSent = user.confirmationSentAt != null;

    if (userAlreadyExists) {
      // User already exists - identities array is empty for existing users
      return AuthResult.failure(
        AuthException(
          AuthErrorType.emailAlreadyExists,
          'This email is already registered. Please sign in instead or use a different email.',
        ),
      );
    } else if (confirmationSent) {
      // New user created, confirmation email sent
      return AuthResult.failure(
        AuthException(
          AuthErrorType.emailNotConfirmed,
          'Please check your email and click the confirmation link to complete your account setup.',
        ),
      );
    } else {
      // New user created and confirmed (email confirmation disabled)
      return AuthResult.failure(
        AuthException(
          AuthErrorType.unknown,
          'Account created but authentication failed. Please try signing in.',
        ),
      );
    }
  }

  /// Process authentication failure with consistent error handling
  AuthResult<User> _processAuthFailure(
    AuthErrorType errorType,
    String message,
    AuthStatus status,
  ) {
    _logError('Authentication failed', message);
    _updateState(status: status, error: message);
    return AuthResult.failure(AuthException(errorType, message));
  }

  /// Execute authentication operation with common error handling
  Future<AuthResult<User>> _executeAuthOperation(
    Future<AuthResult<User>> Function() operation,
  ) async {
    if (_isDisposed) {
      return AuthResult.failure(
        AuthException(AuthErrorType.unknown, 'AuthService has been disposed'),
      );
    }

    _updateState(status: AuthStatus.loading);

    try {
      return await operation();
    } on supabase.AuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return _handleGenericError(e);
    }
  }

  /// Handle Supabase authentication exceptions
  AuthResult<User> _handleAuthException(supabase.AuthException exception) {
    final authException = AuthException.fromSupabase(exception);

    _logError('Authentication failed', exception);

    // Determine appropriate state based on error type
    if (_isUserInputError(authException.type)) {
      _updateState(status: AuthStatus.unauthenticated);
    } else {
      _updateState(status: AuthStatus.error, error: authException.userMessage);
    }

    return AuthResult.failure(authException);
  }

  /// Handle generic (non-auth) exceptions
  AuthResult<User> _handleGenericError(dynamic error) {
    _logError('Unexpected authentication error', error);
    const errorMessage = 'An unexpected error occurred during authentication';

    _updateState(status: AuthStatus.error, error: errorMessage);

    return AuthResult.failure(
      AuthException(AuthErrorType.unknown, errorMessage),
    );
  }

  /// Handle Supabase authentication response
  Future<AuthResult<User>> _handleAuthResponse(
    AuthResponse response,
    String operation, {
    String? username,
  }) async {
    // Case 1: Successful authentication with session
    if (response.session != null && response.user != null) {
      try {
        // Create user object from session, with optional username override
        final user = _createUserFromAuthResponse(response, username);

        _updateState(status: AuthStatus.authenticated, user: user);

        return AuthResult.success(user);
      } catch (e) {
        return _processAuthFailure(
          AuthErrorType.unknown,
          'Failed to process authentication',
          AuthStatus.error,
        );
      }
    }

    // Case 2: User created but needs email verification (signup only)
    if (response.user != null &&
        response.session == null &&
        operation == 'sign up') {
      return _handleSignUpResponse(response.user!);
    }

    // Case 3: No user or session returned (should not happen with valid requests)
    return _processAuthFailure(
      AuthErrorType.unknown,
      '${operation.substring(0, 1).toUpperCase()}${operation.substring(1)} failed',
      AuthStatus.unauthenticated,
    );
  }

  // Error handling and validation methods

  /// Check if error is due to user input (should stay unauthenticated)
  bool _isUserInputError(AuthErrorType errorType) {
    return [
      AuthErrorType.invalidCredentials,
      AuthErrorType.userNotFound,
      AuthErrorType.emailNotConfirmed,
      AuthErrorType.emailAlreadyExists,
      AuthErrorType.weakPassword,
    ].contains(errorType);
  }

  /// Single method to handle all session validation logic
  bool _validateSession() {
    return !_isDisposed;
  }

  // Logging methods

  /// Centralized error logging method
  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      debugPrint('[Auth] $message: $error');
    }
  }

  /// Log significant state transitions only
  void _logStateTransition(AuthState state) {
    if (kDebugMode) {
      switch (state.status) {
        case AuthStatus.authenticated:
          debugPrint('[Auth] User authenticated: ${state.user?.username}');
          break;
        case AuthStatus.error:
          debugPrint('[Auth] Authentication error: ${state.error}');
          break;
        default:
          break;
      }
    }
  }

  // Session management methods

  /// Consolidated session refresh logic for all session operations
  Future<void> _refreshSession() async {
    if (!_validateSession()) return;

    try {
      // Check current session first
      var session = _supabase.auth.currentSession;

      if (session == null) {
        // Try to refresh session in case of email verification
        try {
          final response = await _supabase.auth.refreshSession();
          session = response.session;
        } catch (e) {
          // Session refresh failed - normal if no session exists
        }
      }

      if (session != null) {
        await _handleSignIn(session);
        return;
      }

      // No valid session found
      _updateState(status: AuthStatus.unauthenticated);
    } catch (e) {
      _logError('Session refresh failed', e);
      _updateState(
        status: AuthStatus.error,
        error: 'Session refresh failed: $e',
      );
    }
  }

  /// Common session callback handling logic
  Future<void> _processSessionCallback(String url) async {
    if (!_validateSession()) return;

    try {
      // Parse the URL to extract auth parameters
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];

      if (code != null) {
        // Let Supabase handle the auth callback
        // This should trigger the onAuthStateChange listener
        await _supabase.auth.getSessionFromUrl(uri);
      }
    } catch (e) {
      _logError('Failed to process authentication callback', e);
      _updateState(
        status: AuthStatus.error,
        error: 'Failed to process authentication callback',
      );
    }
  }

  /// Centralized method to handle all auth state changes
  void _updateState({AuthStatus? status, User? user, String? error}) {
    // Skip if service is disposed
    if (_isDisposed) return;

    // Create new state with provided parameters
    _currentState = _currentState.copyWith(
      status: status,
      user: user,
      error: error,
    );

    // Only add to stream if controller is not closed
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
      // Log only significant state transitions
      if (status == AuthStatus.authenticated || status == AuthStatus.error) {
        _logStateTransition(_currentState);
      }
    }
  }

  /// Dispose resources with simplified cleanup
  void dispose() {
    if (_isDisposed) return;

    // Set disposal flag immediately to prevent multiple disposal calls
    _isDisposed = true;

    try {
      // Cancel auth subscription
      _authSubscription?.cancel();
      _authSubscription = null;

      // Close stream controller if not already closed
      if (!_stateController.isClosed) {
        _stateController.close();
      }

      // Clear singleton instance only if this is the current instance
      if (_instance == this) {
        _instance = null;
      }
    } catch (e) {
      _logError('Error disposing AuthService', e);
      // Ensure disposal flag remains set even if cleanup fails
      _isDisposed = true;
    }
  }
}

/// Provider for AuthService with singleton enforcement
@riverpod
Future<AuthService> authService(Ref ref) async {
  // Check if we already have a valid instance
  if (AuthService.hasValidInstance) {
    return AuthService._instance!;
  }

  // Get Supabase client
  final supabase = SupabaseConfigService.client;

  // Create service using factory constructor (enforces singleton)
  final service = AuthService(supabase);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider for authentication state stream
@riverpod
Stream<AuthState> authState(Ref ref) async* {
  try {
    final authService = await ref.watch(authServiceProvider.future);
    yield* authService.authStateStream;
  } catch (e) {
    // Emit error state if service initialization fails
    yield AuthState(
      status: AuthStatus.error,
      error: 'Failed to initialize auth service: $e',
    );
  }
}

/// Provider for current user
@riverpod
Future<User?> currentUser(Ref ref) async {
  try {
    final authService = await ref.watch(authServiceProvider.future);
    return authService.currentUser;
  } catch (e) {
    return null;
  }
}
