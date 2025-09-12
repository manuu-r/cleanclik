import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanclik/core/theme/app_colors.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/services/system/performance_service.dart';

import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';

import 'package:cleanclik/presentation/widgets/animations/progress_ring.dart';
import 'package:cleanclik/presentation/widgets/animations/breathing_widget.dart';
import 'package:cleanclik/presentation/widgets/animations/particle_system.dart';

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



  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final authStateAsync = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);
    final performanceService = ref.watch(performanceServiceProvider);
    final theme = Theme.of(context);
    final arTheme = theme.arTheme;

    // Debug information
    final authService = ref.read(authServiceProvider);
    debugPrint('ProfileScreen: authState = ${authStateAsync.toString()}');
    debugPrint('ProfileScreen: currentUser = ${currentUser?.toString()}');
    debugPrint('ProfileScreen: authService.currentUser = ${authService.currentUser?.username}');
    debugPrint('ProfileScreen: authService.isAuthenticated = ${authService.isAuthenticated}');
    
    // Auth service is already initialized by the provider, no need to reinitialize

    // Create mock user stats for now since userStatsProvider is missing
    final userStats = <String, dynamic>{
      'totalPoints': currentUser?.totalPoints ?? 0,
      'totalItemsCollected': 0,
      'accountAge': currentUser != null 
          ? DateTime.now().difference(currentUser.createdAt).inDays 
          : 0,
      'rank': 1,
      'achievements': <String>[],
      'categoryStats': <String, dynamic>{},
    };

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
                        child: currentUser != null 
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        arTheme.neonGradient.createShader(bounds),
                                    child: Text(
                                      currentUser.username,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Level ${currentUser.level} Eco Warrior',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: NeonColors.electricGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        arTheme.neonGradient.createShader(bounds),
                                    child: const Text(
                                      'Guest User',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Eco Warrior Level 1',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: NeonColors.electricGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(width: 16),

                      // Level Progress Ring
                      currentUser != null
                          ? ProgressRing(
                              progress: currentUser.levelProgress,
                              size: 80,
                              color: NeonColors.electricGreen,
                              showGlow: performanceService.shouldShowAnimations,
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
                                    '${currentUser.level}',
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Level Progress and Stats Row
                authStateAsync.when(
                  data: (authState) {
                    if (!authState.isAuthenticated) {
                      // User is not authenticated, redirect to login
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          context.go('/login');
                        }
                      });
                      return const SizedBox.shrink();
                    }
                    
                    // User is authenticated, show user data
                    final user = authState.user;
                    debugPrint('ProfileScreen: User data = ${user?.toString()}');
                    
                    // Additional debug info for logout section
                    if (user != null) {
                      debugPrint('ProfileScreen: Logout section - user = ${user.username}');
                    }
                    return user != null
                        ? GlassmorphismContainer(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Level Progress
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${user.pointsToNextLevel} pts to next level',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: user.levelProgress,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          NeonColors.electricGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GlassmorphismContainer(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading Profile...',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Setting up your eco-warrior profile',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                CircularProgressIndicator(
                                  color: NeonColors.electricGreen,
                                ),
                              ],
                            ),
                          );
                  },
                  loading: () => GlassmorphismContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: NeonColors.electricGreen,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Checking authentication...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (error, stack) {
                    debugPrint('ProfileScreen: Auth error: $error');
                    return GlassmorphismContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Authentication Error',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ARActionButton(
                            onPressed: () => context.go('/login'),
                            icon: Icons.login,
                            label: 'Sign In Again',
                            color: NeonColors.electricGreen,
                            isPrimary: true,
                          ),
                        ],
                      ),
                    );
                  },
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
                                                as Map<String, dynamic>? ??
                                            {})['recycle'] as int? ??
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
                                                as Map<String, dynamic>? ??
                                            {})['ewaste'] as int? ??
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

                // Category Breakdown with shader mask
                ShaderMask(
                  shaderCallback: (bounds) =>
                      arTheme.neonGradient.createShader(bounds),
                  child: Text(
                    'Category Breakdown',
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
                      _CategoryBreakdown(
                        category: 'EcoGems',
                        count:
                            (userStats['categoryStats'] as Map<String, dynamic>? ??
                                {})['recycle'] as int? ??
                            0,
                        color: AppColors.ecoGems,
                        icon: Icons.recycling,
                      ),
                      const SizedBox(height: 16),
                      _CategoryBreakdown(
                        category: 'FuelShards',
                        count:
                            (userStats['categoryStats'] as Map<String, dynamic>? ??
                                {})['organic'] as int? ??
                            0,
                        color: AppColors.fuelShards,
                        icon: Icons.eco,
                      ),
                      const SizedBox(height: 16),
                      _CategoryBreakdown(
                        category: 'VoidDust',
                        count:
                            (userStats['categoryStats'] as Map<String, dynamic>? ??
                                {})['landfill'] as int? ??
                            0,
                        color: AppColors.voidDust,
                        icon: Icons.delete,
                      ),
                      const SizedBox(height: 16),
                      _CategoryBreakdown(
                        category: 'SparkCores',
                        count:
                            (userStats['categoryStats'] as Map<String, dynamic>? ??
                                {})['ewaste'] as int? ??
                            0,
                        color: AppColors.sparkCores,
                        icon: Icons.electrical_services,
                      ),
                      const SizedBox(height: 16),
                      _CategoryBreakdown(
                        category: 'ToxicCrystals',
                        count:
                            (userStats['categoryStats'] as Map<String, dynamic>? ??
                                {})['hazardous'] as int? ??
                            0,
                        color: AppColors.toxicCrystals,
                        icon: Icons.warning,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Section - Only show if authenticated
                authStateAsync.when(
                  data: (authState) {
                    if (!authState.isAuthenticated) return const SizedBox.shrink();
                    
                    final user = authState.user;
                    debugPrint('ProfileScreen: Logout section - user = ${user?.username}');
                    return GlassmorphismContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                arTheme.neonGradient.createShader(bounds),
                            child: Text(
                              'Account',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user != null 
                                ? 'Signed in as ${user.username}'
                                : 'Authenticated User',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _ARActionButton(
                            onPressed: () => _handleLogout(context, ref),
                            icon: Icons.logout,
                            label: 'Sign Out',
                            color: NeonColors.toxicPurple,
                            isPrimary: false,
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle logout with confirmation dialog
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [NeonColors.toxicPurple, NeonColors.electricGreen],
          ).createShader(bounds),
          child: const Text(
            'Sign Out',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Text(
          'Are you sure you want to sign out? Your progress will be saved.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: NeonColors.electricGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: NeonColors.toxicPurple.withAlpha((0.2 * 255).toInt()),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Store navigator reference before async operations
      final navigator = Navigator.of(context);
      final router = GoRouter.of(context);
      
      try {
        // Show loading indicator
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: NeonColors.toxicPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Signing out...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Get auth service reference before async operation
        final authService = ref.read(authServiceProvider);
        
        // Perform logout
        await authService.signOut();

        // Force close all dialogs by popping until we can't pop anymore
        try {
          while (navigator.canPop()) {
            navigator.pop();
          }
        } catch (e) {
          debugPrint('Error closing dialogs: $e');
        }

        // Only invalidate providers if widget is still mounted
        if (mounted) {
          ref.invalidate(currentUserProvider);
          ref.invalidate(authStateProvider);
        }

        // Navigate to login screen using stored router reference
        router.go('/login');
      } catch (e) {
        debugPrint('Logout error: $e');
        
        // Force close all dialogs
        try {
          while (navigator.canPop()) {
            navigator.pop();
          }
        } catch (dialogError) {
          debugPrint('Error closing dialogs: $dialogError');
        }

        // Force navigation to login even if logout failed
        // This ensures the user isn't stuck in a loading state
        router.go('/login');

        // Show error as a snackbar instead of blocking dialog
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Logout completed with warnings. You have been signed out.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: NeonColors.toxicPurple,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
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
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.05 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha((0.3 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withAlpha((0.5 * 255).toInt()),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Collected items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'items',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withAlpha((0.8 * 255).toInt()),
                ),
              ),
            ],
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
