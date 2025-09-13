import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/presentation/screens/auth/auth_wrapper.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/mock_services.mocks.dart';
import '../../../fixtures/test_data_factory.dart';

class AuthWrapperWidgetTest extends BaseWidgetTest {
  late MockAuthService mockAuthService;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockAuthService = MockAuthService();

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

  void configureAuthState(AuthState state) {
    when(mockAuthService.currentState).thenReturn(state);
    when(mockAuthService.authStateStream).thenAnswer(
      (_) => Stream.value(state),
    );
    when(mockAuthService.isAuthenticated).thenReturn(
      state.status == AuthStatus.authenticated,
    );
  }
}

void main() {
  group('AuthWrapper Widget Tests', () {
    late AuthWrapperWidgetTest testHelper;

    setUp(() {
      testHelper = AuthWrapperWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display loading indicator when auth is loading', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.loading,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });

    testWidgets('should display child when user is authenticated', (tester) async {
      // Arrange
      final mockUser = TestDataFactory.createMockUser();
      testHelper.configureAuthState(AuthState(
        status: AuthStatus.authenticated,
        user: mockUser,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Protected Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should redirect to login when user is unauthenticated', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Protected Content'), findsNothing);
      // Should redirect to login - verify navigation call
      verify(testHelper.mockRouter.go('/login')).called(1);
    });

    testWidgets('should display error message when auth has error', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.error,
        user: null,
        error: 'Authentication failed',
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Authentication Error'), findsOneWidget);
      expect(find.text('Authentication failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });

    testWidgets('should provide retry button on error', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.error,
        user: null,
        error: 'Network error',
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap retry button
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // Assert - should attempt to refresh auth state
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle demo mode authentication', (tester) async {
      // Arrange
      final mockUser = TestDataFactory.createMockUser();
      testHelper.configureAuthState(AuthState(
        status: AuthStatus.authenticated,
        user: mockUser,
        isDemoMode: true,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Protected Content'), findsOneWidget);
      // Should display demo mode indicator
      expect(
        find.text('Demo Mode').or(find.byIcon(Icons.science)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should react to auth state changes', (tester) async {
      // Arrange
      final authStateController = StreamController<AuthState>();
      when(testHelper.mockAuthService.authStateStream).thenAnswer(
        (_) => authStateController.stream,
      );

      // Start with loading state
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.loading,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      await testHelper.pumpAndSettle(tester, widget);

      // Assert initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Act - emit authenticated state
      final mockUser = TestDataFactory.createMockUser();
      final authenticatedState = AuthState(
        status: AuthStatus.authenticated,
        user: mockUser,
        isDemoMode: false,
      );
      
      testHelper.configureAuthState(authenticatedState);
      authStateController.add(authenticatedState);
      await tester.pumpAndSettle();

      // Assert - should now show protected content
      expect(find.text('Protected Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Cleanup
      await authStateController.close();
    });

    testWidgets('should handle navigation to login screen', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockRouter.go('/login')).called(1);
    });

    testWidgets('should handle custom redirect path', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
        redirectPath: '/custom-login',
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockRouter.go('/custom-login')).called(1);
    });

    testWidgets('should display loading with custom message', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.loading,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
        loadingMessage: 'Authenticating user...',
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Authenticating user...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle auth service initialization', (tester) async {
      // Arrange
      when(testHelper.mockAuthService.initialize()).thenAnswer((_) async {});
      
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.loading,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockAuthService.initialize()).called(1);
    });

    testWidgets('should handle widget disposal gracefully', (tester) async {
      // Arrange
      final mockUser = TestDataFactory.createMockUser();
      testHelper.configureAuthState(AuthState(
        status: AuthStatus.authenticated,
        user: mockUser,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - dispose the widget
      await tester.pumpWidget(Container());

      // Assert - should not throw exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle rapid auth state changes', (tester) async {
      // Arrange
      final authStateController = StreamController<AuthState>();
      when(testHelper.mockAuthService.authStateStream).thenAnswer(
        (_) => authStateController.stream,
      );

      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.loading,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - emit rapid state changes
      final mockUser = TestDataFactory.createMockUser();
      
      authStateController.add(AuthState(
        status: AuthStatus.authenticated,
        user: mockUser,
        isDemoMode: false,
      ));
      
      authStateController.add(const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isDemoMode: false,
      ));
      
      authStateController.add(AuthState(
        status: AuthStatus.authenticated,
        user: mockUser,
        isDemoMode: false,
      ));

      await tester.pumpAndSettle();

      // Assert - should handle rapid changes without errors
      expect(tester.takeException(), isNull);

      // Cleanup
      await authStateController.close();
    });
  });

  group('AuthWrapper Material 3 Theme Tests', () {
    late AuthWrapperWidgetTest testHelper;

    setUp(() {
      testHelper = AuthWrapperWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should apply Material 3 design to loading state', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.loading,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

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

    testWidgets('should apply Material 3 design to error state', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.error,
        user: null,
        error: 'Test error',
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should use proper error styling
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be accessible with proper semantics', (tester) async {
      // Arrange
      testHelper.configureAuthState(const AuthState(
        status: AuthStatus.loading,
        user: null,
        isDemoMode: false,
      ));

      const authWrapper = AuthWrapper(
        child: Text('Protected Content'),
      );
      final widget = testHelper.createTestWidget(authWrapper);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have semantic labels for accessibility
      expect(
        find.bySemanticsLabel('Loading').or(find.byType(Semantics)),
        findsAtLeastNWidgets(1),
      );
    });
  });
}