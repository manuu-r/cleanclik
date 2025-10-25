import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Particle system for success animations
class ParticleSystem extends StatefulWidget {
  final ParticleType type;
  final bool isActive;
  final Duration duration;
  final int particleCount;
  final Color color;

  const ParticleSystem({
    super.key,
    required this.type,
    this.isActive = false,
    this.duration = const Duration(milliseconds: 1500),
    this.particleCount = 20,
    this.color = Colors.green,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

enum ParticleType { leaves, sparks, waterDrops, confetti, stars }

class _ParticleSystemState extends State<ParticleSystem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _initializeParticles();

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ParticleSystem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initializeParticles();
        _controller.reset();
        _controller.forward();
      } else {
        _controller.stop();
      }
    }

    if (widget.type != oldWidget.type ||
        widget.particleCount != oldWidget.particleCount) {
      _initializeParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        type: widget.type,
        startX: random.nextDouble(),
        startY: random.nextDouble(),
        velocityX: (random.nextDouble() - 0.5) * 2,
        velocityY: random.nextDouble() * -2 - 1,
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 4,
        scale: random.nextDouble() * 0.5 + 0.5,
        color: _getParticleColor(random),
        delay: random.nextDouble() * 0.3,
      );
    });
  }

  Color _getParticleColor(math.Random random) {
    switch (widget.type) {
      case ParticleType.leaves:
        final colors = [Colors.green, Colors.lightGreen, Colors.teal];
        return colors[random.nextInt(colors.length)];
      case ParticleType.sparks:
        final colors = [Colors.orange, Colors.yellow, Colors.red];
        return colors[random.nextInt(colors.length)];
      case ParticleType.waterDrops:
        final colors = [Colors.blue, Colors.lightBlue, Colors.cyan];
        return colors[random.nextInt(colors.length)];
      case ParticleType.confetti:
        final colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
        ];
        return colors[random.nextInt(colors.length)];
      case ParticleType.stars:
        return Colors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  final ParticleType type;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final double scale;
  final Color color;
  final double delay;

  Particle({
    required this.type,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.scale,
    required this.color,
    required this.delay,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final adjustedProgress = math.max(0.0, progress - particle.delay);
      if (adjustedProgress <= 0) continue;

      final x =
          size.width * particle.startX +
          particle.velocityX * size.width * 0.3 * adjustedProgress;
      final y =
          size.height * particle.startY +
          particle.velocityY * size.height * 0.5 * adjustedProgress;

      final currentRotation =
          particle.rotation +
          particle.rotationSpeed * adjustedProgress * 2 * math.pi;

      final opacity = (1.0 - adjustedProgress).clamp(0.0, 1.0);
      final currentScale = particle.scale * (1.0 - adjustedProgress * 0.5);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation);
      canvas.scale(currentScale);

      _drawParticle(canvas, particle, opacity);

      canvas.restore();
    }
  }

  void _drawParticle(Canvas canvas, Particle particle, double opacity) {
    final paint = Paint()
      ..color = particle.color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    switch (particle.type) {
      case ParticleType.leaves:
        _drawLeaf(canvas, paint);
        break;
      case ParticleType.sparks:
        _drawSpark(canvas, paint);
        break;
      case ParticleType.waterDrops:
        _drawWaterDrop(canvas, paint);
        break;
      case ParticleType.confetti:
        _drawConfetti(canvas, paint);
        break;
      case ParticleType.stars:
        _drawStar(canvas, paint);
        break;
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(0, -8);
    path.quadraticBezierTo(4, -4, 0, 0);
    path.quadraticBezierTo(-4, -4, 0, -8);
    canvas.drawPath(path, paint);
  }

  void _drawSpark(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(0, -6);
    path.lineTo(1, -1);
    path.lineTo(6, 0);
    path.lineTo(1, 1);
    path.lineTo(0, 6);
    path.lineTo(-1, 1);
    path.lineTo(-6, 0);
    path.lineTo(-1, -1);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawWaterDrop(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(0, -6);
    path.quadraticBezierTo(3, -3, 3, 0);
    path.quadraticBezierTo(3, 3, 0, 3);
    path.quadraticBezierTo(-3, 3, -3, 0);
    path.quadraticBezierTo(-3, -3, 0, -6);
    canvas.drawPath(path, paint);
  }

  void _drawConfetti(Canvas canvas, Paint paint) {
    canvas.drawRect(const Rect.fromLTWH(-3, -1, 6, 2), paint);
  }

  void _drawStar(Canvas canvas, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5 - math.pi / 2;
      final x = math.cos(angle) * 4;
      final y = math.sin(angle) * 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      final innerAngle = (i + 0.5) * 2 * math.pi / 5 - math.pi / 2;
      final innerX = math.cos(innerAngle) * 2;
      final innerY = math.sin(innerAngle) * 2;
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
