import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/services/camera/disposal_handling_service.dart';
import 'package:cleanclik/core/models/camera_models.dart';

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
  State<_DisposalCelebrationContent> createState() =>
      _DisposalCelebrationContentState();
}

class _DisposalCelebrationContentState
    extends State<_DisposalCelebrationContent>
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
    final animationTheme =
        theme.extension<AnimationThemeExtension>() ??
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
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
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
                  successStyle.backgroundColor.withValues(
                    alpha: finalOpacity * 0.4,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCelebrationContent(
    BuildContext context,
    OverlayStateStyle successStyle,
  ) {
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

        // Items disposed with enhanced styling and original labels
        _buildDisposedItemsSummary(context, theme),

        // Detection accuracy and confidence metrics
        const SizedBox(height: UIConstants.spacing3),
        _buildDetectionMetrics(context, theme),

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

        // Detection pipeline performance summary
        const SizedBox(height: UIConstants.spacing3),
        _buildDetectionPipelineSummary(context, theme),
      ],
    );
  }

  Widget _buildMaterial3PointsAnimation(
    BuildContext context,
    OverlayStateStyle successStyle,
  ) {
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
                    borderRadius: BorderRadius.circular(
                      UIConstants.radiusXLarge,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 20),
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

  /// Build disposed items summary with original labels
  /// Requirements: 3.4
  Widget _buildDisposedItemsSummary(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.disposalResult.itemsDisposed.length} items disposed',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: UIConstants.spacing2),

        // Show original labels for disposed items
        if (widget.disposalResult.itemsDisposed.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Wrap(
              spacing: UIConstants.spacing1,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: widget.disposalResult.itemsDisposed.take(4).map((item) {
                final originalLabel = widget.disposalResult.getOriginalLabel(
                  item.objectId,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(
                      UIConstants.radiusSmall,
                    ),
                  ),
                  child: Text(
                    originalLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (widget.disposalResult.itemsDisposed.length > 4) ...[
            const SizedBox(height: 4),
            Text(
              '+ ${widget.disposalResult.itemsDisposed.length - 4} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// Build detection accuracy and confidence metrics
  /// Requirements: 3.4
  Widget _buildDetectionMetrics(BuildContext context, ThemeData theme) {
    final avgConfidence = _calculateAverageConfidence();
    final successStyle = OverlayStateStyles.success();

    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing3),
      decoration: BoxDecoration(
        color: successStyle.backgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: successStyle.borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Disposal accuracy
          _buildMetricItem(
            context,
            Icons.track_changes,
            'Accuracy',
            '${(widget.disposalResult.accuracy * 100).toStringAsFixed(0)}%',
            _getAccuracyColor(widget.disposalResult.accuracy),
            theme,
          ),

          // Average detection confidence
          _buildMetricItem(
            context,
            Icons.analytics,
            'Confidence',
            '${(avgConfidence * 100).toStringAsFixed(0)}%',
            _getConfidenceColor(avgConfidence),
            theme,
          ),

          // Categorization success
          _buildMetricItem(
            context,
            Icons.check_circle,
            'Success',
            '${_getCategorizationSuccessCount()}/${widget.disposalResult.itemsDisposed.length}',
            successStyle.primaryColor,
            theme,
          ),
        ],
      ),
    );
  }

  /// Build detection pipeline performance summary
  /// Requirements: 3.4
  Widget _buildDetectionPipelineSummary(BuildContext context, ThemeData theme) {
    final pipelineStats = _calculatePipelineStats();

    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              const SizedBox(width: UIConstants.spacing1),
              Text(
                'Detection Pipeline Performance',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: UIConstants.spacing2),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPipelineStatItem(
                context,
                'ML Only',
                pipelineStats['mlOnly'] as int,
                Colors.green,
                theme,
              ),
              _buildPipelineStatItem(
                context,
                'IMG Only',
                pipelineStats['imageOnly'] as int,
                Colors.blue,
                theme,
              ),
              _buildPipelineStatItem(
                context,
                'Combined',
                pipelineStats['combined'] as int,
                Colors.purple,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual metric item
  /// Requirements: 3.4
  Widget _buildMetricItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Build pipeline statistic item
  /// Requirements: 3.4
  Widget _buildPipelineStatItem(
    BuildContext context,
    String label,
    int count,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Calculate average detection confidence
  /// Requirements: 3.4
  double _calculateAverageConfidence() {
    if (widget.disposalResult.itemsDisposed.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int count = 0;

    for (final item in widget.disposalResult.itemsDisposed) {
      final confidence = widget.disposalResult.getDetectionConfidence(
        item.objectId,
      );
      if (confidence > 0.0) {
        totalConfidence += confidence;
        count++;
      }
    }

    return count > 0 ? totalConfidence / count : 0.0;
  }

  /// Get categorization success count
  /// Requirements: 3.4
  int _getCategorizationSuccessCount() {
    int successCount = 0;

    for (final item in widget.disposalResult.itemsDisposed) {
      final confidence = widget.disposalResult.getDetectionConfidence(
        item.objectId,
      );
      if (confidence >= 0.6) {
        // Consider 60%+ as successful categorization
        successCount++;
      }
    }

    return successCount;
  }

  /// Calculate pipeline statistics
  /// Requirements: 3.4
  Map<String, int> _calculatePipelineStats() {
    int mlOnly = 0;
    int imageOnly = 0;
    int combined = 0;

    for (final item in widget.disposalResult.itemsDisposed) {
      final imageLabels = widget.disposalResult.getImageLabels(item.objectId);
      final hasImageLabels = imageLabels.isNotEmpty;
      final hasMLDetection =
          widget.disposalResult.getOriginalLabel(item.objectId) != 'Unknown';

      if (hasMLDetection && hasImageLabels) {
        combined++;
      } else if (hasImageLabels) {
        imageOnly++;
      } else if (hasMLDetection) {
        mlOnly++;
      }
    }

    return {'mlOnly': mlOnly, 'imageOnly': imageOnly, 'combined': combined};
  }

  /// Get accuracy color based on accuracy level
  /// Requirements: 3.4
  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.9) {
      return Colors.green;
    } else if (accuracy >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Get confidence color based on confidence level
  /// Requirements: 3.4
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
