import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/presentation/widgets/animations/xp_progress_bar.dart';
import 'package:cleanclik/presentation/widgets/camera/level_badge.dart';

/// Camera HUD showing XP progress, level, and streak
///
/// Always visible at the top of the camera screen
class CameraHUD extends ConsumerWidget {
  const CameraHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(syncedCurrentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Level badge
                LevelBadge(level: user.level),
                const SizedBox(width: 12),
                // XP progress bar
                Expanded(
                  child: XPProgressBar(
                    currentXP: user.totalPoints,
                    maxXP: user.pointsToNextLevel + user.totalPoints,
                    progress: user.levelProgress,
                    level: user.level,
                  ),
                ),
                // TODO: Add streak counter when implemented
                // const SizedBox(width: 12),
                // StreakCounter(streak: user.currentStreak),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
