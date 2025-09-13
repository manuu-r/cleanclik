import 'package:flutter/material.dart';
import '../../../core/models/object_indicator_data.dart';
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

  static Color getAnimatedColor(WasteCategory category, double animationValue, {bool isPulsing = false}) {
    final baseColor = getPrimaryColor(category);
    if (isPulsing) {
      final opacity = 0.6 + (0.4 * animationValue);
      return baseColor.withValues(alpha: opacity);
    }
    return baseColor;
  }
}

/// Widget that renders different types of object indicators with animations
class IndicatorWidget extends StatefulWidget {
  final ObjectIndicatorData indicatorData;
  final double opacity;
  final bool enableAnimations;
  final VoidCallback? onTap;

  const IndicatorWidget({
    super.key,
    required this.indicatorData,
    this.opacity = 0.8,
    this.enableAnimations = true,
    this.onTap,
  });

  @override
  State<IndicatorWidget> createState() => _IndicatorWidgetState();
}

class _IndicatorWidgetState extends State<IndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _colorShiftController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _colorShiftAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.enableAnimations) {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    // Pulse animation for pulsating circle
    _pulseController = AnimationController(
      duration: widget.indicatorData.getAnimationDuration(),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Glow animation for glowing dot
    _glowController = AnimationController(
      duration: Duration(
        milliseconds: widget.indicatorData.getAnimationDuration().inMilliseconds + 500,
      ),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Color shift animation for all types
    _colorShiftController = AnimationController(
      duration: Duration(
        milliseconds: widget.indicatorData.getAnimationDuration().inMilliseconds * 2,
      ),
      vsync: this,
    );
    _colorShiftAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorShiftController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    switch (widget.indicatorData.type) {
      case IndicatorType.pulsatingCircle:
        _pulseController.repeat(reverse: true);
        _colorShiftController.repeat(reverse: true);
        break;
      case IndicatorType.glowingDot:
        _glowController.repeat(reverse: true);
        _colorShiftController.repeat(reverse: true);
        break;
      case IndicatorType.targetReticle:
        // Minimal animation for target reticle
        _colorShiftController.repeat(reverse: true);
        break;
    }
  }

  void _stopAnimations() {
    _pulseController.stop();
    _glowController.stop();
    _colorShiftController.stop();
  }

  @override
  void didUpdateWidget(IndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.enableAnimations != oldWidget.enableAnimations) {
      if (widget.enableAnimations) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _colorShiftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.indicatorData.isVisible) {
      return const SizedBox.shrink();
    }

    final size = widget.indicatorData.getIndicatorSize();
    
    return Positioned(
      left: widget.indicatorData.centerPosition.dx - size / 2,
      top: widget.indicatorData.centerPosition.dy - size / 2,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: _buildIndicatorContent(),
        ),
      ),
    );
  }

  Widget _buildIndicatorContent() {
    switch (widget.indicatorData.type) {
      case IndicatorType.pulsatingCircle:
        return _buildPulsatingCircle();
      case IndicatorType.glowingDot:
        return _buildGlowingDot();
      case IndicatorType.targetReticle:
        return _buildTargetReticle();
    }
  }

  Widget _buildPulsatingCircle() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _colorShiftAnimation]),
      builder: (context, child) {
        final scale = widget.enableAnimations ? _pulseAnimation.value : 1.0;
        final colorValue = widget.enableAnimations ? _colorShiftAnimation.value : 0.0;
        
        final animatedColor = _CategoryColors.getAnimatedColor(
          widget.indicatorData.category,
          colorValue,
          isPulsing: true,
        );

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: animatedColor.withValues(alpha: widget.opacity * 0.9),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _CategoryColors.getPrimaryColor(
                    widget.indicatorData.category,
                  ),
                  blurRadius: 6.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: widget.indicatorData.getIndicatorSize() * 0.6,
                height: widget.indicatorData.getIndicatorSize() * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: animatedColor.withValues(alpha: widget.opacity),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowingDot() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _colorShiftAnimation]),
      builder: (context, child) {
        final glowIntensity = widget.enableAnimations ? _glowAnimation.value : 0.7;
        final colorValue = widget.enableAnimations ? _colorShiftAnimation.value : 0.0;
        
        final baseColor = _CategoryColors.getPrimaryColor(widget.indicatorData.category);
        final gradientColors = [
          baseColor.withValues(alpha: glowIntensity * 0.8),
          baseColor.withValues(alpha: glowIntensity * 0.4),
          baseColor.withValues(alpha: 0.0),
        ];

        final animatedColor = _CategoryColors.getAnimatedColor(
          widget.indicatorData.category,
          colorValue,
          isPulsing: false,
        );

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                animatedColor.withValues(alpha: widget.opacity),
                ...gradientColors.map((c) => c.withValues(alpha: widget.opacity * 0.7)),
              ],
              stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: _CategoryColors.getPrimaryColor(widget.indicatorData.category)
                    .withValues(alpha: widget.opacity * glowIntensity * 0.5),
                blurRadius: 8.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetReticle() {
    return AnimatedBuilder(
      animation: _colorShiftAnimation,
      builder: (context, child) {
        final colorValue = widget.enableAnimations ? _colorShiftAnimation.value : 0.0;
        
        final animatedColor = _CategoryColors.getAnimatedColor(
          widget.indicatorData.category,
          colorValue * 0.3, // Subtle color shift for target reticle
          isPulsing: true,
        );

        return CustomPaint(
          size: Size(
            widget.indicatorData.getIndicatorSize(),
            widget.indicatorData.getIndicatorSize(),
          ),
          painter: _TargetReticlePainter(
            color: animatedColor,
            opacity: widget.opacity,
            animationValue: colorValue,
          ),
        );
      },
    );
  }
}

