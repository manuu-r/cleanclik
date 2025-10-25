import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/services/business/user_service.dart';
import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

/// Simplified points display widget
/// Requirements: 2.1, 4.1
class PointsDisplay extends ConsumerWidget {
  final bool showLevel;
  final bool isCompact;

  const PointsDisplay({
    super.key,
    this.showLevel = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);

    if (userProfile == null) {
      return _buildEmptyState();
    }

    return GlassmorphismContainer(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: isCompact
          ? _buildCompactDisplay(userProfile)
          : _buildDetailedDisplay(userProfile),
    );
  }

  Widget _buildEmptyState() {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            color: Colors.white.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Loading points...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDisplay(UserProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star, color: NeonColors.solarYellow, size: 20),
        const SizedBox(width: 6),
        Text(
          '${profile.totalPoints}',
          style: TextStyle(
            color: NeonColors.solarYellow,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showLevel) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: NeonColors.electricGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'L${profile.level}',
              style: TextStyle(
                color: NeonColors.electricGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedDisplay(UserProfile profile) {
    return Column(
      children: [
        // Points section
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: NeonColors.solarYellow, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.totalPoints}',
                  style: TextStyle(
                    color: NeonColors.solarYellow,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total Points',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),

        if (showLevel) ...[
          const SizedBox(height: 16),

          // Level section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level ${profile.level}',
                          style: TextStyle(
                            color: NeonColors.electricGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (profile.pointsToNextLevel > 0)
                          Text(
                            '${profile.pointsToNextLevel} to next',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: profile.levelProgress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        NeonColors.electricGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
