import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mock_services.dart';
import 'mock_services.mocks.dart';
import 'supabase_test_client.dart';

// This is a helper class, not a test file
void main() {
  // No tests in this file - it's a helper class
}

/// Base class for integration tests with full app setup
abstract class BaseIntegrationTest {
  late IntegrationTestWidgetsFlutterBinding binding;
  late MockSupabaseClient mockSupabaseClient;
  late ProviderContainer container;
  late List<Override> providerOverrides;
  late WidgetTester? _tester;

  /// Set up integration test environment
  Future<void> setUpIntegrationTest() async {
    binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    mockSupabaseClient = MockSupabaseClient();
    providerOverrides = [];
    
    await initializeSupabaseMocks();
  }

  /// Clean up integration test resources
  Future<void> tearDownIntegrationTest() async {
    container.dispose();
    reset(mockSupabaseClient);
  }

  /// Initialize Supabase mocks for integration testing
  Future<void> initializeSupabaseMocks() async {
    // Configure mock Supabase client
    final mockAuth = MockGoTrueClient();
    when(mockSupabaseClient.auth).thenReturn(mockAuth);
    
    // Configure default auth state
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.currentSession).thenReturn(null);
    
    // Configure auth stream
    when(mockAuth.onAuthStateChange).thenAnswer(
      (_) => Stream<AuthState>.fromIterable([
        const AuthState(AuthChangeEvent.signedOut, null),
      ]),
    );
  }

  /// Create app widget with test configuration
  Widget createTestApp(Widget app) {
    container = ProviderContainer(overrides: providerOverrides);
    
    return UncontrolledProviderScope(
      container: container,
      child: app,
    );
  }

  /// Override providers for integration testing
  void overrideProviders(List<Override> overrides) {
    providerOverrides.addAll(overrides);
  }

  /// Simulate user authentication for testing
  Future<void> simulateUserAuthentication(WidgetTester tester) async {
    _tester = tester;
    final mockAuth = mockSupabaseClient.auth as MockGoTrueClient;
    
    // Create mock user and session
    when(mockAuth.currentUser).thenReturn(User(
      id: 'test-user-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    ));
    
    when(mockAuth.currentSession).thenReturn(Session(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      expiresIn: 3600,
      tokenType: 'bearer',
      user: User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ));
    
    // Trigger auth state change
    when(mockAuth.onAuthStateChange).thenAnswer(
      (_) => Stream<AuthState>.fromIterable([
        AuthState(AuthChangeEvent.signedIn, mockAuth.currentSession),
      ]),
    );
    
    await tester.pumpAndSettle();
  }

  /// Simulate user sign out for testing
  Future<void> simulateUserSignOut(WidgetTester tester) async {
    _tester = tester;
    final mockAuth = mockSupabaseClient.auth as MockGoTrueClient;
    
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.currentSession).thenReturn(null);
    
    // Trigger auth state change
    when(mockAuth.onAuthStateChange).thenAnswer(
      (_) => Stream<AuthState>.fromIterable([
        const AuthState(AuthChangeEvent.signedOut, null),
      ]),
    );
    
    await tester.pumpAndSettle();
  }

  /// Wait for async operations to complete
  Future<void> waitForAsyncOperations(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Simulate network delay for realistic testing
  Future<void> simulateNetworkDelay([Duration? delay]) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 500));
  }

  /// Verify that no errors occurred during test
  void verifyNoErrors() {
    if (_tester != null) {
      expect(_tester!.takeException(), isNull);
    }
  }
}