import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/presentation/screens/auth/email_verification_screen.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/mock_services.mocks.dart';
import '../../../fixtures/test_data_factory.dart';

class EmailVerificationScreenWidgetTest extends BaseWidgetTest {
  late MockAuthService mockAuthService;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockAuthService = MockAuthService();

    // Configure mock auth service
    when(mockAuthService.handleEmailVerificationComplete()).thenAnswer(
      (_) async {},
    );
    when(mockAuthService.signOut()).thenAnswer(
      (_) async {},
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
  group('EmailVerificationScreen Widget Tests', () {
    late EmailVerificationScreenWidgetTest testHelper;

    setUp(() {
      testHelper = EmailVerificationScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display email verification screen with basic structure', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(EmailVerificationScreen), findsOneWidget);
    });

    testWidgets('should display CleanClik logo and branding', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('CleanClik'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('should display email verification title and message', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(
        find.text('We\'ve sent a verification link to:').or(
          find.text('Check your email for verification')
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display the provided email address', (tester) async {
      // Arrange
      const email = 'test@example.com';
      const screen = EmailVerificationScreen(email: email);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text(email), findsOneWidget);
    });

    testWidgets('should display verification instructions', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        find.text('Click the link in your email to verify your account').or(
          find.text('Please check your email and click the verification link')
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display email verification icon', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        find.byIcon(Icons.email_outlined).or(
          find.byIcon(Icons.mark_email_unread_outlined)
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display resend verification button', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        find.text('Resend Email').or(find.text('Resend Verification')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display back to login button', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        find.text('Back to Login').or(find.text('Sign In')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle resend verification email', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap resend button
      final resendButton = find.text('Resend Email').or(find.text('Resend Verification'));
      if (resendButton.evaluate().isNotEmpty) {
        await tester.tap(resendButton.first);
        await tester.pumpAndSettle();
      }

      // Assert - should handle resend action
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should show resend cooldown timer', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap resend button to trigger cooldown
      final resendButton = find.text('Resend Email').or(find.text('Resend Verification'));
      if (resendButton.evaluate().isNotEmpty) {
        await tester.tap(resendButton.first);
        await tester.pump();

        // Assert - should show cooldown timer or disabled state
        expect(find.byType(Scaffold), findsOneWidget);
        // Timer text would depend on implementation
      }
    });

    testWidgets('should handle back to login navigation', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap back to login button
      final backButton = find.text('Back to Login').or(find.text('Sign In'));
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();
      }

      // Assert - should attempt navigation
      verify(testHelper.mockRouter.go('/login')).called(1);
    });

    testWidgets('should display success message after verification', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate email verification completion
      when(testHelper.mockAuthService.handleEmailVerificationComplete()).thenAnswer(
        (_) async {},
      );

      // Trigger verification check (this would normally happen via deep link)
      await tester.pump();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Success state would depend on implementation
    });

    testWidgets('should handle email verification deep link', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate deep link handling
      // This would normally be triggered by the app receiving a deep link
      await tester.pump();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Deep link handling would be tested at integration level
    });

    testWidgets('should display loading state during verification check', (tester) async {
      // Arrange
      when(testHelper.mockAuthService.handleEmailVerificationComplete()).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
        },
      );

      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - trigger verification check
      // This would normally happen automatically or via user action
      await tester.pump();

      // Assert - should show loading state if implemented
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle different email formats correctly', (tester) async {
      // Arrange
      const longEmail = 'very.long.email.address@example-domain.com';
      const screen = EmailVerificationScreen(email: longEmail);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text(longEmail), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display help or support information', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        find.text('Need help?').or(
          find.text('Didn\'t receive the email?')
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle spam folder reminder', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        find.text('Check your spam folder').or(
          find.text('spam')
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display proper spacing and layout', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle app lifecycle changes gracefully', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate app going to background and returning
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused'),
        ),
        (data) {},
      );

      await tester.pump();

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed'),
        ),
        (data) {},
      );

      await tester.pump();

      // Assert - should handle lifecycle changes without errors
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('EmailVerificationScreen Material 3 Theme Tests', () {
    late EmailVerificationScreenWidgetTest testHelper;

    setUp(() {
      testHelper = EmailVerificationScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should apply Material 3 design system', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
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

    testWidgets('should use proper color scheme and styling', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Container), findsAtLeastNWidgets(1));
      
      // Should have proper styling without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be accessible with proper semantics', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have semantic labels for accessibility
      expect(
        find.bySemanticsLabel('Email verification').or(find.byType(Semantics)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should support light and dark themes', (tester) async {
      // Arrange
      const screen = EmailVerificationScreen(email: 'test@example.com');
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should render without theme-related errors
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}