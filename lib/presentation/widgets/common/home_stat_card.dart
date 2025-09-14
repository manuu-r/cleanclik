import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/services/system/performance_service.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/animations/progress_ring.dart';
import 'package:cleanclik/presentation/widgets/animations/breathing_widget.dart';

/// Reusable stat card component for home screen with Material 3 design
class HomeStatCard extends ConsumerWidget {
  final String title;
  final int value;
  final int maxValue;
  final IconData icon;
  final Color color;
  final bool showBreathing;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? customContent;

  const HomeStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.maxValue,
    required this.icon,
    required this.color,
    this.showBreathing = false,
    this.onTap,
    this.subtitle,
    this.customContent,
  });

  /// Create a stat card for inventory items
  factory HomeStatCard.inventory({
    Key? key,
    required int itemCount,
    int maxItems = 10,
    bool showBreathing = false,
    VoidCallback? onTap,
  }) {
    return HomeStatCard(
      key: key,
      title: 'Items',
      value: itemCount,
      maxValue: maxItems,
      icon: Icons.inventory_outlined,
      color: NeonColors.electricGreen,
      showBreathing: showBreathing,
      onTap: onTap,
    );
  }

  /// Create a stat card for points earned
  factory HomeStatCard.points({
    Key? key,
    required int points,
    int maxPoints = 1000,
    VoidCallback? onTap,
  }) {
    return HomeStatCard(
      key: key,
      title: 'Points',
      value: points,
      maxValue: maxPoints,
      icon: Icons.star_outline,
      color: NeonColors.earthOrange,
      onTap: onTap,
    );
  }

  /// Create a stat card for streak
  factory HomeStatCard.streak({
    Key? key,
    required int streak,
    int maxStreak = 30,
    VoidCallback? onTap,
  }) {
    return HomeStatCard(
      key: key,
      title: 'Streak',
      value: streak,
      maxValue: maxStreak,
      icon: Icons.local_fire_department_outlined,
      color: NeonColors.toxicPurple,
      onTap: onTap,
    );
  }

  /// Create a stat card for rank
  factory HomeStatCard.rank({
    Key? key,
    required int rank,
    int maxRank = 100,
    VoidCallback? onTap,
  }) {
    return HomeStatCard(
      key: key,
      title: 'Rank',
      value: rank,
      maxValue: maxRank,
      icon: Icons.emoji_events_outlined,
      color: NeonColors.oceanBlue,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final performanceService = ref.watch(performanceServiceProvider);
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    Widget card = GlassmorphismContainer.secondary(
      borderRadius: BorderRadius.circular(UIConstants.radiusXXLarge), // Increased border radius for eco score cards
      padding: EdgeInsets.all(UIConstants.spacing2), // Reduced padding
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(UIConstants.radiusXXLarge), // Increased border radius for eco score cards
          child: Padding(
            padding: EdgeInsets.all(UIConstants.spacing1), // Minimal inner padding
            child: customContent ?? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProgressRing(
                  progress: progress,
                  size: 40, // Reduced size to fit better
                  color: color,
                  showGlow: performanceService.shouldShowAnimations,
                  child: Icon(icon, size: 18, color: Colors.white), // Reduced icon size
                ),
                SizedBox(height: UIConstants.spacing2), // Reduced spacing
                Text(
                  '$value',
                  style: theme.textTheme.titleMedium?.copyWith( // Smaller text style
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2), // Minimal spacing
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 10, // Smaller font size
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Allow wrapping for longer titles
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: UIConstants.spacing1),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (showBreathing && performanceService.shouldShowAnimations) {
      card = BreathingWidget(
        enabled: true,
        child: card,
      );
    }

    return card;
  }
}