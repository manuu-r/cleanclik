import 'package:flutter/material.dart';

/// Icon that morphs between different states with smooth transitions
class MorphingIcon extends StatefulWidget {
  final IconData icon;
  final IconData? alternateIcon;
  final bool isAlternate;
  final Color? color;
  final double? size;
  final Duration duration;

  const MorphingIcon({
    super.key,
    required this.icon,
    this.alternateIcon,
    this.isAlternate = false,
    this.color,
    this.size,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<MorphingIcon> createState() => _MorphingIconState();
}

class _MorphingIconState extends State<MorphingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.5, // Half rotation
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
          ),
        );

    if (widget.isAlternate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MorphingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAlternate != oldWidget.isAlternate) {
      if (widget.isAlternate) {
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
        final showAlternate = _controller.value > 0.5;
        final currentIcon = showAlternate
            ? (widget.alternateIcon ?? widget.icon)
            : widget.icon;

        // Calculate scale for the current phase
        double scale;
        if (_controller.value <= 0.5) {
          // Shrinking phase
          scale = 1.0 - (_controller.value * 2);
        } else {
          // Growing phase
          scale = (_controller.value - 0.5) * 2;
        }

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Icon(currentIcon, color: widget.color, size: widget.size),
          ),
        );
      },
    );
  }
}
