import 'package:flutter/material.dart';

class HotspotData {
  final String name;
  final String priority;
  final double lat;
  final double lng;

  const HotspotData({
    required this.name,
    required this.priority,
    required this.lat,
    required this.lng,
  });
}

class HotspotMarker extends StatelessWidget {
  final HotspotData hotspot;
  final void Function(HotspotData) onTap;

  const HotspotMarker({super.key, required this.hotspot, required this.onTap});

  Color _getHotspotColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high priority':
        return Colors.red.withOpacity(0.8);
      case 'medium priority':
        return Colors.orange.withOpacity(0.8);
      case 'low priority':
        return Colors.yellow.withOpacity(0.8);
      default:
        return Colors.red.withOpacity(0.8);
    }
  }

  double _getHotspotSize(String priority) {
    switch (priority.toLowerCase()) {
      case 'high priority':
        return 24.0;
      case 'medium priority':
        return 20.0;
      case 'low priority':
        return 18.0;
      default:
        return 24.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(hotspot),
      child: Container(
        decoration: BoxDecoration(
          color: _getHotspotColor(hotspot.priority),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          Icons.local_fire_department,
          color: Colors.white,
          size: _getHotspotSize(hotspot.priority),
        ),
      ),
    );
  }
}
