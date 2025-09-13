import 'package:supabase_flutter/supabase_flutter.dart';
import '../mock_data/mock_users.dart';
import '../mock_data/mock_inventory_items.dart';
import '../mock_data/mock_bin_locations.dart';
import '../../test_config.dart';

/// Mock Supabase database responses for testing
class DatabaseResponses {
  /// Mock successful database query response
  static PostgrestResponse<T> createSuccessResponse<T>({
    required T data,
    int? count,
  }) {
    return PostgrestResponse<T>(
      data: data,
      count: count,
      status: 200,
    );
  }

  /// Mock database error response
  static PostgrestException createDatabaseError({
    required String message,
    String? code,
    String? details,
  }) {
    return PostgrestException(
      message: message,
      code: code,
      details: details,
    );
  }

  /// Mock user profile queries
  static Map<String, dynamic> createUserProfileResponses() {
    return {
      'select_user_profile': createSuccessResponse(
        data: MockUsers.createAuthenticatedUser(),
      ),
      'update_user_profile': createSuccessResponse(
        data: MockUsers.createAuthenticatedUser(),
      ),
      'insert_user_profile': createSuccessResponse(
        data: MockUsers.createAuthenticatedUser(),
      ),
    };
  }

  /// Mock inventory table queries
  static Map<String, dynamic> createInventoryResponses() {
    return {
      'select_inventory_items': createSuccessResponse(
        data: MockInventoryItems.createMockInventoryItems(),
        count: 50,
      ),
      'insert_inventory_item': createSuccessResponse(
        data: MockInventoryItems.createMockInventoryItems(count: 1).first,
      ),
      'update_inventory_item': createSuccessResponse(
        data: MockInventoryItems.createMockInventoryItems(count: 1).first,
      ),
      'delete_inventory_item': createSuccessResponse(
        data: null,
      ),
      'select_pending_items': createSuccessResponse(
        data: MockInventoryItems.createPendingInventoryItems(),
        count: 15,
      ),
      'select_disposed_items': createSuccessResponse(
        data: MockInventoryItems.createDisposedInventoryItems(),
        count: 20,
      ),
    };
  }

