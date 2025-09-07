import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/routing/routes.dart';
import 'package:cleanclik/core/services/inventory_service.dart';
import 'package:cleanclik/core/services/performance_service.dart';
import 'package:cleanclik/core/constants/ui_constants.dart';
import 'package:cleanclik/presentation/widgets/glassmorphism_container.dart';

import 'package:cleanclik/presentation/widgets/progress_ring.dart';
import 'package:cleanclik/presentation/widgets/breathing_widget.dart';
import 'package:cleanclik/presentation/widgets/particle_system.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  bool _showCelebration = false;

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
    final inventoryService = ref.read(inventoryServiceProvider);
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
            'CleanCity Vibe',
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

                      // Action buttons with breathing animation
                      Row(
                        children: [
                          Expanded(
                            child: BreathingWidget(
                              enabled: performanceService.shouldShowAnimations,
                              child: _ARActionButton(
                                onPressed: () => context.push(Routes.camera),
                                icon: Icons.camera_alt,
                                label: 'Start Scanning',
                                color: NeonColors.electricGreen,
                                isPrimary: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: UIConstants.spacing4),
                      Row(
                        children: [
                          Expanded(
                            child: _ARActionButton(
                              onPressed: () =>
                                  context.push('${Routes.camera}?mode=qr'),
                              icon: Icons.qr_code_scanner,
                              label: 'Scan Bin QR Code',
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
                      child: _ARStatCard(
                        title: 'Items Carrying',
                        value: inventory.inventory.length,
                        maxValue: 10,
                        icon: Icons.inventory_outlined,
                        color: NeonColors.electricGreen,
                        showBreathing: inventory.inventory.isNotEmpty,
                      ),
                    ),
                    SizedBox(width: UIConstants.spacing4),
                    Expanded(
                      child: _ARStatCard(
                        title: 'Points Earned',
                        value: inventory.totalPoints,
                        maxValue: 1000,
                        icon: Icons.star_outline,
                        color: NeonColors.earthOrange,
                        showBreathing: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _ARStatCard(
                        title: 'Current Streak',
                        value: 0,
                        maxValue: 30,
                        icon: Icons.local_fire_department_outlined,
                        color: NeonColors.toxicPurple,
                        showBreathing: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ARStatCard(
                        title: 'Rank',
                        value: 0,
                        maxValue: 100,
                        icon: Icons.emoji_events_outlined,
                        color: NeonColors.oceanBlue,
                        showBreathing: false,
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getCategoryDisplayName(entry.key),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withAlpha(
                                        (0.9 * 255).toInt(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(entry.key),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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

                GlassmorphismContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _ARCategoryItem(
                        name: 'EcoGems',
                        description: 'Recyclable materials',
                        color: NeonColors.electricGreen,
                        icon: Icons.recycling,
                      ),
                      const SizedBox(height: 16),
                      _ARCategoryItem(
                        name: 'FuelShards',
                        description: 'Organic waste',
                        color: NeonColors.oceanBlue,
                        icon: Icons.eco,
                      ),
                      const SizedBox(height: 16),
                      _ARCategoryItem(
                        name: 'VoidDust',
                        description: 'General landfill',
                        color: Colors.grey,
                        icon: Icons.delete,
                      ),
                      const SizedBox(height: 16),
                      _ARCategoryItem(
                        name: 'SparkCores',
                        description: 'Electronic waste',
                        color: NeonColors.earthOrange,
                        icon: Icons.electrical_services,
                      ),
                      const SizedBox(height: 16),
                      _ARCategoryItem(
                        name: 'ToxicCrystals',
                        description: 'Hazardous materials',
                        color: NeonColors.toxicPurple,
                        icon: Icons.warning,
                      ),
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

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'recycle':
        return 'Recycling';
      case 'organic':
        return 'Organic';
      case 'landfill':
        return 'General Waste';
      case 'ewaste':
        return 'E-Waste';
      case 'hazardous':
        return 'Hazardous';
      default:
        return category.toUpperCase();
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'recycle':
        return NeonColors.electricGreen;
      case 'organic':
        return NeonColors.oceanBlue;
      case 'landfill':
        return Colors.grey;
      case 'ewaste':
        return NeonColors.earthOrange;
      case 'hazardous':
        return NeonColors.toxicPurple;
      default:
        return Colors.grey;
    }
  }
}

class _ARStatCard extends ConsumerWidget {
  final String title;
  final int value;
  final int maxValue;
  final IconData icon;
  final Color color;
  final bool showBreathing;

  const _ARStatCard({
    required this.title,
    required this.value,
    required this.maxValue,
    required this.icon,
    required this.color,
    this.showBreathing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final performanceService = ref.watch(performanceServiceProvider);
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    Widget card = GlassmorphismContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ProgressRing(
            progress: progress,
            size: 60,
            color: color,
            showGlow: performanceService.shouldShowAnimations,
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withAlpha((0.8 * 255).toInt()),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (showBreathing && performanceService.shouldShowAnimations) {
      card = BreathingWidget(child: card);
    }

    return card;
  }
}

class _ARCategoryItem extends StatelessWidget {
  final String name;
  final String description;
  final Color color;
  final IconData icon;

  const _ARCategoryItem({
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha((0.2 * 255).toInt()),
            borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
            border: Border.all(
              color: color.withAlpha((0.5 * 255).toInt()),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha((0.8 * 255).toInt()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ARActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;

  const _ARActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: UIConstants.buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
        gradient: isPrimary
            ? LinearGradient(
                colors: [color, color.withAlpha((0.7 * 255).toInt())],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: isPrimary
            ? null
            : Border.all(color: color.withAlpha((0.5 * 255).toInt()), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: UIConstants.spacing5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                SizedBox(width: UIConstants.spacing3),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
