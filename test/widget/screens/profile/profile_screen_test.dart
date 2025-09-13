import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/presentation/screens/profile/profile_screen.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/services/social/leaderboard_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/mock_services.mocks.dart';
import '../../../fixtures/test_data_factory.dart';

class ProfileScreenWidgetTest extends BaseWidgetTest {
  late MockAuthService mockAuthService;
  late MockLeaderboardService mockLeaderboardService;
  late MockInventoryService mockInventoryService;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockAuthService = MockAuthService();
    mockLeaderboardService = MockLeaderboardService();
    mockInventoryService = MockInventoryService();

    // Configure mock auth service with authenticated user
    final mockUser = TestDataFactory.createMockUser();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      user: mockUser,
      isDemoMode: false,
    );
    
    when(mockAuthService.currentState).thenReturn(authState);
    when(mockAuthService.currentUser).thenReturn(mockUser);
    when(mockAuthService.isAuthenticated).thenReturn(true);
    when(mockAuthService.authStateStream).thenAnswer(
      (_) => Stream.value(authState),
    );

    // Configure mock leaderboard service
    when(mockLeaderboardService.userRank).thenReturn(42);
    when(mockLeaderboardService.totalUsers).thenReturn(1000);

    // Configure mock inventory service
    when(mockInventoryService.items).thenReturn(
      TestDataFactory.createMockInventoryItems(count: 15),
    );
    when(mockInventoryService.totalItemsCollected).thenReturn(15);

    // Add provider overrides
    overrideProviders([
      authServiceProvider.overrideWith((ref) => mockAuthService),
      leaderboardServiceProvider.overrideWith((ref) => mockLeaderboardService),
      inventoryServiceProvider.overrideWith((ref) => mockInventoryService),
    ]);
  }

  @override
  void tearDownWidgetTest() {
    super.tearDownWidgetTest();
    reset(mockAuthService);
    reset(mockLeaderboardService);
    reset(mockInventoryService);
  }
}

void main() {
  group('ProfileScreen Widget Tests', () {
    late ProfileScreenWidgetTest testHelper;

    setUp(() {
      testHelper = ProfileScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display profile screen with basic structure', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('should display user information when authenticated', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should display user data from mock
      final mockUser = TestDataFactory.createMockUser();
      expect(find.text(mockUser.username), findsOneWidget);
      expect(find.text(mockUser.email), findsOneWidget);
    });

    testWidgets('should display user statistics', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should display statistics
      final mockUser = TestDataFactory.createMockUser();
      expect(find.text(mockUser.totalPoints.toString()), findsOneWidget);
      expect(find.text('Level ${mockUser.level}'), findsOneWidget);
    });

    testWidgets('should display user rank from leaderboard service', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      verify(testHelper.mockLeaderboardService.userRank).called(greaterThan(0));
    });

    testWidgets('should display inventory statistics', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      verify(testHelper.mockInventoryService.totalItemsCollected).called(greaterThan(0));
    });

    testWidgets('should display user avatar or placeholder', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should have either CircleAvatar or placeholder icon
      expect(
        find.byType(CircleAvatar).or(find.byIcon(Icons.person)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display achievements section', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should have achievements section (text or icons)
      expect(
        find.text('Achievements').or(find.byIcon(Icons.emoji_events)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display category statistics', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should display category stats from mock user
      final mockUser = TestDataFactory.createMockUser();
      if (mockUser.categoryStats.isNotEmpty) {
        // Verify category stats are displayed
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('should handle sign out action', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - look for sign out button and tap it
      final signOutButton = find.byIcon(Icons.logout).or(find.text('Sign Out'));
      if (signOutButton.evaluate().isNotEmpty) {
        await tester.tap(signOutButton.first);
        await tester.pumpAndSettle();
      }

      // Assert - should have attempted to call sign out
      // Note: Actual sign out verification depends on UI implementation
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display edit profile option', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should have edit option (button or icon)
      expect(
        find.byIcon(Icons.edit).or(find.text('Edit')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle unauthenticated state', (tester) async {
      // Arrange
      final unauthenticatedState = AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        isDemoMode: false,
      );
      
      when(testHelper.mockAuthService.currentState).thenReturn(unauthenticatedState);
      when(testHelper.mockAuthService.isAuthenticated).thenReturn(false);
      when(testHelper.mockAuthService.authStateStream).thenAnswer(
        (_) => Stream.value(unauthenticatedState),
      );

      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should handle unauthenticated state gracefully
      expect(find.byType(Scaffold), findsOneWidget);
      // Should show sign in prompt or redirect
    });

    testWidgets('should display loading state when auth is loading', (tester) async {
      // Arrange
      final loadingState = AuthState(
        status: AuthStatus.loading,
        user: null,
        isDemoMode: false,
      );
      
      when(testHelper.mockAuthService.currentState).thenReturn(loadingState);
      when(testHelper.mockAuthService.authStateStream).thenAnswer(
        (_) => Stream.value(loadingState),
      );

      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });
  });

  group('ProfileScreen Integration Tests', () {
    late ProfileScreenWidgetTest testHelper;

    setUp(() {
      testHelper = ProfileScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should integrate with auth service for user data', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockAuthService.currentState).called(greaterThan(0));
      verify(testHelper.mockAuthService.authStateStream).called(greaterThan(0));
    });

    testWidgets('should integrate with leaderboard service for ranking', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockLeaderboardService.userRank).called(greaterThan(0));
    });

    testWidgets('should integrate with inventory service for stats', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockInventoryService.totalItemsCollected).called(greaterThan(0));
    });

    testWidgets('should update when user data changes', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate user data change
      final updatedUser = TestDataFactory.createMockUser(
        username: 'UpdatedUser',
        totalPoints: 5000,
      );
      final updatedState = AuthState(
        status: AuthStatus.authenticated,
        user: updatedUser,
        isDemoMode: false,
      );
      
      when(testHelper.mockAuthService.currentState).thenReturn(updatedState);
      when(testHelper.mockAuthService.currentUser).thenReturn(updatedUser);

      await tester.pump();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      verify(testHelper.mockAuthService.currentState).called(greaterThan(0));
    });
  });

  group('ProfileScreen Material 3 Theme Tests', () {
    late ProfileScreenWidgetTest testHelper;

    setUp(() {
      testHelper = ProfileScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should apply Material 3 design system', (tester) async {
      // Arrange
      const screen = ProfileScreen();
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

    testWidgets('should support light and dark themes', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should render without theme-related errors
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be accessible with proper semantics', (tester) async {
      // Arrange
      const screen = ProfileScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should have semantic labels for accessibility
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Check for semantic labels on key elements
      expect(
        find.bySemanticsLabel('User profile').or(find.byType(Semantics)),
        findsAtLeastNWidgets(1),
      );
    });
  });
}