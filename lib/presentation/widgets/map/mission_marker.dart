import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

class MissionData {
  final String name;
  final String items;
  final String timeLeft;
  final double lat;
  final double lng;

  const MissionData({
    required this.name,
    required this.items,
    required this.timeLeft,
    required this.lat,
    required this.lng,
  });
}

class MissionMarker extends StatelessWidget {
  final MissionData mission;
  final void Function(MissionData) onTap;

  const MissionMarker({super.key, required this.mission, required this.onTap});

  Color _getMissionColor() {
    return NeonColors.oceanBlue.withOpacity(0.9);
  }

  double _getMissionSize() {
    return 22.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(mission),
      child: Container(
        decoration: BoxDecoration(
          color: _getMissionColor(),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(Icons.flag, color: Colors.white, size: _getMissionSize()),
      ),
    );
  }
}
