import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User, AuthState;

import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/models/user.dart';

void main() {
  group('AuthService', () {

    group('AuthState', () {
      test('should have correct convenience getters', () {
        // Test loading state
        const loadingState = AuthState(status: AuthStatus.loading);
        expect(loadingState.isLoading, isTrue);
        expect(loadingState.isAuthenticated, isFalse);
        expect(loadingState.hasError, isFalse);

        // Test authenticated state
        final user = User.defaultUser();
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
        final user = User.defaultUser();
        
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
        final user = User.defaultUser();
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
        // Create a mock Supabase client for testing
        final mockClient = _MockSupabaseClient();
        final authService = AuthService(mockClient);

        await authService.initializeWithDemoUser();

        expect(authService.currentState.status, AuthStatus.authenticated);
        expect(authService.currentState.isDemoMode, isTrue);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.username, 'EcoWarrior');
        expect(authService.isAuthenticated, isTrue);

        authService.dispose();
      });
    });
  });
}

// Simple mock for testing
class _MockSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}