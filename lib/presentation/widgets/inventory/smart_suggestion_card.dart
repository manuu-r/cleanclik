import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanclik/core/services/business/smart_suggestions_service.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

/// Floating card for displaying smart suggestions
class SmartSuggestionCard extends StatefulWidget {
  final SmartSuggestion suggestion;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool isCompact;

  const SmartSuggestionCard({
    super.key,
    required this.suggestion,
    this.onTap,
    this.onDismiss,
    this.isCompact = false,
  });

  @override
  State<SmartSuggestionCard> createState() => _SmartSuggestionCardState();
}

class _SmartSuggestionCardState extends State<SmartSuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Animate in
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onDismiss() {
    HapticFeedback.selectionClick();

    // Animate out
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 300, 0),
          child: Opacity(opacity: _fadeAnimation.value, child: _buildCard()),
        );
      },
    );
  }

  Widget _buildCard() {
    final color = _getSuggestionColor();
    final icon = _getSuggestionIcon();

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: GlassmorphismContainer(
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
          child: Row(
            children: [
              // Icon
              Container(
                width: widget.isCompact ? 32 : 40,
                height: widget.isCompact ? 32 : 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: widget.isCompact ? 16 : 20,
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.suggestion.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (!widget.isCompact) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.suggestion.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Priority indicator
              if (widget.suggestion.priority == SuggestionPriority.urgent)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),

              const SizedBox(width: 8),

              // Dismiss button
              GestureDetector(
                onTap: _onDismiss,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSuggestionColor() {
    switch (widget.suggestion.type) {
      case SuggestionType.tip:
        return NeonColors.oceanBlue;
      case SuggestionType.action:
        return NeonColors.electricGreen;
      case SuggestionType.reminder:
        return NeonColors.solarYellow;
      case SuggestionType.social:
        return NeonColors.cosmicPurple;
      case SuggestionType.achievement:
        return NeonColors.solarYellow;
      case SuggestionType.exploration:
        return NeonColors.oceanBlue;
      case SuggestionType.motivation:
        return NeonColors.electricGreen;
      case SuggestionType.urgent:
        return NeonColors.earthOrange;
      case SuggestionType.celebration:
        return NeonColors.cosmicPurple;
    }
  }

  IconData _getSuggestionIcon() {
    switch (widget.suggestion.type) {
      case SuggestionType.tip:
        return Icons.lightbulb_outline;
      case SuggestionType.action:
        return Icons.play_arrow;
      case SuggestionType.reminder:
        return Icons.notifications_outlined;
      case SuggestionType.social:
        return Icons.people_outline;
      case SuggestionType.achievement:
        return Icons.emoji_events_outlined;
      case SuggestionType.exploration:
        return Icons.explore_outlined;
      case SuggestionType.motivation:
        return Icons.favorite_outline;
      case SuggestionType.urgent:
        return Icons.priority_high;
      case SuggestionType.celebration:
        return Icons.celebration_outlined;
    }
  }
}
