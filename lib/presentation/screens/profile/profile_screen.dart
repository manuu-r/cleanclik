import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cleanclik/core/models/user_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/providers/user_provider.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/theme/category_visuals.dart';

import 'package:cleanclik/presentation/widgets/profile/achievements_display.dart';

/// Profile screen: identity + level card, lifetime stats, achievements,
/// per-category breakdown, sign out. Pushed from the home HUD level badge.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const Color _background = Color(0xFF0E0F12);
  static const Color _surface = Color(0xFF13141A);
  static const Color _brandGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        if (!authState.isAuthenticated || authState.user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/login');
          });
          return const Scaffold(
            backgroundColor: _background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildProfileContent(context, authState.user!);
      },
      loading: () => const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User currentUser) {
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);

    final userStats = dashboardStatsAsync.when(
      data: (dashboardStats) => <String, dynamic>{
        'totalPoints': dashboardStats.totalPoints,
        'totalItemsCollected': dashboardStats.totalItemsDisposed,
        'accountAge': DateTime.now().difference(currentUser.createdAt).inDays,
        'rank': dashboardStats.rank ?? 0,
        'categoryStats': dashboardStats.categoryBreakdown,
        'isStale': dashboardStats.isStale,
      },
      loading: () => <String, dynamic>{
        'totalPoints': currentUser.totalPoints,
        'totalItemsCollected': currentUser.totalItemsCollected,
        'accountAge': DateTime.now().difference(currentUser.createdAt).inDays,
        'rank': 0,
        'categoryStats': currentUser.categoryStats,
        'isStale': false,
      },
      error: (error, stack) => <String, dynamic>{
        'totalPoints': currentUser.totalPoints,
        'totalItemsCollected': currentUser.totalItemsCollected,
        'accountAge': DateTime.now().difference(currentUser.createdAt).inDays,
        'rank': 0,
        'categoryStats': currentUser.categoryStats,
        'isStale': true,
      },
    );

    final categoryStats =
        userStats['categoryStats'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          if (userStats['isStale'] == true)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Offline — tap to refresh',
                icon: const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                onPressed: () => ref.invalidate(dashboardStatsProvider),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Identity + level card
            _buildHeroCard(currentUser),

            const SizedBox(height: 24),

            _sectionHeader('Stats'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Points',
                    value: '${userStats['totalPoints'] ?? 0}',
                    icon: Icons.star_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Items',
                    value: '${userStats['totalItemsCollected'] ?? 0}',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Days Active',
                    value: '${userStats['accountAge'] ?? 0}',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Rank',
                    value: (userStats['rank'] ?? 0) > 0
                        ? '#${userStats['rank']}'
                        : '—',
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const AchievementsDisplay(),

            const SizedBox(height: 24),

            _sectionHeader('Collection'),
            const SizedBox(height: 12),
            ..._buildCategoryRows(categoryStats),

            const SizedBox(height: 32),

            // Sign out
            OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE57373),
                side: BorderSide(
                  color: const Color(0xFFE57373).withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_brandGreen, Color(0xFF2E7D32)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _brandGreen.withValues(alpha: 0.35),
                      blurRadius: 20,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _brandGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Level ${user.level} · Eco Warrior',
                        style: const TextStyle(
                          color: _brandGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // XP progress to next level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${user.level}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${user.pointsToNextLevel} XP to Level ${user.level + 1}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: user.levelProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_brandGreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  List<Widget> _buildCategoryRows(Map<String, dynamic> categoryStats) {
    const categoryIds = ['recycle', 'organic', 'ewaste', 'hazardous', 'landfill'];

    return [
      for (final id in categoryIds) ...[
        _CategoryRow(
          categoryId: id,
          name: WasteCategory.fromId(id)?.codeName ??
              CategoryVisuals.displayName(id),
          count: categoryStats[id] as int? ?? 0,
        ),
        if (id != categoryIds.last) const SizedBox(height: 10),
      ],
    ];
  }

  /// Handle logout with confirmation dialog
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out? Your progress is saved.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      // Store navigator reference before async operations
      final navigator = Navigator.of(context);
      final router = GoRouter.of(context);

      try {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _brandGreen),
                    SizedBox(height: 16),
                    Text(
                      'Signing out…',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final authService = await ref.read(authServiceProvider.future);
        await authService.signOut();

        try {
          while (navigator.canPop()) {
            navigator.pop();
          }
        } catch (e) {
          debugPrint('Error closing dialogs: $e');
        }

        if (mounted) {
          ref.invalidate(authStateProvider);
        }

        router.go('/login');
      } catch (e) {
        debugPrint('Logout error: $e');

        try {
          while (navigator.canPop()) {
            navigator.pop();
          }
        } catch (dialogError) {
          debugPrint('Error closing dialogs: $dialogError');
        }

        // Ensure the user isn't stuck even if sign-out partially failed.
        router.go('/login');
      }
    }
  }
}

/// Compact stat tile: big numeral, muted label, small icon.
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13141A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the per-category collection breakdown.
class _CategoryRow extends StatelessWidget {
  final String categoryId;
  final String name;
  final int count;

  const _CategoryRow({
    required this.categoryId,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.color(categoryId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF13141A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CategoryVisuals.icon(categoryId),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CategoryVisuals.displayName(categoryId),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: count > 0 ? color : Colors.white.withValues(alpha: 0.35),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
