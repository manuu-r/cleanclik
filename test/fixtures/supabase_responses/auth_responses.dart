import 'package:supabase_flutter/supabase_flutter.dart';
import '../mock_data/mock_users.dart';

/// Mock Supabase authentication responses for testing
class AuthResponses {
  /// Mock successful sign in response
  static AuthResponse createSignInResponse({
    Map<String, dynamic>? userData,
  }) {
    final user = userData ?? MockUsers.createAuthenticatedUser();
    
    return AuthResponse(
      user: User.fromJson(user),
      session: Session.fromJson({
        'access_token': 'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
        'expires_in': 3600,
        'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'token_type': 'bearer',
        'user': user,
      }),
    );
  }

  /// Mock successful sign up response
  static AuthResponse createSignUpResponse({
    Map<String, dynamic>? userData,
    bool emailConfirmationRequired = false,
  }) {
    final user = userData ?? MockUsers.createAuthenticatedUser();
    
    return AuthResponse(
      user: emailConfirmationRequired ? null : User.fromJson(user),
      session: emailConfirmationRequired ? null : Session.fromJson({
        'access_token': 'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
        'expires_in': 3600,
        'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'token_type': 'bearer',
        'user': user,
      }),
    );
  }

  /// Mock Google Sign-In response
  static AuthResponse createGoogleSignInResponse() {
    final user = MockUsers.createGoogleSignInUser();
    
    return AuthResponse(
      user: User.fromJson(user),
      session: Session.fromJson({
        'access_token': 'mock-google-access-token-${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock-google-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
        'expires_in': 3600,
        'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'token_type': 'bearer',
        'provider_token': 'mock-google-provider-token',
        'provider_refresh_token': 'mock-google-provider-refresh-token',
        'user': user,
      }),
    );
  }

  /// Mock authentication error responses
  static AuthException createAuthError({
    required String message,
    String? statusCode,
  }) {
    return AuthException(message, statusCode: statusCode);
  }

  /// Mock common authentication errors
  static Map<String, AuthException> getCommonAuthErrors() {
    return {
      'invalid_credentials': AuthException(
        'Invalid login credentials',
        statusCode: '400',
      ),
      'email_not_confirmed': AuthException(
        'Email not confirmed',
        statusCode: '400',
      ),
      'user_not_found': AuthException(
        'User not found',
        statusCode: '400',
      ),
      'weak_password': AuthException(
        'Password should be at least 6 characters',
        statusCode: '422',
      ),
      'email_already_registered': AuthException(
        'User already registered',
        statusCode: '422',
      ),
      'network_error': AuthException(
        'Network request failed',
        statusCode: '500',
      ),
      'rate_limit_exceeded': AuthException(
        'Too many requests',
        statusCode: '429',
      ),
    };
  }

  /// Mock auth state change events
  static List<AuthState> createAuthStateChanges() {
    return [
      // Initial state - signed out
      AuthState(AuthChangeEvent.signedOut, null),
      
      // User signs in
      AuthState(
        AuthChangeEvent.signedIn,
        Session.fromJson({
          'access_token': 'mock-access-token',
          'refresh_token': 'mock-refresh-token',
          'expires_in': 3600,
          'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'token_type': 'bearer',
          'user': MockUsers.createAuthenticatedUser(),
        }),
      ),
      
      // Token refresh
      AuthState(
        AuthChangeEvent.tokenRefreshed,
        Session.fromJson({
          'access_token': 'mock-refreshed-access-token',
          'refresh_token': 'mock-refreshed-refresh-token',
          'expires_in': 3600,
          'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'token_type': 'bearer',
          'user': MockUsers.createAuthenticatedUser(),
        }),
      ),
      
      // User signs out
      AuthState(AuthChangeEvent.signedOut, null),
    ];
  }

  /// Mock password reset response
  static Map<String, dynamic> createPasswordResetResponse({
    required String email,
  }) {
    return {
      'message': 'Password reset email sent',
      'email': email,
      'sent_at': DateTime.now().toIso8601String(),
    };
  }

  /// Mock email verification response
  static Map<String, dynamic> createEmailVerificationResponse({
    required String email,
  }) {
    return {
      'message': 'Verification email sent',
      'email': email,
      'sent_at': DateTime.now().toIso8601String(),
    };
  }

  /// Mock user update response
  static AuthResponse createUserUpdateResponse({
    required Map<String, dynamic> updates,
    Map<String, dynamic>? currentUser,
  }) {
    final user = currentUser ?? MockUsers.createAuthenticatedUser();
    final updatedUser = {...user, ...updates};
    
    return AuthResponse(
      user: User.fromJson(updatedUser),
      session: Session.fromJson({
        'access_token': 'mock-access-token',
        'refresh_token': 'mock-refresh-token',
        'expires_in': 3600,
        'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'token_type': 'bearer',
        'user': updatedUser,
      }),
    );
  }

  /// Mock session refresh response
  static AuthResponse createSessionRefreshResponse({
    Map<String, dynamic>? userData,
  }) {
    final user = userData ?? MockUsers.createAuthenticatedUser();
    
    return AuthResponse(
      user: User.fromJson(user),
      session: Session.fromJson({
        'access_token': 'mock-refreshed-access-token-${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock-refreshed-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
        'expires_in': 3600,
        'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'token_type': 'bearer',
        'user': user,
      }),
    );
  }

  /// Mock demo mode authentication
  static AuthResponse createDemoModeResponse() {
    final user = MockUsers.createDemoUser();
    
    return AuthResponse(
      user: User.fromJson(user),
      session: Session.fromJson({
        'access_token': 'demo-access-token',
        'refresh_token': 'demo-refresh-token',
        'expires_in': 86400, // 24 hours for demo
        'expires_at': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
        'token_type': 'bearer',
        'user': user,
      }),
    );
  }

  /// Mock multi-factor authentication response
  static Map<String, dynamic> createMFAResponse({
    required String challengeId,
    required String factorId,
  }) {
    return {
      'challenge_id': challengeId,
      'factor_id': factorId,
      'expires_at': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
      'status': 'pending',
    };
  }

  /// Mock OAuth provider responses
  static Map<String, AuthResponse> createOAuthResponses() {
    return {
      'google': createGoogleSignInResponse(),
      'apple': AuthResponse(
        user: User.fromJson({
          ...MockUsers.createAuthenticatedUser(),
          'app_metadata': {
            'provider': 'apple',
            'providers': ['apple'],
          },
        }),
        session: Session.fromJson({
          'access_token': 'mock-apple-access-token',
          'refresh_token': 'mock-apple-refresh-token',
          'expires_in': 3600,
          'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          'token_type': 'bearer',
          'provider_token': 'mock-apple-provider-token',
          'user': MockUsers.createAuthenticatedUser(),
        }),
      ),
    };
  }

  /// Mock auth configuration response
  static Map<String, dynamic> createAuthConfigResponse() {
    return {
      'providers': ['email', 'google', 'apple'],
      'password_requirements': {
        'min_length': 6,
        'require_uppercase': false,
        'require_lowercase': false,
        'require_numbers': false,
        'require_symbols': false,
      },
      'session_timeout': 3600,
      'refresh_token_rotation': true,
      'email_confirmation_required': true,
      'phone_confirmation_required': false,
      'mfa_enabled': false,
    };
  }
}