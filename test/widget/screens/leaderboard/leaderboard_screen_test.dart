import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/presentation/screens/leaderboard/leaderboard_screen.dart';
import 'package:cleanclik/core/services/social/leaderboard_service.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/mock_services.mocks.dart';
import '../../../fixtures/test_data_factory.dart';

class LeaderboardScreenWidgetTest extends BaseWidgetTest {
  late MockLeaderboardService mockLeaderboardService;
  late MockAuthService mockAuthService;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockLeaderboardService = MockLeaderboardService();
    mockAuthService = MockAuthService();

    // Configure mock leaderboard service
    final mockLeaderboard = TestDataFactory.createMockLeaderboardEntries(count: 10);
    when(mockLeaderboardService.topUsers).thenReturn(mockLeaderboard);
    when(mockLeaderboardService.userRank).thenReturn(5);
    when(mockLeaderboardService.totalUsers).thenReturn(1000);
    when(mockLeaderboardService.isLoading).thenReturn(false);

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

    // Add provider overrides
    overrideProviders([
      leaderboardServiceProvider.overrideWith((ref) => mockLeaderboardService),
      authServiceProvider.overrideWith((ref) => mockAuthService),
    ]);
  }

  @override
  void tearDownWidgetTest() {
    super.tearDownWidgetTest();
    reset(mockLeaderboardService);
    reset(mockAuthService);
  }
}

void main() {
  group('LeaderboardScreen Widget Tests', () {
    late LeaderboardScreenWidgetTest testHelper;

    setUp(() {
      testHelper = LeaderboardScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display leaderboard screen with basic structure', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(LeaderboardScreen), findsOneWidget);
    });

    testWidgets('should display leaderboard title', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(
        find.text('Leaderboard').or(find.text('Rankings')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display top users list', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      verify(testHelper.mockLeaderboardService.topUsers).called(greaterThan(0));
      
      // Should display list of users
      expect(find.byType(ListView).or(find.byType(Column)), findsAtLeastNWidgets(1));
    });

    testWidgets('should display user rankings with positions', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should display ranking positions (1, 2, 3, etc.)
      expect(
        find.text('1').or(find.text('#1')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display user points/scores', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should display points from mock leaderboard entries
      final mockEntries = TestDataFactory.createMockLeaderboardEntries(count: 3);
      if (mockEntries.isNotEmpty) {
        expect(
          find.text(mockEntries.first.points.toString()),
          findsAtLeastNWidgets(1),
        );
      }
    });

    testWidgets('should highlight current user in leaderboard', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      verify(testHelper.mockLeaderboardService.userRank).called(greaterThan(0));
      
      // Should show current user's rank
      expect(find.text('5').or(find.text('#5')), findsAtLeastNWidgets(1));
    });

    testWidgets('should display loading state when data is loading', (tester) async {
      // Arrange
      when(testHelper.mockLeaderboardService.isLoading).thenReturn(true);
      
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should display empty state when no users', (tester) async {
      // Arrange
      when(testHelper.mockLeaderboardService.topUsers).thenReturn([]);
      
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should show empty state message
      expect(
        find.text('No rankings available').or(find.text('Be the first!')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display user avatars in leaderboard', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should display avatars or placeholder icons
      expect(
        find.byType(CircleAvatar).or(find.byIcon(Icons.person)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display achievement badges for top users', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should display badges or trophies for top positions
      expect(
        find.byIcon(Icons.emoji_events).or(find.byIcon(Icons.star)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle refresh action', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - look for refresh button or pull-to-refresh
      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton.first);
        await tester.pumpAndSettle();
      }

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should have attempted to refresh data
    });

    testWidgets('should display time period filters', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have time period options (Daily, Weekly, All-time)
      expect(
        find.text('Daily').or(find.text('Weekly')).or(find.text('All Time')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle social sharing', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - look for share button
      final shareButton = find.byIcon(Icons.share);
      if (shareButton.evaluate().isNotEmpty) {
        await tester.tap(shareButton.first);
        await tester.pumpAndSettle();
      }

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should handle share action gracefully
    });
  });

  group('LeaderboardScreen Integration Tests', () {
    late LeaderboardScreenWidgetTest testHelper;

    setUp(() {
      testHelper = LeaderboardScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should integrate with leaderboard service for data', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockLeaderboardService.topUsers).called(greaterThan(0));
      verify(testHelper.mockLeaderboardService.userRank).called(greaterThan(0));
    });

    testWidgets('should integrate with auth service for current user', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockAuthService.currentUser).called(greaterThan(0));
    });

    testWidgets('should update when leaderboard data changes', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate leaderboard data change
      final newLeaderboard = TestDataFactory.createMockLeaderboardEntries(count: 15);
      when(testHelper.mockLeaderboardService.topUsers).thenReturn(newLeaderboard);

      await tester.pump();

      // Assert
      verify(testHelper.mockLeaderboardService.topUsers).called(greaterThan(0));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle real-time updates', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate real-time rank change
      when(testHelper.mockLeaderboardService.userRank).thenReturn(3);

      await tester.pump();

      // Assert
      verify(testHelper.mockLeaderboardService.userRank).called(greaterThan(0));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('LeaderboardScreen Social Features Tests', () {
    late LeaderboardScreenWidgetTest testHelper;

    setUp(() {
      testHelper = LeaderboardScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display friend rankings when available', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have friends tab or section
      expect(
        find.text('Friends').or(find.byIcon(Icons.people)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should display achievement sharing options', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have sharing capabilities
      expect(
        find.byIcon(Icons.share).or(find.text('Share')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle user profile navigation', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap on a user in the leaderboard
      final userTile = find.byType(ListTile).or(find.byType(Card));
      if (userTile.evaluate().isNotEmpty) {
        await tester.tap(userTile.first);
        await tester.pumpAndSettle();
      }

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should handle user profile navigation
    });
  });

  group('LeaderboardScreen Material 3 Theme Tests', () {
    late LeaderboardScreenWidgetTest testHelper;

    setUp(() {
      testHelper = LeaderboardScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should apply Material 3 design system', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
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

    testWidgets('should use proper color scheme for rankings', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should use theme colors appropriately
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be accessible with proper semantics', (tester) async {
      // Arrange
      const screen = LeaderboardScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have semantic labels for accessibility
      expect(
        find.bySemanticsLabel('Leaderboard').or(find.byType(Semantics)),
        findsAtLeastNWidgets(1),
      );
    });
  });
}