import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/providers/inventory_provider.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

/// Widget for displaying inventory items with simplified data
/// Requirements: 2.1, 3.1
class InventoryDisplay extends ConsumerWidget {
  final bool isCompact;
  final Function(InventoryItem)? onItemTap;
  final Function(List<String>)? onItemsDispose;

  const InventoryDisplay({
    super.key,
    this.isCompact = false,
    this.onItemTap,
    this.onItemsDispose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryItems = ref.watch(inventoryItemsProvider);
    final isEmpty = ref.watch(isInventoryEmptyProvider);

    if (isEmpty) {
      return _buildEmptyState();
    }

    return _buildInventoryList(inventoryItems);
  }

  Widget _buildEmptyState() {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No items in inventory',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning objects to build your inventory',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(List<InventoryItem> items) {
    if (isCompact) {
      return _buildCompactList(items);
    }
    return _buildDetailedList(items);
  }

  Widget _buildCompactList(List<InventoryItem> items) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: _buildCompactItemCard(item),
          );
        },
      ),
    );
  }

  Widget _buildDetailedList(List<InventoryItem> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildDetailedItemCard(item),
        );
      },
    );
  }

  Widget _buildCompactItemCard(InventoryItem item) {
    return GestureDetector(
      onTap: () => onItemTap?.call(item),
      child: GlassmorphismContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(item.category),
              color: _getCategoryColor(item.category),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getCategoryDisplayName(item.category),
                style: TextStyle(
                  color: _getCategoryColor(item.category),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedItemCard(InventoryItem item) {
    return GestureDetector(
      onTap: () => onItemTap?.call(item),
      child: GlassmorphismContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getCategoryColor(item.category),
                  width: 1,
                ),
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: _getCategoryColor(item.category),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            item.category,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCategoryDisplayName(item.category),
                          style: TextStyle(
                            color: _getCategoryColor(item.category),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(item.confidence * 100).toInt()}% confidence',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(item.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Action button
            IconButton(
              onPressed: () => onItemsDispose?.call([item.id]),
              icon: const Icon(Icons.delete_outline),
              color: Colors.white.withOpacity(0.7),
              tooltip: 'Dispose item',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'recycle':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'landfill':
        return Icons.delete_outline;
      case 'ewaste':
        return Icons.electrical_services;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.inventory;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'recycle':
        return NeonColors.electricGreen;
      case 'organic':
        return NeonColors.oceanBlue;
      case 'landfill':
        return Colors.grey;
      case 'ewaste':
        return NeonColors.earthOrange;
      case 'hazardous':
        return NeonColors.toxicPurple;
      default:
        return Colors.blue;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'recycle':
        return 'Recycle';
      case 'organic':
        return 'Organic';
      case 'landfill':
        return 'Landfill';
      case 'ewaste':
        return 'E-Waste';
      case 'hazardous':
        return 'Hazardous';
      default:
        return 'Unknown';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
