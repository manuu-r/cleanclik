import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_screen.dart';
import 'package:cleanclik/presentation/widgets/camera/camera_hud.dart';
import 'package:cleanclik/presentation/widgets/overlays/pickup_confirmation_sheet.dart';
import 'package:cleanclik/presentation/widgets/overlays/xp_reward_sheet.dart';

/// Unified camera-first screen with XP HUD and bottom sheets
///
/// Main entry point for the camera-first UX
class UnifiedCameraScreen extends ConsumerStatefulWidget {
  const UnifiedCameraScreen({super.key});

  @override
  ConsumerState<UnifiedCameraScreen> createState() =>
      _UnifiedCameraScreenState();
}

class _UnifiedCameraScreenState extends ConsumerState<UnifiedCameraScreen> {
  // UI state
  bool _showPickupSheet = false;
  bool _showXPRewardSheet = false;
  DetectedObject? _pendingPickup;
  int _lastXPGain = 0;
  String _lastAction = '';
  bool _didLevelUp = false;
  int? _newLevel;

  // Track previous user state to detect changes
  int? _previousLevel;
  int? _previousPoints;

  @override
  Widget build(BuildContext context) {
    // Watch user to detect XP/level changes
    final userAsync = ref.watch(syncedCurrentUserProvider);

    // Listen for user changes to trigger XP animations
    ref.listen<AsyncValue>(syncedCurrentUserProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && _previousPoints != null) {
          // Check if points changed
          if (user.totalPoints > _previousPoints!) {
            final xpGained = user.totalPoints - _previousPoints!;
            final leveledUp = user.level > (_previousLevel ?? user.level);

            setState(() {
              _lastXPGain = xpGained;
              _lastAction = 'Trash Picked Up!';
              _didLevelUp = leveledUp;
              _newLevel = leveledUp ? user.level : null;
              _showXPRewardSheet = true;
            });
          }
        }

        // Update previous values
        if (user != null) {
          _previousLevel = user.level;
          _previousPoints = user.totalPoints;
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera view (persistent, full screen)
          const Positioned.fill(
            child: ARCameraScreen(
              initialMode: CameraMode.mlDetection,
            ),
          ),

          // 2. Top HUD (XP bar, level, streak) - always visible
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CameraHUD(),
          ),

          // 3. Floating action buttons (bottom right)
          Positioned(
            bottom: 32,
            right: 16,
            child: _buildFloatingActions(),
          ),

          // 4. Pickup confirmation sheet (conditional)
          if (_showPickupSheet && _pendingPickup != null)
            PickupConfirmationSheet(
              detectedObject: _pendingPickup!,
              onPickup: () {
                setState(() {
                  _showPickupSheet = false;
                });
                // XP reward will be triggered by user change listener
              },
              onSkip: () {
                setState(() {
                  _showPickupSheet = false;
                  _pendingPickup = null;
                });
              },
            ),

          // 5. XP reward sheet (conditional)
          if (_showXPRewardSheet)
            XPRewardSheet(
              xpGained: _lastXPGain,
              actionLabel: _lastAction,
              leveledUp: _didLevelUp,
              newLevel: _newLevel,
              onDismiss: () {
                setState(() {
                  _showXPRewardSheet = false;
                  _didLevelUp = false;
                  _newLevel = null;
                });
              },
            ),

          // TODO: Add slide panels for Map, Profile, Inventory
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Map button
        FloatingActionButton(
          heroTag: 'map',
          onPressed: () {
            // TODO: Show map slide panel
            // For now, just navigate to map
            // context.go('/map');
          },
          backgroundColor: Colors.blue.withOpacity(0.9),
          child: const Icon(Icons.map),
        ),
        const SizedBox(height: 12),
        // Profile button
        FloatingActionButton(
          heroTag: 'profile',
          onPressed: () {
            // TODO: Show profile slide panel
            // For now, just navigate to profile
            // context.go('/profile');
          },
          backgroundColor: Colors.purple.withOpacity(0.9),
          child: const Icon(Icons.person),
        ),
        const SizedBox(height: 12),
        // Inventory button
        FloatingActionButton(
          heroTag: 'inventory',
          onPressed: () {
            // TODO: Show inventory slide panel
          },
          backgroundColor: Colors.orange.withOpacity(0.9),
          child: const Icon(Icons.inventory_2),
        ),
      ],
    );
  }
}
