import '../models/user.dart';
import '../models/database_exceptions.dart';
import 'database_service.dart';

/// Database service for User entities with Supabase integration
class UserDatabaseService extends DatabaseService<User> {
  @override
  String get tableName => 'users';

  @override
  User fromDatabaseRow(Map<String, dynamic> data) {
    return User.fromSupabase(data);
  }

  @override
  Map<String, dynamic> toDatabaseRow(User entity, String userId) {
    return entity.toSupabase();
  }

  // ===== USER-SPECIFIC OPERATIONS =====

  /// Find user by auth ID (Supabase auth.users reference)
  Future<DatabaseResult<User?>> findByAuthId(String authId) async {
    return await executeWithRetry(
      operation: 'findByAuthId',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('auth_id', authId)
            .maybeSingle();

        if (response == null) {
          return DatabaseResult.success(null);
        }

        final user = fromDatabaseRow(response);
        return DatabaseResult.success(user);
      },
    );
  }

  /// Find user by username
  Future<DatabaseResult<User?>> findByUsername(String username) async {
    return await executeWithRetry(
      operation: 'findByUsername',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('username', username)
            .maybeSingle();

        if (response == null) {
          return DatabaseResult.success(null);
        }

        final user = fromDatabaseRow(response);
        return DatabaseResult.success(user);
      },
    );
  }

  /// Find user by email
  Future<DatabaseResult<User?>> findByEmail(String email) async {
    return await executeWithRetry(
      operation: 'findByEmail',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('email', email)
            .maybeSingle();

        if (response == null) {
          return DatabaseResult.success(null);
        }

        final user = fromDatabaseRow(response);
        return DatabaseResult.success(user);
      },
    );
  }

  /// Update user points and level
  Future<DatabaseResult<User>> updatePoints(String userId, int totalPoints, int level) async {
    return await executeWithRetry(
      operation: 'updatePoints',
      action: () async {
        final response = await client
            .from(tableName)
            .update({
              'total_points': totalPoints,
              'level': level,
              'last_active_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId)
            .select()
            .single();

        final updatedUser = fromDatabaseRow(response);
        return DatabaseResult.success(updatedUser);
      },
    );
  }

  /// Update user online status
  Future<DatabaseResult<User>> updateOnlineStatus(String userId, bool isOnline) async {
    return await executeWithRetry(
      operation: 'updateOnlineStatus',
      action: () async {
        final response = await client
            .from(tableName)
            .update({
              'is_online': isOnline,
              'last_active_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId)
            .select()
            .single();

        final updatedUser = fromDatabaseRow(response);
        return DatabaseResult.success(updatedUser);
      },
    );
  }

  /// Get leaderboard users (top users by points)
  Future<DatabaseResult<List<User>>> getLeaderboard({int limit = 50}) async {
    return await executeWithRetry(
      operation: 'getLeaderboard',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .gt('total_points', 0)
            .order('total_points', ascending: false)
            .limit(limit);

        final users = response
            .map<User>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(users);
      },
    );
  }

  /// Get user rank by points
  Future<DatabaseResult<int>> getUserRank(String userId) async {
    return await executeWithRetry(
      operation: 'getUserRank',
      action: () async {
        // First get the user's points
        final userResponse = await client
            .from(tableName)
            .select('total_points')
            .eq('id', userId)
            .single();

        final userPoints = userResponse['total_points'] as int;

        // Count users with higher points
        final rankResponse = await client
            .from(tableName)
            .select('id')
            .gt('total_points', userPoints);

        final rank = rankResponse.length + 1;
        return DatabaseResult.success(rank);
      },
    );
  }

  /// Check if username is available
  Future<DatabaseResult<bool>> isUsernameAvailable(String username) async {
    return await executeWithRetry(
      operation: 'isUsernameAvailable',
      action: () async {
        final response = await client
            .from(tableName)
            .select('id')
            .eq('username', username)
            .limit(1);

        final isAvailable = response.isEmpty;
        return DatabaseResult.success(isAvailable);
      },
    );
  }

  /// Get users by activity (recently active users)
  Future<DatabaseResult<List<User>>> getActiveUsers({
    Duration? since,
    int limit = 20,
  }) async {
    return await executeWithRetry(
      operation: 'getActiveUsers',
      action: () async {
        final sinceDate = since != null 
            ? DateTime.now().subtract(since)
            : DateTime.now().subtract(const Duration(days: 7));

        final response = await client
            .from(tableName)
            .select()
            .gte('last_active_at', sinceDate.toIso8601String())
            .order('last_active_at', ascending: false)
            .limit(limit);

        final users = response
            .map<User>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(users);
      },
    );
  }

  // ===== HELPER METHODS =====


}