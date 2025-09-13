import 'package:cleanclik/core/models/user.dart';
import '../test_data_factory.dart';
import '../../test_config.dart';

/// Comprehensive mock authentication states for all testing scenarios
class MockAuthStates {
  /// Get all predefined auth state fixtures
  static Map<String, Map<String, dynamic>> getAllAuthStates() {
    return TestDataFactory.createAuthStateFixtures();
  }

  /// Get signed out state
  static Map<String, dynamic> getSignedOutState() {
    return getAllAuthStates()['signed_out']!;
  }

  /// Get signed in state with regular user
  static Map<String, dynamic> getSignedInState({
    User? customUser,
  }) {
    if (customUser != null) {
      return TestDataFactory.createMockAuthState(
        status: 'signed_in',
        user: customUser,
        isDemoMode: false,
      );
    }
    return getAllAuthStates()['signed_in']!;
  }

  /// Get demo mode state
  static Map<String, dynamic> getDemoModeState() {
    return getAllAuthStates()['demo_mode']!;
  }

  /// Get Google signed in state
  static Map<String, dynamic> getGoogleSignedInState() {
    return getAllAuthStates()['google_signed_in']!;
  }

  /// Get email verification pending state
  static Map<String, dynamic> getEmailVerificationPendingState() {
    return getAllAuthStates()['email_verification_pending']!;
  }

  /// Get authentication error state
  static Map<String, dynamic> getAuthErrorState({
    String? customError,
  }) {
    if (customError != null) {
      return TestDataFactory.createMockAuthState(
        status: 'error',
        user: null,
        isDemoMode: false,
        error: customError,
      );
    }
    return getAllAuthStates()['auth_error']!;
  }

  /// Get loading/initializing state
  static Map<String, dynamic> getLoadingState() {
    return TestDataFactory.createMockAuthState(
      status: 'loading',
      user: null,
      isDemoMode: false,
    );
  }

  /// Get session expired state
  static Map<String, dynamic> getSessionExpiredState() {
    return TestDataFactory.createMockAuthState(
      status: 'session_expired',
      user: null,
      isDemoMode: false,
      error: 'Session has expired. Please sign in again.',
    );
  }

  /// Get network error state
  static Map<String, dynamic> getNetworkErrorState() {
    return TestDataFactory.createMockAuthState(
      status: 'error',
      user: null,
      isDemoMode: false,
      error: TestConfig.errorMessages['network_error'],
    );
  }

  /// Create auth state transition sequence for testing flows
  static List<Map<String, dynamic>> createAuthFlowSequence({
    required String flowType,
  }) {
    switch (flowType) {
      case 'email_signup':
        return [
          getSignedOutState(),
          getLoadingState(),
          getEmailVerificationPendingState(),
          getSignedInState(),
        ];
      
      case 'email_signin':
        return [
          getSignedOutState(),
          getLoadingState(),
          getSignedInState(),
        ];
      
      case 'google_signin':
        return [
          getSignedOutState(),
          getLoadingState(),
          getGoogleSignedInState(),
        ];
      
      case 'demo_mode':
        return [
          getSignedOutState(),
          getLoadingState(),
          getDemoModeState(),
        ];
      
      case 'signout':
        return [
          getSignedInState(),
          getLoadingState(),
          getSignedOutState(),
        ];
      
      case 'session_refresh':
        return [
          getSignedInState(),
          getLoadingState(),
          getSignedInState(), // Refreshed session
        ];
      
      case 'auth_error_recovery':
        return [
          getSignedOutState(),
          getLoadingState(),
          getAuthErrorState(),
          getLoadingState(),
          getSignedInState(),
        ];
      
      case 'network_error_recovery':
        return [
          getSignedOutState(),
          getLoadingState(),
          getNetworkErrorState(),
          getLoadingState(),
          getSignedInState(),
        ];
      
      default:
        return [getSignedOutState()];
    }
  }

  /// Create auth state with specific user profile
  static Map<String, dynamic> createAuthStateWithProfile({
    required String profileType,
  }) {
    final profiles = TestDataFactory.createUserProfileFixtures();
    final profile = profiles[profileType];
    
    if (profile == null) {
      throw ArgumentError('Unknown profile type: $profileType');
    }

    final user = User.fromJson(profile);
    return TestDataFactory.createMockAuthState(
      status: 'signed_in',
      user: user,
      isDemoMode: profile['isDemoMode'] ?? false,
    );
  }

  /// Get auth states for permission testing
  static Map<String, Map<String, dynamic>> getPermissionTestStates() {
    return {
      'no_permissions': TestDataFactory.createMockAuthState(
        status: 'signed_in',
        user: TestDataFactory.createMockUser(
          id: 'no-permissions-user',
          email: 'nopermissions@example.com',
        ),
        isDemoMode: false,
      ),
      'camera_permission_denied': TestDataFactory.createMockAuthState(
        status: 'signed_in',
        user: TestDataFactory.createMockUser(
          id: 'camera-denied-user',
          email: 'cameradenied@example.com',
        ),
        isDemoMode: false,
      ),
      'location_permission_denied': TestDataFactory.createMockAuthState(
        status: 'signed_in',
        user: TestDataFactory.createMockUser(
          id: 'location-denied-user',
          email: 'locationdenied@example.com',
        ),
        isDemoMode: false,
      ),
      'all_permissions_granted': TestDataFactory.createMockAuthState(
        status: 'signed_in',
        user: TestDataFactory.createMockUser(
          id: 'all-permissions-user',
          email: 'allpermissions@example.com',
        ),
        isDemoMode: false,
      ),
    };
  }

