import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/services/business/user_service.dart';
import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/animations/progress_ring.dart';

/// Simplified user profile card widget
/// Requirements: 2.1, 4.1
class UserProfileCard extends ConsumerWidget {
  final bool isCompact;
  final VoidCallback? onTap;

  const UserProfileCard({super.key, this.isCompact = false, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);

    if (userProfile == null) {
      return _buildEmptyState();
    }

    return GestureDetector(
      onTap: onTap,
      child: GlassmorphismContainer(
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        child: isCompact
            ? _buildCompactProfile(userProfile)
            : _buildDetailedProfile(userProfile),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading Profile...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Setting up your eco-warrior profile',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProfile(UserProfile profile) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: NeonColors.electricGreen.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: NeonColors.electricGreen, width: 1),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Level ${profile.level} • ${profile.totalPoints} pts',
                style: TextStyle(
                  color: NeonColors.electricGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Level indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: NeonColors.electricGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${profile.level}',
              style: TextStyle(
                color: NeonColors.electricGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedProfile(UserProfile profile) {
    return Row(
      children: [
        // Avatar with level ring
        Stack(
          alignment: Alignment.center,
          children: [
            ProgressRing(
              progress: profile.levelProgress,
              size: 80,
              color: NeonColors.electricGreen,
              strokeWidth: 3,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: NeonColors.electricGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: NeonColors.electricGreen, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),

        // User details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Level ${profile.level} Eco Warrior',
                style: TextStyle(
                  color: NeonColors.electricGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: NeonColors.solarYellow, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.totalPoints} points',
                    style: TextStyle(
                      color: NeonColors.solarYellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (profile.pointsToNextLevel > 0) ...[
                    Icon(
                      Icons.trending_up,
                      color: Colors.white.withOpacity(0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.pointsToNextLevel} to next level',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
