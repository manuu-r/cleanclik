import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

/// Enhanced action button with Material 3 expressive design and micro-animations
class EnhancedActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final Color? color;
  final bool isPrimary;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const EnhancedActionButton({
    super.key,
    this.onPressed,
    this.icon,
    required this.label,
    this.color,
    this.isPrimary = false,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.leadingIcon,
    this.trailingIcon,
  });

  /// Create a primary action button with prominent styling
  factory EnhancedActionButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    Color? color,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double? height,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    return EnhancedActionButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      color: color ?? NeonColors.electricGreen,
      isPrimary: true,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: width,
      height: height,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  /// Create a secondary action button with outline styling
  factory EnhancedActionButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    Color? color,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double? height,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    return EnhancedActionButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      color: color ?? NeonColors.oceanBlue,
      isPrimary: false,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: width,
      height: height,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  @override
  State<EnhancedActionButton> createState() => _EnhancedActionButtonState();
}

class _EnhancedActionButtonState extends State<EnhancedActionButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _loadingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _loadingAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.linear,
    ));

    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(EnhancedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _pressController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled || widget.isLoading) return;
    
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled || widget.isLoading) return;
    
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    if (!widget.isEnabled || widget.isLoading) return;
    
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTap() {
    if (!widget.isEnabled || widget.isLoading) return;
    
    HapticFeedback.selectionClick();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arTheme = theme.arTheme;
    final animationTheme = theme.animationTheme;
    
    final effectiveColor = widget.color ?? theme.colorScheme.primary;
    final isEnabled = widget.isEnabled && !widget.isLoading;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _loadingAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: animationTheme.microInteractionDuration,
              curve: animationTheme.microInteractionEasing,
              width: widget.width,
              height: widget.height ?? UIConstants.buttonHeight,
              padding: widget.padding ?? EdgeInsets.symmetric(
                horizontal: UIConstants.spacing5,
                vertical: UIConstants.spacing3,
              ),
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(UIConstants.radiusXLarge),
                gradient: widget.isPrimary && isEnabled
                    ? LinearGradient(
                        colors: [
                          effectiveColor,
                          effectiveColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isPrimary 
                    ? null 
                    : (isEnabled ? Colors.transparent : Colors.grey.withValues(alpha: 0.1)),
                border: widget.isPrimary
                    ? null
                    : Border.all(
                        color: isEnabled 
                            ? effectiveColor.withValues(alpha: 0.6)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 2,
                      ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.leadingIcon != null) ...[
                    widget.leadingIcon!,
                    SizedBox(width: UIConstants.spacing2),
                  ],
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isPrimary ? Colors.white : effectiveColor,
                        ),
                      ),
                    ),
                    SizedBox(width: UIConstants.spacing3),
                  ] else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.isPrimary 
                          ? Colors.white 
                          : (isEnabled ? effectiveColor : Colors.grey),
                      size: 24,
                    ),
                    SizedBox(width: UIConstants.spacing3),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: widget.isPrimary 
                            ? Colors.white 
                            : (isEnabled ? effectiveColor : Colors.grey),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.trailingIcon != null) ...[
                    SizedBox(width: UIConstants.spacing2),
                    widget.trailingIcon!,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}