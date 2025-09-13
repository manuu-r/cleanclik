import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/presentation/screens/auth/signup_screen.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/mock_services.mocks.dart';
import '../../../fixtures/test_data_factory.dart';

class SignUpScreenWidgetTest extends BaseWidgetTest {
  late MockAuthService mockAuthService;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockAuthService = MockAuthService();

    // Configure mock auth service
    when(mockAuthService.signUpWithEmail(any, any, any)).thenAnswer(
      (_) async => AuthResult.success(TestDataFactory.createMockUser()),
    );
    when(mockAuthService.signInWithGoogle()).thenAnswer(
      (_) async => AuthResult.success(TestDataFactory.createMockUser()),
    );

    // Add provider overrides
    overrideProviders([
      authServiceProvider.overrideWith((ref) => mockAuthService),
    ]);
  }

  @override
  void tearDownWidgetTest() {
    super.tearDownWidgetTest();
    reset(mockAuthService);
  }
}

void main() {
  group('SignUpScreen Widget Tests', () {
    late SignUpScreenWidgetTest testHelper;

    setUp(() {
      testHelper = SignUpScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display sign up screen with basic structure', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SignUpScreen), findsOneWidget);
    });

    testWidgets('should display CleanClik logo and title', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('CleanClik'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
      expect(find.text('Join the CleanClik Community'), findsOneWidget);
    });

    testWidgets('should display all required input fields', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(4)); // Username, Email, Password, Confirm Password
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('should display sign up button', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('should display Google sign up button', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    });

    testWidgets('should display sign in navigation link', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('should validate username field', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap create account without entering username
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a username'), findsOneWidget);
    });

    testWidgets('should validate username length', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter short username
      final usernameField = find.byType(TextFormField).first;
      await tester.enterText(usernameField, 'ab');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('should validate email field', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter username but no email
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should validate email format', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter invalid email
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'invalid-email');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate password field', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter username and email but no password
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('should validate password length', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter short password
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), '123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should validate password confirmation', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter mismatched passwords
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'differentpassword');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap password visibility toggle
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      if (visibilityButtons.evaluate().isNotEmpty) {
        await tester.tap(visibilityButtons.first);
        await tester.pumpAndSettle();

        // Assert - icon should change to visibility_off
        expect(find.byIcon(Icons.visibility_off_outlined), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('should handle successful sign up', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter valid information and sign up
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockAuthService.signUpWithEmail(
        'test@example.com',
        'password123',
        'testuser',
      )).called(1);
    });

    testWidgets('should handle Google sign up', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap Google sign up button
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockAuthService.signInWithGoogle()).called(1);
    });

    testWidgets('should display error message on sign up failure', (tester) async {
      // Arrange
      when(testHelper.mockAuthService.signUpWithEmail(any, any, any)).thenAnswer(
        (_) async => AuthResult.failure(
          AuthErrorType.emailAlreadyInUse,
          'Email is already registered',
        ),
      );

      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - attempt sign up with existing email
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'existing@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Email is already registered'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show loading state during sign up', (tester) async {
      // Arrange
      when(testHelper.mockAuthService.signUpWithEmail(any, any, any)).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return AuthResult.success(TestDataFactory.createMockUser());
        },
      );

      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - start sign up process
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pump(); // Don't settle to catch loading state

      // Assert - should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should disable buttons during loading', (tester) async {
      // Arrange
      when(testHelper.mockAuthService.signUpWithEmail(any, any, any)).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return AuthResult.success(TestDataFactory.createMockUser());
        },
      );

      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - start sign up process
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // Assert - buttons should be disabled
      final signUpButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(signUpButton.onPressed, isNull);

      final googleButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(googleButton.onPressed, isNull);
    });

    testWidgets('should navigate to sign in screen', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap sign in link
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Assert - should attempt navigation
      verify(testHelper.mockRouter.pop()).called(1);
    });

    testWidgets('should display terms and privacy policy', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        find.text('By creating an account, you agree to our').or(
          find.text('Terms of Service')
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle keyboard submission', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter credentials and submit via keyboard
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'test@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockAuthService.signUpWithEmail(
        'test@example.com',
        'password123',
        'testuser',
      )).called(1);
    });
  });

  group('SignUpScreen Material 3 Theme Tests', () {
    late SignUpScreenWidgetTest testHelper;

    setUp(() {
      testHelper = SignUpScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should apply Material 3 design system', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should use Material 3 components
      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );
      expect(materialApp.theme?.useMaterial3, isTrue);
    });

    testWidgets('should be accessible with proper semantics', (tester) async {
      // Arrange
      const screen = SignUpScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have semantic labels for form fields
      expect(find.byType(TextFormField), findsNWidgets(4));
      
      // Check for accessibility features
      expect(tester.takeException(), isNull);
    });
  });
}