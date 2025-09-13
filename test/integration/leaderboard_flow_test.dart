import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import '../helpers/base_integration_test.dart';
import '../helpers/mock_services.dart';
import '../fixtures/test_data_factory.dart';
import '../../lib/core/models/user.dart';
import '../../lib/core/models/leaderboard_entry.dart';
import '../../lib/core/models/achievement.dart';
import '../../lib/core/models/social_share.dart';
import '../../lib/core/providers/leaderboard_provider.dart';
import '../../lib/core/providers/social_provider.dart';
import '../../lib/presentation/screens/leaderboard/leaderboard_screen.dart';
import '../../lib/presentation/screens/profile/profile_screen.dart';
import '../../lib/presentation/widgets/social/achievement_badge.dart';
import '../../lib/presentation/widgets/social/share_dialog.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Leaderboard and Social Features Integration Tests', () {
    late MockLeaderboardService mockLeaderboardService;
    late MockSocialSharingService mockSocialService;
    late MockAchievementService mockAchievementService;
    late MockAuthService mockAuthService;
    late MockSupabaseClient mockSupabaseClient;
    late ProviderContainer container;

    setUp(() {
      mockLeaderboardService = MockLeaderboardService();
      mockSocialService = MockSocialSharingService();
      mockAchievementService = MockAchievementService();
      mockAuthService = MockAuthService();
      mockSupabaseClient = MockSupabaseClient();
      
      container = ProviderContainer(
        overrides: [
          leaderboardServiceProvider.overrideWithValue(mockLeaderboardService),
          socialSharingServiceProvider.overrideWithValue(mockSocialService),
          achievementServiceProvider.overrideWithValue(mockAchievementService),
          authServiceProvider.overrideWithValue(mockAuthService),
          supabaseClientProvider.overrideWithValue(mockSupabaseClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete leaderboard viewing and ranking workflow', (tester) async {
      // Arrange
      final currentUser = TestDataFactory.createMockUser(
        id: 'user1',
        username: 'TestUser',
        totalScore: 1250,
      );

      final leaderboardEntries = [
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'user2',
          username: 'TopPlayer',
          score: 2500,
          rank: 1,
        ),
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'user1',
          username: 'TestUser',
          score: 1250,
          rank: 2,
        ),
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'user3',
          username: 'NewPlayer',
          score: 800,
          rank: 3,
        ),
      ];

      when(mockAuthService.getCurrentUser()).thenReturn(currentUser);
      when(mockLeaderboardService.getGlobalLeaderboard(any))
          .thenAnswer((_) async => leaderboardEntries);
      when(mockLeaderboardService.getUserRank(currentUser.id))
          .thenAnswer((_) async => 2);
      when(mockLeaderboardService.leaderboardUpdatesStream)
          .thenAnswer((_) => Stream.value(leaderboardEntries));

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LeaderboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify leaderboard is loaded
      verify(mockLeaderboardService.getGlobalLeaderboard(any)).called(1);

      // Verify leaderboard entries are displayed
      expect(find.text('TopPlayer'), findsOneWidget);
      expect(find.text('TestUser'), findsOneWidget);
      expect(find.text('NewPlayer'), findsOneWidget);

      // Verify scores and ranks
      expect(find.text('2,500'), findsOneWidget);
      expect(find.text('1,250'), findsOneWidget);
      expect(find.text('800'), findsOneWidget);

      // Verify rank indicators
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);

      // Verify current user is highlighted
      expect(find.byKey(Key('highlighted_entry_${currentUser.id}')), findsOneWidget);

      // Verify user's rank is displayed prominently
      expect(find.text('Your Rank: #2'), findsOneWidget);
    });

    testWidgets('Real-time leaderboard updates workflow', (tester) async {
      // Arrange
      final currentUser = TestDataFactory.createMockUser(id: 'user1');
      final initialEntries = [
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'user1',
          username: 'TestUser',
          score: 1000,
          rank: 2,
        ),
      ];

      final updatedEntries = [
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'user1',
          username: 'TestUser',
          score: 1500,
          rank: 1,
        ),
      ];

      when(mockAuthService.getCurrentUser()).thenReturn(currentUser);
      when(mockLeaderboardService.getGlobalLeaderboard(any))
          .thenAnswer((_) async => initialEntries);

      final leaderboardController = StreamController<List<LeaderboardEntry>>();
      when(mockLeaderboardService.leaderboardUpdatesStream)
          .thenAnswer((_) => leaderboardController.stream);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LeaderboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('1,000'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);

      // Simulate real-time update
      leaderboardController.add(updatedEntries);
      await tester.pump();

      // Verify updated state
      expect(find.text('1,500'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);

      // Verify rank improvement animation/notification
      expect(find.text('Rank Up!'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      leaderboardController.close();
    });

    testWidgets('Achievement unlock and display workflow', (tester) async {
      // Arrange
      final currentUser = TestDataFactory.createMockUser(id: 'user1');
      final achievements = [
        TestDataFactory.createMockAchievement(
          id: 'first_disposal',
          title: 'First Steps',
          description: 'Dispose of your first item',
          isUnlocked: true,
          unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        TestDataFactory.createMockAchievement(
          id: 'recycling_champion',
          title: 'Recycling Champion',
          description: 'Recycle 100 items',
          isUnlocked: false,
          progress: 75,
          maxProgress: 100,
        ),
      ];

      when(mockAuthService.getCurrentUser()).thenReturn(currentUser);
      when(mockAchievementService.getUserAchievements(currentUser.id))
          .thenAnswer((_) async => achievements);
      when(mockAchievementService.achievementUnlocksStream)
          .thenAnswer((_) => Stream.value(achievements.first));

      // Act & Assert - Start with profile screen to view achievements
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to achievements section
      await tester.tap(find.byKey(const Key('achievements_section')));
      await tester.pumpAndSettle();

      // Verify achievements are displayed
      expect(find.byType(AchievementBadge), findsNWidgets(2));
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Recycling Champion'), findsOneWidget);

      // Verify unlocked achievement
      expect(find.byKey(const Key('unlocked_first_disposal')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify progress achievement
      expect(find.text('75/100'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Simulate new achievement unlock
      final newAchievement = TestDataFactory.createMockAchievement(
        id: 'recycling_champion',
        title: 'Recycling Champion',
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      // Trigger achievement unlock notification
      when(mockAchievementService.achievementUnlocksStream)
          .thenAnswer((_) => Stream.value(newAchievement));

      await tester.pump();

      // Verify unlock celebration
      expect(find.text('Achievement Unlocked!'), findsOneWidget);
      expect(find.text('Recycling Champion'), findsOneWidget);
      expect(find.byIcon(Icons.celebration), findsOneWidget);
    });

    testWidgets('Social sharing workflow', (tester) async {
      // Arrange
      final currentUser = TestDataFactory.createMockUser(
        id: 'user1',
        username: 'TestUser',
        totalScore: 1500,
      );

      final shareableAchievement = TestDataFactory.createMockAchievement(
        id: 'eco_warrior',
        title: 'Eco Warrior',
        description: 'Dispose of 50 items',
        isUnlocked: true,
      );

      when(mockAuthService.getCurrentUser()).thenReturn(currentUser);
      when(mockSocialService.generateShareContent(any, any))
          .thenAnswer((_) async => SocialShareContent(
            text: 'I just unlocked Eco Warrior achievement in CleanClik! 🌱',
            imageUrl: 'https://example.com/achievement.png',
            hashtags: ['CleanClik', 'EcoWarrior', 'Sustainability'],
          ));
      when(mockSocialService.shareToSocialMedia(any, any))
          .thenAnswer((_) async => true);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to achievements
      await tester.tap(find.byKey(const Key('achievements_section')));
      await tester.pumpAndSettle();

      // Tap share button on achievement
      await tester.tap(find.byKey(Key('share_${shareableAchievement.id}')));
      await tester.pumpAndSettle();

      // Verify share dialog opens
      expect(find.byType(ShareDialog), findsOneWidget);
      expect(find.text('Share Achievement'), findsOneWidget);

      // Verify share content generation
      verify(mockSocialService.generateShareContent(
        ShareType.achievement,
        shareableAchievement,
      )).called(1);

      // Verify share preview
      expect(find.text('I just unlocked Eco Warrior achievement in CleanClik! 🌱'), findsOneWidget);
      expect(find.text('#CleanClik #EcoWarrior #Sustainability'), findsOneWidget);

      // Share to Twitter
      await tester.tap(find.byKey(const Key('share_twitter')));
      await tester.pumpAndSettle();

      // Verify share was initiated
      verify(mockSocialService.shareToSocialMedia(
        SocialPlatform.twitter,
        any,
      )).called(1);

      // Verify success message
      expect(find.text('Shared successfully!'), findsOneWidget);
    });

    testWidgets('Leaderboard filtering and time periods workflow', (tester) async {
      // Arrange
      final weeklyEntries = [
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'user1',
          username: 'WeeklyChamp',
          score: 500,
          rank: 1,
        ),
      ];

      final monthlyEntries = [
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'user2',
          username: 'MonthlyChamp',
          score: 2000,
          rank: 1,
        ),
      ];

      when(mockLeaderboardService.getGlobalLeaderboard(LeaderboardPeriod.weekly))
          .thenAnswer((_) async => weeklyEntries);
      when(mockLeaderboardService.getGlobalLeaderboard(LeaderboardPeriod.monthly))
          .thenAnswer((_) async => monthlyEntries);
      when(mockLeaderboardService.getGlobalLeaderboard(LeaderboardPeriod.allTime))
          .thenAnswer((_) async => []);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LeaderboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify default (weekly) leaderboard
      expect(find.text('WeeklyChamp'), findsOneWidget);

      // Switch to monthly
      await tester.tap(find.byKey(const Key('monthly_tab')));
      await tester.pumpAndSettle();

      // Verify monthly leaderboard is loaded
      verify(mockLeaderboardService.getGlobalLeaderboard(LeaderboardPeriod.monthly)).called(1);
      expect(find.text('MonthlyChamp'), findsOneWidget);
      expect(find.text('WeeklyChamp'), findsNothing);

      // Switch to all-time
      await tester.tap(find.byKey(const Key('all_time_tab')));
      await tester.pumpAndSettle();

      // Verify all-time leaderboard is loaded
      verify(mockLeaderboardService.getGlobalLeaderboard(LeaderboardPeriod.allTime)).called(1);
    });

    testWidgets('Friend leaderboard and social connections workflow', (tester) async {
      // Arrange
      final currentUser = TestDataFactory.createMockUser(id: 'user1');
      final friends = [
        TestDataFactory.createMockUser(id: 'friend1', username: 'BestFriend'),
        TestDataFactory.createMockUser(id: 'friend2', username: 'Colleague'),
      ];

      final friendsLeaderboard = [
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'friend1',
          username: 'BestFriend',
          score: 1800,
          rank: 1,
        ),
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'user1',
          username: 'TestUser',
          score: 1250,
          rank: 2,
        ),
        TestDataFactory.createMockLeaderboardEntry(
          userId: 'friend2',
          username: 'Colleague',
          score: 900,
          rank: 3,
        ),
      ];

      when(mockAuthService.getCurrentUser()).thenReturn(currentUser);
      when(mockSocialService.getFriends(currentUser.id))
          .thenAnswer((_) async => friends);
      when(mockLeaderboardService.getFriendsLeaderboard(currentUser.id, any))
          .thenAnswer((_) async => friendsLeaderboard);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LeaderboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to friends leaderboard
      await tester.tap(find.byKey(const Key('friends_tab')));
      await tester.pumpAndSettle();

      // Verify friends leaderboard is loaded
      verify(mockLeaderboardService.getFriendsLeaderboard(currentUser.id, any)).called(1);

      // Verify friends are displayed
      expect(find.text('BestFriend'), findsOneWidget);
      expect(find.text('Colleague'), findsOneWidget);
      expect(find.text('TestUser'), findsOneWidget);

      // Verify competitive messaging
      expect(find.text('You\'re 550 points behind BestFriend'), findsOneWidget);
      expect(find.text('You\'re ahead of Colleague by 350 points'), findsOneWidget);
    });

    testWidgets('Score update and leaderboard refresh workflow', (tester) async {
      // Arrange
      final currentUser = TestDataFactory.createMockUser(
        id: 'user1',
        totalScore: 1000,
      );

      when(mockAuthService.getCurrentUser()).thenReturn(currentUser);
      when(mockLeaderboardService.updateScore(any))
          .thenAnswer((_) async {});
      when(mockLeaderboardService.getGlobalLeaderboard(any))
          .thenAnswer((_) async => []);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LeaderboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate score update from disposal action
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'score_update',
        null,
        (data) {},
      );

      // Verify score update was processed
      verify(mockLeaderboardService.updateScore(any)).called(1);

      // Verify leaderboard refresh
      verify(mockLeaderboardService.getGlobalLeaderboard(any)).called(atLeast(1));

      // Verify UI reflects score change
      expect(find.text('Score Updated!'), findsOneWidget);
    });

    testWidgets('Deep link sharing and invitation workflow', (tester) async {
      // Arrange
      final currentUser = TestDataFactory.createMockUser(id: 'user1');
      
      when(mockAuthService.getCurrentUser()).thenReturn(currentUser);
      when(mockSocialService.generateInviteLink(currentUser.id))
          .thenAnswer((_) async => 'https://cleanclik.app/invite/user1');
      when(mockSocialService.shareInviteLink(any))
          .thenAnswer((_) async => true);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LeaderboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap invite friends button
      await tester.tap(find.byKey(const Key('invite_friends_button')));
      await tester.pumpAndSettle();

      // Verify invite link generation
      verify(mockSocialService.generateInviteLink(currentUser.id)).called(1);

      // Verify invite dialog
      expect(find.text('Invite Friends'), findsOneWidget);
      expect(find.text('Challenge your friends to join CleanClik!'), findsOneWidget);

      // Share invite link
      await tester.tap(find.byKey(const Key('share_invite_link')));
      await tester.pumpAndSettle();

      // Verify invite was shared
      verify(mockSocialService.shareInviteLink(any)).called(1);
      expect(find.text('Invite sent!'), findsOneWidget);
    });
  });
}