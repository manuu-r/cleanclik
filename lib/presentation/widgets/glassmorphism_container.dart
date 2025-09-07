import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/constants/ui_constants.dart';

/// Glassmorphism container with frosted glass effect
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double opacity;
  final double blurRadius;
  final Border? border;
  
  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.opacity = UIConstants.glassOpacity,
    this.blurRadius = UIConstants.glassBlurRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final defaultBackgroundColor = isDark 
        ? Colors.white.withOpacity(opacity)
        : Colors.white.withOpacity(opacity * 1.5);
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurRadius,
            sigmaY: blurRadius,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBackgroundColor,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ?? Border.all(
                color: Colors.white.withOpacity(UIConstants.glassBorderOpacity),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity * 0.8),
                  Colors.white.withOpacity(opacity * 0.3),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}