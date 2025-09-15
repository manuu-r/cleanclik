import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

class MapControlItem {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final bool? isActive;
  final int? count;

  const MapControlItem({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.isActive,
    this.count,
  });
}

class MapControlColumn extends StatelessWidget {
  final List<MapControlItem> items;

  const MapControlColumn({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MapControlButton(item: item),
        );
      }).toList(),
    );
  }
}

class _MapControlButton extends StatefulWidget {
  final MapControlItem item;

  const _MapControlButton({required this.item});

  @override
  State<_MapControlButton> createState() => _MapControlButtonState();
}

class _MapControlButtonState extends State<_MapControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.item.isActive == true;
    final iconColor = isActive ? widget.item.color : Colors.white;
    
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.item.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? widget.item.color : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                      if (isActive)
                        BoxShadow(
                          color: widget.item.color.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                if (widget.item.count != null && widget.item.count! > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      decoration: BoxDecoration(
                        color: widget.item.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.item.count! > 99 ? '99+' : '${widget.item.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}