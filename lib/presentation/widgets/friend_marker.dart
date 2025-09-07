import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

class FriendData {
  final String username;
  final String level;
  final String status;
  final double lat;
  final double lng;

  const FriendData({
    required this.username,
    required this.level,
    required this.status,
    required this.lat,
    required this.lng,
  });
}

class FriendMarker extends StatelessWidget {
  final FriendData friend;
  final void Function(FriendData) onTap;

  const FriendMarker({super.key, required this.friend, required this.onTap});

  Color _getFriendColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return NeonColors.earthOrange.withOpacity(0.9);
      case 'recently active':
        return NeonColors.earthOrange.withOpacity(0.7);
      case 'away':
        return NeonColors.earthOrange.withOpacity(0.5);
      default:
        return NeonColors.earthOrange.withOpacity(0.9);
    }
  }

  double _getFriendSize(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return 20.0;
      case 'recently active':
        return 18.0;
      case 'away':
        return 16.0;
      default:
        return 20.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(friend),
      child: Container(
        decoration: BoxDecoration(
          color: _getFriendColor(friend.status),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: _getFriendSize(friend.status),
        ),
      ),
    );
  }
}
