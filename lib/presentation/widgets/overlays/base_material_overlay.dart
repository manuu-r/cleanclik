import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

/// Base Material 3 overlay component with common patterns and animations
abstract class BaseMaterialOverlay extends StatefulWidget {
  /// Whether the overlay can be dismissed by tapping outside
  final bool dismissible;
  
  /// Callback when overlay is dismissed
  final VoidCallback? onDismiss;
  
  /// Background color for the overlay scrim
  final Color? backgroundColor;
  
  /// Whether to provide haptic feedback on show
  final bool hapticFeedback;
  
  /// Animation configuration for entrance
  final AnimationConfig? entranceAnimation;
  
  /// Animation configuration for exit
  final AnimationConfig? exitAnimation;

  const BaseMaterialOverlay({
    super.key,
    this.dismissible = true,
    this.onDismiss,
    this.backgroundColor,
    this.hapticFeedback = true,
    this.entranceAnimation,
    this.exitAnimation,
  });

  /// Build the main content of the overlay
  Widget buildContent(BuildContext context, Animation<double> animation);
  
  /// Get the overlay type for haptic feedback
  void get hapticType => HapticFeedback.mediumImpact();
  
  /// Get the entrance animation configuration
  AnimationConfig getEntranceAnimation(BuildContext context) {
    return entranceAnimation ?? context.componentChangeAnimation;
  }
  
  /// Get the exit animation configuration
  AnimationConfig getExitAnimation(BuildContext context) {
    return exitAnimation ?? context.simpleTransitionAnimation;
  }

  @override
  State<BaseMaterialOverlay> createState() => _BaseMaterialOverlayState();
}

class _BaseMaterialOverlayState extends State<BaseMaterialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _exitController;
  late Animation<double> _entranceAnimation;
  late Animation<double> _exitAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntranceAnimation();
  }

  void _initializeAnimations() {
    final entranceConfig = widget.getEntranceAnimation(context);
    final exitConfig = widget.getExitAnimation(context);
    
    // Entrance animation controller
    _entranceController = entranceConfig.createController(this);
    
    // Exit animation controller
    _exitController = exitConfig.createController(this);
    
    // Create entrance animation with Material 3 emphasized curve
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: entranceConfig.curve,
    );
    
    // Create exit animation with decelerate curve
    _exitAnimation = CurvedAnimation(
      parent: _exitController,
      curve: exitConfig.curve,
    );
    
    // Scale animation for Material 3 surface emergence
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(_entranceAnimation);
    
    // Slide animation for contextual entrance
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_entranceAnimation);
  }

  void _startEntranceAnimation() {
    // Provide haptic feedback
    if (widget.hapticFeedback) {
      widget.hapticType;
    }
    
    // Start entrance animation
    _entranceController.forward();
  }

  Future<void> _handleDismiss() async {
    if (_isExiting || !widget.dismissible) return;
    
    setState(() {
      _isExiting = true;
    });
    
    // Start exit animation
    await _exitController.forward();
    
    // Call dismiss callback
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceAnimation, _exitAnimation]),
        builder: (context, child) {
          // Calculate combined opacity for entrance/exit
          final entranceOpacity = _entranceAnimation.value;
          final exitOpacity = _isExiting ? 1.0 - _exitAnimation.value : 1.0;
          final combinedOpacity = entranceOpacity * exitOpacity;
          
          return Opacity(
            opacity: combinedOpacity,
            child: Stack(
              children: [
                // Background scrim with Material 3 surface treatment
                _buildBackgroundScrim(context, combinedOpacity),
                
                // Main content with Material 3 motion
                _buildAnimatedContent(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundScrim(BuildContext context, double opacity) {
    final backgroundColor = widget.backgroundColor ?? 
        Colors.black.withValues(alpha: 0.6 * opacity);
    
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.dismissible ? _handleDismiss : null,
        child: Container(
          color: backgroundColor,
        ),
      ),
    );
  }

  Widget _buildAnimatedContent(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.buildContent(context, _entranceAnimation),
      ),
    );
  }
}

