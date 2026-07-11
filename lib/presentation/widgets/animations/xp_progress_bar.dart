import 'package:flutter/material.dart';

/// Animated XP progress bar showing progress to next level
///
/// Displays current XP and animates smoothly when XP increases
class XPProgressBar extends StatefulWidget {
  final int currentXP;
  final int maxXP;
  final double progress; // 0.0 to 1.0
  final int level;

  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.maxXP,
    required this.progress,
    required this.level,
  });

  @override
  State<XPProgressBar> createState() => _XPProgressBarState();
}

class _XPProgressBarState extends State<XPProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _previousProgress = widget.progress;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: _previousProgress,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(XPProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNearCompletion = widget.progress > 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // XP numbers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${widget.level}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.currentXP} / ${widget.maxXP} XP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Progress bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isNearCompletion
                    ? [
                        BoxShadow(
                          color: _getGradientColor(widget.level).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Progress fill with gradient
                    FractionallySizedBox(
                      widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getGradientColor(widget.level),
                              _getGradientColor(widget.level).withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Shimmer effect when near completion
                    if (isNearCompletion)
                      Positioned.fill(
                        child: _ShimmerEffect(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getGradientColor(int level) {
    // Different colors for different level tiers
    if (level >= 6) return Colors.purple;
    if (level >= 5) return Colors.orange;
    if (level >= 4) return Colors.blue;
    if (level >= 3) return Colors.green;
    if (level >= 2) return Colors.teal;
    return Colors.cyan;
  }
}

/// Shimmer effect for progress bar when near completion
class _ShimmerEffect extends StatefulWidget {
  final Color color;

  const _ShimmerEffect({required this.color});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              colors: [
                Colors.transparent,
                widget.color,
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}
