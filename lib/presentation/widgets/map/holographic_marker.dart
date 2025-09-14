import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'dart:math' as math;

class HolographicMarker extends StatefulWidget {
  final String category;
  final double? distance;
  final bool isSimple;

  const HolographicMarker({
    super.key,
    required this.category,
    this.distance,
    this.isSimple = false,
  });

  @override
  State<HolographicMarker> createState() => _HolographicMarkerState();
}

class _HolographicMarkerState extends State<HolographicMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(widget.category);
    final icon = _getCategoryIcon(widget.category);

    if (widget.isSimple) {
      return Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: color.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          child: CustomPaint(
            painter: _HolographicPainter(color, _controller),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  if (widget.distance != null && widget.distance! < 1000)
                    Text(
                      '${widget.distance!.round()}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
        return NeonColors.electricGreen;
      case 'organic':
        return NeonColors.earthOrange;
      case 'ewaste':
        return NeonColors.oceanBlue;
      case 'hazardous':
        return NeonColors.toxicPurple;
      case 'landfill':
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'ewaste':
        return Icons.electrical_services;
      case 'hazardous':
        return Icons.warning;
      case 'landfill':
      default:
        return Icons.delete;
    }
  }
}

class _HolographicPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  _HolographicPainter(this.color, this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.8),
          color.withOpacity(0.2),
        ],
        stops: [0.0, 0.5, 1.0],
        transform: GradientRotation(animation.value * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, gradientPaint);

    final innerPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.8, innerPaint);

    // Add rotating arcs
    final arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      animation.value * 2 * math.pi,
      math.pi / 2,
      false,
      arcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.7),
      -animation.value * 2 * math.pi,
      math.pi / 2,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HolographicPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}
