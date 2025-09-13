import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/theme/app_colors.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/models/leaderboard_entry.dart';
import 'package:cleanclik/core/models/achievement_card.dart';

import 'package:cleanclik/core/services/social/leaderboard_service.dart';
import 'package:cleanclik/core/services/social/social_sharing_service.dart';
import 'package:cleanclik/core/services/social/social_card_generation_service.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/animations/particle_system.dart';


import 'package:cleanclik/presentation/widgets/common/sync_status_indicator.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _particleController;
  late AnimationController _celebrationController;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Listen for achievement unlocks
    _listenForAchievements();

    // Listen for tab changes
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _particleController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _listenForAchievements() {
    ref.read(leaderboardServiceProvider.future).then((leaderboardService) {
      leaderboardService.achievementUnlockedStream.listen((achievement) {
        _showAchievementCelebration(achievement);
      });
    });
  }

  void _onTabChanged() {
    // Tab change handling can be added here if needed
  }

  void _showAchievementCelebration(String achievementTitle) {
    setState(() {
      _showCelebration = true;
    });

    _celebrationController.forward().then((_) {
      setState(() {
        _showCelebration = false;
      });
      _celebrationController.reset();
    });

    // Show achievement dialog
    _showAchievementDialog(achievementTitle);
  }

  void _showAchievementDialog(String achievementTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _AchievementUnlockedDialog(achievementTitle: achievementTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arTheme = theme.arTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => arTheme.neonGradient.createShader(bounds),
          child: const Text(
            'Leaderboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          // Debug button (remove in production)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              final service = await ref.read(leaderboardServiceProvider.future);
              await service.testDatabaseDirectly();
            },
          ),
          // Sync status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SyncStatusIndicator(
              showDetails: true,
              onTap: () => _showSyncStatusDialog(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeonColors.electricGreen,
          labelColor: NeonColors.electricGreen,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  NeonColors.earthOrange.withAlpha((0.05 * 255).round()),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Particle system for celebrations
          if (_showCelebration)
            ParticleSystem(
              type: ParticleType.confetti,
              isActive: _showCelebration,
              color: NeonColors.earthOrange,
            ),

          // Main content
          Column(
            children: [
              // User's Current Rank with dynamic data
              _buildUserRankCard(),

              // Leaderboard List with real data
              Expanded(
                flex: 2,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardList(LeaderboardPeriod.daily),
                    _buildLeaderboardList(LeaderboardPeriod.weekly),
                    _buildLeaderboardList(LeaderboardPeriod.monthly),
                    _buildLeaderboardList(LeaderboardPeriod.allTime),
                  ],
                ),
              ),

              // Achievement Cards and Social Sharing
              _buildAchievementCardsSection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard() {
    final currentUser = ref.watch(currentUserProvider);
    final leaderboardServiceAsync = ref.watch(leaderboardServiceProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassmorphismContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: NeonColors.electricGreen.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: NeonColors.electricGreen, width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rank',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => Theme.of(
                      context,
                    ).arTheme.neonGradient.createShader(bounds),
                    child: Text(
                      currentUser != null
                          ? '#${currentUser.rank} (${currentUser.totalPoints} points)'
                          : '#-- (0 points)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (currentUser != null) ...[
                    const SizedBox(height: 4),
                    leaderboardServiceAsync.when(
                      data: (leaderboardService) => Text(
                        '${leaderboardService.currentStreak} day streak • ${leaderboardService.accuracyPercentage.toStringAsFixed(1)}% accuracy',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      loading: () => Text(
                        'Loading stats...',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      error: (_, __) => Text(
                        'Stats unavailable',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: _showShareOptions,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NeonColors.earthOrange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(LeaderboardPeriod period) {
    return Consumer(
      builder: (context, ref, child) {
        final leaderboardAsync = ref.watch(leaderboardProvider(period: period));

        return leaderboardAsync.when(
          data: (users) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final entry = users[index];
              return _buildLeaderboardItem(entry);
            },
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: NeonColors.electricGreen),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Failed to load leaderboard',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphismContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank Badge with animation for current user
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entry.isCurrentUser
                    ? NeonColors.electricGreen.withOpacity(0.3)
                    : _getRankColor(entry.rank).withAlpha((0.15 * 255).round()),
                shape: BoxShape.circle,
                border: Border.all(
                  color: entry.isCurrentUser
                      ? NeonColors.electricGreen
                      : _getRankColor(entry.rank).withOpacity(0.3),
                  width: entry.isCurrentUser ? 2 : 1,
                ),
                boxShadow: entry.isCurrentUser
                    ? [
                        BoxShadow(
                          color: NeonColors.electricGreen.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: entry.rank <= 3
                    ? Icon(
                        _getRankIcon(entry.rank),
                        color: entry.isCurrentUser
                            ? Colors.white
                            : _getRankColor(entry.rank),
                        size: 22,
                      )
                    : Text(
                        '${entry.rank}',
                        style: TextStyle(
                          color: entry.isCurrentUser
                              ? Colors.white
                              : _getRankColor(entry.rank),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // User Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entry.isCurrentUser
                    ? NeonColors.electricGreen.withOpacity(0.2)
                    : AppColors.primary.withAlpha((0.15 * 255).round()),
                shape: BoxShape.circle,
                border: Border.all(
                  color: entry.isCurrentUser
                      ? NeonColors.electricGreen.withOpacity(0.5)
                      : AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person,
                color: entry.isCurrentUser ? Colors.white : AppColors.primary,
                size: 22,
              ),
            ),

            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: entry.isCurrentUser
                              ? NeonColors.electricGreen
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${entry.level}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Points and Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.totalPoints}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: entry.isCurrentUser
                        ? NeonColors.electricGreen
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                if (entry.level >= 5) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('🏆', style: const TextStyle(fontSize: 10)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCardsSection() {
    return Consumer(
      builder: (context, ref, child) {
        final cards = ref.watch(achievementCardsProvider);

        if (cards.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Achievements',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return GestureDetector(
                      onTap: () => _showAchievementCardDialog(card),
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        child: GlassmorphismContainer(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    card.type.name,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Icon(
                                    Icons.share,
                                    color: NeonColors.electricGreen,
                                    size: 16,
                                  ),
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
          ),
        );
      },
    );
  }

  void _showSyncStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SyncStatusDialog(),
    );
  }

  void _showShareOptions() {
    print('📤 [LEADERBOARD_SCREEN] _showShareOptions() called');
    
    try {
      // Use a simpler dialog approach to avoid overlay complexity
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => _buildSimpleShareDialog(context),
      );
      print('✅ [LEADERBOARD_SCREEN] Share dialog shown successfully');
    } catch (e) {
      print('❌ [LEADERBOARD_SCREEN] Error showing share options: $e');
      // Fallback to direct sharing
      _shareDirectly();
    }
  }

  Widget _buildSimpleShareDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Your Achievement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Share button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _shareDirectly();
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  'Share Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeonColors.electricGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Generate and share a beautiful achievement card!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareDirectly() async {
    try {
      print('📤 [LEADERBOARD_SCREEN] Starting image card generation and share...');
      
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        print('❌ [LEADERBOARD_SCREEN] No current user found');
        _showErrorMessage('Unable to share: No user data available');
        return;
      }

      print('👤 [LEADERBOARD_SCREEN] Current user: ${currentUser.username}, Points: ${currentUser.totalPoints}');

      // Show loading message
      _showLoadingMessage('Generating your achievement card...');

      try {
        // Generate card data
        final cardGenerationService = ref.read(socialCardGenerationServiceProvider);
        final cardData = await cardGenerationService.aggregateUserData(ref);
        
        print('📊 [LEADERBOARD_SCREEN] Card data aggregated successfully');

        // Generate the visual card image
        final cardFile = await cardGenerationService.generateCard(
          template: CardTemplate.achievement,
          data: cardData,
          platform: SocialPlatform.system,
        );

        print('🎨 [LEADERBOARD_SCREEN] Card image generated: ${cardFile.path}');

        // Share the image using the social sharing service
        final socialService = ref.read(socialSharingServiceProvider);
        final success = await socialService.shareSocialCard(
          cardFile,
          'Check out my CleanClik achievement! 🌍♻️ #CleanClik #CleanCity',
          SocialPlatform.system,
        );

        if (success) {
          print('✅ [LEADERBOARD_SCREEN] Image card shared successfully');
          _showSuccessMessage('Achievement card shared successfully!');
        } else {
          print('❌ [LEADERBOARD_SCREEN] Share failed or was dismissed');
          _showErrorMessage('Share was cancelled or unavailable.');
        }
      } catch (cardError) {
        print('⚠️ [LEADERBOARD_SCREEN] Card generation failed, falling back to text: $cardError');
        
        // Fallback to text sharing if card generation fails
        final card = AchievementCard.pointsMilestone(
          points: currentUser.totalPoints,
          username: currentUser.username,
          totalItems: currentUser.totalItemsCollected,
          accuracy: 95.0,
        );

        final socialService = ref.read(socialSharingServiceProvider);
        final success = await socialService.shareAchievementCard(
          card,
          SocialPlatform.system,
        );

        if (success) {
          print('✅ [LEADERBOARD_SCREEN] Fallback text share completed');
          _showSuccessMessage('Achievement shared successfully!');
        } else {
          _showErrorMessage('Share was cancelled or unavailable.');
        }
      }
    } catch (e, stackTrace) {
      print('❌ [LEADERBOARD_SCREEN] Error in direct share: $e');
      print('📍 [LEADERBOARD_SCREEN] Stack trace: $stackTrace');
      _showErrorMessage('An error occurred while sharing: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showLoadingMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: NeonColors.electricGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAchievementCardDialog(AchievementCard card) {
    showDialog(
      context: context,
      builder: (context) => _AchievementCardDialog(card: card),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primary;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.emoji_events_outlined;
      case 3:
        return Icons.emoji_events_outlined;
      default:
        return Icons.person;
    }
  }
}

/// Dialog for showing achievement unlock celebration
class _AchievementUnlockedDialog extends ConsumerWidget {
  final String achievementTitle;

  const _AchievementUnlockedDialog({required this.achievementTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeonColors.electricGreen.withOpacity(0.9),
              NeonColors.electricGreen.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 16),

            // Achievement unlocked text
            const Text(
              'Achievement Unlocked!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Achievement name
            Text(
              achievementTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Achievement description
            Text(
              'Congratulations on your achievement!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Rarity badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Achievement',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Generate and share achievement card
                      _shareAchievement(context, ref, achievementTitle);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                    child: const Text(
                      'Share',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareAchievement(
    BuildContext context,
    WidgetRef ref,
    String achievementTitle,
  ) {
    // Implementation for sharing achievement
    // Generate quick card and share with achievement title
    print('Sharing achievement: $achievementTitle');
  }
}

/// Dialog for showing achievement card with sharing options
class _AchievementCardDialog extends ConsumerWidget {
  final AchievementCard card;

  const _AchievementCardDialog({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey cardKey = GlobalKey();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Achievement card
          RepaintBoundary(
            key: cardKey,
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: card.background.gradientColors,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      card.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      card.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Share button
          ElevatedButton.icon(
            onPressed: () async {
              final socialService = ref.read(socialSharingServiceProvider);
              await socialService.shareAchievementCard(
                card,
                SocialPlatform.system,
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Achievement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeonColors.electricGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
