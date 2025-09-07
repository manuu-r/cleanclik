import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/neon_colors.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/services/bin_matching_service.dart';
import '../../core/services/inventory_service.dart';
import 'glassmorphism_container.dart';
import 'disposal_confirmation_dialog.dart';

/// Overlay widget that provides visual feedback for bin matching results
class BinFeedbackOverlay extends StatefulWidget {
  final BinMatchResult matchResult;
  final VoidCallback onDismiss;
  final Function(List<InventoryItem> itemsToDispose)? onDispose;
  
  const BinFeedbackOverlay({
    super.key,
    required this.matchResult,
    required this.onDismiss,
    this.onDispose,
  });

  @override
  State<BinFeedbackOverlay> createState() => _BinFeedbackOverlayState();
}

class _BinFeedbackOverlayState extends State<BinFeedbackOverlay>
    with TickerProviderStateMixin {
  
  late AnimationController _overlayController;
  late AnimationController _breathingController;
  late AnimationController _particleController;
  
  late Animation<double> _overlayAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _particleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOutBack,
    );
    
    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );
    
    // Start animations
    _overlayController.forward();
    
    if (widget.matchResult.isInfoResult) {
      _breathingController.repeat(reverse: true);
    }
    
    if (widget.matchResult.isPositiveResult) {
      _particleController.forward();
    }
    
    // Provide haptic feedback
    _provideHapticFeedback();
  }
  
  @override
  void dispose() {
    _overlayController.dispose();
    _breathingController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  void _provideHapticFeedback() {
    switch (widget.matchResult.matchType) {
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
  
  Color _getOverlayColor() {
    switch (widget.matchResult.matchType) {
      case BinMatchType.perfectMatch:
        return NeonColors.electricGreen;
      case BinMatchType.partialMatch:
        return NeonColors.solarYellow;
      case BinMatchType.noMatch:
        return NeonColors.glowRed;
      case BinMatchType.emptyInventory:
        return NeonColors.oceanBlue;
    }
  }

  /// Show the disposal confirmation dialog
  void _showDisposalConfirmationDialog() {
    if (widget.onDispose == null) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return DisposalConfirmationDialog(
          matchResult: widget.matchResult,
          onConfirmDisposal: (itemsToDispose) async {
            // Call the disposal callback
            await widget.onDispose!(itemsToDispose);
          },
          onCancel: () {
            // Close the dialog
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Full screen colored overlay
              _buildColoredOverlay(),
              
              // Particle effects for success
              if (widget.matchResult.isPositiveResult)
                _buildParticleEffects(),
              
              // Main feedback content
              _buildFeedbackContent(context),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildColoredOverlay() {
    final overlayColor = _getOverlayColor();
    
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, child) {
          final opacity = widget.matchResult.isInfoResult 
              ? 0.1 * _breathingAnimation.value
              : 0.15;
              
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  overlayColor.withOpacity(opacity),
                  overlayColor.withOpacity(opacity * 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildParticleEffects() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticleEffectPainter(
              progress: _particleAnimation.value,
              color: NeonColors.electricGreen,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFeedbackContent(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _overlayAnimation,
        child: GlassmorphismContainer(
          margin: const EdgeInsets.all(UIConstants.spacing6),
          padding: const EdgeInsets.all(UIConstants.spacing6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and main message
              _buildMainMessage(context),
              
              // Additional info if available
              if (widget.matchResult.additionalInfo != null) ...[
                const SizedBox(height: UIConstants.spacing4),
                _buildAdditionalInfo(context),
              ],
              
              // Item breakdown for partial matches
              if (widget.matchResult.isWarningResult) ...[
                const SizedBox(height: UIConstants.spacing4),
                _buildItemBreakdown(context),
              ],
              
              // Action buttons
              const SizedBox(height: UIConstants.spacing6),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainMessage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with breathing animation for info messages
        AnimatedBuilder(
          animation: widget.matchResult.isInfoResult ? _breathingAnimation : _overlayAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.matchResult.isInfoResult ? _breathingAnimation.value : 1.0,
              child: Text(
                widget.matchResult.icon,
                style: const TextStyle(fontSize: 48),
              ),
            );
          },
        ),
        
        const SizedBox(height: UIConstants.spacing4),
        
        // Main message
        Text(
          widget.matchResult.message,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Bin info
        const SizedBox(height: UIConstants.spacing2),
        Text(
          'Bin: ${widget.matchResult.binInfo.category.codeName}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildAdditionalInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Text(
        widget.matchResult.additionalInfo!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildItemBreakdown(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Matching items
        if (widget.matchResult.matchingItems.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: NeonColors.electricGreen, size: 16),
              const SizedBox(width: UIConstants.spacing1),
              Text(
                '${widget.matchResult.matchingItems.length} items can be disposed here',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: NeonColors.electricGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.spacing1),
        ],
        
        // Non-matching items
        if (widget.matchResult.nonMatchingItems.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, color: NeonColors.solarYellow, size: 16),
              const SizedBox(width: UIConstants.spacing1),
              Text(
                '${widget.matchResult.nonMatchingItems.length} items need different bins',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: NeonColors.solarYellow,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Dismiss button
        TextButton(
          onPressed: widget.onDismiss,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacing4,
              vertical: UIConstants.spacing2,
            ),
          ),
          child: const Text('Close'),
        ),
        
        // Dispose button (only for matches)
        if (BinMatchingService.shouldAllowDisposal(widget.matchResult) && widget.onDispose != null)
          ElevatedButton(
            onPressed: _showDisposalConfirmationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getOverlayColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacing6,
                vertical: UIConstants.spacing2,
              ),
            ),
            child: Text(
              widget.matchResult.isPositiveResult ? 'Dispose All' : 'Dispose Matching',
            ),
          ),
      ],
    );
  }
}

/// Custom painter for particle effects during successful matches
class _ParticleEffectPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  _ParticleEffectPainter({
    required this.progress,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;
    
    final paint = Paint()
      ..color = color.withOpacity((1.0 - progress) * 0.8)
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final particleCount = 20;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * 3.14159;
      final distance = progress * 150;
      final particleSize = (1.0 - progress) * 8;
      
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}