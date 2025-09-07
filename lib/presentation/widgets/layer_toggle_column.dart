import 'package:flutter/material.dart';
import 'package:cleanclik/presentation/widgets/layer_toggle.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

class LayerToggleColumn extends StatelessWidget {
  final bool showBins;
  final bool showHotspots;
  final bool showMissions;
  final bool showFriends;
  final bool? showUserLocation;
  final int binCount;
  final int hotspotCount;
  final int missionCount;
  final int friendCount;
  final void Function(String layer) onToggleLayer;

  const LayerToggleColumn({
    super.key,
    required this.showBins,
    required this.showHotspots,
    required this.showMissions,
    required this.showFriends,
    this.showUserLocation,
    required this.binCount,
    required this.hotspotCount,
    required this.missionCount,
    required this.friendCount,
    required this.onToggleLayer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayerToggle(
          icon: Icons.delete_outline,
          isActive: showBins,
          count: binCount,
          onTap: () => onToggleLayer('bins'),
          activeColor: NeonColors.electricGreen,
          badgeColor: NeonColors.electricGreen,
        ),
        const SizedBox(height: 8),
        LayerToggle(
          icon: Icons.whatshot,
          isActive: showHotspots,
          count: hotspotCount,
          onTap: () => onToggleLayer('hotspots'),
          activeColor: NeonColors.toxicPurple,
          badgeColor: NeonColors.toxicPurple,
        ),
        const SizedBox(height: 8),
        LayerToggle(
          icon: Icons.flag,
          isActive: showMissions,
          count: missionCount,
          onTap: () => onToggleLayer('missions'),
          activeColor: NeonColors.oceanBlue,
          badgeColor: NeonColors.oceanBlue,
        ),
        const SizedBox(height: 8),
        LayerToggle(
          icon: Icons.people,
          isActive: showFriends,
          count: friendCount,
          onTap: () => onToggleLayer('friends'),
          activeColor: NeonColors.earthOrange,
          badgeColor: NeonColors.earthOrange,
        ),
        if (showUserLocation != null) ...[
          const SizedBox(height: 8),
          LayerToggle(
            icon: Icons.my_location,
            isActive: showUserLocation!,
            count: 0,
            onTap: () => onToggleLayer('location'),
            activeColor: Colors.blue,
            badgeColor: Colors.blue,
          ),
        ],
      ],
    );
  }
}
