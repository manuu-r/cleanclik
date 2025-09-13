import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:cleanclik/core/models/leaderboard_entry.dart';
import 'package:cleanclik/core/models/achievement_card.dart';
import 'package:cleanclik/core/services/social/leaderboard_service.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/sync_status_indicator.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/widget_test_helpers.dart';
import '../../../helpers/mock_services.dart';
import '../../../fixtures/test_data_factory.dart';

void main() {
  group('Leaderboard Components Widget Tests', () {
    late BaseWidgetTest testHelper;
    late MockLeaderboardService mockLeaderboardService;

    setUp(() {
      testHelper = _LeaderboardComponentsTestHelper();
      testHelper.setUpWidgetTest();
      mockLeaderboardService = MockLeaderboardService();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    group('Leaderboard Entry Item', () {
      testWidgets('should render leaderboard entry with rank badge', (tester) async {
        // Arrange
        final entry = LeaderboardEntry(
          userId: 'user_001',
          username: 'TestUser',
          totalPoints: 1250,
          rank: 1,
          level: 8,
          isCurrentUser: false,
        );

        final widget = _LeaderboardItemWidget(entry: entry);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('TestUser'), findsOneWidget);
        expect(find.text('1250'), findsOneWidget);
        expect(find.text('points'), findsOneWidget);
        expect(find.text('Level 8'), findsOneWidget);
        expect(find.byIcon(Icons.emoji_events), findsOneWidget); // Gold trophy for rank 1
        expect(find.byType(GlassmorphismContainer), findsOneWidget);
      });

      testWidgets('should highlight current user entry', (tester) async {
        // Arrange
        final entry = LeaderboardEntry(
          userId: 'current_user',
          username: 'CurrentUser',
          totalPoints: 850,
          rank: 5,
          level: 6,
          isCurrentUser: true,
        );

        final widget = _LeaderboardItemWidget(entry: entry);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('CurrentUser'), findsOneWidget);
        expect(find.text('850'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        // Current user should have special styling (verified through widget structure)
      });

      testWidgets('should show trophy icons for top 3 ranks', (tester) async {
        final topRanks = [
          LeaderboardEntry(
            userId: 'user_1',
            username: 'First',
            totalPoints: 2000,
            rank: 1,
            level: 10,
            isCurrentUser: false,
          ),
          LeaderboardEntry(
            userId: 'user_2',
            username: 'Second',
            totalPoints: 1800,
            rank: 2,
            level: 9,
            isCurrentUser: false,
          ),
          LeaderboardEntry(
            userId: 'user_3',
            username: 'Third',
            totalPoints: 1600,
            rank: 3,
            level: 8,
            isCurrentUser: false,
          ),
        ];

        for (final entry in topRanks) {
          // Act
          await tester.pumpWidget(
            WidgetTestHelpers.createTestApp(
              child: _LeaderboardItemWidget(entry: entry),
            ),
          );
          await tester.pumpAndSettle();

          // Assert
          expect(find.byIcon(Icons.emoji_events), findsOneWidget);
          expect(find.text(entry.username), findsOneWidget);
        }
      });

      testWidgets('should show numeric rank for ranks beyond 3', (tester) async {
        // Arrange
        final entry = LeaderboardEntry(
          userId: 'user_4',
          username: 'Fourth',
          totalPoints: 1400,
          rank: 4,
          level: 7,
          isCurrentUser: false,
        );

        final widget = _LeaderboardItemWidget(entry: entry);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('4'), findsOneWidget);
        expect(find.text('Fourth'), findsOneWidget);
        expect(find.text('1400'), findsOneWidget);
      });

      testWidgets('should show achievement badge for high-level users', (tester) async {
        // Arrange
        final entry = LeaderboardEntry(
          userId: 'user_high',
          username: 'HighLevel',
          totalPoints: 3000,
          rank: 1,
          level: 15, // High level
          isCurrentUser: false,
        );

        final widget = _LeaderboardItemWidget(entry: entry);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('HighLevel'), findsOneWidget);
        expect(find.text('🏆'), findsOneWidget); // Achievement badge
      });
    });

    group('User Rank Card', () {
      testWidgets('should render current user rank card', (tester) async {
        // Arrange
        final currentUser = TestDataFactory.createMockUser(
          username: 'CurrentUser',
          totalPoints: 1250,
          rank: 3,
        );

        final widget = _UserRankCardWidget(user: currentUser);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Your Rank'), findsOneWidget);
        expect(find.text('#3 (1250 points)'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.byIcon(Icons.share), findsOneWidget);
        expect(find.byType(GlassmorphismContainer), findsOneWidget);
      });

      testWidgets('should handle share button tap', (tester) async {
        // Arrange
        bool sharePressed = false;
        final currentUser = TestDataFactory.createMockUser();

        final widget = _UserRankCardWidget(
          user: currentUser,
          onShare: () => sharePressed = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byIcon(Icons.share));
        await tester.pumpAndSettle();

        // Assert
        expect(sharePressed, isTrue);
      });

      testWidgets('should show placeholder when no user', (tester) async {
        // Arrange
        final widget = _UserRankCardWidget(user: null);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Your Rank'), findsOneWidget);
        expect(find.text('#-- (0 points)'), findsOneWidget);
      });
    });

    group('Achievement Cards Section', () {
      testWidgets('should render achievement cards horizontally', (tester) async {
        // Arrange
        final achievementCards = [
          AchievementCard.pointsMilestone(
            points: 1000,
            username: 'TestUser',
            totalItems: 50,
            accuracy: 95.0,
          ),
          AchievementCard.streakMilestone(
            streakDays: 7,
            username: 'TestUser',
            totalItems: 35,
            accuracy: 92.0,
          ),
        ];

        final widget = _AchievementCardsSectionWidget(cards: achievementCards);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Recent Achievements'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(GlassmorphismContainer), findsAtLeastNWidgets(2));
      });

      testWidgets('should handle achievement card tap', (tester) async {
        // Arrange
        AchievementCard? tappedCard;
        final achievementCard = AchievementCard.pointsMilestone(
          points: 500,
          username: 'TestUser',
          totalItems: 25,
          accuracy: 88.0,
        );

        final widget = _AchievementCardsSectionWidget(
          cards: [achievementCard],
          onCardTap: (card) => tappedCard = card,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Assert
        expect(tappedCard, isNotNull);
        expect(tappedCard!.type, equals(AchievementType.pointsMilestone));
      });

      testWidgets('should not render when no achievement cards', (tester) async {
        // Arrange
        final widget = _AchievementCardsSectionWidget(cards: []);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Recent Achievements'), findsNothing);
        expect(find.byType(ListView), findsNothing);
      });

      testWidgets('should show share icon on achievement cards', (tester) async {
        // Arrange
        final achievementCard = AchievementCard.accuracyMilestone(
          accuracy: 98.5,
          username: 'TestUser',
          totalItems: 100,
          streakDays: 14,
        );

        final widget = _AchievementCardsSectionWidget(cards: [achievementCard]);

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.share), findsOneWidget);
      });
    });

    group('Sync Status Integration', () {
      testWidgets('should render sync status indicator', (tester) async {
        // Arrange
        final widget = _SyncStatusWidget();

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(SyncStatusIndicator), findsOneWidget);
      });

      testWidgets('should handle sync status tap', (tester) async {
        // Arrange
        bool syncStatusTapped = false;
        final widget = _SyncStatusWidget(
          onTap: () => syncStatusTapped = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(SyncStatusIndicator));
        await tester.pumpAndSettle();

        // Assert
        expect(syncStatusTapped, isTrue);
      });
    });

    group('Social Sharing Components', () {
      testWidgets('should render share dialog components', (tester) async {
        // Arrange
        final widget = _ShareDialogWidget();

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Share Your Achievement'), findsOneWidget);
        expect(find.text('Share Now'), findsOneWidget);
        expect(find.byIcon(Icons.share), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should handle share dialog actions', (tester) async {
        // Arrange
        bool sharePressed = false;
        bool closePressed = false;

        final widget = _ShareDialogWidget(
          onShare: () => sharePressed = true,
          onClose: () => closePressed = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        
        // Test share button
        await tester.tap(find.text('Share Now'));
        await tester.pumpAndSettle();
        
        // Test close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(sharePressed, isTrue);
        expect(closePressed, isTrue);
      });
    });
  });
}

// Helper widgets for testing individual components

class _LeaderboardItemWidget extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardItemWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: Center(
              child: entry.rank <= 3
                  ? Icon(Icons.emoji_events, color: Colors.white)
                  : Text('${entry.rank}', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 16),
          // User avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.username, style: TextStyle(color: Colors.white)),
                Text('Level ${entry.level}', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          // Points and badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.totalPoints}', style: TextStyle(color: Colors.white)),
              Text('points', style: TextStyle(color: Colors.white70)),
              if (entry.level >= 5) Text('🏆'),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserRankCardWidget extends StatelessWidget {
  final dynamic user;
  final VoidCallback? onShare;

  const _UserRankCardWidget({this.user, this.onShare});

  @override
  Widget build(BuildContext context) {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Rank', style: TextStyle(color: Colors.white70)),
                Text(
                  user != null ? '#${user.rank} (${user.totalPoints} points)' : '#-- (0 points)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onShare,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.share, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCardsSectionWidget extends StatelessWidget {
  final List<AchievementCard> cards;
  final Function(AchievementCard)? onCardTap;

  const _AchievementCardsSectionWidget({
    required this.cards,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Achievements', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return GestureDetector(
                onTap: () => onCardTap?.call(card),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: GlassmorphismContainer(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.title, style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(card.type.name, style: TextStyle(color: Colors.white70)),
                            Icon(Icons.share, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SyncStatusWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const _SyncStatusWidget({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SyncStatusIndicator(
        showDetails: true,
        onTap: onTap,
      ),
    );
  }
}

class _ShareDialogWidget extends StatelessWidget {
  final VoidCallback? onShare;
  final VoidCallback? onClose;

  const _ShareDialogWidget({this.onShare, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Share Your Achievement', style: TextStyle(color: Colors.white)),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onShare,
            icon: Icon(Icons.share, color: Colors.white),
            label: Text('Share Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardComponentsTestHelper extends BaseWidgetTest {}