  /// Mock bin locations table queries
  static Map<String, dynamic> createBinLocationResponses() {
    return {
      'select_bin_locations': createSuccessResponse(
        data: MockBinLocations.createMockBinLocations(),
        count: 20,
      ),
      'select_nearby_bins': createSuccessResponse(
        data: MockBinLocations.createNearbyBinLocations(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        count: 5,
      ),
      'select_category_bins': createSuccessResponse(
        data: MockBinLocations.createCategoryBinLocations(
          category: WasteCategory.recycle,
        ),
        count: 5,
      ),
      'update_bin_status': createSuccessResponse(
        data: MockBinLocations.createMockBinLocations(count: 1).first,
      ),
    };
  }

  /// Mock leaderboard queries
  static Map<String, dynamic> createLeaderboardResponses() {
    return {
      'select_leaderboard': createSuccessResponse(
        data: List.generate(10, (index) => {
          'user_id': 'user-$index',
          'username': 'user$index',
          'full_name': 'User $index',
          'total_points': 1000 - (index * 100),
          'items_collected': 100 - (index * 10),
          'rank': index + 1,
          'avatar_url': index % 3 == 0 ? 'https://example.com/avatar$index.jpg' : null,
          'last_activity': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
        }),
        count: 10,
      ),
      'select_user_rank': createSuccessResponse(
        data: {
          'user_id': 'test-user-id',
          'rank': 5,
          'total_points': 500,
          'items_collected': 50,
        },
      ),
    };
  }

  /// Mock achievements queries
  static Map<String, dynamic> createAchievementResponses() {
    return {
      'select_achievements': createSuccessResponse(
        data: [
          {
            'id': 'first_recycler',
            'title': 'First Recycler',
            'description': 'Recycle your first item',
            'icon_url': 'assets/icons/achievement_recycle.svg',
            'required_points': 10,
            'category': 'recycle',
            'is_unlocked': true,
            'unlocked_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          },
          {
            'id': 'eco_warrior',
            'title': 'Eco Warrior',
            'description': 'Collect 100 items',
            'icon_url': 'assets/icons/achievement_warrior.svg',
            'required_points': 1000,
            'category': null,
            'is_unlocked': false,
            'unlocked_at': null,
          },
        ],
        count: 2,
      ),
      'unlock_achievement': createSuccessResponse(
        data: {
          'id': 'eco_warrior',
          'unlocked_at': DateTime.now().toIso8601String(),
        },
      ),
    };
  }

  /// Mock statistics queries
  static Map<String, dynamic> createStatisticsResponses() {
    return {
      'select_user_stats': createSuccessResponse(
        data: {
          'user_id': 'test-user-id',
          'total_points': 1250,
          'items_collected': 125,
          'categories_used': 4,
          'streak_days': 7,
          'longest_streak': 15,
          'average_items_per_day': 3.5,
          'favorite_category': 'recycle',
          'total_distance': 15.2,
          'co2_saved': 45.6,
        },
      ),
      'select_category_stats': createSuccessResponse(
        data: [
          {
            'category': 'recycle',
            'items_collected': 50,
            'total_points': 500,
            'last_collected': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'average_confidence': 0.85,
          },
          {
            'category': 'organic',
            'items_collected': 40,
            'total_points': 320,
            'last_collected': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
            'average_confidence': 0.82,
          },
        ],
        count: 2,
      ),
    };
  }

  /// Mock real-time subscription responses
  static Map<String, dynamic> createRealtimeResponses() {
    return {
      'leaderboard_updates': {
        'eventType': 'UPDATE',
        'new': {
          'user_id': 'test-user-id',
          'total_points': 1300,
          'rank': 4,
          'updated_at': DateTime.now().toIso8601String(),
        },
        'old': {
          'user_id': 'test-user-id',
          'total_points': 1250,
          'rank': 5,
          'updated_at': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
        },
      },
      'inventory_sync': {
        'eventType': 'INSERT',
        'new': MockInventoryItems.createMockInventoryItems(count: 1).first,
        'old': null,
      },
      'bin_status_update': {
        'eventType': 'UPDATE',
        'new': {
          'bin_id': 'bin-123',
          'capacity': 85,
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        },
        'old': {
          'bin_id': 'bin-123',
          'capacity': 75,
          'status': 'active',
          'updated_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
      },
    };
  }

  /// Mock RPC (stored procedure) responses
  static Map<String, dynamic> createRPCResponses() {
    return {
      'calculate_user_rank': createSuccessResponse(
        data: {
          'rank': 5,
          'total_users': 1000,
          'percentile': 95.0,
        },
      ),
      'get_nearby_bins': createSuccessResponse(
        data: MockBinLocations.createNearbyBinLocations(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        count: 5,
      ),
      'sync_inventory_batch': createSuccessResponse(
        data: {
          'synced_items': 10,
          'failed_items': 0,
          'conflicts': 0,
          'sync_id': 'sync-${DateTime.now().millisecondsSinceEpoch}',
        },
      ),
      'update_leaderboard': createSuccessResponse(
        data: {
          'updated': true,
          'new_rank': 4,
          'points_added': 50,
        },
      ),
    };
  }

  /// Mock common database errors
  static Map<String, PostgrestException> getCommonDatabaseErrors() {
    return {
      'connection_error': createDatabaseError(
        message: 'Connection to database failed',
        code: 'PGRST301',
      ),
      'permission_denied': createDatabaseError(
        message: 'Permission denied for relation',
        code: 'PGRST116',
      ),
      'row_not_found': createDatabaseError(
        message: 'No rows found',
        code: 'PGRST116',
      ),
      'constraint_violation': createDatabaseError(
        message: 'Unique constraint violation',
        code: 'PGRST202',
      ),
      'invalid_json': createDatabaseError(
        message: 'Invalid JSON format',
        code: 'PGRST102',
      ),
      'timeout': createDatabaseError(
        message: 'Request timeout',
        code: 'PGRST301',
      ),
    };
  }

  /// Mock batch operation responses
  static Map<String, dynamic> createBatchResponses() {
    return {
      'batch_insert_inventory': createSuccessResponse(
        data: MockInventoryItems.createMockInventoryItems(count: 10),
        count: 10,
      ),
      'batch_update_bins': createSuccessResponse(
        data: MockBinLocations.createMockBinLocations(count: 5),
        count: 5,
      ),
      'batch_delete_items': createSuccessResponse(
        data: null,
        count: 3,
      ),
    };
  }

  /// Mock analytics and reporting responses
  static Map<String, dynamic> createAnalyticsResponses() {
    return {
      'user_analytics': createSuccessResponse(
        data: {
          'user_id': 'test-user-id',
          'period': 'last_30_days',
          'total_items': 45,
          'total_points': 450,
          'category_breakdown': {
            'recycle': 20,
            'organic': 15,
            'landfill': 8,
            'ewaste': 2,
          },
          'daily_average': 1.5,
          'streak_days': 7,
        },
      ),
      'system_analytics': createSuccessResponse(
        data: {
          'total_users': 10000,
          'active_users_today': 1500,
          'total_items_collected': 500000,
          'total_bins': 2500,
          'average_items_per_user': 50,
          'top_categories': ['recycle', 'organic', 'landfill'],
        },
      ),
    };
  }

  /// Mock search responses
  static Map<String, dynamic> createSearchResponses() {
    return {
      'search_users': createSuccessResponse(
        data: MockUsers.createMockUsers(count: 5),
        count: 5,
      ),
      'search_bins': createSuccessResponse(
        data: MockBinLocations.createMockBinLocations(count: 8),
        count: 8,
      ),
      'search_inventory': createSuccessResponse(
        data: MockInventoryItems.createMockInventoryItems(count: 15),
        count: 15,
      ),
    };
  }

  /// Mock configuration responses
  static Map<String, dynamic> createConfigurationResponses() {
    return {
      'app_config': createSuccessResponse(
        data: {
          'version': '1.0.0',
          'min_supported_version': '1.0.0',
          'features': {
            'ar_detection': true,
            'social_sharing': true,
            'offline_mode': true,
            'push_notifications': true,
          },
          'limits': {
            'max_inventory_items': 1000,
            'max_daily_uploads': 100,
            'sync_interval_minutes': 5,
          },
          'updated_at': DateTime.now().toIso8601String(),
        },
      ),
      'category_config': createSuccessResponse(
        data: TestConfig.wasteCategories.entries.map((entry) => {
          'category': entry.key,
          'points': TestConfig.categoryPoints[entry.key] ?? 5,
          'color': _getCategoryColor(entry.key),
          'icon': _getCategoryIcon(entry.key),
          'enabled': true,
          'labels': entry.value,
        }).toList(),
        count: TestConfig.wasteCategories.length,
      ),
    };
  }

  /// Mock comprehensive test scenarios
  static Map<String, dynamic> createTestScenarios() {
    return {
      'offline_sync_scenario': {
        'local_changes': MockInventoryItems.createMockInventoryItems(count: 5),
        'remote_changes': MockInventoryItems.createMockInventoryItems(count: 3),
        'conflicts': MockInventoryItems.createConflictedInventoryItems(count: 2),
        'sync_result': {
          'synced': 6,
          'conflicts': 2,
          'failed': 0,
        },
      },
      'bulk_operations_scenario': {
        'batch_insert': MockInventoryItems.createMockInventoryItems(count: 100),
        'batch_update': MockBinLocations.createMockBinLocations(count: 50),
        'batch_delete': List.generate(25, (index) => 'item-$index'),
        'performance_metrics': {
          'insert_time': 2500, // milliseconds
          'update_time': 1800,
          'delete_time': 1200,
        },
      },
      'real_time_updates_scenario': {
        'leaderboard_stream': List.generate(10, (index) => {
          'event_type': 'UPDATE',
          'timestamp': DateTime.now().add(Duration(seconds: index)).toIso8601String(),
          'data': {
            'user_id': 'user-$index',
            'points_change': 10 + (index * 5),
            'new_rank': index + 1,
          },
        }),
        'inventory_stream': List.generate(5, (index) => {
          'event_type': 'INSERT',
          'timestamp': DateTime.now().add(Duration(minutes: index)).toIso8601String(),
          'data': MockInventoryItems.createMockInventoryItems(count: 1).first,
        }),
      },
    };
  }

  /// Mock error simulation responses
  static Map<String, dynamic> createErrorSimulations() {
    return {
      'network_errors': {
        'timeout': createDatabaseError(
          message: 'Request timeout',
          code: 'PGRST301',
        ),
        'connection_lost': createDatabaseError(
          message: 'Connection lost',
          code: 'PGRST301',
        ),
        'rate_limited': createDatabaseError(
          message: 'Too many requests',
          code: 'PGRST429',
        ),
      },
      'data_errors': {
        'constraint_violation': createDatabaseError(
          message: 'Foreign key constraint violation',
          code: 'PGRST202',
        ),
        'invalid_data': createDatabaseError(
          message: 'Invalid JSON in request body',
          code: 'PGRST102',
        ),
        'permission_denied': createDatabaseError(
          message: 'Insufficient privileges',
          code: 'PGRST116',
        ),
      },
      'sync_errors': {
        'version_conflict': createDatabaseError(
          message: 'Version conflict detected',
          code: 'PGRST409',
        ),
        'data_corruption': createDatabaseError(
          message: 'Data integrity check failed',
          code: 'PGRST500',
        ),
      },
    };
  }

  /// Mock performance test responses
  static Map<String, dynamic> createPerformanceResponses() {
    return {
      'large_dataset_query': createSuccessResponse(
        data: MockInventoryItems.createPerformanceTestItems(count: 10000),
        count: 10000,
      ),
      'complex_join_query': createSuccessResponse(
        data: List.generate(1000, (index) => {
          'user': MockUsers.createMockUsers(count: 1).first,
          'inventory': MockInventoryItems.createMockInventoryItems(count: 5),
          'stats': {
            'total_points': 500 + (index * 10),
            'rank': index + 1,
            'items_count': 50 + index,
          },
        }),
        count: 1000,
      ),
      'aggregation_query': createSuccessResponse(
        data: {
          'total_users': 50000,
          'total_items': 2500000,
          'total_points': 25000000,
          'category_totals': TestConfig.wasteCategories.keys.map((category) => {
            'category': category,
            'total_items': 400000 + (category.hashCode % 100000),
            'total_points': (400000 + (category.hashCode % 100000)) * (TestConfig.categoryPoints[category] ?? 5),
          }).toList(),
          'daily_stats': List.generate(30, (day) => {
            'date': DateTime.now().subtract(Duration(days: day)).toIso8601String().split('T')[0],
            'new_users': 100 + (day % 50),
            'items_collected': 5000 + (day % 1000),
            'points_earned': 50000 + (day % 10000),
          }),
        },
      ),
    };
  }

  /// Helper method to get category color
  static String _getCategoryColor(String category) {
    switch (category) {
      case 'recycle':
        return '#4CAF50';
      case 'organic':
        return '#8BC34A';
      case 'landfill':
        return '#9E9E9E';
      case 'ewaste':
        return '#FF9800';
      case 'hazardous':
        return '#F44336';
      default:
        return '#607D8B';
    }
  }

  /// Helper method to get category icon
  static String _getCategoryIcon(String category) {
    switch (category) {
      case 'recycle':
        return 'recycle';
      case 'organic':
        return 'compost';
      case 'landfill':
        return 'delete';
      case 'ewaste':
        return 'memory';
      case 'hazardous':
        return 'warning';
      default:
        return 'help';
    }
  }
}