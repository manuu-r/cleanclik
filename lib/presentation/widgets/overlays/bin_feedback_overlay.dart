import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/services/location/bin_matching_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/models/camera_models.dart';

import 'package:cleanclik/presentation/widgets/overlays/disposal_confirmation_dialog.dart';
import 'package:cleanclik/presentation/widgets/overlays/base_material_overlay.dart';

/// Material 3 overlay widget that provides visual feedback for bin matching results
class BinFeedbackOverlay extends BaseMaterialOverlay {
  final BinMatchResult matchResult;
  final Function(List<InventoryItem> itemsToDispose)? onDispose;

  const BinFeedbackOverlay({
    super.key,
    required this.matchResult,
    required super.onDismiss,
    this.onDispose,
    super.dismissible = true,
    super.hapticFeedback = true,
  });

  @override
  void get hapticType {
    switch (matchResult.matchType) {
      case BinMatchType.perfectMatch:
        HapticFeedback.heavyImpact();
        break;
      case BinMatchType.partialMatch:
        HapticFeedback.mediumImpact();
        break;
      case BinMatchType.noMatch:
        HapticFeedback.mediumImpact();
        break;
      case BinMatchType.emptyInventory:
        HapticFeedback.lightImpact();
        break;
    }
  }

  @override
  AnimationConfig getEntranceAnimation(BuildContext context) {
    // Use emphasized animation for important feedback
    // Use default duration to avoid theme access during initialization
    return AnimationConfig(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
    );
  }

  @override
  Widget buildContent(BuildContext context, Animation<double> animation) {
    print(
      '🎭 [BIN_FEEDBACK_OVERLAY] Building content for match type: ${matchResult.matchType}',
    );
    return _BinFeedbackContent(
      matchResult: matchResult,
      onDispose: onDispose,
      onDismiss: onDismiss,
      animation: animation,
    );
  }
}

/// Content widget for bin feedback with Material 3 design and micro-animations
class _BinFeedbackContent extends StatefulWidget {
  final BinMatchResult matchResult;
  final Function(List<InventoryItem> itemsToDispose)? onDispose;
  final VoidCallback? onDismiss;
  final Animation<double> animation;

  const _BinFeedbackContent({
    required this.matchResult,
    required this.onDispose,
    required this.onDismiss,
    required this.animation,
  });

  @override
  State<_BinFeedbackContent> createState() => _BinFeedbackContentState();
}

