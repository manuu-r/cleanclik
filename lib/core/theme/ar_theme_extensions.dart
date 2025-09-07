import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

/// Theme extensions for AR-first design system
@immutable
class ARThemeExtension extends ThemeExtension<ARThemeExtension> {
  final Color neonAccent;
  final Color glowColor;
  final Color glassSurface;
  final Color glassOverlay;
  final double glassOpacity;
  final double neonIntensity;
  final List<BoxShadow> neonGlow;
  final Gradient neonGradient;
  
  const ARThemeExtension({
    required this.neonAccent,
    required this.glowColor,
    required this.glassSurface,
    required this.glassOverlay,
    required this.glassOpacity,
    required this.neonIntensity,
    required this.neonGlow,
    required this.neonGradient,
  });
  
  @override
  ARThemeExtension copyWith({
    Color? neonAccent,
    Color? glowColor,
    Color? glassSurface,
    Color? glassOverlay,
    double? glassOpacity,
    double? neonIntensity,
    List<BoxShadow>? neonGlow,
    Gradient? neonGradient,
  }) {
    return ARThemeExtension(
      neonAccent: neonAccent ?? this.neonAccent,
      glowColor: glowColor ?? this.glowColor,
      glassSurface: glassSurface ?? this.glassSurface,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      neonIntensity: neonIntensity ?? this.neonIntensity,
      neonGlow: neonGlow ?? this.neonGlow,
      neonGradient: neonGradient ?? this.neonGradient,
    );
  }
  
  @override
  ARThemeExtension lerp(ARThemeExtension? other, double t) {
    if (other is! ARThemeExtension) {
      return this;
    }
    
    return ARThemeExtension(
      neonAccent: Color.lerp(neonAccent, other.neonAccent, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t)!,
      glassOpacity: lerpDouble(glassOpacity, other.glassOpacity, t)!,
      neonIntensity: lerpDouble(neonIntensity, other.neonIntensity, t)!,
      neonGlow: BoxShadow.lerpList(neonGlow, other.neonGlow, t)!,
      neonGradient: Gradient.lerp(neonGradient, other.neonGradient, t)!,
    );
  }
  
  static ARThemeExtension light() {
    return const ARThemeExtension(
      neonAccent: NeonColors.electricGreen,
      glowColor: NeonColors.glowGreen,
      glassSurface: Color(0x26FFFFFF), // Colors.white.withOpacity(0.15)
      glassOverlay: Color(0xCCFFFFFF), // Colors.white.withOpacity(0.8)
      glassOpacity: 0.15,
      neonIntensity: 1.0,
      neonGlow: [], // Zero shadows - Material 3 expressive
      neonGradient: LinearGradient(
        colors: [NeonColors.electricGreen, NeonColors.oceanBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
  
  static ARThemeExtension dark() {
    return const ARThemeExtension(
      neonAccent: NeonColors.electricGreen,
      glowColor: NeonColors.glowGreen,
      glassSurface: Color(0x1AFFFFFF), // Colors.white.withOpacity(0.1)
      glassOverlay: Color(0x4D000000), // Colors.black.withOpacity(0.3)
      glassOpacity: 0.1,
      neonIntensity: 1.2,
      neonGlow: [], // Zero shadows - Material 3 expressive
      neonGradient: LinearGradient(
        colors: [NeonColors.electricGreen, NeonColors.oceanBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}

/// Animation theme extension for consistent motion design
@immutable
class AnimationThemeExtension extends ThemeExtension<AnimationThemeExtension> {
  final Duration fastDuration;
  final Duration mediumDuration;
  final Duration slowDuration;
  final Curve defaultCurve;
  final Curve elasticCurve;
  final Curve bounceCurve;
  
  const AnimationThemeExtension({
    required this.fastDuration,
    required this.mediumDuration,
    required this.slowDuration,
    required this.defaultCurve,
    required this.elasticCurve,
    required this.bounceCurve,
  });
  
  @override
  AnimationThemeExtension copyWith({
    Duration? fastDuration,
    Duration? mediumDuration,
    Duration? slowDuration,
    Curve? defaultCurve,
    Curve? elasticCurve,
    Curve? bounceCurve,
  }) {
    return AnimationThemeExtension(
      fastDuration: fastDuration ?? this.fastDuration,
      mediumDuration: mediumDuration ?? this.mediumDuration,
      slowDuration: slowDuration ?? this.slowDuration,
      defaultCurve: defaultCurve ?? this.defaultCurve,
      elasticCurve: elasticCurve ?? this.elasticCurve,
      bounceCurve: bounceCurve ?? this.bounceCurve,
    );
  }
  
  @override
  AnimationThemeExtension lerp(AnimationThemeExtension? other, double t) {
    if (other is! AnimationThemeExtension) {
      return this;
    }
    
    return AnimationThemeExtension(
      fastDuration: lerpDuration(fastDuration, other.fastDuration, t),
      mediumDuration: lerpDuration(mediumDuration, other.mediumDuration, t),
      slowDuration: lerpDuration(slowDuration, other.slowDuration, t),
      defaultCurve: other.defaultCurve, // Curves don't lerp well
      elasticCurve: other.elasticCurve,
      bounceCurve: other.bounceCurve,
    );
  }
  
  static AnimationThemeExtension standard() {
    return const AnimationThemeExtension(
      fastDuration: Duration(milliseconds: 200),
      mediumDuration: Duration(milliseconds: 300),
      slowDuration: Duration(milliseconds: 500),
      defaultCurve: Curves.easeOutCubic,
      elasticCurve: Curves.elasticOut,
      bounceCurve: Curves.bounceOut,
    );
  }
}

/// Helper functions for theme extensions
extension ThemeDataExtensions on ThemeData {
  ARThemeExtension get arTheme => extension<ARThemeExtension>()!;
  AnimationThemeExtension get animationTheme => extension<AnimationThemeExtension>()!;
}

/// Helper functions for lerping
double lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

Duration lerpDuration(Duration a, Duration b, double t) {
  return Duration(
    microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
  );
}