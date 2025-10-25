import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import '../helpers/base_integration_test.dart';
import '../helpers/mock_services.dart';
import '../fixtures/test_data_factory.dart';
import '../../lib/core/models/auth_state.dart';
import '../../lib/core/models/user.dart';
import '../../lib/core/providers/auth_provider.dart';
import '../../lib/presentation/screens/auth/login_screen.dart';
import '../../lib/presentation/screens/auth/signup_screen.dart';
import '../../lib/presentation/screens/auth/email_verification_screen.dart';
import '../../lib/presentation/screens/camera/ar_camera_screen.dart';
import '../../lib/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockSupabaseClient mockSupabaseClient;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthService();
      mockSupabaseClient = MockSupabaseClient();

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          supabaseClientProvider.overrideWithValue(mockSupabaseClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete Supabase authentication flow with email/password', (
      tester,
    ) async {
      // Arrange
      final testUser = TestDataFactory.createMockUser(
        email: 'test@example.com',
        username: 'testuser',
      );

      when(
        mockAuthService.signInWithEmail(any, any),
      ).thenAnswer((_) async => AuthResult.success(testUser));
      when(mockAuthService.getCurrentUser()).thenReturn(testUser);
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(AuthState.authenticated(testUser)));

      // Act & Assert - Start at login screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Enter email and password
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.pumpAndSettle();

      // Tap sign in button
      await tester.tap(find.byKey(const Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Verify authentication service was called
      verify(
        mockAuthService.signInWithEmail('test@example.com', 'password123'),
      ).called(1);

      // Verify navigation to main app (AR Camera Screen)
      expect(find.byType(ARCameraScreen), findsOneWidget);
    });

    testWidgets('Google Sign-In authentication flow', (tester) async {
      // Arrange
      final testUser = TestDataFactory.createMockUser(
        email: 'google@example.com',
        username: 'googleuser',
      );

      when(
        mockAuthService.signInWithGoogle(),
      ).thenAnswer((_) async => AuthResult.success(testUser));
      when(mockAuthService.getCurrentUser()).thenReturn(testUser);
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(AuthState.authenticated(testUser)));

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Google Sign-In button
      await tester.tap(find.byKey(const Key('google_sign_in_button')));
      await tester.pumpAndSettle();

      // Verify Google Sign-In was called
      verify(mockAuthService.signInWithGoogle()).called(1);

      // Verify navigation to main app
      expect(find.byType(ARCameraScreen), findsOneWidget);
    });

    testWidgets('Email verification flow', (tester) async {
      // Arrange
      final unverifiedUser = TestDataFactory.createMockUser(
        email: 'unverified@example.com',
        isEmailVerified: false,
      );
      final verifiedUser = TestDataFactory.createMockUser(
        email: 'unverified@example.com',
        isEmailVerified: true,
      );

      when(
        mockAuthService.signUpWithEmail(any, any),
      ).thenAnswer((_) async => AuthResult.success(unverifiedUser));
      when(
        mockAuthService.resendEmailVerification(),
      ).thenAnswer((_) async => true);
      when(mockAuthService.getCurrentUser()).thenReturn(unverifiedUser);

      // Act & Assert - Start with signup
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SignUpScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Fill signup form
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'unverified@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('username_field')),
        'unverifieduser',
      );
      await tester.pumpAndSettle();

      // Tap sign up button
      await tester.tap(find.byKey(const Key('sign_up_button')));
      await tester.pumpAndSettle();

      // Verify navigation to email verification screen
      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(find.text('Verify Your Email'), findsOneWidget);

      // Test resend verification
      await tester.tap(find.byKey(const Key('resend_verification_button')));
      await tester.pumpAndSettle();

      verify(mockAuthService.resendEmailVerification()).called(1);

      // Simulate email verification completion
      when(mockAuthService.getCurrentUser()).thenReturn(verifiedUser);
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(AuthState.authenticated(verifiedUser)));

      // Trigger refresh
      await tester.tap(find.byKey(const Key('check_verification_button')));
      await tester.pumpAndSettle();

      // Verify navigation to main app after verification
      expect(find.byType(ARCameraScreen), findsOneWidget);
    });

    testWidgets('Sign up with email verification flow', (tester) async {
      // Arrange
      final newUser = TestDataFactory.createMockUser(
        email: 'newuser@example.com',
        username: 'newuser',
      );

      when(
        mockAuthService.signUpWithEmail(any, any, any),
      ).thenAnswer((_) async => AuthResult.success(newUser));
      when(mockAuthService.getCurrentUser()).thenReturn(newUser);
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(AuthState.authenticated(newUser)));

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SignUpScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Fill sign up form
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'newuser@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('username_field')),
        'newuser',
      );
      await tester.pumpAndSettle();

      // Tap sign up button
      await tester.tap(find.byKey(const Key('sign_up_button')));
      await tester.pumpAndSettle();

      // Verify sign up was called with correct parameters
      verify(
        mockAuthService.signUpWithEmail(
          'newuser@example.com',
          'password123',
          'newuser',
        ),
      ).called(1);

      // Verify navigation to main app
      expect(find.byType(ARCameraScreen), findsOneWidget);
    });

    testWidgets('Authentication error handling', (tester) async {
      // Arrange
      when(
        mockAuthService.signInWithEmail(any, any),
      ).thenAnswer((_) async => AuthResult.failure('Invalid credentials'));

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalid@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'wrongpassword',
      );
      await tester.pumpAndSettle();

      // Tap sign in button
      await tester.tap(find.byKey(const Key('sign_in_button')));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Invalid credentials'), findsOneWidget);

      // Verify still on login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Sign out flow', (tester) async {
      // Arrange
      final testUser = TestDataFactory.createMockUser();

      when(mockAuthService.getCurrentUser()).thenReturn(testUser);
      when(mockAuthService.signOut()).thenAnswer((_) async {});
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(AuthState.unauthenticated()));

      // Start authenticated
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ARCameraScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to profile and sign out
      await tester.tap(find.byKey(const Key('profile_tab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sign_out_button')));
      await tester.pumpAndSettle();

      // Verify sign out was called
      verify(mockAuthService.signOut()).called(1);

      // Verify navigation back to login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
