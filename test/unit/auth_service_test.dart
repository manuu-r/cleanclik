import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User, AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User, AuthState;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/models/user.dart';
import '../helpers/base_service_test.dart';
import '../helpers/mock_services.mocks.dart';
import '../fixtures/test_data_factory.dart';

void main() {
  group('AuthService', () {
    late MockSupabaseClient mockSupabaseClient;
    late AuthService authService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      authService = AuthService(mockSupabaseClient);
    });

    tearDown(() {
      authService.dispose();
    });

    group('AuthState', () {
      test('should have correct convenience getters', () {
        // Test loading state
        const loadingState = AuthState(status: AuthStatus.loading);
        expect(loadingState.isLoading, isTrue);
        expect(loadingState.isAuthenticated, isFalse);
        expect(loadingState.hasError, isFalse);

        // Test authenticated state
        final user = TestDataFactory.createMockUser();
        final authenticatedState = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
        expect(authenticatedState.isLoading, isFalse);
        expect(authenticatedState.isAuthenticated, isTrue);
        expect(authenticatedState.hasError, isFalse);

        // Test unauthenticated state
        const unauthenticatedState = AuthState(status: AuthStatus.unauthenticated);
        expect(unauthenticatedState.isLoading, isFalse);
        expect(unauthenticatedState.isAuthenticated, isFalse);
        expect(unauthenticatedState.hasError, isFalse);

        // Test error state
        const errorState = AuthState(
          status: AuthStatus.error,
          error: 'Test error',
        );
        expect(errorState.isLoading, isFalse);
        expect(errorState.isAuthenticated, isFalse);
        expect(errorState.hasError, isTrue);
      });

      test('should copy with new values', () {
        const originalState = AuthState(status: AuthStatus.loading);
        final user = TestDataFactory.createMockUser();
        
        final newState = originalState.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );

        expect(newState.status, AuthStatus.authenticated);
        expect(newState.user, user);
        expect(newState.error, isNull);
        expect(newState.isDemoMode, isFalse);
      });
    });

    group('AuthResult', () {
      test('should create success result', () {
        final user = TestDataFactory.createMockUser();
        final result = AuthResult.success(user);

        expect(result.success, isTrue);
        expect(result.user, user);
        expect(result.error, isNull);
      });

      test('should create failure result', () {
        const errorMessage = 'Test error';
        final result = AuthResult.failure(
          AuthErrorType.invalidCredentials,
          errorMessage,
        );

        expect(result.success, isFalse);
        expect(result.user, isNull);
        expect(result.error?.type, AuthErrorType.invalidCredentials);
        expect(result.error?.message, errorMessage);
      });
    });

    group('Demo Mode', () {
      test('should initialize with demo user', () async {
        await authService.initializeWithDemoUser();

        expect(authService.currentState.status, AuthStatus.authenticated);
        expect(authService.currentState.isDemoMode, isTrue);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.username, 'EcoWarrior');
        expect(authService.isAuthenticated, isTrue);
      });

      test('should sign out from demo mode', () async {
        await authService.initializeWithDemoUser();
        expect(authService.currentState.isDemoMode, isTrue);

        await authService.signOut();
        expect(authService.currentState.status, AuthStatus.unauthenticated);
        expect(authService.currentState.isDemoMode, isFalse);
        expect(authService.currentUser, isNull);
      });
    });

    group('Supabase Authentication', () {
      test('should initialize service', () async {
        await authService.initialize();
        
        // Service should be initialized without errors
        expect(authService.currentState, isNotNull);
      });

      test('should handle sign in with email', () async {
        // Mock Supabase auth response
        when(mockSupabaseClient.auth).thenReturn(MockGoTrueClient());
        
        final result = await authService.signInWithEmail(
          'test@example.com',
          'password123',
        );

        // Should return a result (success or failure)
        expect(result, isA<AuthResult>());
      });

      test('should handle sign out', () async {
        when(mockSupabaseClient.auth).thenReturn(MockGoTrueClient());
        
        await authService.signOut();
        
        // Should complete without throwing
        expect(authService.currentState.status, isNot(AuthStatus.authenticated));
      });
    });

    group('Stream Management', () {
      test('should provide auth state stream', () async {
        final stateChanges = <AuthState>[];
        final subscription = authService.authStateStream.listen(stateChanges.add);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateChanges, isNotEmpty);
        expect(stateChanges.first, isA<AuthState>());
        
        await subscription.cancel();
      });
    });

    group('Basic Properties', () {
      test('should provide current state', () {
        final state = authService.currentState;
        expect(state, isA<AuthState>());
      });

      test('should provide current user', () {
        final user = authService.currentUser;
        expect(user, isNull); // Initially null
      });

      test('should check authentication status', () {
        final isAuthenticated = authService.isAuthenticated;
        expect(isAuthenticated, isFalse); // Initially false
      });
    });
  });
}