import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cleanclik/core/constants/ui_constants.dart';

/// Circular progress ring with neon glow effects
class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? backgroundColor;
  final Widget? child;
  final bool animated;
  final Duration animationDuration;
  final bool showGlow;
  final String? label;
  
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = UIConstants.progressRingSize,
    this.strokeWidth = UIConstants.progressRingStrokeWidth,
    required this.color,
    this.backgroundColor,
    this.child,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.showGlow = true,
    this.label,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    if (widget.animated) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      
      if (widget.animated) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? 
        theme.colorScheme.outline.withOpacity(0.2);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Material 3 surface treatment (no glow effect)
          
          // Progress ring
          AnimatedBuilder(
            animation: widget.animated ? _progressAnimation : 
                AlwaysStoppedAnimation(widget.progress),
            builder: (context, child) {
              final progress = widget.animated ? 
                  _progressAnimation.value : widget.progress;
              
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: progress,
                  strokeWidth: widget.strokeWidth,
                  color: widget.color,
                  backgroundColor: backgroundColor,
                ),
              );
            },
          ),
          
          // Center content
          if (widget.child != null)
            widget.child!
          else if (widget.label != null)
            Text(
              widget.label!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: widget.color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      // Add gradient effect
      final rect = Rect.fromCircle(center: center, radius: radius);
      progressPaint.shader = SweepGradient(
        colors: [
          color.withOpacity(0.3),
          color,
          color,
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
      ).createShader(rect);
      
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start from top
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}