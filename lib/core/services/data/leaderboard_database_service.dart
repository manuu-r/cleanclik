import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:cleanclik/core/models/leaderboard_entry.dart';
import 'package:cleanclik/core/models/database_exceptions.dart';
import 'database_service.dart';

/// Database service for leaderboard operations with Supabase integration
class LeaderboardDatabaseService extends DatabaseService<LeaderboardEntry> {
  @override
  String get tableName => 'leaderboard'; // This is a view, not a table

  /// Page size for leaderboard pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  @override
  LeaderboardEntry fromDatabaseRow(Map<String, dynamic> data) {
    return LeaderboardEntry.fromSupabase(data);
  }

  @override
  Map<String, dynamic> toDatabaseRow(LeaderboardEntry entity, String userId) {
    // Leaderboard is a view, so we don't insert directly
    throw UnsupportedError('Cannot insert into leaderboard view');
  }

  /// Get leaderboard page with pagination
  Future<DatabaseResult<LeaderboardPage>> getLeaderboardPage({
    int page = 1,
    int pageSize = defaultPageSize,
    String? currentUserId,
    LeaderboardFilter filter = LeaderboardFilter.all,
    LeaderboardSort sort = LeaderboardSort.points,
  }) async {
    return await executeWithRetry(
      operation: 'getLeaderboardPage',
      action: () async {
        // Validate parameters
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > maxPageSize) pageSize = defaultPageSize;

        final offset = (page - 1) * pageSize;

        // Build query step by step to avoid type issues
        debugPrint(
          '🏆 [DB] Building leaderboard query with filter: $filter, sort: $sort',
        );
        var query = client.from('leaderboard').select('''
          id,
          username,
          total_points,
          level,
          rank,
          avatar_url,
          last_active_at
        ''');

        // Apply filters first
        switch (filter) {
          case LeaderboardFilter.all:
            break; // No filter
          case LeaderboardFilter.friends:
            // TODO: Implement friends filter when friends system is added
            break;
          case LeaderboardFilter.thisWeek:
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            query = query.gte('last_active_at', weekAgo.toIso8601String());
            break;
          case LeaderboardFilter.thisMonth:
            final monthAgo = DateTime.now().subtract(const Duration(days: 30));
            query = query.gte('last_active_at', monthAgo.toIso8601String());
            break;
          case LeaderboardFilter.allTime:
            break; // No filter
        }

        // Apply sorting and pagination in one chain to avoid type issues
        dynamic finalQuery;
        switch (sort) {
          case LeaderboardSort.points:
            finalQuery = query.order('total_points', ascending: false);
            break;
          case LeaderboardSort.level:
            finalQuery = query.order('level', ascending: false);
            break;
          case LeaderboardSort.recent:
            finalQuery = query.order('last_active_at', ascending: false);
            break;
        }

        // Apply pagination
        final paginatedQuery = finalQuery.range(offset, offset + pageSize - 1);

        debugPrint('🏆 [DB] Executing leaderboard query...');
        final response = await paginatedQuery;
        debugPrint('🏆 [DB] Query returned ${response.length} rows');

        // Get total count for pagination info
        final totalCount = await _getTotalCount(filter);

        final entries = response.map<LeaderboardEntry>((row) {
          return LeaderboardEntry.fromSupabase(
            row,
            currentUserId: currentUserId,
          );
        }).toList();

        final totalPages = (totalCount / pageSize).ceil();

        final leaderboardPage = LeaderboardPage(
          entries: entries,
          currentPage: page,
          totalPages: totalPages,
          totalEntries: totalCount,
          hasNextPage: page < totalPages,
          hasPreviousPage: page > 1,
          lastUpdated: DateTime.now(),
        );

        return DatabaseResult.success(leaderboardPage);
      },
    );
  }

  /// Get user's current rank and surrounding entries
  Future<DatabaseResult<LeaderboardPage>> getUserRankContext({
    required String userId,
    int contextSize = 5,
    LeaderboardFilter filter = LeaderboardFilter.all,
  }) async {
    return await executeWithRetry(
      operation: 'getUserRankContext',
      action: () async {
        // First, get the user's current rank
        final userRankResult = await _getUserRank(userId, filter);
        if (!userRankResult.isSuccess) {
          return DatabaseResult.failure(userRankResult.error!);
        }

        final userRank = userRankResult.data!;

        // Calculate range around user's rank
        final startRank = (userRank - contextSize)
            .clamp(1, double.infinity)
            .toInt();
        final endRank = userRank + contextSize;

        // Get entries in the rank range
        var query = client.from('leaderboard').select('''
          id,
          username,
          total_points,
          level,
          rank,
          avatar_url,
          last_active_at
        ''');

        // Apply filter and build final query in one chain
        dynamic finalQuery;
        switch (filter) {
          case LeaderboardFilter.all:
            finalQuery = query
                .gte('rank', startRank)
                .lte('rank', endRank)
                .order('rank', ascending: true);
            break;
          case LeaderboardFilter.friends:
            // TODO: Implement friends filter when friends system is added
            finalQuery = query
                .gte('rank', startRank)
                .lte('rank', endRank)
                .order('rank', ascending: true);
            break;
          case LeaderboardFilter.thisWeek:
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            finalQuery = query
                .gte('last_active_at', weekAgo.toIso8601String())
                .gte('rank', startRank)
                .lte('rank', endRank)
                .order('rank', ascending: true);
            break;
          case LeaderboardFilter.thisMonth:
            final monthAgo = DateTime.now().subtract(const Duration(days: 30));
            finalQuery = query
                .gte('last_active_at', monthAgo.toIso8601String())
                .gte('rank', startRank)
                .lte('rank', endRank)
                .order('rank', ascending: true);
            break;
          case LeaderboardFilter.allTime:
            finalQuery = query
                .gte('rank', startRank)
                .lte('rank', endRank)
                .order('rank', ascending: true);
            break;
        }

        final response = await finalQuery;

        final entries = response.map<LeaderboardEntry>((row) {
          return LeaderboardEntry.fromSupabase(row, currentUserId: userId);
        }).toList();

        final leaderboardPage = LeaderboardPage(
          entries: entries,
          currentPage: 1, // Context view doesn't use traditional pagination
          totalPages: 1,
          totalEntries: entries.length,
          hasNextPage: false,
          hasPreviousPage: false,
          lastUpdated: DateTime.now(),
        );

        return DatabaseResult.success(leaderboardPage);
      },
    );
  }

  /// Get top N users from leaderboard
  Future<DatabaseResult<List<LeaderboardEntry>>> getTopUsers({
    int limit = 10,
    String? currentUserId,
    LeaderboardFilter filter = LeaderboardFilter.all,
  }) async {
    return await executeWithRetry(
      operation: 'getTopUsers',
      action: () async {
        var query = client.from('leaderboard').select('''
          id,
          username,
          total_points,
          level,
          rank,
          avatar_url,
          last_active_at
        ''');

        // Apply filter and build final query in one chain
        dynamic finalQuery;
        switch (filter) {
          case LeaderboardFilter.all:
            finalQuery = query.order('rank', ascending: true).limit(limit);
            break;
          case LeaderboardFilter.friends:
            // TODO: Implement friends filter when friends system is added
            finalQuery = query.order('rank', ascending: true).limit(limit);
            break;
          case LeaderboardFilter.thisWeek:
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            finalQuery = query
                .gte('last_active_at', weekAgo.toIso8601String())
                .order('rank', ascending: true)
                .limit(limit);
            break;
          case LeaderboardFilter.thisMonth:
            final monthAgo = DateTime.now().subtract(const Duration(days: 30));
            finalQuery = query
                .gte('last_active_at', monthAgo.toIso8601String())
                .order('rank', ascending: true)
                .limit(limit);
            break;
          case LeaderboardFilter.allTime:
            finalQuery = query.order('rank', ascending: true).limit(limit);
            break;
        }

        final response = await finalQuery;

        final entries = response.map<LeaderboardEntry>((row) {
          return LeaderboardEntry.fromSupabase(
            row,
            currentUserId: currentUserId,
          );
        }).toList();

        return DatabaseResult.success(entries);
      },
    );
  }

  /// Get user's current rank
  Future<DatabaseResult<int>> getUserRank(
    String userId, {
    LeaderboardFilter filter = LeaderboardFilter.all,
  }) async {
    return await _getUserRank(userId, filter);
  }

  /// Search users in leaderboard by username
  Future<DatabaseResult<List<LeaderboardEntry>>> searchUsers({
    required String query,
    int limit = 20,
    String? currentUserId,
  }) async {
    return await executeWithRetry(
      operation: 'searchUsers',
      action: () async {
        final searchQuery = client
            .from('leaderboard')
            .select('''
          id,
          username,
          total_points,
          level,
          rank,
          avatar_url,
          last_active_at
        ''')
            .ilike('username', '%$query%')
            .order('rank', ascending: true)
            .limit(limit);

        final response = await searchQuery;

        final entries = response.map<LeaderboardEntry>((row) {
          return LeaderboardEntry.fromSupabase(
            row,
            currentUserId: currentUserId,
          );
        }).toList();

        return DatabaseResult.success(entries);
      },
    );
  }

  /// Subscribe to real-time leaderboard updates
  Stream<List<LeaderboardEntry>> subscribeToLeaderboard({
    int limit = 20,
    String? currentUserId,
  }) {
    return client
        .from('leaderboard')
        .stream(primaryKey: ['id'])
        .order('rank', ascending: true)
        .limit(limit)
        .map(
          (data) => data.map<LeaderboardEntry>((row) {
            return LeaderboardEntry.fromSupabase(
              row,
              currentUserId: currentUserId,
            );
          }).toList(),
        );
  }

  /// Subscribe to user's rank changes
  Stream<int?> subscribeToUserRank(String userId) {
    return client
        .from('leaderboard')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? data.first['rank'] as int : null);
  }

  /// Get leaderboard statistics
  Future<DatabaseResult<Map<String, dynamic>>> getLeaderboardStats() async {
    return await executeWithRetry(
      operation: 'getLeaderboardStats',
      action: () async {
        // Get total users count
        final totalUsersQuery = client.from('leaderboard').select('id');
        final totalUsersResponse = await totalUsersQuery;
        final totalUsers = totalUsersResponse.length;

        // Get active users count (last active within 7 days)
        final activeUsersQuery = client
            .from('leaderboard')
            .select('id')
            .gte(
              'last_active_at',
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toIso8601String(),
            );
        final activeUsersResponse = await activeUsersQuery;
        final activeUsers = activeUsersResponse.length;

        // Get top score
        final topScoreQuery = client
            .from('leaderboard')
            .select('total_points')
            .order('total_points', ascending: false)
            .limit(1);
        final topScoreResponse = await topScoreQuery;
        final topScore = topScoreResponse.isNotEmpty
            ? topScoreResponse.first['total_points'] as int
            : 0;

        // Get average score
        final avgScoreQuery = client.rpc('get_average_score');
        final avgScoreResponse = await avgScoreQuery;
        final avgScore = avgScoreResponse as double? ?? 0.0;

        final stats = {
          'totalUsers': totalUsers,
          'activeUsers': activeUsers,
          'topScore': topScore,
          'averageScore': avgScore.round(),
          'lastUpdated': DateTime.now().toIso8601String(),
        };

        return DatabaseResult.success(stats);
      },
    );
  }

  /// Private helper methods

  /// Get total count for pagination
  Future<int> _getTotalCount(LeaderboardFilter filter) async {
    try {
      var query = client.from('leaderboard').select('id');

      // Apply filter and build final query in one chain
      dynamic finalQuery;
      switch (filter) {
        case LeaderboardFilter.all:
          finalQuery = query;
          break;
        case LeaderboardFilter.friends:
          // TODO: Implement friends filter when friends system is added
          finalQuery = query;
          break;
        case LeaderboardFilter.thisWeek:
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          finalQuery = query.gte('last_active_at', weekAgo.toIso8601String());
          break;
        case LeaderboardFilter.thisMonth:
          final monthAgo = DateTime.now().subtract(const Duration(days: 30));
          finalQuery = query.gte('last_active_at', monthAgo.toIso8601String());
          break;
        case LeaderboardFilter.allTime:
          finalQuery = query;
          break;
      }

      final response = await finalQuery;
      return response.length;
    } catch (e) {
      debugPrint('Error getting total count: $e');
      return 0;
    }
  }

  /// Get user's rank
  Future<DatabaseResult<int>> _getUserRank(
    String userId,
    LeaderboardFilter filter,
  ) async {
    return await executeWithRetry(
      operation: '_getUserRank',
      action: () async {
        var query = client.from('leaderboard').select('rank').eq('id', userId);

        // Apply filter and build final query in one chain
        dynamic finalQuery;
        switch (filter) {
          case LeaderboardFilter.all:
            finalQuery = query;
            break;
          case LeaderboardFilter.friends:
            // TODO: Implement friends filter when friends system is added
            finalQuery = query;
            break;
          case LeaderboardFilter.thisWeek:
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            finalQuery = query.gte('last_active_at', weekAgo.toIso8601String());
            break;
          case LeaderboardFilter.thisMonth:
            final monthAgo = DateTime.now().subtract(const Duration(days: 30));
            finalQuery = query.gte(
              'last_active_at',
              monthAgo.toIso8601String(),
            );
            break;
          case LeaderboardFilter.allTime:
            finalQuery = query;
            break;
        }

        final response = await finalQuery.maybeSingle();

        if (response == null) {
          return DatabaseResult.failure(
            DatabaseException(
              DatabaseErrorType.recordNotFound,
              'User not found in leaderboard',
              table: tableName,
              operation: '_getUserRank',
            ),
          );
        }

        final rank = response['rank'] as int;
        return DatabaseResult.success(rank);
      },
    );
  }

  /// Refresh leaderboard view (if needed)
  Future<DatabaseResult<void>> refreshLeaderboard() async {
    return await executeWithRetry(
      operation: 'refreshLeaderboard',
      action: () async {
        // The leaderboard view should automatically update when users table changes
        // This method can be used to trigger manual refresh if needed

        // For now, we'll just verify the view exists and is accessible
        await client.from('leaderboard').select('count').limit(1);

        return const DatabaseResult.success(null);
      },
    );
  }
}
