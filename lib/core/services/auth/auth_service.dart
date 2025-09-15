import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User, AuthState;
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase
    show User, AuthState;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cleanclik/core/models/user.dart';
import 'package:cleanclik/core/services/auth/supabase_config_service.dart';

part 'auth_service.g.dart';

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
  final bool isDemoMode;

  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.isDemoMode = false,
  });

  // Convenience getters
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
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
  networkError, // Network connectivity issues
  invalidCredentials, // Wrong email/password
  emailNotVerified, // Email confirmation required
  userNotFound, // User doesn't exist
  weakPassword, // Password doesn't meet requirements
  emailAlreadyInUse, // Email already registered
  configurationError, // Supabase not configured
  unknownError, // Unexpected errors
}

/// Authentication result with categorized errors
class AuthResult {
  final bool success;
  final User? user;
  final AuthError? error;

  const AuthResult({required this.success, this.user, this.error});

  factory AuthResult.success(User user) =>
      AuthResult(success: true, user: user);

  factory AuthResult.failure(AuthErrorType type, String message) => AuthResult(
    success: false,
    error: AuthError(type: type, message: message),
  );
}

/// Authentication error with type and message
class AuthError {
  final AuthErrorType type;
  final String message;

  const AuthError({required this.type, required this.message});

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
  
