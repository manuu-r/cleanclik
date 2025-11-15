import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/presentation/screens/profile/profile_screen.dart';

/// Slide-in panel for the profile view
///
/// Slides from the left edge and covers 85% of screen width
class ProfileSlidePanel extends ConsumerWidget {
  final VoidCallback onClose;

  const ProfileSlidePanel({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            // Left panel (profile content)
            Expanded(
              flex: 85,
              child: GestureDetector(
                onTap: () {}, // Prevent tap propagation
                onHorizontalDragEnd: (details) {
                  // Swipe left to close
                  if (details.primaryVelocity! < 0) {
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
                              Text(
                                'Profile',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: onClose,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Profile content
                      const Expanded(
                        child: ProfileScreen(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Right dimmed area (tap to close)
            Expanded(
              flex: 15,
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }
}
