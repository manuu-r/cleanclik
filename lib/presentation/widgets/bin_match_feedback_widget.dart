import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/bin_matching_service.dart';
import '../../core/services/inventory_service.dart';

class BinMatchFeedbackWidget extends StatefulWidget {
  final BinMatchResult matchResult;
  final VoidCallback? onDismiss;

  const BinMatchFeedbackWidget({
    super.key,
    required this.matchResult,
    this.onDismiss,
  });

  @override
  State<BinMatchFeedbackWidget> createState() => _BinMatchFeedbackWidgetState();
}

class _BinMatchFeedbackWidgetState extends State<BinMatchFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Trigger haptic feedback and confetti for success
    if (widget.matchResult.matchType == BinMatchType.perfectMatch) {
      HapticFeedback.heavyImpact();
      _confettiController.forward();
    } else if (widget.matchResult.matchType == BinMatchType.emptyInventory) {
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black87,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _fadeAnimation,
            _confettiAnimation,
          ]),
          builder: (context, child) {
            return Stack(
              children: [
                // Confetti effect for success
                if (widget.matchResult.matchType == BinMatchType.perfectMatch)
                  _buildConfettiEffect(),

                // Main feedback content
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildFeedbackContent(),
                    ),
                  ),
                ),

                // Dismiss hint
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Tap anywhere to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeedbackContent() {
    switch (widget.matchResult.matchType) {
      case BinMatchType.perfectMatch:
        return _buildSuccessFeedback(widget.matchResult.matchingItems, 0);

      case BinMatchType.emptyInventory:
        return _buildNoItemsFeedback(
          widget.matchResult.binInfo.category.id,
          [],
        );

      case BinMatchType.noMatch:
      case BinMatchType.partialMatch:
        return _buildWrongCategoryFeedback(
          widget.matchResult.binInfo.category.id,
          widget.matchResult.inventoryItems
              .map((item) => item.category)
              .toList(),
        );
    }
  }

  Widget _buildSuccessFeedback(List<InventoryItem> items, int points) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.green.shade700,
            ),
          ),

          const SizedBox(height: 16),

          // Success message
          const Text(
            'Perfect Match!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Items disposed
          Text(
            '${items.length} item${items.length == 1 ? '' : 's'} disposed correctly',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          const SizedBox(height: 16),

          // Points awarded
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$points points',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Environmental impact message
          Text(
            _getEnvironmentalMessage(
              items.isNotEmpty ? items.first.category : 'recycle',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoItemsFeedback(
    String binCategory,
    List<String> availableCategories,
  ) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 50,
              color: Colors.orange.shade600,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Empty Inventory',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'This is a ${_getCategoryDisplayName(binCategory)} bin',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          const SizedBox(height: 16),

          const Text(
            'Pick up some items first, then scan a bin to dispose of them!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWrongCategoryFeedback(
    String binCategory,
    List<String> carriedCategories,
  ) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_outlined,
              size: 50,
              color: Colors.red.shade600,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Wrong Bin Type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'This bin is for ${_getCategoryDisplayName(binCategory)}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          const SizedBox(height: 16),

          const Text(
            'You\'re carrying:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: carriedCategories.map((category) {
              return Chip(
                label: Text(_getCategoryDisplayName(category)),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(color: Colors.red.shade600, fontSize: 12),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          const Text(
            'Find the correct bin for your items!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiEffect() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _confettiAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: ConfettiPainter(_confettiAnimation.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'recycle':
        return 'Recycling';
      case 'organic':
        return 'Organic Waste';
      case 'landfill':
        return 'General Waste';
      case 'ewaste':
        return 'E-Waste';
      case 'hazardous':
        return 'Hazardous Waste';
      default:
        return category.toUpperCase();
    }
  }

  String _getEnvironmentalMessage(String category) {
    switch (category) {
      case 'recycle':
        return 'Great job! Recycling helps reduce waste and conserve resources.';
      case 'organic':
        return 'Excellent! Organic waste can be composted to enrich soil.';
      case 'landfill':
        return 'Good disposal! Proper waste management keeps our environment clean.';
      case 'ewaste':
        return 'Perfect! E-waste recycling recovers valuable materials safely.';
      case 'hazardous':
        return 'Critical disposal! You\'ve prevented environmental contamination.';
      default:
        return 'Thank you for proper waste disposal!';
    }
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.orange,
    ];

    // Draw confetti particles
    for (int i = 0; i < 50; i++) {
      final x = (i * 37) % size.width;
      final y =
          size.height * 0.2 + (progress * size.height * 0.8) + (i * 13) % 100;

      if (y > size.height) continue;

      paint.color = colors[i % colors.length];

      // Draw small rectangles as confetti
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 8, height: 4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
