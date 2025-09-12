import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/app_theme.dart';

/// Glass level enum for different opacity tiers
enum GlassLevel {
  /// Primary level - highest opacity (0.35) for most important content
  primary(UIConstants.glassPrimaryOpacity),
  /// Secondary level - medium opacity (0.25) for secondary content
  secondary(UIConstants.glassSecondaryOpacity),
  /// Tertiary level - lowest opacity (0.15) for background elements
  tertiary(UIConstants.glassTertiaryOpacity);

  const GlassLevel(this.opacity);
  final double opacity;
}

/// Enhanced glassmorphism container with improved opacity and reusable components
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? opacity;
  final double blurRadius;
  final Border? border;
  final GlassLevel level;
  final bool hasGlow;
  final bool responsiveOpacity;

  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.opacity,
    this.blurRadius = UIConstants.glassEnhancedBlurRadius,
    this.border,
    this.level = GlassLevel.secondary,
    this.hasGlow = false,
    this.responsiveOpacity = true,
  });

  /// Creates a primary level glassmorphism container for high importance content
  const GlassmorphismContainer.primary({
    super.key,
    required this.child,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.opacity,
    this.blurRadius = UIConstants.glassEnhancedBlurRadius,
    this.border,
    this.hasGlow = true,
    this.responsiveOpacity = true,
  }) : level = GlassLevel.primary;

  /// Creates a secondary level glassmorphism container for medium importance content
  const GlassmorphismContainer.secondary({
    super.key,
    required this.child,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.opacity,
    this.blurRadius = UIConstants.glassEnhancedBlurRadius,
    this.border,
    this.hasGlow = false,
    this.responsiveOpacity = true,
  }) : level = GlassLevel.secondary;

  /// Creates a tertiary level glassmorphism container for background elements
  const GlassmorphismContainer.tertiary({
    super.key,
    required this.child,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.opacity,
    this.blurRadius = UIConstants.glassBlurRadius,
    this.border,
    this.hasGlow = false,
    this.responsiveOpacity = false,
  }) : level = GlassLevel.tertiary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate effective opacity based on level and responsive settings
    final effectiveOpacity = _calculateEffectiveOpacity(context);
    
    // Enhanced border opacity for better contrast
    final borderOpacity = level == GlassLevel.primary 
        ? UIConstants.glassEnhancedBorderOpacity 
        : UIConstants.glassBorderOpacity;

    final defaultBackgroundColor = isDark
        ? Colors.white.withValues(alpha: effectiveOpacity)
        : Colors.white.withValues(alpha: effectiveOpacity * 1.2);

    final borderRadius = this.borderRadius ?? BorderRadius.circular(UIConstants.radiusXLarge);

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBackgroundColor,
              borderRadius: borderRadius,
              border: border ?? _buildEnhancedBorder(borderOpacity, isDark),
              gradient: _buildEnhancedGradient(effectiveOpacity, isDark),
              boxShadow: hasGlow ? _buildGlowEffect(isDark) : null,
            ),
            child: child,
          ),
        ),
      ),
    );

    return container;
  }

  /// Calculates effective opacity based on level, responsive settings, and context
  double _calculateEffectiveOpacity(BuildContext context) {
    double baseOpacity = opacity ?? level.opacity;
    
    if (!responsiveOpacity) return baseOpacity;
    
    // Responsive opacity based on content importance and screen size
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 600;
    
    // Adjust opacity for larger screens (slightly more transparent)
    if (isLargeScreen && level != GlassLevel.primary) {
      baseOpacity *= 0.9;
    }
    
    // Ensure opacity stays within acceptable range
    return baseOpacity.clamp(0.1, 0.4);
  }

  /// Builds enhanced border with improved contrast
  Border _buildEnhancedBorder(double borderOpacity, bool isDark) {
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: borderOpacity)
        : Colors.white.withValues(alpha: borderOpacity * 0.8);
        
    return Border.all(
      color: borderColor,
      width: level == GlassLevel.primary ? 1.5 : 1.0,
    );
  }

  /// Builds enhanced gradient with better depth perception
  LinearGradient _buildEnhancedGradient(double effectiveOpacity, bool isDark) {
    final gradientColors = isDark
        ? [
            Colors.white.withValues(alpha: effectiveOpacity * 0.9),
            Colors.white.withValues(alpha: effectiveOpacity * 0.4),
            Colors.white.withValues(alpha: effectiveOpacity * 0.1),
          ]
        : [
            Colors.white.withValues(alpha: effectiveOpacity * 1.1),
            Colors.white.withValues(alpha: effectiveOpacity * 0.6),
            Colors.white.withValues(alpha: effectiveOpacity * 0.2),
          ];

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
      colors: gradientColors,
    );
  }

  /// Builds subtle glow effect for primary level containers
  List<BoxShadow> _buildGlowEffect(bool isDark) {
    if (!hasGlow) return [];
    
    final glowColor = isDark 
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.2);
        
    return [
      BoxShadow(
        color: glowColor,
        blurRadius: 8.0,
        spreadRadius: 0.0,
        offset: const Offset(0, 0),
      ),
    ];
  }
}
