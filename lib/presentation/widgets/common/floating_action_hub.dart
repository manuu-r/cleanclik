import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/models/ui_context.dart';
import 'package:cleanclik/core/services/system/ui_context_service.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/neon_icon_button.dart';

/// Revolutionary floating action hub that morphs based on context
class FloatingActionHub extends ConsumerStatefulWidget {
  final VoidCallback? onCenterTap;
  final Function(String action)? onActionTap;

  const FloatingActionHub({super.key, this.onCenterTap, this.onActionTap});

  @override
  ConsumerState<FloatingActionHub> createState() => _FloatingActionHubState();
}

class _FloatingActionHubState extends ConsumerState<FloatingActionHub>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _breathingController;
  late AnimationController _morphController;

  late Animation<double> _expandAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _morphAnimation;

  bool _isExpanded = false;
  UIContextData? _lastContext;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _morphController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.elasticOut,
    );

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    );

    // Start breathing animation
    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _expandController.dispose();
    _breathingController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _onActionTap(String action) {
    HapticFeedback.selectionClick();
    widget.onActionTap?.call(action);

    // Auto-collapse after action
    if (_isExpanded) {
      _toggleExpanded();
    }
  }

  void _onLongPress() {
    HapticFeedback.heavyImpact();
    // Show quick actions or context menu
    _showQuickActions();
  }

  void _showQuickActions() {
    // Implementation for quick actions overlay
  }

  @override
  Widget build(BuildContext context) {
    final contextAsync = ref.watch(currentUIContextProvider);

    return contextAsync.when(
      data: (contextData) {
        // Trigger morph animation when context changes
        if (_lastContext != null && _lastContext != contextData) {
          _morphController.forward().then((_) {
            _morphController.reverse();
          });
        }
        _lastContext = contextData;

        return _buildHub(context, contextData);
      },
      loading: () => _buildHub(context, null),
      error: (_, __) => _buildHub(context, null),
    );
  }

  Widget _buildHub(BuildContext context, UIContextData? contextData) {
    final actions = contextData != null
        ? ref.read(uiContextServiceProvider).getContextualActions()
        : ['scan', 'inventory', 'nearby_bins', 'profile_stats'];

    return AnimatedBuilder(
      animation: Listenable.merge([
        _expandAnimation,
        _breathingAnimation,
        _morphAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _breathingAnimation.value,
          child: SizedBox(
            width: _isExpanded
                ? UIConstants.hubExpandedSize
                : UIConstants.hubSize,
            height: _isExpanded
                ? UIConstants.hubExpandedSize
                : UIConstants.hubSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanded action buttons
                if (_isExpanded) ..._buildActionButtons(actions),

                // Center hub button
                _buildCenterButton(contextData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterButton(UIContextData? contextData) {
    final isActive = contextData?.activityState != ActivityState.idle;
    final color = isActive
        ? NeonColors.electricGreen
        : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: _isExpanded
          ? _toggleExpanded
          : (widget.onCenterTap ?? _toggleExpanded),
      onLongPress: _onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: UIConstants.hubSize,
        height: UIConstants.hubSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isActive
              ? NeonColors.createNeonGlow(color, intensity: 0.8)
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: GlassmorphismContainer(
          borderRadius: BorderRadius.circular(UIConstants.hubSize / 2),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
              ),
            ),
            child: Icon(
              _isExpanded ? Icons.close : _getCenterIcon(contextData),
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCenterIcon(UIContextData? contextData) {
    if (contextData == null) return Icons.camera_alt;

    switch (contextData.context) {
      case UIContext.arCamera:
        switch (contextData.activityState) {
          case ActivityState.scanning:
            return Icons.search;
          case ActivityState.tracking:
          case ActivityState.carrying:
            return Icons.inventory;
          case ActivityState.approaching:
            return Icons.place;
          case ActivityState.disposing:
            return Icons.delete;
          case ActivityState.celebrating:
            return Icons.celebration;
          default:
            return Icons.camera_alt;
        }
      case UIContext.map:
        return Icons.map;
      case UIContext.inventory:
        return Icons.inventory;
      case UIContext.social:
        return Icons.people;
      case UIContext.profile:
        return Icons.person;
      case UIContext.mission:
        return Icons.flag;
    }
  }

  List<Widget> _buildActionButtons(List<String> actions) {
    final buttons = <Widget>[];
    final angleStep = (2 * math.pi) / actions.length;
    final radius =
        (UIConstants.hubExpandedSize - UIConstants.hubActionSize) / 2 - 8;

    for (int i = 0; i < actions.length; i++) {
      final angle = i * angleStep - math.pi / 2; // Start from top
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);

      buttons.add(
        AnimatedPositioned(
          duration: Duration(milliseconds: 300 + (i * 50)),
          curve: Curves.elasticOut,
          left:
              (UIConstants.hubExpandedSize / 2) +
              x -
              (UIConstants.hubActionSize / 2),
          top:
              (UIConstants.hubExpandedSize / 2) +
              y -
              (UIConstants.hubActionSize / 2),
          child: Transform.scale(
            scale: _expandAnimation.value,
            child: _buildActionButton(actions[i]),
          ),
        ),
      );
    }

    return buttons;
  }

  Widget _buildActionButton(String action) {
    final iconData = _getActionIcon(action);
    final color = _getActionColor(action);

    return NeonIconButton(
      icon: iconData,
      color: color,
      size: UIConstants.hubActionSize,
      onTap: () => _onActionTap(action),
      tooltip: _getActionTooltip(action),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'scan':
        return Icons.qr_code_scanner;
      case 'inventory':
        return Icons.inventory;
      case 'nearby_bins':
        return Icons.place;
      case 'profile_stats':
        return Icons.analytics;
      case 'bins':
        return Icons.delete_outline;
      case 'hotspots':
        return Icons.whatshot;
      case 'missions':
        return Icons.flag;
      case 'friends':
        return Icons.people;
      case 'dispose':
        return Icons.delete;
      case 'categories':
        return Icons.category;
      case 'share':
        return Icons.share;
      case 'clear':
        return Icons.clear_all;
      case 'leaderboard':
        return Icons.leaderboard;
      case 'challenges':
        return Icons.emoji_events;
      case 'stats':
        return Icons.analytics;
      case 'badges':
        return Icons.military_tech;
      case 'settings':
        return Icons.settings;
      case 'help':
        return Icons.help;
      case 'find_bin':
        return Icons.search;
      case 'cancel_pickup':
        return Icons.cancel;
      case 'wrong_bin':
        return Icons.warning;
      case 'confirm':
        return Icons.check;
      case 'cancel':
        return Icons.close;
      case 'continue':
        return Icons.arrow_forward;
      case 'next_mission':
        return Icons.skip_next;
      case 'accept':
        return Icons.check_circle;
      case 'details':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'scan':
      case 'inventory':
        return NeonColors.electricGreen;
      case 'nearby_bins':
      case 'bins':
        return NeonColors.oceanBlue;
      case 'profile_stats':
      case 'stats':
        return NeonColors.solarYellow;
      case 'dispose':
      case 'confirm':
        return NeonColors.neonEcoGems;
      case 'cancel':
      case 'cancel_pickup':
        return NeonColors.neonToxicCrystals;
      case 'share':
        return NeonColors.cosmicPurple;
      default:
        return NeonColors.glowWhite;
    }
  }

  String _getActionTooltip(String action) {
    switch (action) {
      case 'scan':
        return 'Scan Objects';
      case 'inventory':
        return 'View Inventory';
      case 'nearby_bins':
        return 'Find Nearby Bins';
      case 'profile_stats':
        return 'View Stats';
      case 'bins':
        return 'Show Bins';
      case 'hotspots':
        return 'Show Hotspots';
      case 'missions':
        return 'View Missions';
      case 'friends':
        return 'Friends';
      case 'dispose':
        return 'Dispose Items';
      case 'categories':
        return 'Filter Categories';
      case 'share':
        return 'Share Achievement';
      case 'clear':
        return 'Clear All';
      case 'leaderboard':
        return 'Leaderboard';
      case 'challenges':
        return 'Challenges';
      case 'stats':
        return 'Statistics';
      case 'badges':
        return 'Badges';
      case 'settings':
        return 'Settings';
      case 'help':
        return 'Help';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }
}
