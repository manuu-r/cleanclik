import 'package:riverpod_annotation/riverpod_annotation.dart';

// UserDatabaseService removed - user operations now handled by AuthService
import 'package:cleanclik/core/services/data/inventory_database_service.dart';
import 'package:cleanclik/core/services/data/achievement_database_service.dart';
import 'package:cleanclik/core/services/data/category_stats_database_service.dart';
import 'package:cleanclik/core/services/data/leaderboard_database_service.dart';

part 'database_service_provider.g.dart';

// UserDatabaseService provider removed - user operations now handled by AuthService

/// Provider for InventoryDatabaseService
@riverpod
InventoryDatabaseService inventoryDatabaseService(
  InventoryDatabaseServiceRef ref,
) {
  return InventoryDatabaseService();
}

/// Provider for AchievementDatabaseService
@riverpod
AchievementDatabaseService achievementDatabaseService(
  AchievementDatabaseServiceRef ref,
) {
  return AchievementDatabaseService();
}

/// Provider for CategoryStatsDatabaseService
@riverpod
CategoryStatsDatabaseService categoryStatsDatabaseService(
  CategoryStatsDatabaseServiceRef ref,
) {
  return CategoryStatsDatabaseService();
}

/// Provider for LeaderboardDatabaseService
@riverpod
LeaderboardDatabaseService leaderboardDatabaseService(
  LeaderboardDatabaseServiceRef ref,
) {
  return LeaderboardDatabaseService();
}

/// Composite database service provider that provides access to all database services
@riverpod
DatabaseServices databaseServices(DatabaseServicesRef ref) {
  return DatabaseServices(
    inventoryService: ref.watch(inventoryDatabaseServiceProvider),
    achievementService: ref.watch(achievementDatabaseServiceProvider),
    categoryStatsService: ref.watch(categoryStatsDatabaseServiceProvider),
    leaderboardService: ref.watch(leaderboardDatabaseServiceProvider),
  );
}

/// Composite class that provides access to all database services
class DatabaseServices {
  final InventoryDatabaseService inventoryService;
  final AchievementDatabaseService achievementService;
  final CategoryStatsDatabaseService categoryStatsService;
  final LeaderboardDatabaseService leaderboardService;

  const DatabaseServices({
    required this.inventoryService,
    required this.achievementService,
    required this.categoryStatsService,
    required this.leaderboardService,
  });

  /// Test all database connections
  Future<Map<String, bool>> testAllConnections() async {
    final results = <String, bool>{};

    // User database operations now handled by AuthService
    results['inventory'] = await inventoryService.testConnection();
    results['achievements'] = await achievementService.testConnection();
    results['category_stats'] = await categoryStatsService.testConnection();
    results['leaderboard'] = await leaderboardService.testConnection();

    return results;
  }

  /// Get health status for all database services
  Future<Map<String, Map<String, dynamic>>> getAllHealthStatus() async {
    final results = <String, Map<String, dynamic>>{};

    // User database operations now handled by AuthService
    
    final inventoryHealth = await inventoryService.getHealthStatus();
    results['inventory'] = inventoryHealth.isSuccess
        ? inventoryHealth.data!
        : {'healthy': false, 'error': inventoryHealth.error?.message};

    final achievementHealth = await achievementService.getHealthStatus();
    results['achievements'] = achievementHealth.isSuccess
        ? achievementHealth.data!
        : {'healthy': false, 'error': achievementHealth.error?.message};

    final categoryStatsHealth = await categoryStatsService.getHealthStatus();
    results['category_stats'] = categoryStatsHealth.isSuccess
        ? categoryStatsHealth.data!
        : {'healthy': false, 'error': categoryStatsHealth.error?.message};

    final leaderboardHealth = await leaderboardService.getHealthStatus();
    results['leaderboard'] = leaderboardHealth.isSuccess
        ? leaderboardHealth.data!
        : {'healthy': false, 'error': leaderboardHealth.error?.message};

    return results;
  }

  /// Check if all services are healthy
  Future<bool> areAllServicesHealthy() async {
    final healthStatus = await getAllHealthStatus();
    return healthStatus.values.every((status) => status['healthy'] == true);
  }
}
