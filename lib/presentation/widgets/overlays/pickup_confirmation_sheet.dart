import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/providers/inventory_provider.dart';
import 'package:cleanclik/core/utils/haptics_util.dart';
import 'package:cleanclik/presentation/widgets/overlays/base_bottom_sheet.dart';

/// Bottom sheet for confirming trash pickup
///
/// Shows detected item and XP reward preview
class PickupConfirmationSheet extends ConsumerWidget {
  final DetectedObject detectedObject;
  final VoidCallback? onPickup;
  final VoidCallback? onSkip;

  const PickupConfirmationSheet({
    super.key,
    required this.detectedObject,
    this.onPickup,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Convert String category to WasteCategory enum
    final category = WasteCategory.fromString(detectedObject.category) ??
        WasteCategory.recycle;

    return BaseBottomSheet(
      heightFraction: 0.4,
      isDismissible: true,
      onDismiss: onSkip,
      title: 'Item Detected!',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Category icon and name
          Icon(
            _getCategoryIcon(category.id),
            size: 64,
            color: category.color,
          ),
          const SizedBox(height: 12),
          Text(
            category.codeName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Confidence
          Text(
            '${(detectedObject.confidence * 100).toStringAsFixed(0)}% confident',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          // XP reward preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '+25 XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Actions
          Row(
            children: [
              // Skip button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    HapticsUtil.selectionClick();
                    if (onSkip != null) onSkip!();
                  },
                  child: Text(
                    'Skip',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Pick up button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticsUtil.mediumImpact();
                    // Add to inventory
                    await ref
                        .read(inventoryServiceProvider)
                        .addItemFromDetectedObject(detectedObject);
                    if (onPickup != null) onPickup!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Pick Up',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
        return Icons.recycling;
      case 'organic':
        return Icons.compost;
      case 'ewaste':
        return Icons.devices;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.delete;
    }
  }
}
