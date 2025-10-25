import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

class PingAnimation extends StatelessWidget {
  final LatLng center;
  final AnimationController controller;

  const PingAnimation({
    super.key,
    required this.center,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0, end: 1).animate(controller);
    final map = MapCamera.of(context);
    return CustomPaint(painter: _PingPainter(animation, center, map));
  }
}

class _PingPainter extends CustomPainter {
  final Animation<double> animation;
  final LatLng center;
  final MapCamera map;

  _PingPainter(this.animation, this.center, this.map)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final centerOffset = map.getOffsetFromOrigin(center);
    final radius = (animation.value * 150) * (map.zoom / 15);

    final paint = Paint()
      ..color = NeonColors.electricGreen.withOpacity(1 - animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(centerOffset, radius, paint);
  }

  @override
  bool shouldRepaint(_PingPainter oldDelegate) {
    return animation != oldDelegate.animation ||
        center != oldDelegate.center ||
        map != oldDelegate.map;
  }
}
