import 'package:flutter/material.dart';
import '../../../core/models/waste_models.dart';

/// Simple color mapping for waste categories
class _CategoryColors {
  static final Map<WasteCategory, Color> _categoryColors = {
    WasteCategory.recycle: const Color(0xFF4CAF50),
    WasteCategory.organic: const Color(0xFF8BC34A),
    WasteCategory.ewaste: const Color(0xFFFF9800),
    WasteCategory.hazardous: const Color(0xFFF44336),
  };

  static Color getPrimaryColor(WasteCategory category) {
    return _categoryColors[category] ?? Colors.grey;
  }
}

/// Concise tooltip widget that displays essential object information
class TooltipWidget extends StatefulWidget {
  final WasteCategory category;
  final String objectInfo;
  final Offset indicatorPosition;
  final Size screenSize;
  final bool isVisible;
  final Duration animationDuration;
  final VoidCallback? onTap;
  final double? categoryConfidence;

  const TooltipWidget({
    super.key,
    required this.category,
    required this.objectInfo,
    required this.indicatorPosition,
    required this.screenSize,
    this.isVisible = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onTap,
    this.categoryConfidence,
  });

  @override
  State<TooltipWidget> createState() => _TooltipWidgetState();
}

class _TooltipWidgetState extends State<TooltipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  Offset _calculatedPosition = Offset.zero;
  Size _tooltipSize = const Size(120, 40);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _calculatePosition();

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  void _calculatePosition() {
    // Estimate tooltip size based on text content
    _tooltipSize = _estimateTooltipSize(widget.objectInfo);

    // Calculate optimal position to avoid screen edges
    final position = _findOptimalPosition(
      widget.indicatorPosition,
      _tooltipSize,
      widget.screenSize,
    );

    _calculatedPosition = position.offset;
  }

  Size _estimateTooltipSize(String text) {
    // Compact tooltip sizing
    const double charWidth = 7.0;
    const double lineHeight = 16.0;
    const double padding = 12.0;
    const double maxWidth = 120.0; // Much smaller max width

    final textWidth = text.length * charWidth;
    final width = (textWidth + padding).clamp(60.0, maxWidth);
    final height = lineHeight + padding;

    return Size(width, height);
  }

  _PositionResult _findOptimalPosition(
    Offset indicatorPos,
    Size tooltipSize,
    Size screenSize,
  ) {
    const double margin = 8.0;
    const double indicatorOffset = 24.0; // Distance from indicator

    // Try positions in order of preference: above, below, right, left
    final positions = [
      _tryPosition(
        TooltipPosition.above,
        indicatorPos,
        tooltipSize,
        screenSize,
        margin,
        indicatorOffset,
      ),
      _tryPosition(
        TooltipPosition.below,
        indicatorPos,
        tooltipSize,
        screenSize,
        margin,
        indicatorOffset,
      ),
      _tryPosition(
        TooltipPosition.right,
        indicatorPos,
        tooltipSize,
        screenSize,
        margin,
        indicatorOffset,
      ),
      _tryPosition(
        TooltipPosition.left,
        indicatorPos,
        tooltipSize,
        screenSize,
        margin,
        indicatorOffset,
      ),
    ];

    // Return the first position that fits, or the best available
    for (final position in positions) {
      if (position.fitsOnScreen) {
        return position;
      }
    }

    // If none fit perfectly, return the one with least overflow
    positions.sort((a, b) => a.overflowAmount.compareTo(b.overflowAmount));
    return positions.first;
  }

  _PositionResult _tryPosition(
    TooltipPosition position,
    Offset indicatorPos,
    Size tooltipSize,
    Size screenSize,
    double margin,
    double indicatorOffset,
  ) {
    Offset offset;

    switch (position) {
      case TooltipPosition.above:
        offset = Offset(
          indicatorPos.dx - tooltipSize.width / 2,
          indicatorPos.dy - tooltipSize.height - indicatorOffset,
        );
        break;
      case TooltipPosition.below:
        offset = Offset(
          indicatorPos.dx - tooltipSize.width / 2,
          indicatorPos.dy + indicatorOffset,
        );
        break;
      case TooltipPosition.left:
        offset = Offset(
          indicatorPos.dx - tooltipSize.width - indicatorOffset,
          indicatorPos.dy - tooltipSize.height / 2,
        );
        break;
      case TooltipPosition.right:
        offset = Offset(
          indicatorPos.dx + indicatorOffset,
          indicatorPos.dy - tooltipSize.height / 2,
        );
        break;
    }

    // Adjust to keep within screen bounds
    final adjustedOffset = Offset(
      offset.dx.clamp(margin, screenSize.width - tooltipSize.width - margin),
      offset.dy.clamp(margin, screenSize.height - tooltipSize.height - margin),
    );

    // Calculate if it fits on screen
    final fitsOnScreen =
        adjustedOffset.dx >= margin &&
        adjustedOffset.dy >= margin &&
        adjustedOffset.dx + tooltipSize.width <= screenSize.width - margin &&
        adjustedOffset.dy + tooltipSize.height <= screenSize.height - margin;

    // Calculate overflow amount for ranking
    double overflowAmount = 0.0;
    if (adjustedOffset.dx < margin) {
      overflowAmount += margin - adjustedOffset.dx;
    }
    if (adjustedOffset.dy < margin) {
      overflowAmount += margin - adjustedOffset.dy;
    }
    if (adjustedOffset.dx + tooltipSize.width > screenSize.width - margin) {
      overflowAmount +=
          (adjustedOffset.dx + tooltipSize.width) - (screenSize.width - margin);
    }
    if (adjustedOffset.dy + tooltipSize.height > screenSize.height - margin) {
      overflowAmount +=
          (adjustedOffset.dy + tooltipSize.height) -
          (screenSize.height - margin);
    }

    return _PositionResult(
      position: position,
      offset: adjustedOffset,
      fitsOnScreen: fitsOnScreen,
      overflowAmount: overflowAmount,
    );
  }

  @override
  void didUpdateWidget(TooltipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }

    if (widget.indicatorPosition != oldWidget.indicatorPosition ||
        widget.screenSize != oldWidget.screenSize ||
        widget.objectInfo != oldWidget.objectInfo) {
      _calculatePosition();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _calculatedPosition.dx,
      top: _calculatedPosition.dy,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildTooltipContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTooltipContent() {
    final backgroundColor = _CategoryColors.getPrimaryColor(
      widget.category,
    ).withValues(alpha: 0.9);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 60,
          maxWidth: 120,
          minHeight: 24,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category icon
            Icon(
              _getCategoryIcon(widget.category),
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 4),
            // Concise object info
            Flexible(
              child: Text(
                _getShortObjectInfo(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Confidence indicator if available
            if (widget.categoryConfidence != null) ...[
              const SizedBox(width: 4),
              _buildCompactConfidenceBadge(),
            ],
          ],
        ),
      ),
    );
  }

  /// Get short object info for compact display
  String _getShortObjectInfo() {
    if (widget.objectInfo.isEmpty) return 'Object';

    // Truncate long object names
    if (widget.objectInfo.length > 12) {
      return '${widget.objectInfo.substring(0, 9)}...';
    }
    return widget.objectInfo;
  }

  /// Get category icon
  IconData _getCategoryIcon(WasteCategory category) {
    switch (category) {
      case WasteCategory.recycle:
        return Icons.recycling;
      case WasteCategory.organic:
        return Icons.eco;
      case WasteCategory.ewaste:
        return Icons.electrical_services;
      case WasteCategory.hazardous:
        return Icons.warning;
    }
  }

  /// Build compact confidence badge
  Widget _buildCompactConfidenceBadge() {
    final confidence = widget.categoryConfidence!;
    final confidencePercent = (confidence * 100).round();
    final badgeColor = _getConfidenceColor(confidence);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$confidencePercent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get confidence color
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// Possible tooltip positions relative to the indicator
enum TooltipPosition { above, below, left, right }

/// Result of position calculation
class _PositionResult {
  final TooltipPosition position;
  final Offset offset;
  final bool fitsOnScreen;
  final double overflowAmount;

  const _PositionResult({
    required this.position,
    required this.offset,
    required this.fitsOnScreen,
    required this.overflowAmount,
  });
}
