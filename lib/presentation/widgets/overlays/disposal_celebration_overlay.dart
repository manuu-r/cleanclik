import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/services/camera/disposal_detection_service.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

/// Overlay widget that shows celebration animation for successful disposal
class DisposalCelebrationOverlay extends StatefulWidget {
  final DisposalResult disposalResult;
  final VoidCallback onComplete;

  const DisposalCelebrationOverlay({
    super.key,
    required this.disposalResult,
    required this.onComplete,
  });

  @override
  State<DisposalCelebrationOverlay> createState() =>
      _DisposalCelebrationOverlayState();
}

class _DisposalCelebrationOverlayState extends State<DisposalCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _pointsController;
  late AnimationController _fadeController;

  late Animation<double> _celebrationAnimation;
  late Animation<double> _pointsAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );

    _pointsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pointsController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start celebration sequence
    _startCelebration();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _pointsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startCelebration() async {
    // Provide haptic feedback
    HapticFeedback.heavyImpact();

    // Start celebration animation
    _celebrationController.forward();

    // Delay points animation slightly
    await Future.delayed(const Duration(milliseconds: 200));
    _pointsController.forward();

    // Auto-dismiss after showing celebration
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      _fadeController.forward().then((_) {
        widget.onComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _celebrationAnimation,
        _pointsAnimation,
        _fadeAnimation,
      ]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Success glow overlay
                _buildSuccessGlow(),

                // Main celebration content
                _buildCelebrationContent(context),

                // Floating points animation
                _buildPointsAnimation(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessGlow() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              NeonColors.electricGreen.withOpacity(
                0.2 * _celebrationAnimation.value,
              ),
              NeonColors.electricGreen.withOpacity(
                0.1 * _celebrationAnimation.value,
              ),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationContent(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _celebrationAnimation,
        child: GlassmorphismContainer(
          padding: const EdgeInsets.all(UIConstants.spacing6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Icon(
                Icons.check_circle,
                color: NeonColors.electricGreen,
                size: 64 * _celebrationAnimation.value,
              ),

              const SizedBox(height: UIConstants.spacing4),

              // Success message
              Text(
                'Disposal Complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: UIConstants.spacing2),

              // Items disposed
              Text(
                '${widget.disposalResult.itemsDisposed.length} items disposed',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),

              // Streak info
              if (widget.disposalResult.streakCount > 1) ...[
                const SizedBox(height: UIConstants.spacing1),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacing3,
                    vertical: UIConstants.spacing1,
                  ),
                  decoration: BoxDecoration(
                    color: NeonColors.solarYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      UIConstants.radiusSmall,
                    ),
                  ),
                  child: Text(
                    '${widget.disposalResult.streakCount}x Streak!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NeonColors.solarYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsAnimation(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3,
      left: 0,
      right: 0,
      child: Transform.translate(
        offset: Offset(0, -50 * _pointsAnimation.value),
        child: Opacity(
          opacity: _pointsAnimation.value.clamp(0.0, 1.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacing4,
                vertical: UIConstants.spacing2,
              ),
              decoration: BoxDecoration(
                color: NeonColors.electricGreen.withOpacity(0.9),
                borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.electricGreen.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '+${widget.disposalResult.pointsEarned} points',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
