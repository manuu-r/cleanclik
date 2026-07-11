import 'package:flutter/material.dart';

/// Circular level badge with gradient border
///
/// Displays the current user level with visual effects
class LevelBadge extends StatelessWidget {
  final int level;
  final double size;

  const LevelBadge({
    super.key,
    required this.level,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getLevelColor(level),
            _getLevelColor(level).withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getLevelColor(level).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.35,
                ),
              ),
              Text(
                'LVL',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: size * 0.15,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    // Different colors for different level tiers
    if (level >= 6) return Colors.purple;
    if (level >= 5) return Colors.orange;
    if (level >= 4) return Colors.blue;
    if (level >= 3) return Colors.green;
    if (level >= 2) return Colors.teal;
    return Colors.cyan;
  }
}
