import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/location_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/providers/inventory_provider.dart';
import 'package:cleanclik/core/utils/haptics_util.dart';
import 'package:cleanclik/presentation/widgets/overlays/base_bottom_sheet.dart';

/// Bottom sheet for disposal options
///
/// Shows bin info and compatible items for disposal
class DisposalOptionsSheet extends ConsumerWidget {
  final BinLocation bin;
  final VoidCallback? onDisposeAll;
  final VoidCallback? onSelectItems;
  final VoidCallback? onCancel;

  const DisposalOptionsSheet({
    super.key,
    required this.bin,
    this.onDisposeAll,
    this.onSelectItems,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return BaseBottomSheet(
      heightFraction: 0.5,
      isDismissible: true,
      onDismiss: onCancel,
      title: 'Dispose Items',
      content: inventoryAsync.when(
        data: (items) {
          // Filter compatible items by bin category
          final compatibleItems = items.where((item) {
            // TODO: Add proper category matching logic
            // For now, show all items
            return true;
          }).toList();

          final totalXP = compatibleItems.length * 50; // 50 XP per disposal

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Bin info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Color(bin.category?.colorValue ?? Colors.grey.value),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bin.category?.displayName ?? 'General Bin',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${bin.fillLevel}% full',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Compatible items count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compatible Items',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${compatibleItems.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // XP preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.2),
                      Colors.teal.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+$totalXP XP',
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
              if (compatibleItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No compatible items',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    // Select items button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticsUtil.selectionClick();
                          if (onSelectItems != null) onSelectItems!();
                        },
                        child: Text(
                          'Select Items',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Dispose all button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticsUtil.successPattern();
                          if (onDisposeAll != null) onDisposeAll!();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Dispose All',
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Error loading inventory',
            style: TextStyle(color: Colors.red[300]),
          ),
        ),
      ),
    );
  }
}
