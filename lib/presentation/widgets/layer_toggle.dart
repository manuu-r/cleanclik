import 'package:flutter/material.dart';

class LayerToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final int count;
  final VoidCallback onTap;
  final Color activeColor;
  final Color badgeColor;

  const LayerToggle({
    super.key,
    required this.icon,
    required this.isActive,
    required this.count,
    required this.onTap,
    this.activeColor = const Color(0xFF39FF14), // Default neon green
    this.badgeColor = const Color(0xFF39FF14),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isActive ? activeColor : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : Colors.white,
              size: 24,
            ),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
