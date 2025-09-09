import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'user_database_service.dart';
import 'inventory_database_service.dart';
import 'achievement_database_service.dart';
import 'category_stats_database_service.dart';

part 'database_service_provider.g.dart';

/// Provider for UserDatabaseService
@riverpod
UserDatabaseService userDatabaseService(UserDatabaseServiceRef ref) {
  return UserDatabaseService();
}

/// Provider for InventoryDatabaseService
@riverpod
InventoryDatabaseService inventoryDatabaseService(InventoryDatabaseServiceRef ref) {
  return InventoryDatabaseService();
}

/// Provider for AchievementDatabaseService
@riverpod
AchievementDatabaseService achievementDatabaseService(AchievementDatabaseServiceRef ref) {
  return AchievementDatabaseService();
}

/// Provider for CategoryStatsDatabaseService
@riverpod
CategoryStatsDatabaseService categoryStatsDatabaseService(CategoryStatsDatabaseServiceRef ref) {
  return CategoryStatsDatabaseService();
}

/// Composite database service provider that provides access to all database services
@riverpod
DatabaseServices databaseServices(DatabaseServicesRef ref) {
  return DatabaseServices(
    userService: ref.watch(userDatabaseServiceProvider),
    inventoryService: ref.watch(inventoryDatabaseServiceProvider),
    achievementService: ref.watch(achievementDatabaseServiceProvider),
    categoryStatsService: ref.watch(categoryStatsDatabaseServiceProvider),
  );
}

/// Composite class that provides access to all database services
class DatabaseServices {
  final UserDatabaseService userService;
  final InventoryDatabaseService inventoryService;
  final AchievementDatabaseService achievementService;
  final CategoryStatsDatabaseService categoryStatsService;

  const DatabaseServices({
    required this.userService,
    required this.inventoryService,
    required this.achievementService,
    required this.categoryStatsService,
  });

  /// Test all database connections
  Future<Map<String, bool>> testAllConnections() async {
    final results = <String, bool>{};
    
    results['users'] = await userService.testConnection();
    results['inventory'] = await inventoryService.testConnection();
    results['achievements'] = await achievementService.testConnection();
    results['category_stats'] = await categoryStatsService.testConnection();
    
    return results;
  }

  /// Get health status for all database services
  Future<Map<String, Map<String, dynamic>>> getAllHealthStatus() async {
    final results = <String, Map<String, dynamic>>{};
    
    final userHealth = await userService.getHealthStatus();
    results['users'] = userHealth.isSuccess ? userHealth.data! : {'healthy': false, 'error': userHealth.error?.message};
    
    final inventoryHealth = await inventoryService.getHealthStatus();
    results['inventory'] = inventoryHealth.isSuccess ? inventoryHealth.data! : {'healthy': false, 'error': inventoryHealth.error?.message};
    
    final achievementHealth = await achievementService.getHealthStatus();
    results['achievements'] = achievementHealth.isSuccess ? achievementHealth.data! : {'healthy': false, 'error': achievementHealth.error?.message};
    
    final categoryStatsHealth = await categoryStatsService.getHealthStatus();
    results['category_stats'] = categoryStatsHealth.isSuccess ? categoryStatsHealth.data! : {'healthy': false, 'error': categoryStatsHealth.error?.message};
    
    return results;
  }

  /// Check if all services are healthy
  Future<bool> areAllServicesHealthy() async {
    final healthStatus = await getAllHealthStatus();
    return healthStatus.values.every((status) => status['healthy'] == true);
  }
}