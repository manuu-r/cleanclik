import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/services/camera/disposal_detection_service.dart';

import 'package:cleanclik/presentation/widgets/overlays/base_material_overlay.dart';

/// Material 3 overlay widget that shows celebration animation for successful disposal
class DisposalCelebrationOverlay extends BaseMaterialOverlay {
  final DisposalResult disposalResult;

  const DisposalCelebrationOverlay({
    super.key,
    required this.disposalResult,
    required super.onDismiss,
    super.dismissible = false,
    super.hapticFeedback = true,
  });

  @override
  void get hapticType => HapticFeedback.heavyImpact();

  @override
  AnimationConfig getEntranceAnimation(BuildContext context) {
    return AnimationConfig(
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
    );
  }

  @override
  Widget buildContent(BuildContext context, Animation<double> animation) {
    return _DisposalCelebrationContent(
      disposalResult: disposalResult,
      onComplete: onDismiss!,
      animation: animation,
    );
  }

}

/// Content widget for disposal celebration with Material 3 design and animations
class _DisposalCelebrationContent extends StatefulWidget {
  final DisposalResult disposalResult;
  final VoidCallback onComplete;
  final Animation<double> animation;

  const _DisposalCelebrationContent({
    required this.disposalResult,
    required this.onComplete,
    required this.animation,
  });

  @override
  State<_DisposalCelebrationContent> createState() => _DisposalCelebrationContentState();
}

class _DisposalCelebrationContentState extends State<_DisposalCelebrationContent>
    with TickerProviderStateMixin {
  late AnimationController _pointsController;
  late AnimationController _pulseController;
  late Animation<double> _pointsAnimation;
  late Animation<double> _pulseAnimation;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    // Don't initialize animations here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationsInitialized) {
      _initializeCelebrationAnimations();
      _startCelebrationSequence();
      _animationsInitialized = true;
    }
  }

  void _initializeCelebrationAnimations() {
    final theme = Theme.of(context);
    final animationTheme = theme.extension<AnimationThemeExtension>() ?? 
                          AnimationThemeExtension.standard();
    
    // Points animation with Material 3 emphasized curve
    _pointsController = AnimationController(
      duration: animationTheme.motionMedium4,
      vsync: this,
    );
    
    _pointsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pointsController,
        curve: animationTheme.emphasizedEasing,
      ),
    );

    // Pulse animation for success glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  void _startCelebrationSequence() async {
    if (!mounted) return;
    
    // Start pulse animation immediately
    _pulseController.repeat(reverse: true);
    
    // Delay points animation for better visual flow
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _pointsController.forward();
    }

    // Auto-dismiss after celebration
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    if (_animationsInitialized) {
      _pointsController.dispose();
      _pulseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final successStyle = OverlayStateStyles.success();
    
    return Stack(
      children: [
        // Success glow overlay with Material 3 surface treatment
        _buildMaterial3SuccessGlow(successStyle),

        // Main celebration content
        OverlayPatterns.centeredDialog(
          child: _buildCelebrationContent(context, successStyle),
        ),

        // Floating points animation
        _buildMaterial3PointsAnimation(context, successStyle),
      ],
    );
  }

  Widget _buildMaterial3SuccessGlow(OverlayStateStyle successStyle) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.animation, _pulseAnimation]),
        builder: (context, child) {
          // Enhanced opacity for better visibility (0.25-0.35 range)
          final baseOpacity = 0.3 * widget.animation.value;
          final pulseMultiplier = 0.8 + 0.2 * _pulseAnimation.value;
          final finalOpacity = baseOpacity * pulseMultiplier;
          
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.8,
                colors: [
                  successStyle.backgroundColor.withValues(alpha: finalOpacity),
                  successStyle.backgroundColor.withValues(alpha: finalOpacity * 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCelebrationContent(BuildContext context, OverlayStateStyle successStyle) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success icon with pulse animation
        OverlayMicroAnimations.pulse(
          animation: _pulseAnimation,
          color: successStyle.primaryColor,
          child: Icon(
            successStyle.iconData,
            color: successStyle.primaryColor,
            size: 64,
          ),
        ),

        const SizedBox(height: UIConstants.spacing4),

        // Success message with Material 3 typography
        Text(
          'Disposal Complete!',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),

        const SizedBox(height: UIConstants.spacing2),

        // Items disposed with enhanced styling
        Text(
          '${widget.disposalResult.itemsDisposed.length} items disposed',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),
        ),

        // Streak info with Material 3 chip styling
        if (widget.disposalResult.streakCount > 1) ...[
          const SizedBox(height: UIConstants.spacing3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacing4,
              vertical: UIConstants.spacing2,
            ),
            decoration: BoxDecoration(
              color: OverlayStateStyles.warning().backgroundColor,
              borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
              border: Border.all(
                color: OverlayStateStyles.warning().borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: OverlayStateStyles.warning().primaryColor,
                  size: 18,
                ),
                const SizedBox(width: UIConstants.spacing1),
                Text(
                  '${widget.disposalResult.streakCount}x Streak!',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: OverlayStateStyles.warning().primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMaterial3PointsAnimation(BuildContext context, OverlayStateStyle successStyle) {
    final theme = Theme.of(context);
    
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pointsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -60 * _pointsAnimation.value),
            child: Opacity(
              opacity: _pointsAnimation.value,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing5,
                    vertical: UIConstants.spacing3,
                  ),
                  decoration: BoxDecoration(
                    color: successStyle.primaryColor,
                    borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: UIConstants.spacing2),
                      Text(
                        '+${widget.disposalResult.pointsEarned} points',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