  // Prevent duplicate user profile creation
  final Map<String, Future<User>> _userCreationLocks = {};

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
      _updateState(
        AuthState(
          status: AuthStatus.error,
          error: 'Failed to initialize authentication: $e',
          isDemoMode: SupabaseConfigService.isDemoMode,
        ),
      );
    }
  }

  /// Refresh authentication state (call when app resumes or on deep links)
  Future<void> refreshAuthState() async {
    debugPrint('Refreshing authentication state...');
    await _checkExistingSession();
  }

  /// Handle Supabase auth callback from deep link
  Future<void> handleAuthCallback(String url) async {
    if (SupabaseConfigService.isDemoMode) return;
    
    try {
      debugPrint('Handling Supabase auth callback: $url');
      
      // Parse the URL to extract auth parameters
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      
      if (code != null) {
        debugPrint('Found auth code, processing...');
        
        // Let Supabase handle the auth callback
        // This should trigger the onAuthStateChange listener
        await _supabase.auth.getSessionFromUrl(uri);
        
        debugPrint('Auth callback processed');
      } else {
        debugPrint('No auth code found in callback URL');
      }
    } catch (e) {
      debugPrint('Error handling auth callback: $e');
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

      return _handleAuthResponse(response, 'sign in');
    } on AuthException catch (e) {
      return _handleAuthException(e, 'sign in');
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      const errorMessage = 'An unexpected error occurred during sign in';
      _updateState(
        AuthState(
          status: AuthStatus.error,
          error: errorMessage,
          isDemoMode: false,
        ),
      );
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
        _updateState(
          AuthState(status: AuthStatus.unauthenticated, isDemoMode: false),
        );
        return AuthResult.failure(
          AuthErrorType.unknownError,
          'Google sign in was cancelled by user',
        );
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        _updateState(
          AuthState(status: AuthStatus.unauthenticated, isDemoMode: false),
        );
        return AuthResult.failure(
          AuthErrorType.unknownError,
          'Failed to get Google authentication tokens',
        );
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return _handleAuthResponse(response, 'Google sign in');
    } on AuthException catch (e) {
      return _handleAuthException(e, 'Google sign in');
    } catch (e) {
      debugPrint('Unexpected error during Google sign in: $e');
      const errorMessage = 'An unexpected error occurred during Google sign in';
      _updateState(
        AuthState(
          status: AuthStatus.error,
          error: errorMessage,
          isDemoMode: false,
        ),
      );
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

      return _handleAuthResponse(response, 'sign up', username: username);
    } on AuthException catch (e) {
      return _handleAuthException(e, 'sign up');
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      const errorMessage = 'An unexpected error occurred during sign up';
      _updateState(
        AuthState(
          status: AuthStatus.error,
          error: errorMessage,
          isDemoMode: false,
        ),
      );
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
      _updateState(
        AuthState(
          status: AuthStatus.unauthenticated,
          isDemoMode: SupabaseConfigService.isDemoMode,
        ),
      );

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
      _updateState(
        AuthState(
          status: AuthStatus.unauthenticated,
          isDemoMode: SupabaseConfigService.isDemoMode,
        ),
      );
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
  
  /// Update user rank (called by LeaderboardService)
  void updateUserRank(int newRank) {
    final currentUser = _currentState.user;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(rank: newRank);
      _updateState(_currentState.copyWith(user: updatedUser));
      debugPrint('User rank updated via LeaderboardService: ${currentUser.username} is now rank #$newRank');
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
    
    // Trigger rank update after points change
    await _updateUserRank(updatedUser);
    
    // Notify leaderboard service to trigger updates
    await _notifyLeaderboardService(updatedUser.id);
  }
  
  /// Notify leaderboard service of user changes
  Future<void> _notifyLeaderboardService(String userId) async {
    try {
      // Import and use leaderboard service to trigger updates
      // This will be handled by the leaderboard service's real-time subscriptions
      debugPrint('User points updated, leaderboard will be updated via real-time subscriptions');
    } catch (e) {
      debugPrint('Error notifying leaderboard service: $e');
    }
  }
  
  /// Initialize leaderboard service for real-time updates
  void _initializeLeaderboardService() {
    try {
      // The leaderboard service will be initialized by Riverpod when first accessed
      // Real-time subscriptions will handle rank updates automatically
      debugPrint('Leaderboard service initialization triggered');
    } catch (e) {
      debugPrint('Error initializing leaderboard service: $e');
    }
  }
  
  /// Force refresh user rank (for testing/debugging)
  Future<void> forceRefreshRank() async {
    final currentUser = _currentState.user;
    if (currentUser != null) {
      final userWithRank = await _fetchUserRank(currentUser);
      _updateState(_currentState.copyWith(user: userWithRank));
      debugPrint('Force refreshed rank for ${currentUser.username}: ${userWithRank.rank}');
    }
  }
  
  /// Update user rank after points change
  Future<void> _updateUserRank(User user) async {
    try {
      // Get user's new rank from leaderboard
      final rankQuery = await _supabase
          .from('leaderboard')
          .select('rank')
          .eq('id', user.id)
          .maybeSingle();
      
      if (rankQuery != null) {
        final newRank = rankQuery['rank'] as int;
        final userWithRank = user.copyWith(rank: newRank);
        
        // Update state with new rank
        _updateState(_currentState.copyWith(user: userWithRank));
        
        debugPrint('User rank updated: ${user.username} is now rank #$newRank');
      }
    } catch (e) {
      debugPrint('Error updating user rank: $e');
    }
  }
  
  /// Fetch user rank from leaderboard
  Future<User> _fetchUserRank(User user) async {
    try {
      final rankQuery = await _supabase
          .from('leaderboard')
          .select('rank')
          .eq('id', user.id)
          .maybeSingle();
      
      if (rankQuery != null) {
        final rank = rankQuery['rank'] as int;
        debugPrint('Fetched rank for ${user.username}: #$rank');
        return user.copyWith(rank: rank);
      } else {
        debugPrint('User ${user.username} not found in leaderboard (no points yet)');
        return user.copyWith(rank: null);
      }
    } catch (e) {
      debugPrint('Error fetching user rank: $e');
      return user; // Return user without rank if fetch fails
    }
  }

  /// Handle email verification completion (call this when app resumes or on deep link)
  Future<void> handleEmailVerificationComplete() async {
    if (SupabaseConfigService.isDemoMode) return;
    
    try {
      debugPrint('Handling email verification completion...');
      
      // Refresh the session to check if user is now authenticated
      await _supabase.auth.refreshSession();
      
      // Check current session
      final session = _supabase.auth.currentSession;
      if (session != null && session.user != null) {
        debugPrint('Email verification successful, user authenticated');
        await _handleSignIn(session);
      } else {
        debugPrint('No valid session after email verification');
        _updateState(AuthState(
          status: AuthStatus.unauthenticated,
          isDemoMode: false,
        ));
      }
    } catch (e) {
      debugPrint('Error handling email verification: $e');
      // Don't update to error state, just stay unauthenticated
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: false,
      ));
    }
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
      _updateState(
        AuthState(
          status: AuthStatus.authenticated,
          user: demoUser,
          isDemoMode: true,
        ),
      );

      debugPrint('Demo user initialized: ${demoUser.username}');
    } catch (e) {
      debugPrint('Failed to initialize demo user: $e');
      _updateState(
        AuthState(
          status: AuthStatus.error,
          error: 'Failed to initialize demo user: $e',
          isDemoMode: true,
        ),
      );
      rethrow;
    }
  }

  /// Initialize authentication state and listen to auth changes
  void _initializeAuthState() {
    // Check if running in demo mode
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Running in demo mode, skipping Supabase auth initialization');
      _updateState(
        AuthState(status: AuthStatus.unauthenticated, isDemoMode: true),
      );
      return;
    }

    try {
      // Listen to Supabase auth state changes
      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        debugPrint('Supabase auth state changed: $event (isSigningOut: $_isSigningOut)');
        if (session?.user != null) {
          debugPrint('Session user: ${session!.user.email}, confirmed: ${session.user.emailConfirmedAt}');
        }

        // Skip processing auth events if we're in the middle of signing out
        if (_isSigningOut && event != AuthChangeEvent.signedOut) {
          debugPrint('Ignoring auth event during sign out process: $event');
          return;
        }

        switch (event) {
          case AuthChangeEvent.signedIn:
            if (session != null &&
                !_currentState.isAuthenticated &&
                !_isSigningOut) {
              debugPrint('Processing signedIn event');
              await _handleSignIn(session);
            }
            break;
          case AuthChangeEvent.signedOut:
            if (!_isSigningOut) {
              _updateState(
                AuthState(
                  status: AuthStatus.unauthenticated,
                  isDemoMode: false,
                ),
              );
            } else {
              debugPrint(
                'Sign out event during logout process - resetting flag',
              );
              _isSigningOut = false;
            }
            break;
          case AuthChangeEvent.tokenRefreshed:
            // Token refresh is handled automatically by Supabase client
            debugPrint('Token refreshed automatically');
            break;
          case AuthChangeEvent.userUpdated:
            if (session != null &&
                _currentState.isAuthenticated &&
                !_isSigningOut) {
              await _syncUserData();
            }
            break;
          default:
            debugPrint('Unhandled auth event: $event');
            break;
        }
      });

      // Check if user is already authenticated on startup
      _checkExistingSession();
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
      _updateState(
        AuthState(
          status: AuthStatus.error,
          error: 'Failed to initialize authentication: $e',
          isDemoMode: false,
        ),
      );
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
      _updateState(
        AuthState(status: AuthStatus.unauthenticated, isDemoMode: true),
      );
      return;
    }

    try {
      debugPrint('Checking existing session...');

      // Add timeout to prevent hanging
      await _performSessionCheck().timeout(
        const Duration(seconds: 10), // Increased timeout for email verification
        onTimeout: () {
          debugPrint('Session check timed out after 10 seconds');
          _updateState(
            AuthState(status: AuthStatus.unauthenticated, isDemoMode: false),
          );
          return;
        },
      );
    } catch (e) {
      debugPrint('Error checking existing session: $e');
      _updateState(
        AuthState(
          status: AuthStatus.error,
          error: 'Failed to check existing session: $e',
          isDemoMode: false,
        ),
      );
    }
  }

  /// Perform the actual session check logic
  Future<void> _performSessionCheck() async {
    try {
      // Check current session first
      var session = _supabase.auth.currentSession;
      
      if (session == null) {
        // Try to refresh session in case of email verification
        try {
          final response = await _supabase.auth.refreshSession();
          session = response.session;
          debugPrint('Session refresh completed');
        } catch (e) {
          debugPrint('Session refresh failed (normal if no session): $e');
        }
      }
      
      if (session != null && session.user != null) {
        debugPrint('Found active Supabase session for user: ${session.user.email}');
        await _handleSignIn(session);
        return;
      }

      // No valid session found
      debugPrint('No valid session found, user needs to authenticate');
      _updateState(
        AuthState(status: AuthStatus.unauthenticated, isDemoMode: false),
      );
    } catch (e) {
      debugPrint('Error in session check: $e');
      _updateState(
        AuthState(
          status: AuthStatus.error,
          error: 'Session check failed: $e',
          isDemoMode: false,
        ),
      );
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
      _updateState(
        AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isDemoMode: false,
        ),
      );

      debugPrint(
        'User signed in successfully: ${user.username} (${user.email})',
      );
      
      // Ensure leaderboard service is initialized for real-time updates
      _initializeLeaderboardService();
    } catch (e) {
      debugPrint('Error handling sign in: $e');
      
      // If user session is invalid, clear it and go to unauthenticated state
      if (e.toString().contains('User session invalid') || 
          e.toString().contains('foreign key constraint')) {
        debugPrint('Invalid user session detected, clearing...');
        _updateState(
          AuthState(
            status: AuthStatus.unauthenticated,
            isDemoMode: false,
          ),
        );
      } else {
        _updateState(
          AuthState(
            status: AuthStatus.error,
            error: 'Failed to load user profile: $e',
            isDemoMode: false,
          ),
        );
      }
    }
  }

  /// Load existing user profile or create new one
  Future<User> _loadOrCreateUserProfile(supabase.User supabaseUser) async {
    final authId = supabaseUser.id;
    
    // Check if we're already creating a user profile for this auth ID
    if (_userCreationLocks.containsKey(authId)) {
      debugPrint('User profile creation already in progress for: $authId');
      return await _userCreationLocks[authId]!;
    }
    
    // Create a lock for this user creation
    final creationFuture = _performUserProfileLoad(supabaseUser);
    _userCreationLocks[authId] = creationFuture;
    
    try {
      final user = await creationFuture;
      return user;
    } finally {
      // Remove the lock when done
      _userCreationLocks.remove(authId);
    }
  }

  /// Perform the actual user profile loading/creation
  Future<User> _performUserProfileLoad(supabase.User supabaseUser) async {
    try {
      debugPrint('Loading user profile for auth ID: ${supabaseUser.id}');

      // Try to find existing user profile
      final existingUser = await _findUserByAuthId(supabaseUser.id);

      if (existingUser != null) {
        debugPrint('Found existing user profile: ${existingUser.username}');

        // Update last active timestamp and fetch current rank
        final userWithTimestamp = existingUser.copyWith(lastActiveAt: DateTime.now());
        await _updateUserInDatabase(userWithTimestamp);
        
        // Fetch current rank from leaderboard
        final userWithRank = await _fetchUserRank(userWithTimestamp);
        return userWithRank;
      } else {
        debugPrint('No existing user profile found');
        
        // Check if this is a new user (just confirmed email) or deleted user
        final userCreatedAt = DateTime.parse(supabaseUser.createdAt!);
        final now = DateTime.now();
        final timeSinceCreation = now.difference(userCreatedAt).inMinutes;
        
        debugPrint('User created ${timeSinceCreation} minutes ago');
        
        // If user was created recently (within 10 minutes), it's likely a new signup
        if (timeSinceCreation <= 10) {
          debugPrint('Recent user creation detected, creating new profile...');
          
          // Create new user profile for email verification signup
          final username =
              supabaseUser.userMetadata?['username'] as String? ??
              supabaseUser.email?.split('@').first ??
              'User${DateTime.now().millisecondsSinceEpoch}';
          final user = await _createUserProfile(supabaseUser, username);
          debugPrint('Created new user profile: ${user.username}');
          
          // Fetch initial rank for new user
          final userWithRank = await _fetchUserRank(user);
          return userWithRank;
        } else {
          debugPrint('Old user without profile - likely deleted, clearing session');
          throw Exception('User profile not found - session invalid');
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      
      // If user doesn't exist or there's a foreign key error, clear the session
      if (e.toString().contains('foreign key constraint') || 
          e.toString().contains('User profile not found')) {
        debugPrint('User deleted from Supabase, clearing session...');
        await _clearInvalidSession();
        throw Exception('User session invalid - please sign in again');
      }
      
      rethrow;
    }
  }

  /// Clear invalid session when user doesn't exist
  Future<void> _clearInvalidSession() async {
    try {
      debugPrint('Clearing invalid session...');
      
      // Sign out to clear the session
      await _supabase.auth.signOut();
      
      // Update state to unauthenticated
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: false,
      ));
      
      debugPrint('Invalid session cleared successfully');
    } catch (e) {
      debugPrint('Error clearing invalid session: $e');
      // Even if signOut fails, update state to unauthenticated
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: false,
      ));
    }
  }

  /// Create new user profile in database
  Future<User> _createUserProfile(
    supabase.User supabaseUser,
    String username,
  ) async {
    try {
      // Wait a moment to ensure the auth.users record is fully created
      await Future.delayed(const Duration(milliseconds: 500));
      
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
      
      // If it's a foreign key constraint error, try again after a longer delay
      if (e.toString().contains('foreign key constraint')) {
        debugPrint('Foreign key constraint error, retrying after delay...');
        await Future.delayed(const Duration(seconds: 2));
        
        try {
          final retryUser = User(
            id: supabaseUser.id,
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
          
          await _createUserInDatabase(retryUser);
          debugPrint('Created user profile on retry: ${retryUser.username}');
          return retryUser;
        } catch (retryError) {
          debugPrint('Retry failed: $retryError');
          rethrow;
        }
      }
      
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
      debugPrint('Creating user in database with auth_id: ${user.authId}');
      
      // Verify the auth user exists first
      final authUser = _supabase.auth.currentUser;
      if (authUser == null || authUser.id != user.authId) {
        throw Exception('Auth user not found or ID mismatch');
      }
      
      await _supabase.from('users').insert(user.toSupabase());
      debugPrint('User successfully created in database');
    } catch (e) {
      debugPrint('Error creating user in database: $e');
      
      // If it's a foreign key constraint, provide more helpful error info
      if (e.toString().contains('foreign key constraint')) {
        debugPrint('Foreign key constraint violation - auth user may not exist yet');
        debugPrint('Current auth user: ${_supabase.auth.currentUser?.id}');
        debugPrint('Trying to create user with auth_id: ${user.authId}');
      }
      
      rethrow;
    }
  }

  /// Update user in database
  Future<void> _updateUserInDatabase(User user) async {
    try {
      await _supabase.from('users').update(user.toSupabase()).eq('id', user.id);
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

  /// Handle Supabase authentication response
  Future<AuthResult> _handleAuthResponse(
    AuthResponse response,
    String operation, {
    String? username,
  }) async {
    debugPrint('Handling $operation response: user=${response.user?.id}, session=${response.session?.accessToken != null}');

    // Case 1: Successful authentication with session
    if (response.session != null && response.user != null) {
      try {
        final User user;
        if (operation == 'sign up' && username != null) {
          user = await _createUserProfile(response.user!, username);
        } else {
          user = await _loadOrCreateUserProfile(response.user!);
        }
        
        _updateState(AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isDemoMode: false,
        ));
        
        debugPrint('$operation successful: ${user.username}');
        return AuthResult.success(user);
      } catch (e) {
        debugPrint('Error creating/loading user profile: $e');
        _updateState(AuthState(
          status: AuthStatus.error,
          error: 'Failed to create user profile',
          isDemoMode: false,
        ));
        return AuthResult.failure(
          AuthErrorType.unknownError,
          'Failed to create user profile',
        );
      }
    }

    // Case 2: User created but needs email verification (signup only)
    if (response.user != null && response.session == null && operation == 'sign up') {
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: false,
      ));

      final user = response.user!;
      
      // Check if user already exists using Supabase response indicators
      final bool userAlreadyExists = user.identities?.isEmpty ?? true;
      final bool confirmationSent = user.confirmationSentAt != null;
      
      debugPrint('Signup analysis: userAlreadyExists=$userAlreadyExists, confirmationSent=$confirmationSent');
      debugPrint('User identities: ${user.identities?.length ?? 0}');
      debugPrint('Confirmation sent at: ${user.confirmationSentAt}');
      
      if (userAlreadyExists) {
        // User already exists - identities array is empty for existing users
        debugPrint('User already exists (empty identities)');
        return AuthResult.failure(
          AuthErrorType.emailAlreadyInUse,
          'This email is already registered. Please sign in instead or use a different email.',
        );
      } else if (confirmationSent) {
        // New user created, confirmation email sent
        debugPrint('New user created, email verification required');
        return AuthResult.failure(
          AuthErrorType.emailNotVerified,
          'Please check your email and click the confirmation link to complete your account setup.',
        );
      } else {
        // New user created and confirmed (email confirmation disabled)
        debugPrint('New user created and confirmed');
        return AuthResult.failure(
          AuthErrorType.unknownError,
          'Account created but authentication failed. Please try signing in.',
        );
      }
    }

    // Case 3: No user or session returned (should not happen with valid requests)
    _updateState(AuthState(
      status: AuthStatus.unauthenticated,
      isDemoMode: false,
    ));
    
    debugPrint('$operation failed: no user or session returned');
    return AuthResult.failure(
      AuthErrorType.unknownError,
      '${operation.substring(0, 1).toUpperCase()}${operation.substring(1)} failed',
    );
  }

  /// Handle Supabase authentication exceptions
  AuthResult _handleAuthException(AuthException exception, String operation) {
    final errorType = _mapAuthException(exception);
    final errorMessage = _getErrorMessage(exception, operation);
    
    debugPrint('$operation failed with AuthException: ${exception.message}');

    // Determine appropriate state based on error type
    if (_isUserInputError(errorType)) {
      _updateState(AuthState(
        status: AuthStatus.unauthenticated,
        isDemoMode: false,
      ));
    } else {
      _updateState(AuthState(
        status: AuthStatus.error,
        error: errorMessage,
        isDemoMode: false,
      ));
    }

    return AuthResult.failure(errorType, errorMessage);
  }

  /// Check if error is due to user input (should stay unauthenticated)
  bool _isUserInputError(AuthErrorType errorType) {
    return [
      AuthErrorType.invalidCredentials,
      AuthErrorType.userNotFound,
      AuthErrorType.emailNotVerified,
      AuthErrorType.emailAlreadyInUse,
      AuthErrorType.weakPassword,
    ].contains(errorType);
  }

  /// Get user-friendly error message
  String _getErrorMessage(AuthException exception, String operation) {
    final errorType = _mapAuthException(exception);
    
    switch (errorType) {
      case AuthErrorType.invalidCredentials:
        return operation == 'sign in' 
          ? 'Invalid email or password. Please check your credentials and try again.'
          : 'Invalid credentials provided.';
      
      case AuthErrorType.emailAlreadyInUse:
        return 'This email is already registered. Please sign in instead or use a different email.';
      
      case AuthErrorType.weakPassword:
        return 'Password is too weak. Please use at least 8 characters with uppercase, lowercase, and numbers.';
      
      case AuthErrorType.emailNotVerified:
        return 'Please verify your email address before signing in.';
      
      case AuthErrorType.userNotFound:
        return 'No account found with this email address. Please sign up first.';
      
      case AuthErrorType.networkError:
        return 'Network error. Please check your internet connection and try again.';
      
      case AuthErrorType.configurationError:
        return 'Authentication service is not properly configured.';
      
      case AuthErrorType.unknownError:
      default:
        return exception.message.isNotEmpty 
          ? exception.message 
          : 'An unexpected error occurred during $operation.';
    }
  }

  /// Map Supabase AuthException to AuthErrorType
  AuthErrorType _mapAuthException(AuthException exception) {
    final message = exception.message.toLowerCase();

    // Analyze message content for error detection
    if (message.contains('network') || message.contains('connection') || message.contains('timeout')) {
      return AuthErrorType.networkError;
    } else if (message.contains('invalid') && (message.contains('credentials') || message.contains('login') || message.contains('password'))) {
      return AuthErrorType.invalidCredentials;
    } else if (message.contains('email') && message.contains('not') && message.contains('confirmed')) {
      return AuthErrorType.emailNotVerified;
    } else if (message.contains('user') && message.contains('not') && message.contains('found')) {
      return AuthErrorType.userNotFound;
    } else if (message.contains('password') && (message.contains('weak') || message.contains('short') || message.contains('simple'))) {
      return AuthErrorType.weakPassword;
    } else if (message.contains('email') && (message.contains('already') || message.contains('registered') || message.contains('taken') || message.contains('use'))) {
      return AuthErrorType.emailAlreadyInUse;
    } else if (message.contains('signup') && message.contains('disabled')) {
      return AuthErrorType.configurationError;
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
