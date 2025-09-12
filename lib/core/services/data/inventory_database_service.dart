import 'package:cleanclik/core/models/database_exceptions.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/data/database_service.dart';

/// Database service for InventoryItem entities with Supabase integration
class InventoryDatabaseService extends DatabaseService<InventoryItem> {
  @override
  String get tableName => 'inventory';

  @override
  InventoryItem fromDatabaseRow(Map<String, dynamic> data) {
    return InventoryItem.fromSupabase(data);
  }

  @override
  Map<String, dynamic> toDatabaseRow(InventoryItem entity, String userId) {
    return entity.toSupabase(userId);
  }

  // ===== INVENTORY-SPECIFIC OPERATIONS =====

  /// Find inventory items by category for a user
  Future<DatabaseResult<List<InventoryItem>>> findByUserIdAndCategory(
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
            .order('picked_up_at', ascending: false);

        final items = response
            .map<InventoryItem>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(items);
      },
    );
  }

  /// Find inventory item by tracking ID for a user
  Future<DatabaseResult<InventoryItem?>> findByUserIdAndTrackingId(
    String userId,
    String trackingId,
  ) async {
    return await executeWithRetry(
      operation: 'findByUserIdAndTrackingId',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .eq('tracking_id', trackingId)
            .maybeSingle();

        if (response == null) {
          return DatabaseResult.success(null);
        }

        final item = fromDatabaseRow(response);
        return DatabaseResult.success(item);
      },
    );
  }

  /// Get category statistics for a user
  Future<DatabaseResult<Map<String, int>>> getCategoryStats(
    String userId,
  ) async {
    return await executeWithRetry(
      operation: 'getCategoryStats',
      action: () async {
        final response = await client
            .from(tableName)
            .select('category')
            .eq('user_id', userId);

        final categoryStats = <String, int>{};
        for (final row in response) {
          final category = row['category'] as String;
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        }

        return DatabaseResult.success(categoryStats);
      },
    );
  }

  /// Get items picked up within a date range
  Future<DatabaseResult<List<InventoryItem>>> findByUserIdAndDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await executeWithRetry(
      operation: 'findByUserIdAndDateRange',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .gte('picked_up_at', startDate.toIso8601String())
            .lte('picked_up_at', endDate.toIso8601String())
            .order('picked_up_at', ascending: false);

        final items = response
            .map<InventoryItem>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(items);
      },
    );
  }

  /// Get recent items for a user (last N items)
  Future<DatabaseResult<List<InventoryItem>>> getRecentItems(
    String userId, {
    int limit = 20,
  }) async {
    return await executeWithRetry(
      operation: 'getRecentItems',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .order('picked_up_at', ascending: false)
            .limit(limit);

        final items = response
            .map<InventoryItem>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(items);
      },
    );
  }

  /// Delete items by category for a user
  Future<DatabaseResult<int>> deleteByUserIdAndCategory(
    String userId,
    String category,
  ) async {
    return await executeWithRetry(
      operation: 'deleteByUserIdAndCategory',
      action: () async {
        // First count the items to be deleted
        final countResponse = await client
            .from(tableName)
            .select('id')
            .eq('user_id', userId)
            .eq('category', category);

        final deletedCount = countResponse.length;

        // Then delete them
        await client
            .from(tableName)
            .delete()
            .eq('user_id', userId)
            .eq('category', category);

        return DatabaseResult.success(deletedCount);
      },
    );
  }

  /// Delete items by tracking IDs for a user
  Future<DatabaseResult<int>> deleteByUserIdAndTrackingIds(
    String userId,
    List<String> trackingIds,
  ) async {
    return await executeWithRetry(
      operation: 'deleteByUserIdAndTrackingIds',
      action: () async {
        // First count the items to be deleted
        final countResponse = await client
            .from(tableName)
            .select('id')
            .eq('user_id', userId)
            .inFilter('tracking_id', trackingIds);

        final deletedCount = countResponse.length;

        // Then delete them
        await client
            .from(tableName)
            .delete()
            .eq('user_id', userId)
            .inFilter('tracking_id', trackingIds);

        return DatabaseResult.success(deletedCount);
      },
    );
  }

  /// Get total item count for a user
  Future<DatabaseResult<int>> getTotalItemCount(String userId) async {
    return await executeWithRetry(
      operation: 'getTotalItemCount',
      action: () async {
        final response = await client
            .from(tableName)
            .select('id')
            .eq('user_id', userId);

        final count = response.length;
        return DatabaseResult.success(count);
      },
    );
  }

  /// Get items with high confidence (above threshold)
  Future<DatabaseResult<List<InventoryItem>>> getHighConfidenceItems(
    String userId, {
    double confidenceThreshold = 0.8,
    int limit = 50,
  }) async {
    return await executeWithRetry(
      operation: 'getHighConfidenceItems',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .gte('confidence', confidenceThreshold)
            .order('confidence', ascending: false)
            .limit(limit);

        final items = response
            .map<InventoryItem>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(items);
      },
    );
  }

  /// Search items by display name or code name
  Future<DatabaseResult<List<InventoryItem>>> searchItems(
    String userId,
    String searchTerm, {
    int limit = 20,
  }) async {
    return await executeWithRetry(
      operation: 'searchItems',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .or(
              'display_name.ilike.%$searchTerm%,code_name.ilike.%$searchTerm%',
            )
            .order('picked_up_at', ascending: false)
            .limit(limit);

        final items = response
            .map<InventoryItem>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(items);
      },
    );
  }

  // ===== BATCH OPERATIONS =====

  /// Create multiple inventory items for a user
  Future<DatabaseResult<List<InventoryItem>>> createUserItems(
    List<InventoryItem> items,
    String userId,
  ) async {
    return await createBatch(items, userId);
  }

  /// Update multiple inventory items for a user
  Future<DatabaseResult<List<InventoryItem>>> updateUserItems(
    Map<String, InventoryItem> itemsById,
    String userId,
  ) async {
    return await updateBatch(itemsById, userId);
  }

  // ===== HELPER METHODS =====
  // Inherits _executeWithRetry from DatabaseService base class
}
