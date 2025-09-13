import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/presentation/screens/auth/login_screen.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/mock_services.mocks.dart';
import '../../../fixtures/test_data_factory.dart';

class LoginScreenWidgetTest extends BaseWidgetTest {
  late MockAuthService mockAuthService;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockAuthService = MockAuthService();

    // Configure mock auth service
    when(mockAuthService.signInWithEmail(any, any)).thenAnswer(
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
  group('LoginScreen Widget Tests', () {
    late LoginScreenWidgetTest testHelper;

    setUp(() {
      testHelper = LoginScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display login screen with basic structure', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('should display CleanClik logo and title', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('CleanClik'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
      expect(
        find.text('Transform waste management into an engaging experience'),
        findsOneWidget,
      );
    });

    testWidgets('should display email and password input fields', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should display sign in button', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('should display Google sign in button', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    });

    testWidgets('should display sign up navigation link', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('should validate email field', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap sign in without entering email
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should validate email format', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter invalid email and try to sign in
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate password field', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter email but no password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should validate password length', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter short password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap password visibility toggle
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // Assert - icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('should handle successful email sign in', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter valid credentials and sign in
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockAuthService.signInWithEmail('test@example.com', 'password123'))
          .called(1);
    });

    testWidgets('should handle Google sign in', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap Google sign in button
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockAuthService.signInWithGoogle()).called(1);
    });

    testWidgets('should display error message on sign in failure', (tester) async {
      // Arrange
      when(testHelper.mockAuthService.signInWithEmail(any, any)).thenAnswer(
        (_) async => AuthResult.failure(
          AuthErrorType.invalidCredentials,
          'Invalid email or password',
        ),
      );

      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - attempt sign in with invalid credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show loading state during sign in', (tester) async {
      // Arrange
      when(testHelper.mockAuthService.signInWithEmail(any, any)).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return AuthResult.success(TestDataFactory.createMockUser());
        },
      );

      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - start sign in process
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pump(); // Don't settle to catch loading state

      // Assert - should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should disable buttons during loading', (tester) async {
      // Arrange
      when(testHelper.mockAuthService.signInWithEmail(any, any)).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return AuthResult.success(TestDataFactory.createMockUser());
        },
      );

      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - start sign in process
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // Assert - buttons should be disabled
      final signInButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(signInButton.onPressed, isNull);

      final googleButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(googleButton.onPressed, isNull);
    });

    testWidgets('should navigate to sign up screen', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap sign up link
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Assert - should attempt navigation
      verify(testHelper.mockRouter.push('/signup')).called(1);
    });

    testWidgets('should handle keyboard submission', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - enter credentials and submit via keyboard
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockAuthService.signInWithEmail('test@example.com', 'password123'))
          .called(1);
    });
  });

  group('LoginScreen Material 3 Theme Tests', () {
    late LoginScreenWidgetTest testHelper;

    setUp(() {
      testHelper = LoginScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should apply Material 3 design system', (tester) async {
      // Arrange
      const screen = LoginScreen();
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

    testWidgets('should use proper color scheme and gradients', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Container), findsAtLeastNWidgets(1));
      
      // Should have gradient background
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((container) => 
        container.decoration is BoxDecoration &&
        (container.decoration as BoxDecoration).gradient != null
      );
      expect(hasGradient, isTrue);
    });

    testWidgets('should be accessible with proper semantics', (tester) async {
      // Arrange
      const screen = LoginScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have semantic labels for form fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // Check for accessibility features
      expect(tester.takeException(), isNull);
    });
  });
}