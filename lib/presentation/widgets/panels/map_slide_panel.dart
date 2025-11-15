import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/presentation/screens/map/map_screen.dart';

/// Slide-in panel for the map view
///
/// Slides from the right edge and covers 85% of screen width
class MapSlidePanel extends ConsumerWidget {
  final VoidCallback onClose;

  const MapSlidePanel({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            // Left dimmed area (tap to close)
            Expanded(
              flex: 15,
              child: Container(),
            ),
            // Right panel (map content)
            Expanded(
              flex: 85,
              child: GestureDetector(
                onTap: () {}, // Prevent tap propagation
                onHorizontalDragEnd: (details) {
                  // Swipe right to close
                  if (details.primaryVelocity! > 0) {
                    onClose();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with close button
                      SafeArea(
                        bottom: false,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                onPressed: onClose,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nearby Bins',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Map content
                      const Expanded(
                        child: MapScreen(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
