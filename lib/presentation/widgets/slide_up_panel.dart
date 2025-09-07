import 'package:flutter/material.dart';
import 'package:cleanclik/core/constants/ui_constants.dart';
import 'package:cleanclik/presentation/widgets/glassmorphism_container.dart';

/// Slide-up panel that doesn't obstruct AR view
class SlideUpPanel extends StatefulWidget {
  final Widget child;
  final double minHeight;
  final double maxHeight;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final String? title;
  final List<Widget>? actions;
  final bool showHandle;
  
  const SlideUpPanel({
    super.key,
    required this.child,
    this.minHeight = UIConstants.bottomPanelMinHeight,
    this.maxHeight = UIConstants.bottomPanelMaxHeight,
    this.isExpanded = false,
    this.onToggle,
    this.title,
    this.actions,
    this.showHandle = true,
  });

  @override
  State<SlideUpPanel> createState() => _SlideUpPanelState();
}

class _SlideUpPanelState extends State<SlideUpPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _borderRadiusAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _heightAnimation = Tween<double>(
      begin: widget.minHeight,
      end: widget.maxHeight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _borderRadiusAnimation = Tween<double>(
      begin: 24.0,
      end: 16.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    if (widget.isExpanded) {
      _controller.forward();
    }
  }
  
  @override
  void didUpdateWidget(SlideUpPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
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
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: widget.onToggle,
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: _handleDragEnd,
            child: GlassmorphismContainer(
              height: _heightAnimation.value,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_borderRadiusAnimation.value),
                topRight: Radius.circular(_borderRadiusAnimation.value),
              ),
              child: Column(
                children: [
                  // Handle and header
                  _buildHeader(),
                  
                  // Content
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_borderRadiusAnimation.value),
                        topRight: Radius.circular(_borderRadiusAnimation.value),
                      ),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Drag handle
          if (widget.showHandle)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          
          // Title and actions
          if (widget.title != null || widget.actions != null)
            Row(
              children: [
                if (widget.title != null)
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                
                if (widget.actions != null)
                  ...widget.actions!,
              ],
            ),
        ],
      ),
    );
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    final newValue = _controller.value - (delta / (widget.maxHeight - widget.minHeight));
    _controller.value = newValue.clamp(0.0, 1.0);
  }
  
  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    
    if (velocity > 300) {
      // Fast downward swipe - collapse
      _controller.reverse();
      widget.onToggle?.call();
    } else if (velocity < -300) {
      // Fast upward swipe - expand
      _controller.forward();
      widget.onToggle?.call();
    } else {
      // Slow drag - snap to nearest state
      if (_controller.value > 0.5) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onToggle?.call();
    }
  }
}