  /// Get auth states for different user types
  static Map<String, Map<String, dynamic>> getUserTypeStates() {
    return {
      'new_user': createAuthStateWithProfile(profileType: 'new_user'),
      'active_user': createAuthStateWithProfile(profileType: 'active_user'),
      'premium_user': createAuthStateWithProfile(profileType: 'premium_user'),
    };
  }

  /// Create auth state for testing specific scenarios
  static Map<String, dynamic> createScenarioAuthState({
    required String scenario,
    Map<String, dynamic>? customData,
  }) {
    switch (scenario) {
      case 'first_time_user':
        return TestDataFactory.createMockAuthState(
          status: 'signed_in',
          user: TestDataFactory.createMockUser(
            id: 'first-time-user',
            email: 'firsttime@example.com',
            username: 'firsttimeuser',
            totalPoints: 0,
            level: 1,
            createdAt: DateTime.now(),
            achievements: [],
          ),
          isDemoMode: false,
        );
      
      case 'returning_user':
        return TestDataFactory.createMockAuthState(
          status: 'signed_in',
          user: TestDataFactory.createMockUser(
            id: 'returning-user',
            email: 'returning@example.com',
            username: 'returninguser',
            totalPoints: 500,
            level: 3,
            lastActiveAt: DateTime.now().subtract(const Duration(days: 7)),
            achievements: ['first_recycler'],
          ),
          isDemoMode: false,
        );
      
      case 'power_user':
        return TestDataFactory.createMockAuthState(
          status: 'signed_in',
          user: TestDataFactory.createMockUser(
            id: 'power-user',
            email: 'power@example.com',
            username: 'poweruser',
            totalPoints: 10000,
            level: 15,
            achievements: ['first_recycler', 'eco_warrior', 'organic_expert', 'power_user'],
          ),
          isDemoMode: false,
        );
      
      case 'banned_user':
        return TestDataFactory.createMockAuthState(
          status: 'error',
          user: null,
          isDemoMode: false,
          error: 'Account has been suspended',
        );
      
      case 'unverified_email':
        return TestDataFactory.createMockAuthState(
          status: 'email_verification_pending',
          user: TestDataFactory.createMockUser(
            id: 'unverified-user',
            email: 'unverified@example.com',
            username: 'unverifieduser',
          ),
          isDemoMode: false,
        );
      
      default:
        return getSignedOutState();
    }
  }

  /// Get auth state validation helpers
  static Map<String, bool Function(Map<String, dynamic>)> getValidationHelpers() {
    return {
      'isSignedOut': (state) => state['status'] == 'signed_out' && state['user'] == null,
      'isSignedIn': (state) => state['status'] == 'signed_in' && state['user'] != null,
      'isDemoMode': (state) => state['isDemoMode'] == true,
      'isLoading': (state) => state['status'] == 'loading',
      'hasError': (state) => state['status'] == 'error' && state['error'] != null,
      'needsEmailVerification': (state) => state['status'] == 'email_verification_pending',
      'isGoogleUser': (state) {
        final user = state['user'];
        if (user == null) return false;
        return user['email']?.toString().contains('gmail.com') == true ||
               user['provider'] == 'google';
      },
      'isNewUser': (state) {
        final user = state['user'];
        if (user == null) return false;
        return user['totalPoints'] == 0 && (user['achievements'] as List?)?.isEmpty == true;
      },
      'isPremiumUser': (state) {
        final user = state['user'];
        if (user == null) return false;
        return user['isPremium'] == true;
      },
    };
  }

  /// Create auth state stream for testing real-time updates
  static Stream<Map<String, dynamic>> createAuthStateStream({
    Duration interval = const Duration(seconds: 1),
    List<Map<String, dynamic>>? stateSequence,
  }) async* {
    final sequence = stateSequence ?? [
      getSignedOutState(),
      getLoadingState(),
      getSignedInState(),
    ];

    for (final state in sequence) {
      yield state;
      await Future.delayed(interval);
    }
  }

  /// Get auth state for testing error conditions
  static Map<String, Map<String, dynamic>> getErrorStates() {
    return {
      'invalid_credentials': getAuthErrorState(customError: 'Invalid email or password'),
      'email_not_confirmed': getAuthErrorState(customError: 'Email address not confirmed'),
      'account_locked': getAuthErrorState(customError: 'Account temporarily locked'),
      'weak_password': getAuthErrorState(customError: 'Password is too weak'),
      'email_already_exists': getAuthErrorState(customError: 'Email address already registered'),
      'network_timeout': getNetworkErrorState(),
      'server_error': getAuthErrorState(customError: 'Server temporarily unavailable'),
      'rate_limited': getAuthErrorState(customError: 'Too many login attempts'),
    };
  }
}