import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

/// Button size variants for consistent sizing
enum ButtonSize {
  /// Small button - 40dp height
  small(40.0),
  /// Medium button - 48dp height (default)
  medium(48.0),
  /// Large button - 56dp height
  large(56.0),
  /// Extra large button - 64dp height
  extraLarge(64.0);

  const ButtonSize(this.size);
  final double size;
}

/// Button style variants for different use cases
enum ButtonVariant {
  /// Icon-only button with neon styling
  neon,
  /// Primary button with solid background
  primary,
  /// Secondary button with outline
  secondary,
  /// Glassmorphism button with transparent background
  glass,
}

/// Enhanced neon-styled button with unified action button functionality
class NeonIconButton extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final Color color;
  final ButtonSize buttonSize;
  final ButtonVariant variant;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isActive;
  final bool isLoading;
  final double glowIntensity;
  final bool enableHaptics;
  final bool breathingAnimation;

  const NeonIconButton({
    super.key,
    this.icon,
    this.label,
    required this.color,
    this.buttonSize = ButtonSize.medium,
    this.variant = ButtonVariant.neon,
    this.onTap,
    this.tooltip,
    this.isActive = false,
    this.isLoading = false,
    this.glowIntensity = 1.0,
    this.enableHaptics = true,
    this.breathingAnimation = false,
  }) : assert(icon != null || label != null, 'Either icon or label must be provided');

  /// Creates a primary action button
  const NeonIconButton.primary({
    super.key,
    required String this.label,
    this.icon,
    required this.color,
    this.buttonSize = ButtonSize.medium,
    this.onTap,
    this.tooltip,
    this.isActive = false,
    this.isLoading = false,
    this.glowIntensity = 1.0,
    this.enableHaptics = true,
    this.breathingAnimation = false,
  }) : variant = ButtonVariant.primary;

  /// Creates a secondary action button
  const NeonIconButton.secondary({
    super.key,
    required String this.label,
    this.icon,
    required this.color,
    this.buttonSize = ButtonSize.medium,
    this.onTap,
    this.tooltip,
    this.isActive = false,
    this.isLoading = false,
    this.glowIntensity = 1.0,
    this.enableHaptics = true,
    this.breathingAnimation = false,
  }) : variant = ButtonVariant.secondary;

  /// Creates a glassmorphism button
  const NeonIconButton.glass({
    super.key,
    required String this.label,
    this.icon,
    required this.color,
    this.buttonSize = ButtonSize.medium,
    this.onTap,
    this.tooltip,
    this.isActive = false,
    this.isLoading = false,
    this.glowIntensity = 1.0,
    this.enableHaptics = true,
    this.breathingAnimation = false,
  }) : variant = ButtonVariant.glass;

  @override
  State<NeonIconButton> createState() => _NeonIconButtonState();
}

class _NeonIconButtonState extends State<NeonIconButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late AnimationController _breathingController;
  late AnimationController _loadingController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeAnimations();
    
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
    
    if (widget.breathingAnimation) {
      _breathingController.repeat(reverse: true);
    }
    
    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  void _initializeAnimations() {
    final animationTheme = Theme.of(context).animationTheme;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: animationTheme.microInteractionDuration,
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: animationTheme.microInteractionEasing),
    );

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: animationTheme.breathingCurve),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );
  }

  @override
  void didUpdateWidget(NeonIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    if (widget.breathingAnimation != oldWidget.breathingAnimation) {
      if (widget.breathingAnimation) {
        _breathingController.repeat(reverse: true);
      } else {
        _breathingController.stop();
        _breathingController.reset();
      }
    }

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
        _loadingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    _breathingController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (_isEnabled) {
      setState(() => _isPressed = true);
      _pressController.forward();
      
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isEnabled) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (_isEnabled) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  bool get _isEnabled => widget.onTap != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    Widget button = AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _scaleAnimation,
        _breathingAnimation,
        _rotationAnimation,
      ]),
      builder: (context, child) {
        double scale = 1.0;
        
        if (widget.isActive) {
          scale *= _pulseAnimation.value;
        }
        
        if (widget.breathingAnimation) {
          scale *= _breathingAnimation.value;
        }
        
        scale *= _scaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: _buildButtonContent(context),
        );
      },
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return GestureDetector(
      onTap: _isEnabled ? widget.onTap : null,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: button,
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    switch (widget.variant) {
      case ButtonVariant.neon:
        return _buildNeonButton(context);
      case ButtonVariant.primary:
        return _buildPrimaryButton(context);
      case ButtonVariant.secondary:
        return _buildSecondaryButton(context);
      case ButtonVariant.glass:
        return _buildGlassButton(context);
    }
  }

  Widget _buildNeonButton(BuildContext context) {
    final size = widget.buttonSize.size;
    
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: GlassmorphismContainer(
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: _isEnabled ? 0.8 : 0.3),
                widget.color.withValues(alpha: _isEnabled ? 0.4 : 0.1),
              ],
            ),
          ),
          child: Center(
            child: _buildIconOrLoading(size * 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    final size = widget.buttonSize.size;
    
    return Container(
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing4),
      decoration: BoxDecoration(
        color: _isEnabled ? widget.color : widget.color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
          onTap: _isEnabled ? widget.onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing2),
            child: _buildButtonChild(Colors.white, size),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    final size = widget.buttonSize.size;
    
    return Container(
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing4),
      decoration: BoxDecoration(
        color: _isPressed ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
        border: Border.all(
          color: _isEnabled ? widget.color : widget.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
          onTap: _isEnabled ? widget.onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing2),
            child: _buildButtonChild(
              _isEnabled ? widget.color : widget.color.withValues(alpha: 0.3),
              size,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(BuildContext context) {
    final size = widget.buttonSize.size;
    
    return GlassmorphismContainer(
      level: GlassLevel.secondary,
      borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
      hasGlow: _isPressed,
      child: Container(
        height: size,
        padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
            onTap: _isEnabled ? widget.onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing2),
              child: _buildButtonChild(
                _isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
                size,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonChild(Color foregroundColor, double size) {
    if (widget.icon != null && widget.label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconOrLoading(size * 0.4),
          const SizedBox(width: UIConstants.spacing2),
          Text(
            widget.label!,
            style: TextStyle(
              color: foregroundColor,
              fontSize: size * 0.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (widget.label != null) {
      return Center(
        child: Text(
          widget.label!,
          style: TextStyle(
            color: foregroundColor,
            fontSize: size * 0.3,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Center(child: _buildIconOrLoading(size * 0.5));
  }

  Widget _buildIconOrLoading(double iconSize) {
    if (widget.isLoading) {
      return AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.variant == ButtonVariant.neon ? Colors.white : widget.color,
                ),
              ),
            ),
          );
        },
      );
    }

    return Icon(
      widget.icon,
      color: widget.variant == ButtonVariant.neon ? Colors.white : null,
      size: iconSize,
    );
  }
}
