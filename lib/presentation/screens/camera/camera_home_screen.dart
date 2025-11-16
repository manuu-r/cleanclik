import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/models/location_models.dart';
import 'package:cleanclik/core/models/user_models.dart';
import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/core/providers/inventory_provider.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_screen.dart';
import 'package:cleanclik/presentation/widgets/camera/camera_hud.dart';
import 'package:cleanclik/presentation/widgets/overlays/pickup_confirmation_sheet.dart';
import 'package:cleanclik/presentation/widgets/overlays/xp_reward_sheet.dart';
import 'package:cleanclik/presentation/widgets/overlays/disposal_options_sheet.dart';
import 'package:cleanclik/presentation/widgets/panels/map_slide_panel.dart';
import 'package:cleanclik/presentation/widgets/panels/profile_slide_panel.dart';
import 'package:cleanclik/presentation/widgets/panels/inventory_slide_panel.dart';

/// Camera home screen with XP HUD and bottom sheets
///
/// Main entry point for the camera-first UX
class CameraHomeScreen extends ConsumerStatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  ConsumerState<CameraHomeScreen> createState() =>
      _CameraHomeScreenState();
}

class _CameraHomeScreenState extends ConsumerState<CameraHomeScreen> {
  // Panel state
  bool _showMapPanel = false;
  bool _showProfilePanel = false;
  bool _showInventoryPanel = false;

  // Bottom sheet state
  bool _showPickupSheet = false;
  bool _showXPRewardSheet = false;
  bool _showDisposalSheet = false;

  // Data for sheets
  DetectedObject? _pendingPickup;
  BinLocation? _selectedBin;
  int _lastXPGain = 0;
  String _lastAction = '';
  bool _didLevelUp = false;
  int? _newLevel;

  // Track previous user state to detect changes
  int? _previousLevel;
  int? _previousPoints;

  @override
  void initState() {
    super.initState();
    // Initialize tracking values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userAsync = ref.read(syncedCurrentUserProvider);
      userAsync.whenData((user) {
        if (user != null) {
          setState(() {
            _previousLevel = user.level;
            _previousPoints = user.totalPoints;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch user to detect XP/level changes
    final userAsync = ref.watch(syncedCurrentUserProvider);

    // Listen for user changes to trigger XP animations
    ref.listen<AsyncValue<User?>>(syncedCurrentUserProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && _previousPoints != null && mounted) {
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
              // Close pickup sheet if open
              _showPickupSheet = false;
              _pendingPickup = null;
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

          // 2. Top HUD (XP bar, level) - always visible
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

          // 4. Slide panels (conditional, full screen overlays)
          if (_showMapPanel)
            Positioned.fill(
              child: MapSlidePanel(
                onClose: () => setState(() => _showMapPanel = false),
              ),
            ),

          if (_showProfilePanel)
            Positioned.fill(
              child: ProfileSlidePanel(
                onClose: () => setState(() => _showProfilePanel = false),
              ),
            ),

          if (_showInventoryPanel)
            Positioned.fill(
              child: InventorySlidePanel(
                onClose: () => setState(() => _showInventoryPanel = false),
              ),
            ),

          // 5. Bottom sheets (conditional, rendered on top of panels)
          if (_showPickupSheet && _pendingPickup != null)
            Positioned.fill(
              child: PickupConfirmationSheet(
                detectedObject: _pendingPickup!,
                onPickup: () {
                  // Pickup will trigger user points change, which triggers XP sheet
                  setState(() {
                    _showPickupSheet = false;
                  });
                },
                onSkip: () {
                  setState(() {
                    _showPickupSheet = false;
                    _pendingPickup = null;
                  });
                },
              ),
            ),

          if (_showDisposalSheet && _selectedBin != null)
            Positioned.fill(
              child: DisposalOptionsSheet(
                bin: _selectedBin!,
                onDisposeAll: () async {
                  // Dispose all items
                  final items = ref.read(inventoryItemsProvider);
                  if (items.isNotEmpty) {
                    // Clear inventory and award XP
                    for (final item in items) {
                      await ref.read(inventoryServiceProvider).removeItem(item.id);
                    }

                    // Award XP by manually updating user points
                    // XP listener will automatically trigger reward sheet
                    setState(() {
                      _showDisposalSheet = false;
                      _selectedBin = null;
                    });
                  }
                },
                onSelectItems: () {
                  // TODO: Show item selection UI
                  setState(() {
                    _showDisposalSheet = false;
                  });
                },
                onCancel: () {
                  setState(() {
                    _showDisposalSheet = false;
                    _selectedBin = null;
                  });
                },
              ),
            ),

          if (_showXPRewardSheet)
            Positioned.fill(
              child: XPRewardSheet(
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
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Map button with label
          _buildFAB(
            heroTag: 'map',
            icon: Icons.map,
            label: 'Map',
            color: Colors.blue,
            onPressed: () {
              setState(() {
                _showMapPanel = true;
                _showProfilePanel = false;
                _showInventoryPanel = false;
              });
            },
          ),
          const SizedBox(height: 12),
          // Inventory button with label
          _buildFAB(
            heroTag: 'inventory',
            icon: Icons.inventory_2,
            label: 'Bag',
            color: Colors.orange,
            onPressed: () {
              setState(() {
                _showInventoryPanel = true;
                _showMapPanel = false;
                _showProfilePanel = false;
              });
            },
          ),
          const SizedBox(height: 12),
          // Profile button with label
          _buildFAB(
            heroTag: 'profile',
            icon: Icons.person,
            label: 'Profile',
            color: Colors.purple,
            onPressed: () {
              setState(() {
                _showProfilePanel = true;
                _showMapPanel = false;
                _showInventoryPanel = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAB({
    required String heroTag,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: color.withOpacity(0.95),
        elevation: 0,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Public method to show pickup sheet (can be called from camera events)
  void showPickupConfirmation(DetectedObject object) {
    if (mounted) {
      setState(() {
        _pendingPickup = object;
        _showPickupSheet = true;
      });
    }
  }

  /// Public method to show disposal sheet (can be called from QR scan)
  void showDisposalOptions(BinLocation bin) {
    if (mounted) {
      setState(() {
        _selectedBin = bin;
        _showDisposalSheet = true;
      });
    }
  }
}
