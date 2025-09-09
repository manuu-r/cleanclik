import '../models/category_stats.dart';
import '../models/database_exceptions.dart';
import 'database_service.dart';

/// Database service for CategoryStats entities with Supabase integration
class CategoryStatsDatabaseService extends DatabaseService<CategoryStats> {
  @override
  String get tableName => 'category_stats';

  @override
  CategoryStats fromDatabaseRow(Map<String, dynamic> data) {
    return CategoryStats.fromSupabase(data);
  }

  @override
  Map<String, dynamic> toDatabaseRow(CategoryStats entity, String userId) {
    return entity.toSupabase();
  }

  // ===== CATEGORY STATS SPECIFIC OPERATIONS =====

  /// Find category stats for a user and category
  Future<DatabaseResult<CategoryStats?>> findByUserIdAndCategory(
    String userId,
    String category,
  ) async {
    return await executeWithRetry(
      operation: 'findByUserIdAndCategory',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .eq('category', category)
            .maybeSingle();

        if (response == null) {
          return DatabaseResult.success(null);
        }

        final stats = fromDatabaseRow(response);
        return DatabaseResult.success(stats);
      },
    );
  }

  /// Get all category stats for a user as a map
  Future<DatabaseResult<Map<String, CategoryStats>>> getUserCategoryStatsMap(String userId) async {
    return await executeWithRetry(
      operation: 'getUserCategoryStatsMap',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId);

        final statsMap = <String, CategoryStats>{};
        for (final row in response) {
          final stats = fromDatabaseRow(row);
          statsMap[stats.category] = stats;
        }

        return DatabaseResult.success(statsMap);
      },
    );
  }

  /// Get category stats as simple count map (for backward compatibility)
  Future<DatabaseResult<Map<String, int>>> getUserCategoryCountsMap(String userId) async {
    return await executeWithRetry(
      operation: 'getUserCategoryCountsMap',
      action: () async {
        final response = await client
            .from(tableName)
            .select('category, item_count')
            .eq('user_id', userId);

        final countsMap = <String, int>{};
        for (final row in response) {
          final category = row['category'] as String;
          final itemCount = row['item_count'] as int;
          countsMap[category] = itemCount;
        }

        return DatabaseResult.success(countsMap);
      },
    );
  }

  /// Update or create category stats (upsert operation)
  Future<DatabaseResult<CategoryStats>> upsertCategoryStats(
    String userId,
    String category,
    int itemCountDelta,
    int pointsDelta,
  ) async {
    return await executeWithRetry(
      operation: 'upsertCategoryStats',
      action: () async {
        // Use Supabase upsert functionality
        final data = {
          'user_id': userId,
          'category': category,
          'item_count': itemCountDelta,
          'total_points': pointsDelta,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await client
            .from(tableName)
            .upsert(
              data,
              onConflict: 'user_id,category',
            )
            .select()
            .single();

        final stats = fromDatabaseRow(response);
        return DatabaseResult.success(stats);
      },
    );
  }

  /// Increment category stats (add to existing values)
  Future<DatabaseResult<CategoryStats>> incrementCategoryStats(
    String userId,
    String category,
    int itemCountIncrement,
    int pointsIncrement,
  ) async {
    return await executeWithRetry(
      operation: 'incrementCategoryStats',
      action: () async {
        // First, try to get existing stats
        final existingResult = await findByUserIdAndCategory(userId, category);
        
        if (!existingResult.isSuccess) {
          return DatabaseResult.failure(existingResult.error!);
        }

        final existing = existingResult.data;
        final newItemCount = (existing?.itemCount ?? 0) + itemCountIncrement;
        final newTotalPoints = (existing?.totalPoints ?? 0) + pointsIncrement;

        // Use upsert to handle both create and update cases
        final data = {
          'user_id': userId,
          'category': category,
          'item_count': newItemCount,
          'total_points': newTotalPoints,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await client
            .from(tableName)
            .upsert(
              data,
              onConflict: 'user_id,category',
            )
            .select()
            .single();

        final stats = fromDatabaseRow(response);
        return DatabaseResult.success(stats);
      },
    );
  }

  /// Get top categories by item count for a user
  Future<DatabaseResult<List<CategoryStats>>> getTopCategoriesByItems(
    String userId, {
    int limit = 10,
  }) async {
    return await executeWithRetry(
      operation: 'getTopCategoriesByItems',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .order('item_count', ascending: false)
            .limit(limit);

        final stats = response
            .map<CategoryStats>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(stats);
      },
    );
  }

  /// Get top categories by points for a user
  Future<DatabaseResult<List<CategoryStats>>> getTopCategoriesByPoints(
    String userId, {
    int limit = 10,
  }) async {
    return await executeWithRetry(
      operation: 'getTopCategoriesByPoints',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .order('total_points', ascending: false)
            .limit(limit);

        final stats = response
            .map<CategoryStats>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(stats);
      },
    );
  }

  /// Get total stats across all categories for a user
  Future<DatabaseResult<Map<String, int>>> getTotalUserStats(String userId) async {
    return await executeWithRetry(
      operation: 'getTotalUserStats',
      action: () async {
        final response = await client
            .from(tableName)
            .select('item_count, total_points')
            .eq('user_id', userId);

        int totalItems = 0;
        int totalPoints = 0;

        for (final row in response) {
          totalItems += row['item_count'] as int;
          totalPoints += row['total_points'] as int;
        }

        return DatabaseResult.success({
          'total_items': totalItems,
          'total_points': totalPoints,
          'categories_count': response.length,
        });
      },
    );
  }

  /// Reset category stats for a user (for testing/admin purposes)
  Future<DatabaseResult<void>> resetUserCategoryStats(String userId) async {
    return await executeWithRetry(
      operation: 'resetUserCategoryStats',
      action: () async {
        await client
            .from(tableName)
            .delete()
            .eq('user_id', userId);

        return const DatabaseResult.success(null);
      },
    );
  }

  /// Reset specific category stats for a user
  Future<DatabaseResult<void>> resetUserCategoryStatsForCategory(
    String userId,
    String category,
  ) async {
    return await executeWithRetry(
      operation: 'resetUserCategoryStatsForCategory',
      action: () async {
        await client
            .from(tableName)
            .delete()
            .eq('user_id', userId)
            .eq('category', category);

        return const DatabaseResult.success(null);
      },
    );
  }

  /// Batch update multiple category stats for a user
  Future<DatabaseResult<List<CategoryStats>>> batchUpdateCategoryStats(
    String userId,
    Map<String, Map<String, int>> categoryUpdates, // category -> {itemCount, totalPoints}
  ) async {
    return await executeWithRetry(
      operation: 'batchUpdateCategoryStats',
      action: () async {
        final now = DateTime.now().toIso8601String();
        final dataList = categoryUpdates.entries.map((entry) {
          final category = entry.key;
          final updates = entry.value;
          return {
            'user_id': userId,
            'category': category,
            'item_count': updates['itemCount'] ?? 0,
            'total_points': updates['totalPoints'] ?? 0,
            'updated_at': now,
          };
        }).toList();

        final response = await client
            .from(tableName)
            .upsert(
              dataList,
              onConflict: 'user_id,category',
            )
            .select();

        final stats = response
            .map<CategoryStats>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(stats);
      },
    );
  }

  // ===== HELPER METHODS =====
  // Inherits _executeWithRetry from DatabaseService base class
}