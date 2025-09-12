import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/system/performance_service.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/home_stat_card.dart';
import 'package:cleanclik/presentation/widgets/common/category_item.dart';

import 'package:cleanclik/presentation/widgets/animations/breathing_widget.dart';
import 'package:cleanclik/presentation/widgets/animations/particle_system.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  final bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final inventory = ref.watch(inventoryServiceProvider);
    final performanceService = ref.watch(performanceServiceProvider);
    final theme = Theme.of(context);
    final arTheme = theme.arTheme;
    // final animationTheme = theme.animationTheme; // Unused variable removed

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => arTheme.neonGradient.createShader(bounds),
          child: const Text(
            'CleanClik',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications
            },
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  NeonColors.electricGreen.withAlpha((0.05 * 255).toInt()),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Particle system for celebrations
          if (_showCelebration)
            ParticleSystem(
              type: ParticleType.leaves,
              isActive: _showCelebration,
              color: NeonColors.electricGreen,
            ),

          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              UIConstants.sideMargin,
              16, // Reduced top padding since no extendBodyBehindAppBar
              UIConstants.sideMargin,
              120, // Bottom padding for navigation bar and floating action hub
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section with glassmorphism
                GlassmorphismContainer(
                  padding: EdgeInsets.all(UIConstants.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            arTheme.neonGradient.createShader(bounds),
                        child: Text(
                          'Welcome, Eco Warrior!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: UIConstants.spacing3),
                      Text(
                        'Ready to make your city cleaner? Start by scanning trash with your camera!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha((0.9 * 255).toInt()),
                        ),
                      ),
                      SizedBox(height: UIConstants.spacing6),

                      // Direct action buttons for picking up and disposing
                      Row(
                        children: [
                          Expanded(
                            child: BreathingWidget(
                              enabled: performanceService.shouldShowAnimations,
                              child: _ActionButton(
                                onPressed: () =>
                                    context.push('/camera?mode=ml'),
                                icon: Icons.search,
                                label: 'Pick Up',
                                description: 'Scan trash items',
                                color: NeonColors.electricGreen,
                                isPrimary: true,
                              ),
                            ),
                          ),
                          SizedBox(width: UIConstants.spacing4),
                          Expanded(
                            child: _ActionButton(
                              onPressed: () => context.push('/camera?mode=qr'),
                              icon: Icons.qr_code_scanner,
                              label: 'Dispose',
                              description: 'Scan bin codes',
                              color: NeonColors.oceanBlue,
                              isPrimary: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: UIConstants.sectionSpacing),

                // Quick Stats with neon progress rings
                ShaderMask(
                  shaderCallback: (bounds) =>
                      arTheme.neonGradient.createShader(bounds),
                  child: Text(
                    'Your Impact Today',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: UIConstants.spacing5),

                Row(
                  children: [
                    Expanded(
                      child: HomeStatCard.inventory(
                        itemCount: inventory.inventory.length,
                        showBreathing: inventory.inventory.isNotEmpty,
                        onTap: () => context.push('/profile'),
                      ),
                    ),
                    SizedBox(width: UIConstants.spacing4),
                    Expanded(
                      child: HomeStatCard.points(
                        points: inventory.totalPoints,
                        onTap: () => context.push('/leaderboard'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: UIConstants.spacing4),

                Row(
                  children: [
                    Expanded(
                      child: HomeStatCard.streak(
                        streak: 0,
                        onTap: () => context.push('/profile'),
                      ),
                    ),
                    SizedBox(width: UIConstants.spacing4),
                    Expanded(
                      child: HomeStatCard.rank(
                        rank: 0,
                        onTap: () => context.push('/leaderboard'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Current Inventory with glassmorphism
                if (inventory.inventory.isNotEmpty) ...[
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        arTheme.neonGradient.createShader(bounds),
                    child: Text(
                      'Current Inventory',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  BreathingWidget(
                    enabled: performanceService.shouldShowAnimations,
                    child: GlassmorphismContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ...inventory.categoryCounts.entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: UIConstants.spacing2,
                              ),
                              child: _buildInventoryItem(
                                entry.key,
                                entry.value,
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Category Guide with glassmorphism
                ShaderMask(
                  shaderCallback: (bounds) =>
                      arTheme.neonGradient.createShader(bounds),
                  child: Text(
                    'Waste Categories',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                GlassmorphismContainer.secondary(
                  padding: EdgeInsets.all(UIConstants.spacing5),
                  child: Column(
                    children: [
                      CategoryItem.ecoGems(),
                      SizedBox(height: UIConstants.spacing4),
                      CategoryItem.fuelShards(),
                      SizedBox(height: UIConstants.spacing4),
                      CategoryItem.voidDust(),
                      SizedBox(height: UIConstants.spacing4),
                      CategoryItem.sparkCores(),
                      SizedBox(height: UIConstants.spacing4),
                      CategoryItem.toxicCrystals(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(String category, int count) {
    switch (category) {
      case 'recycle':
        return CategoryItem.ecoGems(count: count, showCount: true);
      case 'organic':
        return CategoryItem.fuelShards(count: count, showCount: true);
      case 'landfill':
        return CategoryItem.voidDust(count: count, showCount: true);
      case 'ewaste':
        return CategoryItem.sparkCores(count: count, showCount: true);
      case 'hazardous':
        return CategoryItem.toxicCrystals(count: count, showCount: true);
      default:
        return CategoryItem(
          name: category.toUpperCase(),
          description: 'Unknown category',
          color: Colors.grey,
          icon: Icons.help_outline,
          count: count,
          showCount: true,
        );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isPrimary;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        gradient: isPrimary
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: isPrimary
            ? null
            : Border.all(color: color.withValues(alpha: 0.6), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          child: Padding(
            padding: EdgeInsets.all(UIConstants.spacing3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      UIConstants.radiusMedium,
                    ),
                    border: Border.all(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.5)
                          : color.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : color,
                    size: 18,
                  ),
                ),
                SizedBox(height: UIConstants.spacing2),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isPrimary ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: UIConstants.spacing1),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
