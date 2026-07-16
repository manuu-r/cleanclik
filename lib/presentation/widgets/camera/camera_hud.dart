import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/presentation/widgets/animations/xp_progress_bar.dart';
import 'package:cleanclik/presentation/widgets/camera/level_badge.dart';

/// Camera HUD showing XP progress, level, and streak
///
/// Always visible at the top of the camera screen
class CameraHUD extends ConsumerWidget {
  /// Called when the level badge is tapped (opens the profile).
  final VoidCallback? onLevelTap;

  const CameraHUD({super.key, this.onLevelTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(syncedCurrentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Level badge (tap → profile)
                      GestureDetector(
                        onTap: onLevelTap,
                        behavior: HitTestBehavior.opaque,
                        child: LevelBadge(level: user.level),
                      ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
