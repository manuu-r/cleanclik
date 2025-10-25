import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/services/business/user_service.dart';
import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

/// Simplified achievements display widget
/// Requirements: 2.1, 4.1
class AchievementsDisplay extends ConsumerWidget {
  final bool isCompact;
  final int maxAchievements;

  const AchievementsDisplay({
    super.key,
    this.isCompact = false,
    this.maxAchievements = 4,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);

    if (userProfile == null) {
      return _buildEmptyState();
    }

    return GlassmorphismContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildAchievementsList(userProfile),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: Colors.white.withOpacity(0.6),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Loading achievements...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.emoji_events, color: NeonColors.solarYellow, size: 24),
        const SizedBox(width: 8),
        const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsList(UserProfile profile) {
    final achievements = Achievement.basicAchievements
        .take(maxAchievements)
        .toList();

    return Column(
      children: achievements.map((achievement) {
        final isUnlocked = _isAchievementUnlocked(achievement, profile);
        final progress = _getAchievementProgress(achievement, profile);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildAchievementItem(achievement, isUnlocked, progress),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementItem(
    Achievement achievement,
    bool isUnlocked,
    double progress,
  ) {
    final color = isUnlocked
        ? NeonColors.solarYellow
        : Colors.white.withOpacity(0.4);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? NeonColors.solarYellow.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked
              ? NeonColors.solarYellow.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Achievement icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Achievement details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
                ),
                if (!isUnlocked && progress > 0) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      NeonColors.solarYellow.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status indicator
          if (isUnlocked)
            Icon(Icons.check_circle, color: NeonColors.electricGreen, size: 20)
          else if (progress > 0)
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  bool _isAchievementUnlocked(Achievement achievement, UserProfile profile) {
    switch (achievement.id) {
      case 'first_disposal':
        return profile.totalPoints > 0;
      default:
        return profile.totalPoints >= achievement.pointsRequired;
    }
  }

  double _getAchievementProgress(Achievement achievement, UserProfile profile) {
    if (_isAchievementUnlocked(achievement, profile)) return 1.0;

    switch (achievement.id) {
      case 'first_disposal':
        return profile.totalPoints > 0 ? 1.0 : 0.0;
      default:
        return (profile.totalPoints / achievement.pointsRequired).clamp(
          0.0,
          1.0,
        );
    }
  }
}
