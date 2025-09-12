import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cleanclik/core/models/ui_context.dart';
import 'package:cleanclik/core/services/system/ui_context_service.dart';
import 'package:cleanclik/core/services/business/smart_suggestions_service.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/presentation/widgets/common/floating_action_hub.dart';
import 'package:cleanclik/presentation/widgets/common/slide_up_panel.dart';
import 'package:cleanclik/presentation/widgets/animations/particle_system.dart';

/// AR-first navigation shell with floating action hub
class ARNavigationShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ARNavigationShell({super.key, required this.navigationShell});

  @override
  ConsumerState<ARNavigationShell> createState() => _ARNavigationShellState();
}

class _ARNavigationShellState extends ConsumerState<ARNavigationShell>
    with TickerProviderStateMixin {
  bool _isPanelExpanded = false;
  bool _showParticles = false;
  ParticleType _currentParticleType = ParticleType.confetti;

  @override
  void initState() {
    super.initState();

    // Set initial UI context based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUIContextFromRoute();
      _generateInitialSuggestions();
    });
  }

  void _updateUIContextFromRoute() {
    final location = GoRouterState.of(context).uri.path;
    final uiContextService = ref.read(uiContextServiceProvider);

    UIContext uiContext;
    switch (location) {
      case '/map':
        uiContext = UIContext.map;
        break;
      case '/leaderboard':
        uiContext = UIContext.social;
        break;
      case '/profile':
        uiContext = UIContext.profile;
        break;
      default:
        uiContext = UIContext.arCamera;
    }

    uiContextService.updateContext(uiContext);
    _generateSuggestionsForContext(uiContext);
  }

  void _generateInitialSuggestions() {
    final uiContextService = ref.read(uiContextServiceProvider);
    final suggestionsService = ref.read(smartSuggestionsServiceProvider);

    suggestionsService.generateSuggestions(
      uiContextService.currentContext,
      userData: {'streak': 5, 'totalPoints': 1234, 'itemsCollected': 89},
      environmentData: {'weather': 'sunny', 'timeOfDay': 'morning'},
    );
  }

  void _generateSuggestionsForContext(UIContext uiContext) {
    final suggestionsService = ref.read(smartSuggestionsServiceProvider);
    final uiContextService = ref.read(uiContextServiceProvider);

    suggestionsService.generateSuggestions(
      uiContextService.currentContext,
      userData: {'streak': 5, 'totalPoints': 1234, 'itemsCollected': 89},
    );
  }

  void _onHubAction(String action) {
    final uiContextService = ref.read(uiContextServiceProvider);

    switch (action) {
      case 'scan':
        // Navigate to home screen where unified camera button is located
        context.go('/');
        break;
      case 'inventory':
        setState(() {
          _isPanelExpanded = !_isPanelExpanded;
        });
        uiContextService.updateContext(UIContext.inventory);
        break;
      case 'nearby_bins':
      case 'bins':
        context.go('/map');
        break;
      case 'profile_stats':
      case 'stats':
        context.go('/profile');
        break;
      case 'leaderboard':
      case 'friends':
        context.go('/leaderboard');
        break;
      case 'share':
        _triggerCelebration(ParticleType.confetti);
        break;
      case 'dispose':
        _triggerCelebration(ParticleType.leaves);
        uiContextService.updateActivityState(ActivityState.celebrating);
        break;
      default:
        debugPrint('Unhandled action: $action');
    }
  }

  void _triggerCelebration(ParticleType type) {
    setState(() {
      _currentParticleType = type;
      _showParticles = true;
    });

    // Auto-hide particles after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showParticles = false;
        });
      }
    });
  }

  void _onPanelToggle() {
    setState(() {
      _isPanelExpanded = !_isPanelExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main content (AR view takes priority)
          Positioned.fill(child: widget.navigationShell),

          // Floating Action Hub (hidden on home screen)
          if (!_isHomeScreen())
            Positioned(
              right: UIConstants.edgeControlsMargin,
              bottom:
                  UIConstants.edgeControlsMargin +
                  120, // Above bottom nav and panel
              child: FloatingActionHub(
                onActionTap: _onHubAction,
                onCenterTap: () {
                  // Context-aware center action
                  final currentContext = ref
                      .read(uiContextServiceProvider)
                      .currentContext;
                  switch (currentContext.context) {
                    case UIContext.arCamera:
                      context.go(
                        '/',
                      ); // Navigate to home where unified camera button is
                      break;
                    case UIContext.map:
                      // Toggle map layers
                      break;
                    case UIContext.inventory:
                      _onPanelToggle();
                      break;
                    default:
                      context.go('/');
                  }
                },
              ),
            ),

          // Slide-up panel for inventory/details
          if (_shouldShowPanel())
            SlideUpPanel(
              isExpanded: _isPanelExpanded,
              onToggle: _onPanelToggle,
              title: _getPanelTitle(),
              actions: _getPanelActions(),
              child: _buildPanelContent(),
            ),

          // Particle system for celebrations
          if (_showParticles)
            Positioned.fill(
              child: IgnorePointer(
                child: ParticleSystem(
                  type: _currentParticleType,
                  isActive: _showParticles,
                ),
              ),
            ),

          // Context-aware edge controls
          ..._buildEdgeControls(),
        ],
      ),
    );
  }

  bool _shouldShowPanel() {
    final location = GoRouterState.of(context).uri.path;
    return location == '/' ||
        location == '/map' ||
        location == '/profile' ||
        location == '/leaderboard';
  }

  bool _isHomeScreen() {
    final location = GoRouterState.of(context).uri.path;
    return location == '/';
  }

  String? _getPanelTitle() {
    // Always show "Quick Actions" title across all screens
    return 'Quick Actions';
  }

  List<Widget>? _getPanelActions() {
    return [
      IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onPressed: () {
          // Show more options
        },
      ),
    ];
  }

  Widget _buildPanelContent() {
    // Always show the home panel content across all screens
    return _buildHomePanel();
  }

  Widget _buildHomePanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Dashboard',
                    Icons.home,
                    () => context.go('/'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'View Map',
                    Icons.map,
                    () => context.go('/map'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Leaderboard',
                    Icons.leaderboard,
                    () => context.go('/leaderboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Profile',
                    Icons.person,
                    () => context.go('/profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100), // Space for floating action hub
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEdgeControls() {
    // Removed duplicate camera button - use floating action hub instead
    return [];
  }
}
