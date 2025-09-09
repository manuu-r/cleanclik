import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import 'token_service.dart';
import 'user_database_service.dart';
import 'database_service_provider.dart';
import 'supabase_config_service.dart';

part 'user_service.g.dart';

/// Authentication result wrapper
class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final AuthException? exception;
  final bool emailConfirmationRequired;

  const AuthResult({
    required this.success,
    this.user,
    this.error,
    this.exception,
    this.emailConfirmationRequired = false,
  });

  factory AuthResult.success(User user) =>
      AuthResult(success: true, user: user);
  factory AuthResult.failure(String error, [AuthException? exception]) =>
      AuthResult(success: false, error: error, exception: exception);
  factory AuthResult.emailConfirmationPending(String email) => AuthResult(
    success: false,
    emailConfirmationRequired: true,
    error:
        'Please check your email ($email) and click the confirmation link to complete your account setup.',
  );
}

/// Service for managing user authentication and profile data with Supabase
class UserService {
  final TokenService _tokenService;
  final UserDatabaseService _userDbService;
  final SupabaseClient _supabase;

  // State management
  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  User? _currentUser;
  StreamSubscription<AuthState>? _authSubscription;

  UserService(this._tokenService, this._userDbService, this._supabase) {
    _initializeAuthState();
  }

  /// Initialize authentication service
  /// Checks for existing session and restores authentication state
  Future<void> initialize() async {
    await _checkExistingSession();
  }

  /// Stream of user changes
  Stream<User?> get userStream => _userController.stream;

  /// Stream of authentication state changes
  Stream<bool> get authStateStream => _authStateController.stream;

  /// Get current user
  User? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated =>
      _supabase.auth.currentUser != null && _currentUser != null;

  /// Initialize authentication state and listen to auth changes
  void _initializeAuthState() {
    // Check if running in demo mode
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Running in demo mode, skipping Supabase auth initialization');
      _authStateController.add(false);
      return;
    }

    try {
      // Listen to Supabase auth state changes
      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        debugPrint('Auth state changed: $event');

        switch (event) {
          case AuthChangeEvent.signedIn:
            if (session != null) {
              await _handleSignIn(session);
            }
            break;
          case AuthChangeEvent.signedOut:
            await _handleSignOut();
            break;
          case AuthChangeEvent.tokenRefreshed:
            if (session != null) {
              await _tokenService.storeTokens(session);
            }
            break;
          case AuthChangeEvent.userUpdated:
            if (session != null) {
              await _handleUserUpdate(session);
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
      _authStateController.add(false);
    }
  }

  /// Check for existing session on startup
  Future<void> _checkExistingSession() async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: No session check needed');
      _authStateController.add(false);
      return;
    }

    try {
      debugPrint('Checking existing session...');

      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('Found active Supabase session');
        await _handleSignIn(session);
        return;
      }

      // Try to restore session from stored tokens
      debugPrint('No active session found, checking stored tokens...');
      final tokenStatus = await _tokenService.getTokenStatus();
      debugPrint('Token status: $tokenStatus');

      if (tokenStatus['hasValidTokens'] == true) {
        debugPrint('Found valid stored tokens, attempting session restore...');
        final restored = await _tokenService.restoreSession();
        if (restored) {
          // Session was restored, re-check current session
          final restoredSession = _supabase.auth.currentSession;
          if (restoredSession != null) {
            await _handleSignIn(restoredSession);
            return;
          }
        }
        debugPrint('Failed to restore session, clearing tokens');
        await _tokenService.clearTokens();
      }

