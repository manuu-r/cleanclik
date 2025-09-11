import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User, AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User, AuthState;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cleanclik/core/models/user.dart';
import 'supabase_config_service.dart';

part 'auth_service.g.dart';

/// Authentication status enumeration
enum AuthStatus {
  loading,      // Initial load or authentication in progress
  authenticated, // User is signed in
  unauthenticated, // User is not signed in
  error         // Authentication error occurred
}

/// Unified authentication state
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isDemoMode;

  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.isDemoMode = false,
  });

  // Convenience getters
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isDemoMode,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.username}, error: $error, isDemoMode: $isDemoMode)';
  }
}

/// Authentication error types for better error handling
enum AuthErrorType {
  networkError,           // Network connectivity issues
  invalidCredentials,     // Wrong email/password
  emailNotVerified,      // Email confirmation required
  userNotFound,          // User doesn't exist
  weakPassword,          // Password doesn't meet requirements
  emailAlreadyInUse,     // Email already registered
  configurationError,    // Supabase not configured
  unknownError          // Unexpected errors
}

/// Authentication result with categorized errors
class AuthResult {
  final bool success;
  final User? user;
  final AuthError? error;

  const AuthResult({
    required this.success,
    this.user,
    this.error,
  });

  factory AuthResult.success(User user) =>
      AuthResult(success: true, user: user);
  
  factory AuthResult.failure(AuthErrorType type, String message) =>
      AuthResult(success: false, error: AuthError(type: type, message: message));
}

/// Authentication error with type and message
class AuthError {
  final AuthErrorType type;
  final String message;

