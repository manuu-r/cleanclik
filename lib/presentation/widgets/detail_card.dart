import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/glassmorphism_container.dart';

enum DetailType { bin, hotspot, mission, friend }

class DetailCard extends StatelessWidget {
  final DetailType type;
  final String title;
  final Map<String, dynamic> details;
  final List<ActionButton> actions;
  final VoidCallback onClose;
  final EdgeInsets padding;

  const DetailCard({
    Key? key,
    required this.type,
    required this.title,
    required this.details,
    required this.actions,
    required this.onClose,
    this.padding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
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
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color)),
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }
}