/// Material 3 overlay patterns for different use cases
mixin OverlayPatterns {
  /// Creates a centered dialog-style overlay
  static Widget centeredDialog({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Center(
      child: GlassmorphismContainer.primary(
        margin: margin ?? const EdgeInsets.all(UIConstants.spacing6),
        padding: padding ?? const EdgeInsets.all(UIConstants.spacing6),
        hasGlow: true,
        child: child,
      ),
    );
  }
  
  /// Creates a bottom sheet-style overlay
  static Widget bottomSheet({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GlassmorphismContainer.secondary(
        padding: padding ?? const EdgeInsets.all(UIConstants.spacing6),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(UIConstants.radiusXXLarge),
          topRight: Radius.circular(UIConstants.radiusXXLarge),
        ),
        child: child,
      ),
    );
  }
  
  /// Creates a full-screen overlay with content positioning
  static Widget fullScreen({
    required Widget child,
    Alignment alignment = Alignment.center,
    EdgeInsetsGeometry? padding,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(UIConstants.spacing4),
        child: child,
      ),
    );
  }
}

/// Contextual micro-animations for overlay elements
class OverlayMicroAnimations {
  /// Creates a breathing animation for info elements
  static Widget breathing({
    required Widget child,
    required Animation<double> animation,
    double intensity = 0.1,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final breathingValue = 1.0 + (intensity * 
            (0.5 + 0.5 * (animation.value * 2 - 1).abs()));
        return Transform.scale(
          scale: breathingValue,
          child: child,
        );
      },
    );
  }
  
  /// Creates a pulse animation for success elements
  static Widget pulse({
    required Widget child,
    required Animation<double> animation,
    Color? color,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final pulseValue = 1.0 + 0.2 * animation.value;
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
              boxShadow: color != null ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3 * animation.value),
                  blurRadius: 20 * animation.value,
                  spreadRadius: 5 * animation.value,
                ),
              ] : null,
            ),
            child: child,
          ),
        );
      },
    );
  }
  
  /// Creates a shimmer animation for loading states
  static Widget shimmer({
    required Widget child,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                animation.value - 0.3,
                animation.value,
                animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
  
  /// Creates a morphing animation for state changes
  static Widget morphing({
    required Widget child,
    required Animation<double> animation,
    BorderRadius? fromRadius,
    BorderRadius? toRadius,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final radius = BorderRadius.lerp(
          fromRadius ?? BorderRadius.circular(UIConstants.radiusSmall),
          toRadius ?? BorderRadius.circular(UIConstants.radiusXLarge),
          animation.value,
        );
        
        return ClipRRect(
          borderRadius: radius ?? BorderRadius.zero,
          child: child,
        );
      },
    );
  }
}

/// State-aware overlay styling for different interaction states
class OverlayStateStyles {
  /// Get styling for success state
  static OverlayStateStyle success() {
    return const OverlayStateStyle(
      primaryColor: Color(0xFF2E7D32), // NeonColors.electricGreen
      backgroundColor: Color(0x1A2E7D32),
      borderColor: Color(0x4D2E7D32),
      iconData: Icons.check_circle,
      hapticType: 'heavy',
    );
  }
  
  /// Get styling for warning state
  static OverlayStateStyle warning() {
    return const OverlayStateStyle(
      primaryColor: Color(0xFFF57F17), // NeonColors.solarYellow
      backgroundColor: Color(0x1AF57F17),
      borderColor: Color(0x4DF57F17),
      iconData: Icons.warning,
      hapticType: 'medium',
    );
  }
  
  /// Get styling for error state
  static OverlayStateStyle error() {
    return const OverlayStateStyle(
      primaryColor: Color(0xFFE91E63), // NeonColors.glowRed
      backgroundColor: Color(0x1AE91E63),
      borderColor: Color(0x4DE91E63),
      iconData: Icons.error,
      hapticType: 'heavy',
    );
  }
  
  /// Get styling for info state
  static OverlayStateStyle info() {
    return const OverlayStateStyle(
      primaryColor: Color(0xFF1976D2), // NeonColors.oceanBlue
      backgroundColor: Color(0x1A1976D2),
      borderColor: Color(0x4D1976D2),
      iconData: Icons.info,
      hapticType: 'light',
    );
  }
}

/// Overlay state styling configuration
class OverlayStateStyle {
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData iconData;
  final String hapticType;
  
  const OverlayStateStyle({
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconData,
    required this.hapticType,
  });
  
  /// Provide haptic feedback based on type
  void provideHapticFeedback() {
    switch (hapticType) {
      case 'heavy':
        HapticFeedback.heavyImpact();
        break;
      case 'medium':
        HapticFeedback.mediumImpact();
        break;
      case 'light':
        HapticFeedback.lightImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }
  }
}