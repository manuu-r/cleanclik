import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/providers/inventory_provider.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/neon_icon_button.dart';

enum DetailType { bin, hotspot, mission, friend, inventory }

class DetailCard extends ConsumerWidget {
  final DetailType type;
  final String title;
  final Map<String, dynamic> details;
  final List<ActionButton> actions;
  final VoidCallback onClose;
  final EdgeInsets padding;
  final InventoryItem? inventoryItem; // For inventory-specific details

  const DetailCard({
    super.key,
    required this.type,
    required this.title,
    required this.details,
    required this.actions,
    required this.onClose,
    this.padding = const EdgeInsets.all(16.0),
    this.inventoryItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: padding,
        child: GlassmorphismContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildDetails(),
              const SizedBox(height: 20),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        NeonIconButton(
          icon: Icons.close,
          color: Colors.white,
          onTap: onClose,
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case DetailType.bin:
        iconData = _getBinIcon(details['type'] ?? 'General');
        iconColor = _getTypeColor();
        break;
      case DetailType.hotspot:
        iconData = Icons.local_fire_department;
        iconColor = Colors.orange;
        break;
      case DetailType.mission:
        iconData = Icons.flag;
        iconColor = NeonColors.oceanBlue;
        break;
      case DetailType.friend:
        iconData = Icons.person;
        iconColor = NeonColors.earthOrange;
        break;
      case DetailType.inventory:
        iconData = _getInventoryIcon(inventoryItem?.category ?? 'general');
        iconColor = _getInventoryColor(inventoryItem?.category ?? 'general');
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildDetails() {
    final detailWidgets = <Widget>[];

    details.forEach((key, value) {
      if (key != 'type') {
        // Type is already shown in the icon
        detailWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$key: ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    if (type == DetailType.bin && details.containsKey('fillLevel')) {
      detailWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Fill Level: ${details['fillLevel']}%',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (details['fillLevel'] as int) / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(_getTypeColor()),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detailWidgets,
    );
  }

  Widget _buildActions() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: actions);
  }

  Color _getTypeColor() {
    if (type != DetailType.bin) {
      return Colors.blue;
    }

    final binType = details['type'] ?? 'General';
    switch (binType) {
      case 'Recycling':
        return NeonColors.electricGreen;
      case 'Organic':
        return NeonColors.oceanBlue;
      case 'E-waste':
        return NeonColors.earthOrange;
      case 'Hazardous':
        return NeonColors.toxicPurple;
      case 'General':
      default:
        return Colors.grey;
    }
  }

  IconData _getBinIcon(String type) {
    switch (type) {
      case 'Recycling':
      case 'Organic':
      case 'General':
        return Icons.delete_outline;
      case 'E-waste':
        return Icons.electrical_services;
      case 'Hazardous':
        return Icons.warning;
      default:
        return Icons.delete_outline;
    }
  }

  /// Get icon for inventory item category
  /// Requirements: 2.1, 3.1
  IconData _getInventoryIcon(String category) {
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

  /// Get color for inventory item category
  /// Requirements: 2.1, 3.1
  Color _getInventoryColor(String category) {
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
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return NeonIconButton.secondary(
      label: label,
      icon: icon,
      color: color,
      onTap: onPressed,
      buttonSize: ButtonSize.small,
    );
  }
}
