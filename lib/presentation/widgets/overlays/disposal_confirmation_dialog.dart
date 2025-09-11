import 'package:flutter/material.dart';
import 'package:cleanclik/core/services/location/bin_matching_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

class DisposalConfirmationDialog extends StatefulWidget {
  final BinMatchResult matchResult;
  final Function(List<InventoryItem> itemsToDispose) onConfirmDisposal;
  final VoidCallback onCancel;

  const DisposalConfirmationDialog({
    super.key,
    required this.matchResult,
    required this.onConfirmDisposal,
    required this.onCancel,
  });

  @override
  State<DisposalConfirmationDialog> createState() =>
      _DisposalConfirmationDialogState();
}

class _DisposalConfirmationDialogState
    extends State<DisposalConfirmationDialog> {
  bool _isDisposing = false;

  /// Handle disposal with proper async/await and error handling
  Future<void> _handleDisposal() async {
    if (_isDisposing || widget.matchResult.matchingItems.isEmpty) {
      return;
    }

    setState(() {
      _isDisposing = true;
    });

    try {
      // Call the disposal callback with proper async handling
      await widget.onConfirmDisposal(widget.matchResult.matchingItems);

      // Only pop if the widget is still mounted and context is valid
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle disposal errors gracefully
      debugPrint('❌ Disposal error: $e');

      if (mounted) {
        setState(() {
          _isDisposing = false;
        });

        // Show error message to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to dispose items: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphismContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with bin info
            Row(
              children: [
                Icon(_getBinIcon(), color: _getBinColor(), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.matchResult.binInfo.binId,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.matchResult.binInfo.category.codeName} Bin',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getBinColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Match result message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getMessageBackgroundColor().withAlpha(
                  (0.2 * 255).toInt(),
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getMessageBackgroundColor().withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.matchResult.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.matchResult.message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.matchResult.matchingItems.isNotEmpty) ...[
              const SizedBox(height: 20),

              // Items to dispose section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Items to Dispose (${widget.matchResult.matchingItems.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: NeonColors.electricGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.matchResult.matchingItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.matchResult.matchingItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: NeonColors.electricGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withAlpha(
                                (0.9 * 255).toInt(),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(item.category),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getCategoryDisplayName(item.category),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Points info
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NeonColors.earthOrange.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: NeonColors.earthOrange.withAlpha(
                      (0.4 * 255).toInt(),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: NeonColors.earthOrange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'You will earn ${_calculatePoints()} points',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: NeonColors.earthOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (widget.matchResult.nonMatchingItems.isNotEmpty) ...[
              const SizedBox(height: 20),

              // Items that don't match
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Items to Keep (${widget.matchResult.nonMatchingItems.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: NeonColors.solarYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These items need different bins and will stay in your inventory.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha((0.7 * 255).toInt()),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                constraints: const BoxConstraints(maxHeight: 80),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.matchResult.nonMatchingItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.matchResult.nonMatchingItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: NeonColors.solarYellow,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withAlpha(
                                (0.8 * 255).toInt(),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(item.category),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getCategoryDisplayName(item.category),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isDisposing ? null : widget.onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _isDisposing
                              ? Colors.grey.withAlpha((0.3 * 255).toInt())
                              : Colors.white.withAlpha((0.3 * 255).toInt()),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _isDisposing
                            ? Colors.grey.withAlpha((0.5 * 255).toInt())
                            : Colors.white.withAlpha((0.8 * 255).toInt()),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        (widget.matchResult.matchingItems.isNotEmpty &&
                            !_isDisposing)
                        ? _handleDisposal
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (widget.matchResult.matchingItems.isNotEmpty &&
                              !_isDisposing)
                          ? NeonColors.electricGreen
                          : Colors.grey.withAlpha((0.5 * 255).toInt()),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation:
                          (widget.matchResult.matchingItems.isNotEmpty &&
                              !_isDisposing)
                          ? 4
                          : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDisposing) ...[
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Disposing...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          Icon(Icons.delete_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.matchResult.matchingItems.isNotEmpty
                                ? 'Dispose Items'
                                : 'No Items to Dispose',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBinIcon() {
    switch (widget.matchResult.binInfo.category.id) {
      case 'recycle':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'ewaste':
        return Icons.electrical_services;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.delete;
    }
  }

  Color _getBinColor() {
    switch (widget.matchResult.binInfo.category.id) {
      case 'recycle':
        return NeonColors.electricGreen;
      case 'organic':
        return NeonColors.oceanBlue;
      case 'ewaste':
        return NeonColors.earthOrange;
      case 'hazardous':
        return NeonColors.toxicPurple;
      default:
        return Colors.grey;
    }
  }

  Color _getMessageBackgroundColor() {
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'recycle':
        return NeonColors.electricGreen;
      case 'organic':
        return NeonColors.oceanBlue;
      case 'ewaste':
        return NeonColors.earthOrange;
      case 'hazardous':
        return NeonColors.toxicPurple;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'recycle':
        return 'Recycle';
      case 'organic':
        return 'Organic';
      case 'ewaste':
        return 'E-Waste';
      case 'hazardous':
        return 'Hazardous';
      default:
        return category.toUpperCase();
    }
  }

  int _calculatePoints() {
    const categoryPoints = {
      'recycle': 10,
      'organic': 8,
      'ewaste': 15,
      'hazardous': 20,
    };

    int totalPoints = 0;
    for (final item in widget.matchResult.matchingItems) {
      totalPoints += categoryPoints[item.category] ?? 5;
    }
    return totalPoints;
  }
}
