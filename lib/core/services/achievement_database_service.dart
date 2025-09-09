import '../models/achievement.dart';
import '../models/database_exceptions.dart';
import 'database_service.dart';

/// Database service for Achievement entities with Supabase integration
/// Manages user achievements in the achievements table
class AchievementDatabaseService extends DatabaseService<Achievement> {
  @override
  String get tableName => 'achievements';

  @override
  Achievement fromDatabaseRow(Map<String, dynamic> data) {
    return Achievement.fromSupabase(data);
  }

  @override
  Map<String, dynamic> toDatabaseRow(Achievement entity, String userId) {
    return entity.toSupabase(userId);
  }

  // ===== ACHIEVEMENT-SPECIFIC OPERATIONS =====

  /// Find user's unlocked achievements
  Future<DatabaseResult<List<Achievement>>> findUnlockedByUserId(String userId) async {
    return await executeWithRetry(
      operation: 'findUnlockedByUserId',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .order('unlocked_at', ascending: false);

        final achievements = response
            .map<Achievement>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(achievements);
      },
    );
  }

  /// Find specific achievement for a user
  Future<DatabaseResult<Achievement?>> findUserAchievement(
    String userId,
    String achievementId,
  ) async {
    return await executeWithRetry(
      operation: 'findUserAchievement',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .eq('achievement_id', achievementId)
            .maybeSingle();

        if (response == null) {
          return DatabaseResult.success(null);
        }

        final achievement = fromDatabaseRow(response);
        return DatabaseResult.success(achievement);
      },
    );
  }

  /// Check if user has specific achievement
  Future<DatabaseResult<bool>> hasUserAchievement(
    String userId,
    String achievementId,
  ) async {
    return await executeWithRetry(
      operation: 'hasUserAchievement',
      action: () async {
        final response = await client
            .from(tableName)
            .select('id')
            .eq('user_id', userId)
            .eq('achievement_id', achievementId)
            .limit(1);

        final hasAchievement = response.isNotEmpty;
        return DatabaseResult.success(hasAchievement);
      },
    );
  }

  /// Unlock achievement for user
  Future<DatabaseResult<Achievement>> unlockAchievement(
    String userId,
    String achievementId, {
    Map<String, dynamic>? metadata,
  }) async {
    return await executeWithRetry(
      operation: 'unlockAchievement',
      action: () async {
        // Check if already unlocked
        final existingResponse = await client
            .from(tableName)
            .select('id')
            .eq('user_id', userId)
            .eq('achievement_id', achievementId)
            .limit(1);

        if (existingResponse.isNotEmpty) {
          throw DatabaseException(
            DatabaseErrorType.duplicateKey,
            'Achievement already unlocked for user',
            table: tableName,
            operation: 'unlockAchievement',
          );
        }

        // Create new achievement record
        final data = {
          'user_id': userId,
          'achievement_id': achievementId,
          'unlocked_at': DateTime.now().toIso8601String(),
          'metadata': metadata ?? {},
        };

        final response = await client
            .from(tableName)
            .insert(data)
            .select()
            .single();

        final achievement = fromDatabaseRow(response);
        return DatabaseResult.success(achievement);
      },
    );
  }

  /// Get achievement statistics for user
  Future<DatabaseResult<Map<String, dynamic>>> getUserAchievementStats(String userId) async {
    return await executeWithRetry(
      operation: 'getUserAchievementStats',
      action: () async {
        final response = await client
            .from(tableName)
            .select('achievement_id, unlocked_at')
            .eq('user_id', userId);

        final totalUnlocked = response.length;
        final recentAchievements = response
            .where((row) {
              final unlockedAt = DateTime.parse(row['unlocked_at'] as String);
              final daysSince = DateTime.now().difference(unlockedAt).inDays;
              return daysSince <= 7;
            })
            .length;

        // Get first and latest achievement dates
        DateTime? firstAchievement;
        DateTime? latestAchievement;
        
        if (response.isNotEmpty) {
          final dates = response
              .map((row) => DateTime.parse(row['unlocked_at'] as String))
              .toList()
            ..sort();
          
          firstAchievement = dates.first;
          latestAchievement = dates.last;
        }

        final stats = {
          'total_unlocked': totalUnlocked,
          'recent_unlocked': recentAchievements,
          'first_achievement': firstAchievement?.toIso8601String(),
          'latest_achievement': latestAchievement?.toIso8601String(),
        };

        return DatabaseResult.success(stats);
      },
    );
  }

  /// Get achievements unlocked in date range
  Future<DatabaseResult<List<Achievement>>> findByUserIdAndDateRange(
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
            .gte('unlocked_at', startDate.toIso8601String())
            .lte('unlocked_at', endDate.toIso8601String())
            .order('unlocked_at', ascending: false);

        final achievements = response
            .map<Achievement>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(achievements);
      },
    );
  }

  /// Get recent achievements for user
  Future<DatabaseResult<List<Achievement>>> getRecentAchievements(
    String userId, {
    int limit = 10,
  }) async {
    return await executeWithRetry(
      operation: 'getRecentAchievements',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .order('unlocked_at', ascending: false)
            .limit(limit);

        final achievements = response
            .map<Achievement>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(achievements);
      },
    );
  }

  /// Get achievements by type for user
  Future<DatabaseResult<List<Achievement>>> findByUserIdAndType(
    String userId,
    AchievementType type,
  ) async {
    return await executeWithRetry(
      operation: 'findByUserIdAndType',
      action: () async {
        // Note: This assumes achievement metadata or a separate achievements definition table
        // For now, we'll filter by achievement_id pattern or use metadata
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .order('unlocked_at', ascending: false);

        // Filter by type in application code since we don't have type in DB
        final achievements = response
            .map<Achievement>((row) => fromDatabaseRow(row))
            .where((achievement) => achievement.type == type)
            .toList();

        return DatabaseResult.success(achievements);
      },
    );
  }

  /// Get achievement count by user
  Future<DatabaseResult<int>> getAchievementCount(String userId) async {
    return await executeWithRetry(
      operation: 'getAchievementCount',
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

  /// Delete specific achievement for user (if needed for testing/admin)
  Future<DatabaseResult<void>> deleteUserAchievement(
    String userId,
    String achievementId,
  ) async {
    return await executeWithRetry(
      operation: 'deleteUserAchievement',
      action: () async {
        await client
            .from(tableName)
            .delete()
            .eq('user_id', userId)
            .eq('achievement_id', achievementId);

        return const DatabaseResult.success(null);
      },
    );
  }

  /// Batch unlock multiple achievements for user
  Future<DatabaseResult<List<Achievement>>> unlockMultipleAchievements(
    String userId,
    List<String> achievementIds, {
    Map<String, dynamic>? metadata,
  }) async {
    return await executeWithRetry(
      operation: 'unlockMultipleAchievements',
      action: () async {
        final now = DateTime.now().toIso8601String();
        final dataList = achievementIds.map((achievementId) => {
          'user_id': userId,
          'achievement_id': achievementId,
          'unlocked_at': now,
          'metadata': metadata ?? {},
        }).toList();

        final response = await client
            .from(tableName)
            .insert(dataList)
            .select();

        final achievements = response
            .map<Achievement>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(achievements);
      },
    );
  }

  // ===== HELPER METHODS =====
  // Inherits _executeWithRetry from DatabaseService base class
}