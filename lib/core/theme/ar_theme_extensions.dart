import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

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
      neonAccent: Color.lerp(neonAccent, other.neonAccent, t) ?? neonAccent,
      glowColor: Color.lerp(glowColor, other.glowColor, t) ?? glowColor,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t) ?? glassSurface,
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t) ?? glassOverlay,
      glassOpacity: lerpDouble(glassOpacity, other.glassOpacity, t),
      neonIntensity: lerpDouble(neonIntensity, other.neonIntensity, t),
      neonGlow: BoxShadow.lerpList(neonGlow, other.neonGlow, t) ?? neonGlow,
      neonGradient: Gradient.lerp(neonGradient, other.neonGradient, t) ?? neonGradient,
    );
  }

  static ARThemeExtension light() {
    return const ARThemeExtension(
      neonAccent: NeonColors.electricGreen,
      glowColor: NeonColors.glowGreen,
      glassSurface: Color(0x40FFFFFF), // Enhanced opacity (0.25)
      glassOverlay: Color(0xCCFFFFFF), // Colors.white.withOpacity(0.8)
      glassOpacity: 0.25, // Enhanced from 0.15 to 0.25
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
      glassSurface: Color(0x33FFFFFF), // Enhanced opacity (0.2)
      glassOverlay: Color(0x4D000000), // Colors.black.withOpacity(0.3)
      glassOpacity: 0.2, // Enhanced from 0.1 to 0.2
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

/// Enhanced animation theme extension for Material 3 motion design system
@immutable
class AnimationThemeExtension extends ThemeExtension<AnimationThemeExtension> {
  // Legacy durations (kept for compatibility)
  final Duration fastDuration;
  final Duration mediumDuration;
  final Duration slowDuration;
  
  // Material 3 Motion Durations
  final Duration motionShort1;
  final Duration motionShort2;
  final Duration motionShort3;
  final Duration motionShort4;
  final Duration motionMedium1;
  final Duration motionMedium2;
  final Duration motionMedium3;
  final Duration motionMedium4;
  final Duration motionLong1;
  final Duration motionLong2;
  final Duration motionLong3;
  final Duration motionLong4;
  
  // Material 3 Easing Curves
  final Curve defaultCurve;
  final Curve elasticCurve;
  final Curve bounceCurve;
  final Curve standardEasing;
  final Curve decelerateEasing;
  final Curve accelerateEasing;
  final Curve emphasizedEasing;
  
  // Specialized animation curves
  final Curve breathingCurve;
  final Curve morphingCurve;
  final Curve particleCurve;
  final Curve microInteractionCurve;

  const AnimationThemeExtension({
    required this.fastDuration,
    required this.mediumDuration,
    required this.slowDuration,
    required this.motionShort1,
    required this.motionShort2,
    required this.motionShort3,
    required this.motionShort4,
    required this.motionMedium1,
    required this.motionMedium2,
    required this.motionMedium3,
    required this.motionMedium4,
    required this.motionLong1,
    required this.motionLong2,
    required this.motionLong3,
    required this.motionLong4,
    required this.defaultCurve,
    required this.elasticCurve,
    required this.bounceCurve,
    required this.standardEasing,
    required this.decelerateEasing,
    required this.accelerateEasing,
    required this.emphasizedEasing,
    required this.breathingCurve,
    required this.morphingCurve,
    required this.particleCurve,
    required this.microInteractionCurve,
  });

  @override
  AnimationThemeExtension copyWith({
    Duration? fastDuration,
    Duration? mediumDuration,
    Duration? slowDuration,
    Duration? motionShort1,
    Duration? motionShort2,
    Duration? motionShort3,
    Duration? motionShort4,
    Duration? motionMedium1,
    Duration? motionMedium2,
    Duration? motionMedium3,
    Duration? motionMedium4,
    Duration? motionLong1,
    Duration? motionLong2,
    Duration? motionLong3,
    Duration? motionLong4,
    Curve? defaultCurve,
    Curve? elasticCurve,
    Curve? bounceCurve,
    Curve? standardEasing,
    Curve? decelerateEasing,
    Curve? accelerateEasing,
    Curve? emphasizedEasing,
    Curve? breathingCurve,
    Curve? morphingCurve,
    Curve? particleCurve,
    Curve? microInteractionCurve,
  }) {
    return AnimationThemeExtension(
      fastDuration: fastDuration ?? this.fastDuration,
      mediumDuration: mediumDuration ?? this.mediumDuration,
      slowDuration: slowDuration ?? this.slowDuration,
      motionShort1: motionShort1 ?? this.motionShort1,
      motionShort2: motionShort2 ?? this.motionShort2,
      motionShort3: motionShort3 ?? this.motionShort3,
      motionShort4: motionShort4 ?? this.motionShort4,
      motionMedium1: motionMedium1 ?? this.motionMedium1,
      motionMedium2: motionMedium2 ?? this.motionMedium2,
      motionMedium3: motionMedium3 ?? this.motionMedium3,
      motionMedium4: motionMedium4 ?? this.motionMedium4,
      motionLong1: motionLong1 ?? this.motionLong1,
      motionLong2: motionLong2 ?? this.motionLong2,
      motionLong3: motionLong3 ?? this.motionLong3,
      motionLong4: motionLong4 ?? this.motionLong4,
      defaultCurve: defaultCurve ?? this.defaultCurve,
      elasticCurve: elasticCurve ?? this.elasticCurve,
      bounceCurve: bounceCurve ?? this.bounceCurve,
      standardEasing: standardEasing ?? this.standardEasing,
      decelerateEasing: decelerateEasing ?? this.decelerateEasing,
      accelerateEasing: accelerateEasing ?? this.accelerateEasing,
      emphasizedEasing: emphasizedEasing ?? this.emphasizedEasing,
      breathingCurve: breathingCurve ?? this.breathingCurve,
      morphingCurve: morphingCurve ?? this.morphingCurve,
      particleCurve: particleCurve ?? this.particleCurve,
      microInteractionCurve: microInteractionCurve ?? this.microInteractionCurve,
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
      motionShort1: lerpDuration(motionShort1, other.motionShort1, t),
      motionShort2: lerpDuration(motionShort2, other.motionShort2, t),
      motionShort3: lerpDuration(motionShort3, other.motionShort3, t),
      motionShort4: lerpDuration(motionShort4, other.motionShort4, t),
      motionMedium1: lerpDuration(motionMedium1, other.motionMedium1, t),
      motionMedium2: lerpDuration(motionMedium2, other.motionMedium2, t),
      motionMedium3: lerpDuration(motionMedium3, other.motionMedium3, t),
      motionMedium4: lerpDuration(motionMedium4, other.motionMedium4, t),
      motionLong1: lerpDuration(motionLong1, other.motionLong1, t),
      motionLong2: lerpDuration(motionLong2, other.motionLong2, t),
      motionLong3: lerpDuration(motionLong3, other.motionLong3, t),
      motionLong4: lerpDuration(motionLong4, other.motionLong4, t),
      defaultCurve: other.defaultCurve, // Curves don't lerp well
      elasticCurve: other.elasticCurve,
      bounceCurve: other.bounceCurve,
      standardEasing: other.standardEasing,
      decelerateEasing: other.decelerateEasing,
      accelerateEasing: other.accelerateEasing,
      emphasizedEasing: other.emphasizedEasing,
      breathingCurve: other.breathingCurve,
      morphingCurve: other.morphingCurve,
      particleCurve: other.particleCurve,
      microInteractionCurve: other.microInteractionCurve,
    );
  }

  static AnimationThemeExtension standard() {
    return const AnimationThemeExtension(
      // Legacy durations
      fastDuration: Duration(milliseconds: 200),
      mediumDuration: Duration(milliseconds: 300),
      slowDuration: Duration(milliseconds: 500),
      
      // Material 3 Motion Durations
      motionShort1: Duration(milliseconds: 50),
      motionShort2: Duration(milliseconds: 100),
      motionShort3: Duration(milliseconds: 150),
      motionShort4: Duration(milliseconds: 200),
      motionMedium1: Duration(milliseconds: 250),
      motionMedium2: Duration(milliseconds: 300),
      motionMedium3: Duration(milliseconds: 350),
      motionMedium4: Duration(milliseconds: 400),
      motionLong1: Duration(milliseconds: 450),
      motionLong2: Duration(milliseconds: 500),
      motionLong3: Duration(milliseconds: 550),
      motionLong4: Duration(milliseconds: 600),
      
      // Easing curves
      defaultCurve: Curves.easeOutCubic,
      elasticCurve: Curves.elasticOut,
      bounceCurve: Curves.bounceOut,
      standardEasing: Curves.easeInOut,
      decelerateEasing: Curves.easeOut,
      accelerateEasing: Curves.easeIn,
      emphasizedEasing: Curves.easeInOutCubic,
      
      // Specialized curves
      breathingCurve: Curves.easeInOutSine,
      morphingCurve: Curves.easeInOutQuart,
      particleCurve: Curves.easeOutExpo,
      microInteractionCurve: Curves.easeOutQuint,
    );
  }
  
  /// Get duration for micro-interactions (button press, hover, etc.)
  Duration get microInteractionDuration => motionShort1;
  
  /// Get duration for simple transitions (fade, slide)
  Duration get simpleTransitionDuration => motionShort2;
  
  /// Get duration for component changes (expand, collapse)
  Duration get componentChangeDuration => motionShort4;
  
  /// Get duration for screen transitions
  Duration get screenTransitionDuration => motionMedium3;
  
  /// Get duration for complex animations
  Duration get complexAnimationDuration => motionLong2;
  
  /// Get curve for micro-interactions
  Curve get microInteractionEasing => microInteractionCurve;
  
  /// Get curve for standard transitions
  Curve get standardTransitionEasing => standardEasing;
  
  /// Get curve for emphasized transitions
  Curve get emphasizedTransitionEasing => emphasizedEasing;
}

/// Helper functions for theme extensions
extension ThemeDataExtensions on ThemeData {
  ARThemeExtension get arTheme => extension<ARThemeExtension>()!;
  AnimationThemeExtension get animationTheme =>
      extension<AnimationThemeExtension>()!;
}

/// Animation configuration extensions for easy access
extension AnimationConfigExtensions on BuildContext {
  /// Get micro-interaction animation config
  AnimationConfig get microInteractionAnimation =>
      AnimationConfig.microInteraction(Theme.of(this).animationTheme);

  /// Get simple transition animation config
  AnimationConfig get simpleTransitionAnimation =>
      AnimationConfig.simpleTransition(Theme.of(this).animationTheme);

  /// Get component change animation config
  AnimationConfig get componentChangeAnimation =>
      AnimationConfig.componentChange(Theme.of(this).animationTheme);

  /// Get screen transition animation config
  AnimationConfig get screenTransitionAnimation =>
      AnimationConfig.screenTransition(Theme.of(this).animationTheme);

  /// Get breathing animation config
  AnimationConfig get breathingAnimation =>
      AnimationConfig.breathing(Theme.of(this).animationTheme);

  /// Get morphing animation config
  AnimationConfig get morphingAnimation =>
      AnimationConfig.morphing(Theme.of(this).animationTheme);

  /// Get particle animation config
  AnimationConfig get particleAnimation =>
      AnimationConfig.particle(Theme.of(this).animationTheme);
}

/// Glassmorphism utilities extension
extension GlassmorphismUtils on BuildContext {
  /// Creates a primary glassmorphism container for high importance content
  Widget glassPrimary({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    bool hasGlow = true,
  }) {
    return GlassmorphismContainer.primary(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      hasGlow: hasGlow,
      child: child,
    );
  }

  /// Creates a secondary glassmorphism container for medium importance content
  Widget glassSecondary({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return GlassmorphismContainer.secondary(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Creates a tertiary glassmorphism container for background elements
  Widget glassTertiary({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return GlassmorphismContainer.tertiary(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

/// Helper functions for lerping
double lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

Duration lerpDuration(Duration a, Duration b, double t) {
  return Duration(
    microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
        .round(),
  );
}

/// Reusable animation configuration system for consistent motion design
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final Duration? reverseDuration;
  final Curve? reverseCurve;

  const AnimationConfig({
    required this.duration,
    required this.curve,
    this.reverseDuration,
    this.reverseCurve,
  });

  /// Create animation config for micro-interactions
  static AnimationConfig microInteraction(AnimationThemeExtension theme) {
    return AnimationConfig(
      duration: theme.microInteractionDuration,
      curve: theme.microInteractionEasing,
    );
  }

  /// Create animation config for simple transitions
  static AnimationConfig simpleTransition(AnimationThemeExtension theme) {
    return AnimationConfig(
      duration: theme.simpleTransitionDuration,
      curve: theme.standardTransitionEasing,
    );
  }

  /// Create animation config for component changes
  static AnimationConfig componentChange(AnimationThemeExtension theme) {
    return AnimationConfig(
      duration: theme.componentChangeDuration,
      curve: theme.emphasizedTransitionEasing,
    );
  }

  /// Create animation config for screen transitions
  static AnimationConfig screenTransition(AnimationThemeExtension theme) {
    return AnimationConfig(
      duration: theme.screenTransitionDuration,
      curve: theme.emphasizedTransitionEasing,
      reverseDuration: theme.motionMedium2,
      reverseCurve: theme.decelerateEasing,
    );
  }

  /// Create animation config for breathing effects
  static AnimationConfig breathing(AnimationThemeExtension theme) {
    return AnimationConfig(
      duration: const Duration(milliseconds: 2000),
      curve: theme.breathingCurve,
    );
  }

  /// Create animation config for morphing effects
  static AnimationConfig morphing(AnimationThemeExtension theme) {
    return AnimationConfig(
      duration: theme.motionMedium4,
      curve: theme.morphingCurve,
    );
  }

  /// Create animation config for particle effects
  static AnimationConfig particle(AnimationThemeExtension theme) {
    return AnimationConfig(
      duration: const Duration(milliseconds: 1500),
      curve: theme.particleCurve,
    );
  }

  /// Create animation controller with this configuration
  AnimationController createController(TickerProvider vsync) {
    return AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      vsync: vsync,
    );
  }

  /// Create animation with this configuration
  Animation<T> createAnimation<T>(
    AnimationController controller,
    Tween<T> tween,
  ) {
    return tween.animate(
      CurvedAnimation(
        parent: controller,
        curve: curve,
        reverseCurve: reverseCurve,
      ),
    );
  }
}
