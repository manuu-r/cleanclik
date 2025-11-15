import 'package:flutter/material.dart';

import 'package:cleanclik/core/utils/haptics_util.dart';
import 'package:cleanclik/presentation/widgets/overlays/base_bottom_sheet.dart';

/// Bottom sheet showing XP reward after an action
///
/// Displays XP gained with animation and optional level up
class XPRewardSheet extends StatefulWidget {
  final int xpGained;
  final String actionLabel;
  final bool leveledUp;
  final int? newLevel;
  final VoidCallback? onDismiss;

  const XPRewardSheet({
    super.key,
    required this.xpGained,
    required this.actionLabel,
    this.leveledUp = false,
    this.newLevel,
    this.onDismiss,
  });

  @override
  State<XPRewardSheet> createState() => _XPRewardSheetState();
}

class _XPRewardSheetState extends State<XPRewardSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _xpCountAnimation;

  @override
  void initState() {
    super.initState();

    // Trigger appropriate haptic
    if (widget.leveledUp) {
      HapticsUtil.levelUpPattern();
    } else {
      HapticsUtil.successPattern();
    }

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _xpCountAnimation = IntTween(
      begin: 0,
      end: widget.xpGained,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseBottomSheet(
      heightFraction: widget.leveledUp ? 0.5 : 0.35,
      isDismissible: true,
      onDismiss: widget.onDismiss,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Action label
          Text(
            widget.actionLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          // XP amount with animation
          AnimatedBuilder(
            animation: _xpCountAnimation,
            builder: (context, child) {
              return Text(
                '+${_xpCountAnimation.value} XP',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Level up banner (if applicable)
          if (widget.leveledUp && widget.newLevel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.3),
                    Colors.blue.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.celebration,
                    color: Colors.amber,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LEVEL UP!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You reached Level ${widget.newLevel}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