      // No valid session or tokens found
      debugPrint('No valid session found, user needs to authenticate');
      _authStateController.add(false);
    } catch (e) {
      debugPrint('Error checking existing session: $e');
      await _tokenService.clearTokens();
      _authStateController.add(false);
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: Cannot sign in with email/password');
      return AuthResult.failure(
        'Authentication not available in demo mode. Please configure Supabase credentials.',
      );
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && response.user != null) {
        await _tokenService.storeTokens(response.session!);
        final user = await _loadOrCreateUserProfile(response.user!);
        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Sign in failed');
      }
    } on AuthException catch (e) {
      debugPrint('Auth error during sign in: ${e.message}');
      return AuthResult.failure(e.message, e);
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: Cannot sign up with email/password');
      return AuthResult.failure(
        'Authentication not available in demo mode. Please configure Supabase credentials.',
      );
    }

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      debugPrint('User signed up successfully, ${response.user.toString()}');

      if (response.user != null) {
        if (response.session != null) {
          // User signed up and is immediately authenticated (email confirmation disabled)
          await _tokenService.storeTokens(response.session!);
          final user = await _createUserProfile(response.user!, username);
          return AuthResult.success(user);
        } else {
          // User signed up but needs email confirmation
          debugPrint('User signed up, email confirmation required');
          return AuthResult.emailConfirmationPending(email);
        }
      } else {
        return AuthResult.failure('Sign up failed - no user returned');
      }
    } on AuthException catch (e) {
      debugPrint('Auth error during sign up: ${e.message}');
      return AuthResult.failure(e.message, e);
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: Cannot sign in with Google');
      return AuthResult.failure(
        'Authentication not available in demo mode. Please configure Supabase credentials.',
      );
    }

    try {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        return AuthResult.failure('Failed to get Google access token');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken,
      );

      if (response.session != null && response.user != null) {
        await _tokenService.storeTokens(response.session!);
        final user = await _loadOrCreateUserProfile(response.user!);
        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Google sign in failed');
      }
    } on AuthException catch (e) {
      debugPrint('Auth error during Google sign in: ${e.message}');
      return AuthResult.failure(e.message, e);
    } catch (e) {
      debugPrint('Unexpected error during Google sign in: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign in anonymously for demo purposes
  Future<AuthResult> signInAnonymously() async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: Cannot sign in anonymously');
      return AuthResult.failure(
        'Authentication not available in demo mode. Please configure Supabase credentials.',
      );
    }

    try {
      final response = await _supabase.auth.signInAnonymously();

      if (response.session != null && response.user != null) {
        await _tokenService.storeTokens(response.session!);
        final user = await _loadOrCreateUserProfile(response.user!);
        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Anonymous sign in failed');
      }
    } on AuthException catch (e) {
      debugPrint('Auth error during anonymous sign in: ${e.message}');
      return AuthResult.failure(e.message, e);
    } catch (e) {
      debugPrint('Unexpected error during anonymous sign in: $e');
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(User updatedUser) async {
    if (_currentUser?.id != updatedUser.id) {
      throw Exception('Cannot update user: ID mismatch');
    }

    try {
      final result = await _userDbService.update(
        updatedUser.id,
        updatedUser,
        updatedUser.authId!,
      );

      if (!result.isSuccess) {
        throw Exception('Failed to update user profile: ${result.error}');
      }

      final updated = result.data!;
      _currentUser = updated;
      _userController.add(updated);
      debugPrint('User profile updated: ${updated.username}');
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      rethrow;
    }
  }

  /// Update user points and level
  Future<void> updateUserPoints(int pointsToAdd) async {
    if (_currentUser == null) return;

    final newTotalPoints = _currentUser!.totalPoints + pointsToAdd;
    final newLevel = User.calculateLevel(newTotalPoints);

    final updatedUser = _currentUser!.copyWith(
      totalPoints: newTotalPoints,
      level: newLevel,
      lastActiveAt: DateTime.now(),
    );

    await updateUserProfile(updatedUser);
  }

  /// Update user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      isOnline: isOnline,
      lastActiveAt: DateTime.now(),
    );

    await updateUserProfile(updatedUser);
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      if (SupabaseConfigService.isFullyConfigured) {
        // Sign out from Supabase
        await _supabase.auth.signOut();

        // Clear tokens
        await _tokenService.clearTokens();
      }

      // Always handle local sign out
      await _handleSignOut();

      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Failed to sign out: $e');
      // Ensure local state is cleared even if Supabase signout fails
      await _handleSignOut();
      rethrow;
    }
  }

  /// Initialize with demo user for development/testing
  /// This creates a demo user session without actual authentication
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

      // Set the current user and notify listeners
      _currentUser = demoUser;
      _userController.add(demoUser);
      _authStateController.add(true);

      debugPrint('Demo user initialized: ${demoUser.username}');
    } catch (e) {
      debugPrint('Failed to initialize demo user: $e');
      _authStateController.add(false);
      rethrow;
    }
  }

  /// Add achievement to current user
  Future<void> addAchievement(String achievementId) async {
    if (_currentUser == null) {
      debugPrint('Cannot add achievement: No current user');
      return;
    }

    // Check if achievement already exists
    if (_currentUser!.achievements.contains(achievementId)) {
      debugPrint('Achievement $achievementId already exists for user');
      return;
    }

    try {
      final updatedAchievements = [
        ..._currentUser!.achievements,
        achievementId,
      ];
      final updatedUser = _currentUser!.copyWith(
        achievements: updatedAchievements,
        lastActiveAt: DateTime.now(),
      );

      await updateUserProfile(updatedUser);
      debugPrint(
        'Achievement $achievementId added to user ${_currentUser!.username}',
      );
    } catch (e) {
      debugPrint('Failed to add achievement $achievementId: $e');
      rethrow;
    }
  }

  /// Get user statistics summary
  Map<String, dynamic> getUserStats() {
    if (_currentUser == null) return {};

    return {
      'totalPoints': _currentUser!.totalPoints,
      'level': _currentUser!.level,
      'levelProgress': _currentUser!.levelProgress,
      'pointsToNextLevel': _currentUser!.pointsToNextLevel,
      'totalItemsCollected': _currentUser!.totalItemsCollected,
      'categoryStats': _currentUser!.categoryStats,
      'achievements': _currentUser!.achievements,
      'rank': _currentUser!.rank,
      'accountAge': DateTime.now().difference(_currentUser!.createdAt).inDays,
    };
  }

  /// Sync user data from database
  Future<void> syncUserData() async {
    if (!isAuthenticated) return;

    try {
      final userId = _supabase.auth.currentUser!.id;
      final result = await _userDbService.findByAuthId(userId);

      if (result.isSuccess && result.data != null) {
        _currentUser = result.data;
        _userController.add(result.data!);
        debugPrint('User data synced from database');
      }
    } catch (e) {
      debugPrint('Failed to sync user data: $e');
    }
  }

  /// Check if user's email is verified
  Future<bool> checkEmailVerification() async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: Email verification not applicable');
      return true;
    }

    try {
      // Refresh the current session to get updated user info
      await _supabase.auth.refreshSession();
      final user = _supabase.auth.currentUser;

      if (user != null) {
        final isVerified = user.emailConfirmedAt != null;
        debugPrint('Email verification status: $isVerified');

        if (isVerified && _currentUser == null) {
          // User is verified but we don't have their profile loaded
          await _handleSignIn(_supabase.auth.currentSession!);
        }

        return isVerified;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  /// Resend email confirmation
  Future<bool> resendEmailConfirmation(String email) async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: Cannot resend email confirmation');
      return false;
    }

    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
      debugPrint('Email confirmation resent to: $email');
      return true;
    } catch (e) {
      debugPrint('Error resending email confirmation: $e');
      return false;
    }
  }

  /// Verify email with token from confirmation link
  Future<AuthResult> verifyEmailWithToken(String token, String email) async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: Cannot verify email with token');
      return AuthResult.failure(
        'Email verification not available in demo mode',
      );
    }

    try {
      final response = await _supabase.auth.verifyOTP(
        token: token,
        type: OtpType.signup,
        email: email,
      );

      if (response.session != null && response.user != null) {
        // Email verified and user is now authenticated
        await _tokenService.storeTokens(response.session!);
        final user = await _loadOrCreateUserProfile(response.user!);
        debugPrint('Email verified successfully for: ${user.email}');
        return AuthResult.success(user);
      } else {
        debugPrint('Email verification failed: No session returned');
        return AuthResult.failure('Email verification failed');
      }
    } on AuthException catch (e) {
      debugPrint('Auth error during email verification: ${e.message}');
      return AuthResult.failure(e.message, e);
    } catch (e) {
      debugPrint('Unexpected error during email verification: $e');
      return AuthResult.failure(
        'An unexpected error occurred during email verification',
      );
    }
  }

  /// Handle successful sign in
  Future<void> _handleSignIn(Session session) async {
    try {
      debugPrint('Handling sign in for user: ${session.user.id}');

      // Store tokens securely
      await _tokenService.storeTokens(session);
      debugPrint('Tokens stored successfully');

      // Load or create user profile
      final user = await _loadOrCreateUserProfile(session.user);

      // Update current state
      _currentUser = user;
      _userController.add(user);
      _authStateController.add(true);

      debugPrint(
        'User signed in successfully: ${user.username} (${user.email})',
      );
    } catch (e) {
      debugPrint('Error handling sign in: $e');
      _authStateController.add(false);
      // Don't rethrow here to prevent breaking auth flow
      // The error will be logged and the user can try again
    }
  }

  /// Handle sign out
  Future<void> _handleSignOut() async {
    try {
      final previousUser = _currentUser?.username ?? 'Unknown';

      _currentUser = null;
      _userController.add(null);
      _authStateController.add(false);

      debugPrint('User signed out: $previousUser');
    } catch (e) {
      debugPrint('Error during sign out handling: $e');
      // Still emit the sign out state even if there's an error
      _currentUser = null;
      _userController.add(null);
      _authStateController.add(false);
    }
  }

  /// Handle user update
  Future<void> _handleUserUpdate(Session session) async {
    try {
      debugPrint('Handling user update event');

      if (_currentUser != null) {
        // Store updated tokens
        await _tokenService.storeTokens(session);

        // Sync user data from database
        await syncUserData();

        debugPrint('User data updated successfully');
      } else {
        debugPrint('No current user to update');
      }
    } catch (e) {
      debugPrint('Error handling user update: $e');
      // Don't break the user session on update errors
    }
  }

  /// Load existing user profile or create new one
  Future<User> _loadOrCreateUserProfile(supabase.User supabaseUser) async {
    try {
      debugPrint('Loading user profile for auth ID: ${supabaseUser.id}');

      // Try to find existing user profile
      final result = await _userDbService.findByAuthId(supabaseUser.id);

      if (!result.isSuccess) {
        debugPrint('Database query failed: ${result.error}');
        throw Exception('Failed to query user profile: ${result.error}');
      }

      User? user = result.data;

      if (user == null) {
        debugPrint('No existing user profile found, creating new profile...');
        // Create new user profile
        final username =
            supabaseUser.userMetadata?['username'] as String? ??
            supabaseUser.email?.split('@').first ??
            'User${DateTime.now().millisecondsSinceEpoch}';
        user = await _createUserProfile(supabaseUser, username);
        debugPrint('Created new user profile: ${user.username}');
      } else {
        debugPrint('Found existing user profile: ${user.username}');

        // Update last active timestamp
        try {
          final updatedUser = user.copyWith(lastActiveAt: DateTime.now());
          await updateUserProfile(updatedUser);
          user = updatedUser;
        } catch (e) {
          debugPrint('Failed to update last active time: $e');
          // Continue with existing user data
        }
      }

      return user!;
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

      final result = await _userDbService.create(newUser, supabaseUser.id);

      if (!result.isSuccess) {
        throw Exception('Failed to create user profile: ${result.error}');
      }

      final createdUser = result.data!;
      debugPrint('Created new user profile: ${createdUser.username}');
      return createdUser;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('Disposing UserService resources...');
    try {
      _authSubscription?.cancel();
      _userController.close();
      _authStateController.close();
      debugPrint('UserService disposed successfully');
    } catch (e) {
      debugPrint('Error disposing UserService: $e');
    }
  }
}

/// Provider for UserService
@riverpod
UserService userService(Ref ref) {
  final tokenService = ref.watch(tokenServiceProvider);
  final userDbService = ref.watch(userDatabaseServiceProvider);

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

  final service = UserService(tokenService, userDbService, supabase);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider for current user
@riverpod
Stream<User?> currentUser(Ref ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.userStream;
}

/// Provider for authentication state
@riverpod
Stream<bool> authState(Ref ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.authStateStream;
}

/// Provider for user statistics
@riverpod
Map<String, dynamic> userStats(Ref ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserStats();
}