class _BinFeedbackContentState extends State<_BinFeedbackContent>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _particleController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _particleAnimation;
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
      _initializeSpecializedAnimations();
      _animationsInitialized = true;
    }
  }

  void _initializeSpecializedAnimations() {
    final theme = Theme.of(context);
    final animationTheme =
        theme.extension<AnimationThemeExtension>() ??
        AnimationThemeExtension.standard();

    // Breathing animation for info results
    _breathingController = AnimationConfig.breathing(
      animationTheme,
    ).createController(this);
    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: animationTheme.breathingCurve,
      ),
    );

    // Particle animation for success results
    _particleController = AnimationConfig.particle(
      animationTheme,
    ).createController(this);
    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: animationTheme.particleCurve,
    );

    // Start appropriate animations based on match result
    if (mounted) {
      if (widget.matchResult.isInfoResult) {
        _breathingController.repeat(reverse: true);
      }

      if (widget.matchResult.isPositiveResult) {
        _particleController.forward();
      }
    }
  }

  @override
  void dispose() {
    if (_animationsInitialized) {
      _breathingController.dispose();
      _particleController.dispose();
    }
    super.dispose();
  }

  OverlayStateStyle _getStateStyle() {
    switch (widget.matchResult.matchType) {
      case BinMatchType.perfectMatch:
        return OverlayStateStyles.success();
      case BinMatchType.partialMatch:
        return OverlayStateStyles.warning();
      case BinMatchType.noMatch:
        return OverlayStateStyles.error();
      case BinMatchType.emptyInventory:
        return OverlayStateStyles.info();
    }
  }

  /// Show the disposal confirmation dialog with Material 3 patterns
  void _showDisposalConfirmationDialog() {
    if (widget.onDispose == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return DisposalConfirmationDialog(
          matchResult: widget.matchResult,
          onConfirmDisposal: (itemsToDispose) async {
            await widget.onDispose!(itemsToDispose);
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateStyle = _getStateStyle();

    return Stack(
      children: [
        // Contextual background overlay with Material 3 surface treatment
        _buildContextualOverlay(stateStyle),

        // Particle effects for success states
        if (widget.matchResult.isPositiveResult)
          _buildMaterial3ParticleEffects(stateStyle),

        // Main feedback content with Material 3 patterns
        OverlayPatterns.centeredDialog(
          child: _buildFeedbackContent(context, stateStyle),
        ),
      ],
    );
  }

  Widget _buildContextualOverlay(OverlayStateStyle stateStyle) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: widget.matchResult.isInfoResult
            ? _breathingAnimation
            : widget.animation,
        builder: (context, child) {
          // Enhanced opacity for better visibility (0.25-0.35 range) with safe clamping
          final baseOpacity = widget.matchResult.isInfoResult ? 0.25 : 0.3;
          final animationMultiplier = widget.matchResult.isInfoResult
              ? _breathingAnimation.value.clamp(0.0, 2.0)
              : widget.animation.value.clamp(0.0, 1.0);
          final opacity = (baseOpacity * animationMultiplier).clamp(0.0, 1.0);

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.8,
                colors: [
                  stateStyle.backgroundColor.withValues(alpha: opacity),
                  stateStyle.backgroundColor.withValues(alpha: opacity * 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterial3ParticleEffects(OverlayStateStyle stateStyle) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _Material3ParticleEffectPainter(
              progress: _particleAnimation.value,
              color: stateStyle.primaryColor,
              style: stateStyle,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackContent(
    BuildContext context,
    OverlayStateStyle stateStyle,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon and main message with Material 3 micro-animations
        _buildMainMessage(context, stateStyle),

        // Additional info if available
        if (widget.matchResult.additionalInfo != null) ...[
          const SizedBox(height: UIConstants.spacing4),
          _buildAdditionalInfo(context, stateStyle),
        ],

        // Item breakdown for partial matches
        if (widget.matchResult.isWarningResult) ...[
          const SizedBox(height: UIConstants.spacing4),
          _buildItemBreakdown(context, stateStyle),
        ],

        // Action buttons with Material 3 styling
        const SizedBox(height: UIConstants.spacing6),
        _buildMaterial3ActionButtons(context, stateStyle),
      ],
    );
  }

  Widget _buildMainMessage(BuildContext context, OverlayStateStyle stateStyle) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with contextual micro-animations
        _buildAnimatedIcon(stateStyle),

        const SizedBox(height: UIConstants.spacing4),

        // Main message with Material 3 typography
        Text(
          widget.matchResult.message,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
          textAlign: TextAlign.center,
        ),

        // Bin info with enhanced styling
        const SizedBox(height: UIConstants.spacing2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing3,
            vertical: UIConstants.spacing1,
          ),
          decoration: BoxDecoration(
            color: stateStyle.backgroundColor,
            borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
            border: Border.all(color: stateStyle.borderColor, width: 1),
          ),
          child: Text(
            'Bin: ${widget.matchResult.binInfo.category.codeName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: stateStyle.primaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon(OverlayStateStyle stateStyle) {
    Widget iconWidget = Icon(
      stateStyle.iconData,
      size: 48,
      color: stateStyle.primaryColor,
    );

    // Apply appropriate micro-animation based on match result
    if (widget.matchResult.isInfoResult) {
      return OverlayMicroAnimations.breathing(
        animation: _breathingAnimation,
        intensity: 0.05,
        child: iconWidget,
      );
    } else if (widget.matchResult.isPositiveResult) {
      return OverlayMicroAnimations.pulse(
        animation: _particleAnimation,
        color: stateStyle.primaryColor,
        child: iconWidget,
      );
    } else {
      return AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.animation.value,
            child: iconWidget,
          );
        },
      );
    }
  }

  Widget _buildAdditionalInfo(
    BuildContext context,
    OverlayStateStyle stateStyle,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing3),
      decoration: BoxDecoration(
        color: stateStyle.backgroundColor,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(color: stateStyle.borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Original additional info
          Text(
            widget.matchResult.additionalInfo!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // Detection details for matching items
          if (widget.matchResult.matchingItems.isNotEmpty) ...[
            const SizedBox(height: UIConstants.spacing3),
            _buildDetectionDetails(context, stateStyle),
          ],
        ],
      ),
    );
  }

  /// Build detection details section showing ML detection + image labeling results
  /// Requirements: 3.1, 3.2, 2.3
  Widget _buildDetectionDetails(
    BuildContext context,
    OverlayStateStyle stateStyle,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detection details header
        Row(
          children: [
            Icon(
              Icons.science_outlined,
              size: 16,
              color: stateStyle.primaryColor,
            ),
            const SizedBox(width: UIConstants.spacing1),
            Text(
              'Detection Details',
              style: theme.textTheme.labelMedium?.copyWith(
                color: stateStyle.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: UIConstants.spacing2),

        // Show detection details for first few items
        ...widget.matchResult.matchingItems.take(3).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.spacing2),
            child: _buildItemDetectionSummary(context, item, stateStyle),
          );
        }).toList(),

        // Show count if more items exist
        if (widget.matchResult.matchingItems.length > 3) ...[
          Text(
            '+ ${widget.matchResult.matchingItems.length - 3} more items with detection data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  /// Build detection summary for a single item
  /// Requirements: 3.1, 3.2, 2.3
  Widget _buildItemDetectionSummary(
    BuildContext context,
    InventoryItem item,
    OverlayStateStyle stateStyle,
  ) {
    final theme = Theme.of(context);

    // Extract detection information from metadata
    final detectionInfo = _extractDetectionInfo(item);

    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Item name and detection source
          Row(
            children: [
              Expanded(
                child: Text(
                  item.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _buildDetectionSourceBadge(
                context,
                detectionInfo['source'] as String?,
              ),
            ],
          ),

          const SizedBox(height: UIConstants.spacing1),

          // Detection pipeline summary
          if (detectionInfo['imageLabels'] != null &&
              (detectionInfo['imageLabels'] as List).isNotEmpty) ...[
            _buildImageLabelsDisplay(
              context,
              detectionInfo['imageLabels'] as List,
            ),
            const SizedBox(height: UIConstants.spacing1),
          ],

          // Confidence and categorization reasoning
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: UIConstants.spacing1),
              Expanded(
                child: Text(
                  detectionInfo['reasoning'] as String? ??
                      'Auto-categorized from detection',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(item.confidence * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getConfidenceColor(item.confidence),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build detection source badge
  /// Requirements: 3.1, 3.2
  Widget _buildDetectionSourceBadge(BuildContext context, String? source) {
    final theme = Theme.of(context);

    final sourceInfo = _getDetectionSourceInfo(source);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing1,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: sourceInfo['color'] as Color,
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
      ),
      child: Text(
        sourceInfo['label'] as String,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Build image labels display
  /// Requirements: 3.1, 3.2, 2.3
  Widget _buildImageLabelsDisplay(BuildContext context, List imageLabels) {
    final theme = Theme.of(context);

    if (imageLabels.isEmpty) return const SizedBox.shrink();

    // Show top 2 image labels
    final topLabels = imageLabels.take(2).toList();

    return Wrap(
      spacing: UIConstants.spacing1,
      runSpacing: 2,
      children: topLabels.map<Widget>((labelData) {
        final label = labelData is Map<String, dynamic>
            ? labelData['text'] as String? ?? 'Unknown'
            : labelData.toString();
        final confidence = labelData is Map<String, dynamic>
            ? (labelData['confidence'] as num?)?.toDouble() ?? 0.0
            : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
          ),
          child: Text(
            '$label ${(confidence * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Extract detection information from item metadata
  /// Requirements: 4.1, 4.2
  Map<String, dynamic> _extractDetectionInfo(InventoryItem item) {
    final metadata = item.metadata;
    if (metadata == null) {
      return {
        'source': 'ml_detection',
        'imageLabels': <Map<String, dynamic>>[],
        'reasoning': 'Auto-categorized from detection',
        'confidence': item.confidence,
      };
    }

    try {
      // Safely extract detection source
      String detectionSource = 'ml_detection';
      try {
        final detection = metadata['detection'] as Map<String, dynamic>?;
        final source = detection?['source'] as Map<String, dynamic>?;
        detectionSource = source?['value'] as String? ?? 'ml_detection';
      } catch (e) {
        print('Warning: Failed to get detection source: $e');
      }

      // Safely extract image labels
      List<Map<String, dynamic>> imageLabels = [];
      try {
        final detection = metadata['detection'] as Map<String, dynamic>?;
        final labels = detection?['imageLabels'] as List<dynamic>?;
        imageLabels = labels?.map((label) => label as Map<String, dynamic>).toList() ?? [];
      } catch (e) {
        print('Warning: Failed to get image labels: $e');
      }

      // Safely extract reasoning
      String reasoning = 'Auto-categorized from detection';
      try {
        final categorization = metadata['categorization'] as Map<String, dynamic>?;
        reasoning = categorization?['reasoning'] as String? ?? 'Auto-categorized from detection';
      } catch (e) {
        print('Warning: Failed to get categorization reasoning: $e');
      }

      // Safely extract confidence
      double confidence = item.confidence;
      try {
        final categorization = metadata['categorization'] as Map<String, dynamic>?;
        confidence = (categorization?['categoryConfidence'] as num?)?.toDouble() ?? item.confidence;
      } catch (e) {
        print('Warning: Failed to get category confidence: $e');
      }

      return {
        'source': detectionSource,
        'imageLabels': imageLabels,
        'reasoning': reasoning,
        'confidence': confidence,
      };
    } catch (e) {
      print('Warning: Failed to extract detection info from metadata: $e');
      return {
        'source': 'ml_detection',
        'imageLabels': <Map<String, dynamic>>[],
        'reasoning': 'Auto-categorized from detection',
        'confidence': item.confidence,
      };
    }
  }

  /// Get detection source information for display
  /// Requirements: 3.1, 3.2
  Map<String, dynamic> _getDetectionSourceInfo(String? source) {
    switch (source?.toLowerCase()) {
      case 'combined':
        return {'label': 'ML+IMG', 'color': Colors.purple};
      case 'image_labeling':
        return {'label': 'IMG', 'color': Colors.blue};
      case 'manual':
        return {'label': 'MANUAL', 'color': Colors.orange};
      case 'ml_detection':
      default:
        return {'label': 'ML', 'color': Colors.green};
    }
  }

  /// Get confidence color based on confidence level
  /// Requirements: 3.1, 3.2
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildItemBreakdown(
    BuildContext context,
    OverlayStateStyle stateStyle,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Matching items with Material 3 styling
        if (widget.matchResult.matchingItems.isNotEmpty) ...[
          _buildBreakdownRow(
            context: context,
            icon: Icons.check_circle_outline,
            color: OverlayStateStyles.success().primaryColor,
            text:
                '${widget.matchResult.matchingItems.length} items can be disposed here',
          ),
          const SizedBox(height: UIConstants.spacing2),
        ],

        // Non-matching items with Material 3 styling
        if (widget.matchResult.nonMatchingItems.isNotEmpty) ...[
          _buildBreakdownRow(
            context: context,
            icon: Icons.info_outline,
            color: OverlayStateStyles.warning().primaryColor,
            text:
                '${widget.matchResult.nonMatchingItems.length} items need different bins',
          ),
        ],
      ],
    );
  }

  Widget _buildBreakdownRow({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing3,
        vertical: UIConstants.spacing2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: UIConstants.spacing2),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterial3ActionButtons(
    BuildContext context,
    OverlayStateStyle stateStyle,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Dismiss button with Material 3 styling
        TextButton(
          onPressed: () {
            // First dismiss the overlay
            Navigator.of(context).pop();
            // Then call the onDismiss callback to reset scanning state
            widget.onDismiss?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacing4,
              vertical: UIConstants.spacing3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Text(
            'Close',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Dispose button with Material 3 elevated styling
        if (BinMatchingService.shouldAllowDisposal(widget.matchResult) &&
            widget.onDispose != null)
          FilledButton.icon(
            onPressed: _showDisposalConfirmationDialog,
            style: FilledButton.styleFrom(
              backgroundColor: stateStyle.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacing5,
                vertical: UIConstants.spacing3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              ),
              elevation: 2,
            ),
            icon: Icon(
              widget.matchResult.isPositiveResult
                  ? Icons.delete_outline
                  : Icons.check_circle_outline,
              size: 18,
            ),
            label: Text(
              widget.matchResult.isPositiveResult
                  ? 'Dispose All'
                  : 'Dispose Matching',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Material 3 particle effect painter with enhanced visual design
class _Material3ParticleEffectPainter extends CustomPainter {
  final double progress;
  final Color color;
  final OverlayStateStyle style;

  _Material3ParticleEffectPainter({
    required this.progress,
    required this.color,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final particleCount = 16; // Reduced for cleaner look

    // Create multiple layers for depth
    _paintParticleLayer(canvas, center, particleCount, 1.0);
    _paintParticleLayer(canvas, center, particleCount ~/ 2, 0.6);
  }

  void _paintParticleLayer(
    Canvas canvas,
    Offset center,
    int count,
    double layerIntensity,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(
        alpha: ((1.0 - progress) * 0.7 * layerIntensity).clamp(0.0, 1.0),
      );

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final distance = progress * 120 * layerIntensity;

      // Variable particle sizes for organic feel
      final baseSize = (1.0 - progress) * 6;
      final sizeVariation = 1.0 + 0.3 * math.sin(angle * 3);
      final particleSize = baseSize * sizeVariation;

      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);

      // Draw particles with subtle gradient effect
      final particleCenter = Offset(x, y);
      final gradient = RadialGradient(
        colors: [
          color.withValues(
            alpha: ((1.0 - progress) * 0.8 * layerIntensity).clamp(0.0, 1.0),
          ),
          color.withValues(
            alpha: ((1.0 - progress) * 0.2 * layerIntensity).clamp(0.0, 1.0),
          ),
        ],
      );

      final rect = Rect.fromCircle(
        center: particleCenter,
        radius: particleSize,
      );
      paint.shader = gradient.createShader(rect);

      canvas.drawCircle(particleCenter, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