  const AuthError({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Simplified authentication service that consolidates all auth operations
class AuthService {
  final SupabaseClient _supabase;

  // State management
  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();
  
  AuthState _currentState = const AuthState(status: AuthStatus.loading);
  StreamSubscription<supabase.AuthState>? _authSubscription;
  bool _isSigningOut = false;
  bool _isDisposed = false;

  AuthService(this._supabase) {
    _initializeAuthState();
  }

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
    try {
      debugPrint('Initializing AuthService...');
      await _checkExistingSession();
    } catch (e) {
      debugPrint('Error during AuthService initialization: $e');
      _updateState(AuthState(
        status: AuthStatus.error,
        error: 'Failed to initialize authentication: $e',
        isDemoMode: SupabaseConfigService.isDemoMode,
      ));
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    if (SupabaseConfigService.isDemoMode) {
      return AuthResult.failure(
        AuthErrorType.configurationError,
        'Authentication not available in demo mode. Please configure Supabase credentials.',
      );
    }

    _updateState(_currentState.copyWith(status: AuthStatus.loading));

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && response.user != null) {
        final user = await _loadOrCreateUserProfile(response.user!);
        _updateState(AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isDemoMode: false,
        ));
        return AuthResult.success(user);
      } else {
        _updateState(AuthState(
          status: AuthStatus.error,
          error: 'Sign in failed',
          isDemoMode: false,
        ));
        return AuthResult.failure(AuthErrorType.unknownError, 'Sign in failed');
      }
    } on AuthException catch (e) {
      final errorType = _mapAuthException(e);
      final errorMessage = e.message;
      
      _updateState(AuthState(
        status: AuthStatus.error,
        error: errorMessage,
        isDemoMode: false,
      ));
      
      return AuthResult.failure(errorType, errorMessage);
    } catch (e) {
      const errorMessage = 'An unexpected error occurred during sign in';
      _updateState(AuthState(
        status: AuthStatus.error,
        error: errorMessage,
        isDemoMode: false,
      ));
      
      return AuthResult.failure(AuthErrorType.unknownError, errorMessage);
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    if (SupabaseConfigService.isDemoMode) {
      return AuthResult.failure(
        AuthErrorType.configurationError,
        'Authentication not available in demo mode. Please configure Supabase credentials.',
      );
    }

    _updateState(_currentState.copyWith(status: AuthStatus.loading));

    try {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _updateState(AuthState(
          status: AuthStatus.unauthenticated,
          isDemoMode: false,
        ));
        return AuthResult.failure(AuthErrorType.unknownError, 'Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        _updateState(AuthState(
          status: AuthStatus.error,
          error: 'Failed to get Google access token',
          isDemoMode: false,
        ));
        return AuthResult.failure(AuthErrorType.unknownError, 'Failed to get Google access token');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken,
      );

      if (response.session != null && response.user != null) {
        final user = await _loadOrCreateUserProfile(response.user!);
        _updateState(AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isDemoMode: false,
        ));
        return AuthResult.success(user);
      } else {
        _updateState(AuthState(
          status: AuthStatus.error,
          error: 'Google sign in failed',
          isDemoMode: false,
        ));
        return AuthResult.failure(AuthErrorType.unknownError, 'Google sign in failed');
      }
    } on AuthException catch (e) {
      final errorType = _mapAuthException(e);
      final errorMessage = e.message;
      
      _updateState(AuthState(
        status: AuthStatus.error,
        error: errorMessage,
        isDemoMode: false,
      ));
      
      return AuthResult.failure(errorType, errorMessage);
    } catch (e) {
      const errorMessage = 'An unexpected error occurred during Google sign in';
      _updateState(AuthState(
        status: AuthStatus.error,
        error: errorMessage,
        isDemoMode: false,
      ));
      
      return AuthResult.failure(AuthErrorType.unknownError, errorMessage);
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    if (SupabaseConfigService.isDemoMode) {
      return AuthResult.failure(
        AuthErrorType.configurationError,
        'Authentication not available in demo mode. Please configure Supabase credentials.',
      );
    }

    _updateState(_currentState.copyWith(status: AuthStatus.loading));

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        if (response.session != null) {
          // User signed up and is immediately authenticated (email confirmation disabled)
          final user = await _createUserProfile(response.user!, username);
          _updateState(AuthState(
            status: AuthStatus.authenticated,
            user: user,
            isDemoMode: false,
          ));
          return AuthResult.success(user);
        } else {
          // User signed up but needs email confirmation
          _updateState(AuthState(
            status: AuthStatus.unauthenticated,
            isDemoMode: false,
          ));
          return AuthResult.failure(
            AuthErrorType.emailNotVerified,
            'Please check your email ($email) and click the confirmation link to complete your account setup.',
          );
        }
      } else {
        _updateState(AuthState(
          status: AuthStatus.error,
          error: 'Sign up failed - no user returned',
          isDemoMode: false,
        ));
        return AuthResult.failure(AuthErrorType.unknownError, 'Sign up failed - no user returned');
      }
    } on AuthException catch (e) {
      final errorType = _mapAuthException(e);
      final errorMessage = e.message;
      
      _updateState(AuthState(
        status: AuthStatus.error,
        error: errorMessage,
        isDemoMode: false,
      ));
      
      return AuthResult.failure(errorType, errorMessage);
    } catch (e) {
      const errorMessage = 'An unexpected error occurred during sign up';
      _updateState(AuthState(
        status: AuthStatus.error,
        error: errorMessage,
        isDemoMode: false,
      ));
      
      return AuthResult.failure(AuthErrorType.unknownError, errorMessage);
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      debugPrint('Starting user sign out process...');
      
      // Set flag to prevent auth state listener from interfering
      _isSigningOut = true;
      
      // Update state to unauthenticated immediately
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: SupabaseConfigService.isDemoMode,
      ));

      if (SupabaseConfigService.isFullyConfigured) {
        // Sign out from Supabase (this may cause expected errors)
        try {
          await _supabase.auth.signOut();
          debugPrint('Supabase sign out completed');
        } catch (e) {
          // Expected errors during signout (real-time disconnections, etc.)
          debugPrint('Expected Supabase signout errors (normal): $e');
        }
      }

      // Reset the flag after successful logout
      _isSigningOut = false;
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Ensure local state is cleared even if there are errors
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: SupabaseConfigService.isDemoMode,
      ));
      _isSigningOut = false;
    }
  }

  /// Update user profile
  Future<void> updateProfile(User updatedUser) async {
    if (_currentState.user?.id != updatedUser.id) {
      throw Exception('Cannot update user: ID mismatch');
    }

    try {
      // Update user in database
      await _updateUserInDatabase(updatedUser);
      
      // Update current state
      _updateState(_currentState.copyWith(user: updatedUser));
      
      debugPrint('User profile updated: ${updatedUser.username}');
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      rethrow;
    }
  }

  /// Add points to current user
  Future<void> addPoints(int points) async {
    final currentUser = _currentState.user;
    if (currentUser == null) return;

    final newTotalPoints = currentUser.totalPoints + points;
    final newLevel = User.calculateLevel(newTotalPoints);

    final updatedUser = currentUser.copyWith(
      totalPoints: newTotalPoints,
      level: newLevel,
      lastActiveAt: DateTime.now(),
    );

    await updateProfile(updatedUser);
  }

  /// Initialize with demo user for development/testing
  Future<void> initializeWithDemoUser() async {
    try {
      debugPrint('Initializing with demo user...');

      // Check if user is already authenticated (don't override real auth)
      if (isAuthenticated) {
        debugPrint('User already authenticated, skipping demo initialization');
        return;
      }

      // Create a demo user instance
      final demoUser = User.defaultUser();

      // Set the current state with demo user
      _updateState(AuthState(
        status: AuthStatus.authenticated,
        user: demoUser,
        isDemoMode: true,
      ));

      debugPrint('Demo user initialized: ${demoUser.username}');
    } catch (e) {
      debugPrint('Failed to initialize demo user: $e');
      _updateState(AuthState(
        status: AuthStatus.error,
        error: 'Failed to initialize demo user: $e',
        isDemoMode: true,
      ));
      rethrow;
    }
  }

  /// Initialize authentication state and listen to auth changes
  void _initializeAuthState() {
    // Check if running in demo mode
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Running in demo mode, skipping Supabase auth initialization');
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: true,
      ));
      return;
    }

    try {
      // Listen to Supabase auth state changes
      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        debugPrint('Auth state changed: $event (isSigningOut: $_isSigningOut)');

        // Skip processing auth events if we're in the middle of signing out
        if (_isSigningOut && event != AuthChangeEvent.signedOut) {
          debugPrint('Ignoring auth event during sign out process: $event');
          return;
        }

        switch (event) {
          case AuthChangeEvent.signedIn:
            if (session != null && !_currentState.isAuthenticated && !_isSigningOut) {
              await _handleSignIn(session);
            }
            break;
          case AuthChangeEvent.signedOut:
            if (!_isSigningOut) {
              _updateState(AuthState(
                status: AuthStatus.unauthenticated,
                isDemoMode: false,
              ));
            } else {
              debugPrint('Sign out event during logout process - resetting flag');
              _isSigningOut = false;
            }
            break;
          case AuthChangeEvent.tokenRefreshed:
            // Token refresh is handled automatically by Supabase client
            debugPrint('Token refreshed automatically');
            break;
          case AuthChangeEvent.userUpdated:
            if (session != null && _currentState.isAuthenticated && !_isSigningOut) {
              await _syncUserData();
            }
            break;
          default:
            break;
        }
      });

      // Check if user is already authenticated on startup
      _checkExistingSession();
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
      _updateState(AuthState(
        status: AuthStatus.error,
        error: 'Failed to initialize authentication: $e',
        isDemoMode: false,
      ));
    }
  }

  /// Check for existing session on startup
  Future<void> _checkExistingSession() async {
    if (_isDisposed) {
      debugPrint('Session check skipped (service disposed)');
      return;
    }
    
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: No session check needed');
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: true,
      ));
      return;
    }

    try {
      debugPrint('Checking existing session...');

      // Add timeout to prevent hanging
      await _performSessionCheck().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Session check timed out after 5 seconds');
          _updateState(AuthState(
            status: AuthStatus.unauthenticated,
            isDemoMode: false,
          ));
          return;
        },
      );
    } catch (e) {
      debugPrint('Error checking existing session: $e');
      _updateState(AuthState(
        status: AuthStatus.error,
        error: 'Failed to check existing session: $e',
        isDemoMode: false,
      ));
    }
  }

  /// Perform the actual session check logic
  Future<void> _performSessionCheck() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('Found active Supabase session');
        await _handleSignIn(session);
        return;
      }

      // No valid session found
      debugPrint('No valid session found, user needs to authenticate');
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: false,
      ));
    } catch (e) {
      debugPrint('Error in session check: $e');
      _updateState(AuthState(
        status: AuthStatus.error,
        error: 'Session check failed: $e',
        isDemoMode: false,
      ));
    }
  }

  /// Handle successful sign in
  Future<void> _handleSignIn(Session session) async {
    if (_isDisposed) {
      debugPrint('Sign in handling skipped (service disposed)');
      return;
    }
    
    try {
      debugPrint('Handling sign in for user: ${session.user.id}');

      // Load or create user profile
      final user = await _loadOrCreateUserProfile(session.user);

      // Update current state
      _updateState(AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isDemoMode: false,
      ));

      debugPrint('User signed in successfully: ${user.username} (${user.email})');
    } catch (e) {
      debugPrint('Error handling sign in: $e');
      _updateState(AuthState(
        status: AuthStatus.error,
        error: 'Failed to load user profile: $e',
        isDemoMode: false,
      ));
    }
  }

  /// Load existing user profile or create new one
  Future<User> _loadOrCreateUserProfile(supabase.User supabaseUser) async {
    try {
      debugPrint('Loading user profile for auth ID: ${supabaseUser.id}');

      // Try to find existing user profile
      final existingUser = await _findUserByAuthId(supabaseUser.id);

      if (existingUser != null) {
        debugPrint('Found existing user profile: ${existingUser.username}');
        
        // Update last active timestamp
        final updatedUser = existingUser.copyWith(lastActiveAt: DateTime.now());
        await _updateUserInDatabase(updatedUser);
        return updatedUser;
      } else {
        debugPrint('No existing user profile found, creating new profile...');
        // Create new user profile
        final username =
            supabaseUser.userMetadata?['username'] as String? ??
            supabaseUser.email?.split('@').first ??
            'User${DateTime.now().millisecondsSinceEpoch}';
        final user = await _createUserProfile(supabaseUser, username);
        debugPrint('Created new user profile: ${user.username}');
        return user;
      }
    } catch (e) {
      debugPrint('Error loading/creating user profile: $e');
      rethrow;
    }
  }

  /// Create new user profile in database
  Future<User> _createUserProfile(
    supabase.User supabaseUser,
    String username,
  ) async {
    try {
      final newUser = User(
        id: supabaseUser.id, // Use Supabase user ID as primary key
        authId: supabaseUser.id,
        username: username,
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

      await _createUserInDatabase(newUser);
      debugPrint('Created new user profile: ${newUser.username}');
      return newUser;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Find user by auth ID in database
  Future<User?> _findUserByAuthId(String authId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return User.fromSupabase(response);
    } catch (e) {
      debugPrint('Error finding user by auth ID: $e');
      rethrow;
    }
  }

  /// Create user in database
  Future<void> _createUserInDatabase(User user) async {
    try {
      await _supabase
          .from('users')
          .insert(user.toSupabase());
    } catch (e) {
      debugPrint('Error creating user in database: $e');
      rethrow;
    }
  }

  /// Update user in database
  Future<void> _updateUserInDatabase(User user) async {
    try {
      await _supabase
          .from('users')
          .update(user.toSupabase())
          .eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating user in database: $e');
      rethrow;
    }
  }

  /// Sync user data from database
  Future<void> _syncUserData() async {
    if (!isAuthenticated) return;

    try {
      final userId = _supabase.auth.currentUser!.id;
      final updatedUser = await _findUserByAuthId(userId);

      if (updatedUser != null) {
        _updateState(_currentState.copyWith(user: updatedUser));
        debugPrint('User data synced from database');
      }
    } catch (e) {
      debugPrint('Failed to sync user data: $e');
    }
  }

  /// Map Supabase AuthException to AuthErrorType
  AuthErrorType _mapAuthException(AuthException exception) {
    final message = exception.message.toLowerCase();
    
    if (message.contains('network') || message.contains('connection')) {
      return AuthErrorType.networkError;
    } else if (message.contains('invalid') && message.contains('credentials')) {
      return AuthErrorType.invalidCredentials;
    } else if (message.contains('email') && message.contains('not') && message.contains('confirmed')) {
      return AuthErrorType.emailNotVerified;
    } else if (message.contains('user') && message.contains('not') && message.contains('found')) {
      return AuthErrorType.userNotFound;
    } else if (message.contains('password') && (message.contains('weak') || message.contains('short'))) {
      return AuthErrorType.weakPassword;
    } else if (message.contains('email') && message.contains('already') && message.contains('use')) {
      return AuthErrorType.emailAlreadyInUse;
    } else {
      return AuthErrorType.unknownError;
    }
  }

  /// Update authentication state and notify listeners
  void _updateState(AuthState newState) {
    // Skip if service is disposed
    if (_isDisposed) {
      debugPrint('Auth state update skipped (service disposed): $newState');
      return;
    }
    
    _currentState = newState;
    
    // Only add to stream if controller is not closed
    if (!_stateController.isClosed) {
      _stateController.add(newState);
      debugPrint('Auth state updated: $newState');
    } else {
      debugPrint('Auth state update skipped (controller closed): $newState');
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('Disposing AuthService resources...');
    _isDisposed = true;
    
    try {
      _authSubscription?.cancel();
      _stateController.close();
      debugPrint('AuthService disposed successfully');
    } catch (e) {
      debugPrint('Error disposing AuthService: $e');
    }
  }
}

/// Provider for AuthService
@riverpod
AuthService authService(Ref ref) {
  // Get Supabase client, using instance client as fallback for demo mode
  late final SupabaseClient supabase;
  try {
    if (SupabaseConfigService.isFullyConfigured) {
      supabase = SupabaseConfigService.client;
    } else {
      supabase = Supabase.instance.client;
    }
  } catch (e) {
    // Fallback to instance client if configuration fails
    supabase = Supabase.instance.client;
  }

  final service = AuthService(supabase);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider for authentication state stream
@riverpod
Stream<AuthState> authState(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateStream;
}

/// Provider for current user
@riverpod
User? currentUser(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
}