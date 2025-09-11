import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

class BinData {
  final String name;
  final String type;
  final int fillLevel;
  final double lat;
  final double lng;

  const BinData({
    required this.name,
    required this.type,
    required this.fillLevel,
    required this.lat,
    required this.lng,
  });
}

class BinMarker extends StatelessWidget {
  final BinData bin;
  final void Function(BinData) onTap;

  const BinMarker({super.key, required this.bin, required this.onTap});

  Color _getBinColor(String type) {
    switch (type.toLowerCase()) {
      case 'recycling':
        return NeonColors.electricGreen;
      case 'organic':
        return NeonColors.oceanBlue;
      case 'e-waste':
        return NeonColors.earthOrange;
      case 'hazardous':
        return NeonColors.toxicPurple;
      case 'general':
        return Colors.grey;
      default:
        return NeonColors.electricGreen;
    }
  }

  IconData _getBinIcon(String type) {
    switch (type.toLowerCase()) {
      case 'recycling':
      case 'organic':
      case 'general':
        return Icons.delete_outline;
      case 'e-waste':
        return Icons.electrical_services;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(bin),
      child: Container(
        decoration: BoxDecoration(
          color: _getBinColor(bin.type),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(_getBinIcon(bin.type), color: Colors.white, size: 20),
      ),
    );
  }
}
