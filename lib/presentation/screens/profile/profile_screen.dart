import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/theme/app_colors.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/services/user_service.dart';
import 'package:cleanclik/core/services/performance_service.dart';

import 'package:cleanclik/presentation/widgets/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/neon_icon_button.dart';
import 'package:cleanclik/presentation/widgets/progress_ring.dart';
import 'package:cleanclik/presentation/widgets/breathing_widget.dart';
import 'package:cleanclik/presentation/widgets/particle_system.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
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

  void _triggerCelebration() {
    setState(() => _showCelebration = true);
    _particleController.forward().then((_) {
      setState(() => _showCelebration = false);
      _particleController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final userAsync = ref.watch(currentUserProvider);
    final userStats = ref.watch(userStatsProvider);
    final performanceService = ref.watch(performanceServiceProvider);
    final theme = Theme.of(context);
    final arTheme = theme.arTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => arTheme.neonGradient.createShader(bounds),
          child: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          NeonIconButton(
            icon: Icons.settings,
            color: NeonColors.oceanBlue,
            size: 40,
            onTap: () {
              // TODO: Navigate to settings
            },
            tooltip: 'Settings',
          ),
          const SizedBox(width: 16),
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
                  NeonColors.toxicPurple.withAlpha((0.05 * 255).toInt()),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Particle system for celebrations
          if (_showCelebration)
            ParticleSystem(
              type: ParticleType.stars,
              isActive: _showCelebration,
              color: NeonColors.earthOrange,
            ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16, // Reduced top padding
              16,
              140,
            ), // Bottom padding for floating hub
            child: Column(
              children: [
                // Profile Header with glassmorphism - Horizontal Layout
                GlassmorphismContainer(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Avatar with neon glow
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: NeonColors.electricGreen.withAlpha(
                            (0.2 * 255).toInt(),
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NeonColors.electricGreen,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(width: 20),

                      // User Info with shader mask
                      Expanded(
                        flex: 2,
                        child: userAsync.when(
                          data: (user) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    arTheme.neonGradient.createShader(bounds),
                                child: Text(
                                  user?.username ?? 'Guest User',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user != null
                                    ? 'Level ${user.level} Eco Warrior'
                                    : 'Eco Warrior Level 1',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: NeonColors.electricGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          loading: () => CircularProgressIndicator(
                            color: NeonColors.electricGreen,
                          ),
                          error: (error, stack) => Text(
                            'Error loading user',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Level Progress Ring
                      userAsync.when(
                        data: (user) => user != null
                            ? ProgressRing(
                                progress: user.levelProgress,
                                size: 80,
                                color: NeonColors.electricGreen,
                                showGlow:
                                    performanceService.shouldShowAnimations,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Level',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      '${user.level}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: NeonColors.electricGreen.withAlpha(
                                    (0.1 * 255).toInt(),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.hourglass_empty,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                        loading: () => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: NeonColors.electricGreen.withAlpha(
                              (0.1 * 255).toInt(),
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgressIndicator(
                            color: NeonColors.electricGreen,
                          ),
                        ),
                        error: (error, stack) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha((0.1 * 255).toInt()),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Level Progress and Stats Row
                userAsync.when(
                  data: (user) => user != null
                      ? GlassmorphismContainer(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Level Progress
                              Column(
                                children: [
                                  Text(
                                    '${user.pointsToNextLevel} pts to next level',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : BreathingWidget(
                          enabled: performanceService.shouldShowAnimations,
                          child: _ARActionButton(
                            onPressed: () {
                              ref
                                  .read(userServiceProvider)
                                  .initializeWithDemoUser();
                              _triggerCelebration();
                            },
                            icon: Icons.login,
                            label: 'Start Playing',
                            color: NeonColors.electricGreen,
                            isPrimary: true,
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),

                // Stats Overview with shader mask
                ShaderMask(
                  shaderCallback: (bounds) =>
                      arTheme.neonGradient.createShader(bounds),
                  child: Text(
                    'Your Impact',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _ARStatCard(
                        title: 'Total Points',
                        value: userStats['totalPoints'] ?? 0,
                        maxValue: 10000,
                        icon: Icons.star,
                        color: NeonColors.earthOrange,
                        performanceService: performanceService,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ARStatCard(
                        title: 'Items Collected',
                        value: userStats['totalItemsCollected'] ?? 0,
                        maxValue: 100,
                        icon: Icons.delete_outline,
                        color: NeonColors.electricGreen,
                        performanceService: performanceService,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _ARStatCard(
                        title: 'Account Age',
                        value: userStats['accountAge'] ?? 0,
                        maxValue: 365,
                        icon: Icons.local_fire_department,
                        color: NeonColors.toxicPurple,
                        performanceService: performanceService,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ARStatCard(
                        title: 'Current Rank',
                        value: userStats['rank'] ?? 0,
                        maxValue: 100,
                        icon: Icons.emoji_events,
                        color: NeonColors.oceanBlue,
                        performanceService: performanceService,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Achievements Section with shader mask
                ShaderMask(
                  shaderCallback: (bounds) =>
                      arTheme.neonGradient.createShader(bounds),
                  child: Text(
                    'Achievements',
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
                      _ARAchievementItem(
                        title: 'First Steps',
                        description: 'Collect your first item',
                        icon: Icons.star_outline,
                        isUnlocked:
                            (userStats['achievements'] as List<String>? ?? [])
                                .contains('first_pickup'),
                        progress:
                            (userStats['totalItemsCollected'] as int? ?? 0) > 0
                            ? 1.0
                            : 0.0,
                        color: NeonColors.earthOrange,
                        performanceService: performanceService,
                      ),
                      const SizedBox(height: 16),
                      _ARAchievementItem(
                        title: 'Eco Warrior',
                        description: 'Collect 50 items',
                        icon: Icons.eco,
                        isUnlocked:
                            (userStats['achievements'] as List<String>? ?? [])
                                .contains('eco_warrior'),
                        progress:
                            ((userStats['totalItemsCollected'] as int? ?? 0) /
                                    50.0)
                                .clamp(0.0, 1.0),
                        color: NeonColors.electricGreen,
                        performanceService: performanceService,
                      ),
                      const SizedBox(height: 16),
                      _ARAchievementItem(
                        title: 'Recycling Champion',
                        description: 'Collect 10 recyclable items',
                        icon: Icons.recycling,
                        isUnlocked:
                            (userStats['achievements'] as List<String>? ?? [])
                                .contains('recycling_champion'),
                        progress:
                            (((userStats['categoryStats']
                                                as Map<String, int>? ??
                                            {})['recycle'] ??
                                        0) /
                                    10.0)
                                .clamp(0.0, 1.0),
                        color: NeonColors.oceanBlue,
                        performanceService: performanceService,
                      ),
                      const SizedBox(height: 16),
                      _ARAchievementItem(
                        title: 'E-Waste Expert',
                        description: 'Collect 10 electronic items',
                        icon: Icons.electrical_services,
                        isUnlocked:
                            (userStats['achievements'] as List<String>? ?? [])
                                .contains('ewaste_collector'),
                        progress:
                            (((userStats['categoryStats']
                                                as Map<String, int>? ??
                                            {})['ewaste'] ??
                                        0) /
                                    10.0)
                                .clamp(0.0, 1.0),
                        color: NeonColors.toxicPurple,
                        performanceService: performanceService,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Category Breakdown
                Text(
                  'Category Breakdown',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                GlassmorphismContainer(
                  child: Column(
                    children: [
                      _CategoryBreakdown(
                        category: 'EcoGems',
                        count:
                            (userStats['categoryStats'] as Map<String, int>? ??
                                {})['recycle'] ??
                            0,
                        color: AppColors.ecoGems,
                        icon: Icons.recycling,
                      ),
                      const Divider(),
                      _CategoryBreakdown(
                        category: 'FuelShards',
                        count:
                            (userStats['categoryStats'] as Map<String, int>? ??
                                {})['organic'] ??
                            0,
                        color: AppColors.fuelShards,
                        icon: Icons.eco,
                      ),
                      const Divider(),
                      _CategoryBreakdown(
                        category: 'VoidDust',
                        count:
                            (userStats['categoryStats'] as Map<String, int>? ??
                                {})['landfill'] ??
                            0,
                        color: AppColors.voidDust,
                        icon: Icons.delete,
                      ),
                      const Divider(),
                      _CategoryBreakdown(
                        category: 'SparkCores',
                        count:
                            (userStats['categoryStats'] as Map<String, int>? ??
                                {})['ewaste'] ??
                            0,
                        color: AppColors.sparkCores,
                        icon: Icons.electrical_services,
                      ),
                      const Divider(),
                      _CategoryBreakdown(
                        category: 'ToxicCrystals',
                        count:
                            (userStats['categoryStats'] as Map<String, int>? ??
                                {})['hazardous'] ??
                            0,
                        color: AppColors.toxicCrystals,
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
}

class _ARStatCard extends StatelessWidget {
  final String title;
  final int value;
  final int maxValue;
  final IconData icon;
  final Color color;
  final PerformanceService performanceService;

  const _ARStatCard({
    required this.title,
    required this.value,
    required this.maxValue,
    required this.icon,
    required this.color,
    required this.performanceService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return GlassmorphismContainer(
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
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ARAchievementItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final double progress;
  final Color color;
  final PerformanceService performanceService;

  const _ARAchievementItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.progress,
    required this.color,
    required this.performanceService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget achievementWidget = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUnlocked
                ? color.withAlpha((0.3 * 255).toInt())
                : Colors.grey.withAlpha((0.2 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked
                  ? color
                  : Colors.grey.withAlpha((0.5 * 255).toInt()),
              width: 1,
            ),
          ),
          child: Icon(icon, color: isUnlocked ? color : Colors.grey, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? Colors.white
                      : Colors.white.withOpacity(0.6),
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isUnlocked
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white.withOpacity(0.5),
                ),
              ),
              if (!isUnlocked && progress > 0) ...[
                const SizedBox(height: 8),
                ProgressRing(
                  progress: progress,
                  size: 24,
                  strokeWidth: 2,
                  color: color,
                  showGlow: false,
                ),
              ],
            ],
          ),
        ),
        if (isUnlocked) Icon(Icons.check_circle, color: color, size: 24),
      ],
    );

    if (isUnlocked && performanceService.shouldShowAnimations) {
      achievementWidget = BreathingWidget(child: achievementWidget);
    }

    return achievementWidget;
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final String category;
  final int count;
  final Color color;
  final IconData icon;

  const _CategoryBreakdown({
    required this.category,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '$count items',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        boxShadow: isPrimary
            ? NeonColors.createNeonGlow(color, intensity: 0.6)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
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
