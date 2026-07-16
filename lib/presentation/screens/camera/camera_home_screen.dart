import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/models/location_models.dart';
import 'package:cleanclik/core/models/user_models.dart';
import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/core/providers/inventory_provider.dart';
import 'package:cleanclik/core/routing/app_router.dart';
import 'package:cleanclik/core/utils/haptics_util.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_screen.dart';
import 'package:cleanclik/presentation/widgets/camera/camera_hud.dart';
import 'package:cleanclik/presentation/widgets/inventory/inventory_display.dart';
import 'package:cleanclik/presentation/widgets/overlays/pickup_confirmation_sheet.dart';
import 'package:cleanclik/presentation/widgets/overlays/xp_reward_sheet.dart';
import 'package:cleanclik/presentation/widgets/overlays/disposal_options_sheet.dart';

/// Camera-first home screen.
///
/// Layout contract (nothing else may draw chrome on this screen):
/// - Top: [CameraHUD] — level badge (tap → profile) + XP bar.
/// - Bottom: one dock — Map (push /map), Scan Bin (center CTA), Bag (sheet).
/// - The embedded [ARCameraScreen] renders camera + AR overlays only
///   (its built-in buttons are disabled via [ARCameraScreen.showBuiltInControls]).
class CameraHomeScreen extends ConsumerStatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  ConsumerState<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends ConsumerState<CameraHomeScreen> {
  static const Color _brandGreen = Color(0xFF4CAF50);

  final GlobalKey<ARCameraScreenState> _cameraKey =
      GlobalKey<ARCameraScreenState>();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userAsync = ref.read(syncedCurrentUserProvider);
      userAsync.whenData((user) {
        if (user != null && mounted) {
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
    // Listen for user changes to trigger XP animations
    ref.listen<AsyncValue<User?>>(syncedCurrentUserProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && _previousPoints != null && mounted) {
          if (user.totalPoints > _previousPoints!) {
            final xpGained = user.totalPoints - _previousPoints!;
            final leveledUp = user.level > (_previousLevel ?? user.level);

            setState(() {
              _lastXPGain = xpGained;
              _lastAction = 'Trash Picked Up!';
              _didLevelUp = leveledUp;
              _newLevel = leveledUp ? user.level : null;
              _showXPRewardSheet = true;
              _showPickupSheet = false;
              _pendingPickup = null;
            });
          }
        }

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
          // 1. Camera view (persistent, full screen, no built-in chrome)
          Positioned.fill(
            child: ARCameraScreen(
              key: _cameraKey,
              initialMode: CameraMode.mlDetection,
              showBuiltInControls: false,
            ),
          ),

          // 2. Top HUD (level → profile, XP bar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CameraHUD(
              onLevelTap: () {
                HapticsUtil.selectionClick();
                context.push(Routes.profile);
              },
            ),
          ),

          // 3. Bottom dock — the only navigation on this screen
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildBottomDock(),
          ),

          // 4. Bottom sheets (conditional, on top of everything)
          if (_showPickupSheet && _pendingPickup != null)
            Positioned.fill(
              child: PickupConfirmationSheet(
                detectedObject: _pendingPickup!,
                onPickup: () {
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
                  final items = ref.read(inventoryItemsProvider);
                  if (items.isNotEmpty) {
                    for (final item in items) {
                      await ref
                          .read(inventoryServiceProvider)
                          .removeItem(item.id);
                    }
                    setState(() {
                      _showDisposalSheet = false;
                      _selectedBin = null;
                    });
                  }
                },
                onSelectItems: () {
                  setState(() {
                    _showDisposalSheet = false;
                  });
                  _showInventorySheet();
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

  // ---------------------------------------------------------------------------
  // Bottom dock
  // ---------------------------------------------------------------------------

  Widget _buildBottomDock() {
    final itemCount = ref.watch(inventoryItemsProvider).length;
    final carrying = itemCount > 0;

    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _DockButton(
            icon: Icons.map_outlined,
            label: 'Map',
            onTap: () {
              HapticsUtil.selectionClick();
              context.push(Routes.map);
            },
          ),
          const SizedBox(width: 24),
          _ScanBinButton(
            active: carrying,
            onTap: () {
              HapticsUtil.mediumImpact();
              _cameraKey.currentState?.startQRScanning();
            },
          ),
          const SizedBox(width: 24),
          _DockButton(
            icon: Icons.backpack_outlined,
            label: 'Bag',
            badgeCount: itemCount,
            onTap: () {
              HapticsUtil.selectionClick();
              _showInventorySheet();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Inventory sheet (standard modal — swipe down or tap outside to dismiss)
  // ---------------------------------------------------------------------------

  void _showInventorySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final itemCount = ref.watch(inventoryItemsProvider).length;
            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFF13141A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.backpack_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Bag',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        if (itemCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _brandGreen.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$itemCount',
                              style: const TextStyle(
                                color: _brandGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: InventoryDisplay(
                        onItemsDispose: (ids) async {
                          for (final id in ids) {
                            await ref
                                .read(inventoryServiceProvider)
                                .removeItem(id);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

/// Secondary dock button: frosted glass circle with a label below.
class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: CircleBorder(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: Colors.white, size: 26),
                      if (badgeCount > 0)
                        Positioned(
                          top: 8,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              badgeCount > 99 ? '99+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

/// Primary dock CTA: scan a bin to dispose. Glows green while carrying items.
class _ScanBinButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _ScanBinButton({required this.active, required this.onTap});

  static const Color _brandGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_brandGreen, Color(0xFF2E7D32)],
                  )
                : null,
            color: active ? null : Colors.black.withValues(alpha: 0.55),
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _brandGreen.withValues(alpha: 0.55),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : const [
                    BoxShadow(color: Colors.black45, blurRadius: 12),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          active ? 'Dispose' : 'Scan Bin',
          style: TextStyle(
            color: active ? _brandGreen : Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}
