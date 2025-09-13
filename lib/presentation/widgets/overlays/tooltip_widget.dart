import 'package:flutter/material.dart';
import '../../../core/models/waste_category.dart';

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

/// Widget that displays informative tooltips with smart positioning and animations
class TooltipWidget extends StatefulWidget {
  final WasteCategory category;
  final String objectInfo;
  final Offset indicatorPosition;
  final Size screenSize;
  final bool isVisible;
  final Duration animationDuration;
  final VoidCallback? onTap;

  const TooltipWidget({
    super.key,
    required this.category,
    required this.objectInfo,
    required this.indicatorPosition,
    required this.screenSize,
    this.isVisible = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onTap,
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
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
    // Estimate size based on text length and typical font metrics
    const double charWidth = 8.0;
    const double lineHeight = 20.0;
    const double padding = 16.0;
    const double maxWidth = 200.0;
    
    final textWidth = text.length * charWidth;
    final width = (textWidth + padding).clamp(80.0, maxWidth);
    
    // Calculate number of lines needed
    final lines = (textWidth / (maxWidth - padding)).ceil().clamp(1, 3);
    final height = (lines * lineHeight) + padding;
    
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
      _tryPosition(TooltipPosition.above, indicatorPos, tooltipSize, screenSize, margin, indicatorOffset),
      _tryPosition(TooltipPosition.below, indicatorPos, tooltipSize, screenSize, margin, indicatorOffset),
      _tryPosition(TooltipPosition.right, indicatorPos, tooltipSize, screenSize, margin, indicatorOffset),
      _tryPosition(TooltipPosition.left, indicatorPos, tooltipSize, screenSize, margin, indicatorOffset),
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
    final fitsOnScreen = adjustedOffset.dx >= margin &&
        adjustedOffset.dy >= margin &&
        adjustedOffset.dx + tooltipSize.width <= screenSize.width - margin &&
        adjustedOffset.dy + tooltipSize.height <= screenSize.height - margin;
    
    // Calculate overflow amount for ranking
    double overflowAmount = 0.0;
    if (adjustedOffset.dx < margin) overflowAmount += margin - adjustedOffset.dx;
    if (adjustedOffset.dy < margin) overflowAmount += margin - adjustedOffset.dy;
    if (adjustedOffset.dx + tooltipSize.width > screenSize.width - margin) {
      overflowAmount += (adjustedOffset.dx + tooltipSize.width) - (screenSize.width - margin);
    }
    if (adjustedOffset.dy + tooltipSize.height > screenSize.height - margin) {
      overflowAmount += (adjustedOffset.dy + tooltipSize.height) - (screenSize.height - margin);
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
    final backgroundColor = _CategoryColors.getPrimaryColor(widget.category).withValues(alpha: 0.9);
    final textColor = Colors.white;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 80,
          maxWidth: 200,
          minHeight: 32,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: _CategoryColors.getPrimaryColor(widget.category).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.codeName,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (widget.objectInfo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.objectInfo,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Possible tooltip positions relative to the indicator
enum TooltipPosition {
  above,
  below,
  left,
  right,
}

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

/// Manages multiple tooltips to prevent overlaps
class TooltipManager {
  static final List<Rect> _activeTooltipBounds = [];
  static const double _minDistance = 8.0;

  /// Check if a tooltip position conflicts with existing tooltips
  static bool hasConflict(Offset position, Size size) {
    final newBounds = Rect.fromLTWH(
      position.dx - _minDistance,
      position.dy - _minDistance,
      size.width + (_minDistance * 2),
      size.height + (_minDistance * 2),
    );

    return _activeTooltipBounds.any((bounds) => bounds.overlaps(newBounds));
  }

  /// Register a tooltip's bounds
  static void registerTooltip(Offset position, Size size) {
    final bounds = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    _activeTooltipBounds.add(bounds);
  }

  /// Unregister a tooltip's bounds
  static void unregisterTooltip(Offset position, Size size) {
    final bounds = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    _activeTooltipBounds.removeWhere((b) => b == bounds);
  }

  /// Clear all registered tooltips
  static void clearAll() {
    _activeTooltipBounds.clear();
  }

  /// Get adjusted position to avoid conflicts
  static Offset getAdjustedPosition(
    Offset preferredPosition,
    Size tooltipSize,
    Size screenSize,
  ) {
    if (!hasConflict(preferredPosition, tooltipSize)) {
      return preferredPosition;
    }

    // Try nearby positions
    const double step = 16.0;
    final positions = [
      preferredPosition.translate(0, -step),
      preferredPosition.translate(0, step),
      preferredPosition.translate(-step, 0),
      preferredPosition.translate(step, 0),
      preferredPosition.translate(-step, -step),
      preferredPosition.translate(step, -step),
      preferredPosition.translate(-step, step),
      preferredPosition.translate(step, step),
    ];

    for (final position in positions) {
      if (!hasConflict(position, tooltipSize) &&
          position.dx >= 0 &&
          position.dy >= 0 &&
          position.dx + tooltipSize.width <= screenSize.width &&
          position.dy + tooltipSize.height <= screenSize.height) {
        return position;
      }
    }

    // If no good position found, return original
    return preferredPosition;
  }
}