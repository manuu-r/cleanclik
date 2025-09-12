import 'package:flutter/material.dart';
import 'package:cleanclik/core/services/location/bin_matching_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/theme/app_theme.dart';

import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/overlays/base_material_overlay.dart';

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
    final stateStyle = _getStateStyle();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphismContainer.primary(
        padding: const EdgeInsets.all(UIConstants.spacing6),
        hasGlow: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with bin info using Material 3 styling
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing4),
              decoration: BoxDecoration(
                color: stateStyle.backgroundColor,
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(
                  color: stateStyle.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getBinIcon(), 
                    color: stateStyle.primaryColor, 
                    size: 32,
                  ),
                  const SizedBox(width: UIConstants.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.matchResult.binInfo.binId,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.matchResult.binInfo.category.codeName} Bin',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: stateStyle.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: UIConstants.spacing6),

            // Match result message with Material 3 styling
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(UIConstants.spacing4),
              decoration: BoxDecoration(
                color: stateStyle.backgroundColor,
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(
                  color: stateStyle.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    stateStyle.iconData,
                    color: stateStyle.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: UIConstants.spacing3),
                  Expanded(
                    child: Text(
                      widget.matchResult.message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
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

            // Action buttons with Material 3 styling
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isDisposing ? null : widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: UIConstants.spacing4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                        side: BorderSide(
                          color: _isDisposing
                              ? theme.colorScheme.outline.withValues(alpha: 0.3)
                              : theme.colorScheme.outline.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: UIConstants.spacing4),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: (widget.matchResult.matchingItems.isNotEmpty && !_isDisposing)
                        ? _handleDisposal
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: (widget.matchResult.matchingItems.isNotEmpty && !_isDisposing)
                          ? stateStyle.primaryColor
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: UIConstants.spacing4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                      ),
                      elevation: (widget.matchResult.matchingItems.isNotEmpty && !_isDisposing) ? 2 : 0,
                    ),
                    icon: _isDisposing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      _isDisposing
                          ? 'Disposing...'
                          : widget.matchResult.matchingItems.isNotEmpty
                              ? 'Dispose Items'
                              : 'No Items to Dispose',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