/// Custom painter for target reticle indicator with animation support
class _TargetReticlePainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double animationValue;

  _TargetReticlePainter({
    required this.color,
    required this.opacity,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Animate the crosshair length slightly
    final crosshairLength = radius * (0.6 + animationValue * 0.1);

    // Draw outer circle
    canvas.drawCircle(center, radius, paint);

    // Draw inner circle (animated size)
    final innerRadius = radius * (0.3 + animationValue * 0.1);
    canvas.drawCircle(center, innerRadius, paint);

    // Draw crosshairs
    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - crosshairLength, center.dy),
      Offset(center.dx + crosshairLength, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairLength),
      Offset(center.dx, center.dy + crosshairLength),
      paint,
    );

    // Draw center dot with animated size
    paint.style = PaintingStyle.fill;
    final centerDotRadius = 2.0 + animationValue * 0.5;
    canvas.drawCircle(center, centerDotRadius, paint);

    // Add subtle corner markers
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;
    final cornerLength = radius * 0.2;
    final cornerOffset = radius * 0.7;

    // Top-left corner
    canvas.drawLine(
      Offset(center.dx - cornerOffset, center.dy - cornerOffset),
      Offset(center.dx - cornerOffset + cornerLength, center.dy - cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - cornerOffset, center.dy - cornerOffset),
      Offset(center.dx - cornerOffset, center.dy - cornerOffset + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(center.dx + cornerOffset, center.dy - cornerOffset),
      Offset(center.dx + cornerOffset - cornerLength, center.dy - cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + cornerOffset, center.dy - cornerOffset),
      Offset(center.dx + cornerOffset, center.dy - cornerOffset + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(center.dx - cornerOffset, center.dy + cornerOffset),
      Offset(center.dx - cornerOffset + cornerLength, center.dy + cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - cornerOffset, center.dy + cornerOffset),
      Offset(center.dx - cornerOffset, center.dy + cornerOffset - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(center.dx + cornerOffset, center.dy + cornerOffset),
      Offset(center.dx + cornerOffset - cornerLength, center.dy + cornerOffset),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + cornerOffset, center.dy + cornerOffset),
      Offset(center.dx + cornerOffset, center.dy + cornerOffset - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _TargetReticlePainter ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.animationValue != animationValue;
  }
}