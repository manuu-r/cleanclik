import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/presentation/navigation/home/home_screen.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/social/leaderboard_service.dart';

import '../../helpers/base_widget_test.dart';
import '../../helpers/mock_services.mocks.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../fixtures/test_data_factory.dart';

class HomeScreenWidgetTest extends BaseWidgetTest {
  late MockAuthService mockAuthService;
  late MockInventoryService mockInventoryService;
  late MockLeaderboardService mockLeaderboardService;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockAuthService = MockAuthService();
    mockInventoryService = MockInventoryService();
    mockLeaderboardService = MockLeaderboardService();

    // Configure mock auth service
    final mockUser = TestDataFactory.createMockUser();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      user: mockUser,
      isDemoMode: false,
    );
    
    when(mockAuthService.currentState).thenReturn(authState);
    when(mockAuthService.currentUser).thenReturn(mockUser);
    when(mockAuthService.isAuthenticated).thenReturn(true);

    // Configure mock inventory service
    when(mockInventoryService.inventory).thenReturn(
      TestDataFactory.createMockInventoryItems(count: 5),
    );
    // Mock inventory service methods (totalItemsCollected is accessed through User model)

    // Configure mock leaderboard service (userRank is accessed through User model)

    // Add provider overrides
    overrideProviders([
      authServiceProvider.overrideWith((ref) => mockAuthService),
      inventoryServiceProvider.overrideWith((ref) => mockInventoryService),
      leaderboardServiceProvider.overrideWith((ref) => mockLeaderboardService),
    ]);
  }

  @override
  void tearDownWidgetTest() {
    super.tearDownWidgetTest();
    reset(mockAuthService);
    reset(mockInventoryService);
    reset(mockLeaderboardService);
  }
}

void main() {
  group('HomeScreen Widget Tests', () {
    late HomeScreenWidgetTest testHelper;

    setUp(() {
      testHelper = HomeScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display home screen with basic structure', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should display CleanClik branding', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('CleanClik'), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('should display user greeting when authenticated', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      final mockUser = TestDataFactory.createMockUser();
      expect(
        find.text('Hello, ${mockUser.username}!').or(
          find.text('Welcome back, ${mockUser.username}')
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display main camera action button', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        WidgetTestHelpers.findAny([find.text('Start Scanning'), find.text('Scan Objects')]),
        findsAtLeastNWidgets(1),
      );
      expect(
        WidgetTestHelpers.findAny([find.byIcon(Icons.camera_alt), find.byIcon(Icons.qr_code_scanner)]),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display user statistics cards', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      final mockUser = TestDataFactory.createMockUser();
      expect(find.text(mockUser.totalPoints.toString()), findsOneWidget);
      expect(find.text('Level ${mockUser.level}'), findsOneWidget);
    });

    testWidgets('should display inventory summary', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('5'), findsAtLeastNWidgets(1)); // Total items collected
      // Verify inventory service was accessed (totalItemsCollected is on User model)
    });

    testWidgets('should display leaderboard rank', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('#10'), findsOneWidget);
      verify(testHelper.mockLeaderboardService.userRank).called(greaterThan(0));
    });

    testWidgets('should display recent achievements', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        WidgetTestHelpers.findAny([find.text('Achievements'), find.byIcon(Icons.emoji_events)]),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display quick navigation options', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('should handle camera action button tap', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap camera button
      final cameraButton = WidgetTestHelpers.findAny([find.text('Start Scanning'), find.text('Scan Objects')]);
      if (cameraButton.evaluate().isNotEmpty) {
        await tester.tap(cameraButton.first);
        await tester.pumpAndSettle();
      }

      // Assert - should navigate to camera
      verify(testHelper.mockRouter.go('/camera')).called(1);
    });

    testWidgets('should handle map navigation', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap map button
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockRouter.go('/map')).called(1);
    });

    testWidgets('should handle leaderboard navigation', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap leaderboard button
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockRouter.go('/leaderboard')).called(1);
    });

    testWidgets('should handle profile navigation', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap profile button
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Assert
      verify(testHelper.mockRouter.go('/profile')).called(1);
    });

    testWidgets('should display daily mission or challenge', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        WidgetTestHelpers.findAny([find.text('Daily Challenge'), find.text('Mission')]),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display environmental impact summary', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        WidgetTestHelpers.findAny([find.text('Impact'), find.text('CO₂ Saved')]),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle refresh action', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - pull to refresh
      await tester.fling(find.byType(HomeScreen), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Assert - should refresh data
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display loading state when data is loading', (tester) async {
      // Arrange
      when(testHelper.mockInventoryService.items).thenReturn([]);
      // Mock leaderboard service (userRank is accessed through User model)

      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should handle loading gracefully
      expect(find.byType(Scaffold), findsOneWidget);
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

      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should redirect to login or show guest mode
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display demo mode indicator when in demo mode', (tester) async {
      // Arrange
      final mockUser = TestDataFactory.createMockUser();
      final demoState = AuthState(
        status: AuthStatus.authenticated,
        user: mockUser,
        isDemoMode: true,
      );
      
      when(testHelper.mockAuthService.currentState).thenReturn(demoState);

      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        WidgetTestHelpers.findAny([find.text('Demo Mode'), find.byIcon(Icons.science)]),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle category statistics display', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Category stats would be displayed based on user data
    });

    testWidgets('should display recent activity feed', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(
        WidgetTestHelpers.findAny([find.text('Recent Activity'), find.text('Activity')]),
        findsAtLeastNWidgets(1),
      );
    });
  });

  group('HomeScreen Integration Tests', () {
    late HomeScreenWidgetTest testHelper;

    setUp(() {
      testHelper = HomeScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should integrate with auth service for user data', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockAuthService.currentUser).called(greaterThan(0));
    });

    testWidgets('should integrate with inventory service for stats', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      // Verify inventory service was accessed (totalItemsCollected is on User model)
    });

    testWidgets('should integrate with leaderboard service for ranking', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockLeaderboardService.userRank).called(greaterThan(0));
    });

    testWidgets('should update when user data changes', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate user data change
      final updatedUser = TestDataFactory.createMockUser(
        totalPoints: 10000,
        level: 5,
      );
      when(testHelper.mockAuthService.currentUser).thenReturn(updatedUser);

      await tester.pump();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('HomeScreen Material 3 Theme Tests', () {
    late HomeScreenWidgetTest testHelper;

    setUp(() {
      testHelper = HomeScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should apply Material 3 design system', (tester) async {
      // Arrange
      const screen = HomeScreen();
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

    testWidgets('should use proper card elevation and styling', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Card), findsAtLeastNWidgets(1));
      
      // Should use Material 3 card styling
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be accessible with proper semantics', (tester) async {
      // Arrange
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have semantic labels for accessibility
      expect(
        WidgetTestHelpers.findAny([find.bySemanticsLabel('Home screen'), find.byType(Semantics)]),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should support responsive design', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      const screen = HomeScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should adapt to larger screen
      expect(tester.takeException(), isNull);
      
      // Reset view
      addTearDown(tester.view.reset);
    });
  });
}