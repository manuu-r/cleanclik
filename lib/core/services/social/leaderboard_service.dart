import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanclik/core/models/leaderboard_entry.dart';
import 'package:cleanclik/core/models/sync_status.dart';
import 'package:cleanclik/core/models/achievement_card.dart';

import 'package:cleanclik/core/services/data/leaderboard_database_service.dart';
import 'package:cleanclik/core/services/data/database_service_provider.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';

part 'leaderboard_service.g.dart';

/// Service for managing leaderboard data with real-time updates and caching
class LeaderboardService {
  final LeaderboardDatabaseService _dbService;
  final AuthService _authService;
  final SharedPreferences _prefs;

  // State management
  final StreamController<LeaderboardPage> _leaderboardController =
      StreamController<LeaderboardPage>.broadcast();
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<int?> _userRankController =
      StreamController<int?>.broadcast();
  final StreamController<String> _achievementController =
      StreamController<String>.broadcast();

  // Cache management
  LeaderboardPage? _cachedLeaderboard;
  int? _cachedUserRank;
  DateTime? _lastCacheUpdate;
  Timer? _refreshTimer;
  StreamSubscription? _realtimeSubscription;
  StreamSubscription? _userRankSubscription;

  // User stats
  int _currentStreak = 0;
  double _accuracyPercentage = 0.0;

  // Configuration
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const Duration refreshInterval = Duration(
    minutes: 2,
  ); // Reduced frequency
  static const String cacheKeyPrefix = 'leaderboard_cache_';
  static const String userRankCacheKey = 'user_rank_cache';

  LeaderboardService(this._dbService, this._authService, this._prefs) {
    _initializeService();
  }

  /// Initialize the service
  void _initializeService() {
    _loadCachedData();
    _setupRealtimeSubscriptions();
    _startPeriodicRefresh();

    // Initialize user rank if we have a current user
    _initializeUserRank();
  }

  /// Initialize user rank on service startup
  Future<void> _initializeUserRank() async {
    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null) {
        final rank = await getUserRank();
        if (rank != null) {
          _notifyAuthServiceOfRankChange(currentUserId, rank);
        }
      }
    } catch (e) {
      debugPrint('Error initializing user rank: $e');
    }
  }

  /// Streams for reactive UI updates
  Stream<LeaderboardPage> get leaderboardStream =>
      _leaderboardController.stream;
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  Stream<int?> get userRankStream => _userRankController.stream;

  /// Achievement unlocked stream for notifications
  Stream<String> get achievementUnlockedStream => _achievementController.stream;

  /// Current user streak
  int get currentStreak => _currentStreak;

  /// Current user accuracy percentage
  double get accuracyPercentage => _accuracyPercentage;

  /// Get current cached leaderboard
  LeaderboardPage? get cachedLeaderboard => _cachedLeaderboard;

  /// Get current cached user rank
  int? get cachedUserRank => _cachedUserRank;

  /// Check if cache is valid
  bool get isCacheValid {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < cacheExpiry;
  }

  /// Clear cache and force refresh from database
  Future<void> clearCache() async {
    debugPrint('🏆 [LEADERBOARD] Clearing cache and forcing refresh');
    _cachedLeaderboard = null;
    _lastCacheUpdate = null;
    await _prefs.remove('${cacheKeyPrefix}page_1');
  }

  /// Debug method to test database directly
  Future<void> testDatabaseDirectly() async {
    debugPrint('🏆 [LEADERBOARD] Testing database directly...');
    try {
      // Clear cache first
      await clearCache();

      // Test connection
      final connectionTest = await _dbService.testConnection();
      debugPrint('🏆 [LEADERBOARD] Connection test: $connectionTest');

      // Try to get leaderboard data
      final result = await _dbService.getLeaderboardPage(
        page: 1,
        pageSize: 10,
        currentUserId: _authService.currentUser?.id,
      );

      if (result.isSuccess) {
        debugPrint(
          '🏆 [LEADERBOARD] Direct DB query SUCCESS: ${result.data!.entries.length} entries',
        );
        for (final entry in result.data!.entries) {
          debugPrint(
            '🏆 [LEADERBOARD] Entry: ${entry.username} - ${entry.totalPoints} points (rank ${entry.rank})',
          );
        }

        // Test current user rank
        final currentUserId = _authService.currentUser?.id;
        if (currentUserId != null) {
          final rankResult = await _dbService.getUserRank(currentUserId);
          if (rankResult.isSuccess) {
            debugPrint(
              '🏆 [LEADERBOARD] Current user rank: ${rankResult.data}',
            );

            // Update auth service with current rank
            _notifyAuthServiceOfRankChange(currentUserId, rankResult.data!);
          } else {
            debugPrint(
              '🏆 [LEADERBOARD] Failed to get user rank: ${rankResult.error}',
            );
          }
        }
      } else {
        debugPrint(
          '🏆 [LEADERBOARD] Direct DB query FAILED: ${result.error!.message}',
        );
      }
    } catch (e) {
      debugPrint('🏆 [LEADERBOARD] Direct DB test exception: $e');
    }
  }

  /// Get leaderboard page with caching and real-time updates
  Future<LeaderboardPage> getLeaderboardPage({
    int page = 1,
    int pageSize = 20,
    LeaderboardFilter filter = LeaderboardFilter.all,
    LeaderboardSort sort = LeaderboardSort.points,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint(
        '🏆 [LEADERBOARD] Getting leaderboard page: page=$page, pageSize=$pageSize, filter=$filter, sort=$sort, forceRefresh=$forceRefresh',
      );
      _syncStatusController.add(SyncStatus.syncing());

      // Return cached data if valid and not forcing refresh
      if (!forceRefresh &&
          isCacheValid &&
          _cachedLeaderboard != null &&
          page == 1) {
        debugPrint(
          '🏆 [LEADERBOARD] Returning cached data: ${_cachedLeaderboard!.entries.length} entries',
        );
        _syncStatusController.add(SyncStatus.success());
        return _cachedLeaderboard!;
      }

      // Fetch from database
      final currentUserId = _authService.currentUser?.id;
      debugPrint(
        '🏆 [LEADERBOARD] Fetching from database for user: $currentUserId',
      );

      // Test database connection first
      try {
        final testResult = await _dbService.testConnection();
        debugPrint(
          '🏆 [LEADERBOARD] Database connection test: ${testResult ? "SUCCESS" : "FAILED"}',
        );
      } catch (e) {
        debugPrint('🏆 [LEADERBOARD] Database connection test exception: $e');
      }

      final result = await _dbService.getLeaderboardPage(
        page: page,
        pageSize: pageSize,
        currentUserId: currentUserId,
        filter: filter,
        sort: sort,
      );

      if (!result.isSuccess) {
        debugPrint(
          '🏆 [LEADERBOARD] Database query failed: ${result.error!.userMessage}',
        );
        _syncStatusController.add(SyncStatus.error(result.error!.userMessage));

        // Return cached data as fallback
        if (_cachedLeaderboard != null) {
          debugPrint(
            '🏆 [LEADERBOARD] Returning cached data as fallback: ${_cachedLeaderboard!.entries.length} entries',
          );
          return _cachedLeaderboard!;
        }

        throw Exception(result.error!.userMessage);
      }

      final leaderboardPage = result.data!;
      debugPrint(
        '🏆 [LEADERBOARD] Successfully fetched ${leaderboardPage.entries.length} entries from database',
      );

      // Update cache for first page
      if (page == 1) {
        await _updateCache(leaderboardPage);
      }

      _syncStatusController.add(SyncStatus.success());
      return leaderboardPage;
    } catch (e) {
      debugPrint('🏆 [LEADERBOARD] Exception occurred: $e');
      _syncStatusController.add(SyncStatus.error(e.toString()));

      // Return cached data as fallback
      if (_cachedLeaderboard != null) {
        debugPrint(
          '🏆 [LEADERBOARD] Returning cached data after exception: ${_cachedLeaderboard!.entries.length} entries',
        );
        return _cachedLeaderboard!;
      }

      debugPrint(
        '🏆 [LEADERBOARD] No cached data available, returning empty page',
      );
      return LeaderboardPage.empty();
    }
  }

  /// Get user's rank with caching
  Future<int?> getUserRank({
    LeaderboardFilter filter = LeaderboardFilter.all,
    bool forceRefresh = false,
  }) async {
    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) return null;

      // Return cached rank if valid and not forcing refresh
      if (!forceRefresh && isCacheValid && _cachedUserRank != null) {
        return _cachedUserRank;
      }

      final result = await _dbService.getUserRank(
        currentUserId,
        filter: filter,
      );

      if (!result.isSuccess) {
        debugPrint('Error getting user rank: ${result.error}');
        return _cachedUserRank; // Return cached value as fallback
      }

      final rank = result.data!;
      await _updateUserRankCache(rank);
      return rank;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return _cachedUserRank;
    }
  }

  /// Get user's rank context (surrounding entries)
  Future<LeaderboardPage> getUserRankContext({
    int contextSize = 5,
    LeaderboardFilter filter = LeaderboardFilter.all,
  }) async {
    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) return LeaderboardPage.empty();

      final result = await _dbService.getUserRankContext(
        userId: currentUserId,
        contextSize: contextSize,
        filter: filter,
      );

      if (!result.isSuccess) {
        throw Exception(result.error!.userMessage);
      }

      return result.data!;
    } catch (e) {
      debugPrint('Error getting user rank context: $e');
      return LeaderboardPage.empty();
    }
  }

  /// Get top users
  Future<List<LeaderboardEntry>> getTopUsers({
    int limit = 10,
    LeaderboardFilter filter = LeaderboardFilter.all,
  }) async {
    try {
      final currentUserId = _authService.currentUser?.id;
      final result = await _dbService.getTopUsers(
        limit: limit,
        currentUserId: currentUserId,
        filter: filter,
      );

      if (!result.isSuccess) {
        throw Exception(result.error!.userMessage);
      }

      return result.data!;
    } catch (e) {
      debugPrint('Error getting top users: $e');
      return [];
    }
  }

  /// Search users in leaderboard
  Future<List<LeaderboardEntry>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      final currentUserId = _authService.currentUser?.id;
      final result = await _dbService.searchUsers(
        query: query.trim(),
        limit: limit,
        currentUserId: currentUserId,
      );

      if (!result.isSuccess) {
        throw Exception(result.error!.userMessage);
      }

      return result.data!;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Get leaderboard statistics
  Future<Map<String, dynamic>> getLeaderboardStats() async {
    try {
      final result = await _dbService.getLeaderboardStats();

      if (!result.isSuccess) {
        throw Exception(result.error!.userMessage);
      }

      return result.data!;
    } catch (e) {
      debugPrint('Error getting leaderboard stats: $e');
      return {};
    }
  }

  /// Manually refresh leaderboard data
  Future<void> refreshLeaderboard() async {
    try {
      await getLeaderboardPage(forceRefresh: true);
      await getUserRank(forceRefresh: true);
    } catch (e) {
      debugPrint('Error refreshing leaderboard: $e');
    }
  }

  /// Force refresh user rank and update auth service
  Future<void> refreshUserRank() async {
    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null) {
        final rank = await getUserRank(forceRefresh: true);
        if (rank != null) {
          _notifyAuthServiceOfRankChange(currentUserId, rank);
        }
      }
    } catch (e) {
      debugPrint('Error refreshing user rank: $e');
    }
  }

  /// Trigger rank update for a specific user (called when points change)
  Future<void> triggerRankUpdate(String userId) async {
    try {
      debugPrint('🏆 [LEADERBOARD] Triggering rank update for user: $userId');

      // Force refresh leaderboard data
      await refreshLeaderboard();

      // If it's the current user, update their rank
      if (_authService.currentUser?.id == userId) {
        await refreshUserRank();
      }

      debugPrint('🏆 [LEADERBOARD] Rank update completed for user: $userId');
    } catch (e) {
      debugPrint('🏆 [LEADERBOARD] Error triggering rank update: $e');
    }
  }

  /// Sync leaderboard data (for offline/online sync)
  Future<void> syncLeaderboardData() async {
    try {
      // Skip sync if cache is still valid (within 30 seconds)
      if (isCacheValid && _lastCacheUpdate != null) {
        final timeSinceLastUpdate = DateTime.now().difference(
          _lastCacheUpdate!,
        );
        if (timeSinceLastUpdate < const Duration(seconds: 30)) {
          debugPrint(
            '🏆 [LEADERBOARD] Skipping sync - cache is fresh (${timeSinceLastUpdate.inSeconds}s old)',
          );
          _syncStatusController.add(SyncStatus.success());
          return;
        }
      }

      _syncStatusController.add(SyncStatus.syncing());

      // Refresh leaderboard data
      await refreshLeaderboard();

      // Refresh database view if needed
      await _dbService.refreshLeaderboard();

      _syncStatusController.add(SyncStatus.success());
    } catch (e) {
      debugPrint('Error syncing leaderboard data: $e');
      _syncStatusController.add(SyncStatus.error(e.toString()));
    }
  }

  /// Handle optimistic updates when user points change
  void handleUserPointsUpdate(String userId, int newPoints, int newLevel) {
    if (_cachedLeaderboard == null) return;

    try {
      // Find user in cached leaderboard
      final entries = List<LeaderboardEntry>.from(_cachedLeaderboard!.entries);
      final userIndex = entries.indexWhere((entry) => entry.id == userId);

      if (userIndex != -1) {
        // Update user's entry optimistically
        final updatedEntry = entries[userIndex].copyWith(
          totalPoints: newPoints,
          level: newLevel,
        );
        entries[userIndex] = updatedEntry;

        // Re-sort entries by points (optimistic ranking)
        entries.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

        // Update ranks
        for (int i = 0; i < entries.length; i++) {
          entries[i] = entries[i].copyWith(rank: i + 1);
        }

        // Update cached leaderboard
        final updatedLeaderboard = _cachedLeaderboard!.copyWith(
          entries: entries,
          lastUpdated: DateTime.now(),
        );

        _cachedLeaderboard = updatedLeaderboard;
        _leaderboardController.add(updatedLeaderboard);

        // Update user rank cache and notify auth service
        final newRank = entries.indexWhere((entry) => entry.id == userId) + 1;
        _updateUserRankCache(newRank);

        // Notify auth service of rank change
        _notifyAuthServiceOfRankChange(userId, newRank);
      }
    } catch (e) {
      debugPrint('Error handling optimistic update: $e');
    }
  }

  /// Notify auth service of rank changes
  void _notifyAuthServiceOfRankChange(String userId, int newRank) {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        // Update the user's rank in auth service
        _authService.updateUserRank(newRank);
      }
    } catch (e) {
      debugPrint('Error notifying auth service of rank change: $e');
    }
  }

  /// Private methods

  /// Load cached data from local storage
  Future<void> _loadCachedData() async {
    try {
      // Load cached leaderboard
      final cachedLeaderboardJson = _prefs.getString('${cacheKeyPrefix}page_1');
      if (cachedLeaderboardJson != null) {
        final cachedData = jsonDecode(cachedLeaderboardJson);
        _cachedLeaderboard = LeaderboardPage.fromJson(cachedData['data']);
        _lastCacheUpdate = DateTime.parse(cachedData['timestamp']);
      }

      // Load cached user rank
      final cachedRankJson = _prefs.getString(userRankCacheKey);
      if (cachedRankJson != null) {
        final cachedData = jsonDecode(cachedRankJson);
        _cachedUserRank = cachedData['rank'] as int?;
      }

      // Emit cached data if available
      if (_cachedLeaderboard != null) {
        _leaderboardController.add(_cachedLeaderboard!);
      }
      if (_cachedUserRank != null) {
        _userRankController.add(_cachedUserRank);
      }
    } catch (e) {
      debugPrint('Error loading cached leaderboard data: $e');
    }
  }

  /// Update cache with new leaderboard data
  Future<void> _updateCache(LeaderboardPage leaderboardPage) async {
    try {
      _cachedLeaderboard = leaderboardPage;
      _lastCacheUpdate = DateTime.now();

      // Save to local storage
      final cacheData = {
        'data': leaderboardPage.toJson(),
        'timestamp': _lastCacheUpdate!.toIso8601String(),
      };
      await _prefs.setString('${cacheKeyPrefix}page_1', jsonEncode(cacheData));

      // Emit updated data
      _leaderboardController.add(leaderboardPage);
    } catch (e) {
      debugPrint('Error updating leaderboard cache: $e');
    }
  }

  /// Update user rank cache
  Future<void> _updateUserRankCache(int rank) async {
    try {
      _cachedUserRank = rank;

      // Save to local storage
      final cacheData = {
        'rank': rank,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _prefs.setString(userRankCacheKey, jsonEncode(cacheData));

      // Emit updated rank
      _userRankController.add(rank);
    } catch (e) {
      debugPrint('Error updating user rank cache: $e');
    }
  }

  /// Setup real-time subscriptions
  void _setupRealtimeSubscriptions() {
    try {
      // Subscribe to leaderboard changes with debouncing
      _realtimeSubscription = _dbService
          .subscribeToLeaderboard(
            limit: 20,
            currentUserId: _authService.currentUser?.id,
          )
          .distinct() // Avoid duplicate events
          .listen(
            (entries) {
              if (entries.isNotEmpty) {
                final updatedPage = LeaderboardPage(
                  entries: entries,
                  currentPage: 1,
                  totalPages: 1,
                  totalEntries: entries.length,
                  hasNextPage: false,
                  hasPreviousPage: false,
                  lastUpdated: DateTime.now(),
                );
                _updateCache(updatedPage);

                // Update current user's rank if they're in the leaderboard
                final currentUserId = _authService.currentUser?.id;
                if (currentUserId != null) {
                  final userEntry = entries.firstWhere(
                    (entry) => entry.id == currentUserId,
                    orElse: () => LeaderboardEntry(
                      id: '',
                      username: '',
                      totalPoints: 0,
                      level: 1,
                      rank: 0,
                      lastActiveAt: DateTime.now(),
                      isCurrentUser: false,
                    ),
                  );

                  if (userEntry.id.isNotEmpty) {
                    _updateUserRankCache(userEntry.rank);
                    _notifyAuthServiceOfRankChange(
                      currentUserId,
                      userEntry.rank,
                    );
                  }
                }
              }
            },
            onError: (error) {
              debugPrint('Real-time leaderboard subscription error: $error');
              // Retry subscription after a delay
              Timer(const Duration(seconds: 5), () {
                _setupRealtimeSubscriptions();
              });
            },
          );

      // Subscribe to user rank changes with retry logic
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null) {
        _userRankSubscription = _dbService
            .subscribeToUserRank(currentUserId)
            .distinct() // Avoid duplicate events
            .listen(
              (rank) {
                if (rank != null) {
                  _updateUserRankCache(rank);
                  _notifyAuthServiceOfRankChange(currentUserId, rank);
                }
              },
              onError: (error) {
                debugPrint('Real-time user rank subscription error: $error');
                // Retry subscription after a delay
                Timer(const Duration(seconds: 5), () {
                  _setupRealtimeSubscriptions();
                });
              },
            );
      }
    } catch (e) {
      debugPrint('Error setting up real-time subscriptions: $e');
    }
  }

  /// Start periodic refresh timer
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(refreshInterval, (timer) {
      if (!isCacheValid) {
        refreshLeaderboard();
      }
    });
  }

  /// Dispose resources and clean up
  void dispose() {
    debugPrint('Disposing LeaderboardService resources...');
    try {
      _refreshTimer?.cancel();
      _realtimeSubscription?.cancel();
      _userRankSubscription?.cancel();
      _leaderboardController.close();
      _syncStatusController.close();
      _userRankController.close();
      _achievementController.close();
      debugPrint('LeaderboardService disposed successfully');
    } catch (e) {
      debugPrint('Error disposing LeaderboardService: $e');
    }
  }
}

/// Provider for LeaderboardService
@riverpod
Future<LeaderboardService> leaderboardService(Ref ref) async {
  final dbService = ref.watch(leaderboardDatabaseServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final prefs = await ref.watch(sharedPreferencesProvider.future);

  final service = LeaderboardService(dbService, authService, prefs);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider for leaderboard page data
@riverpod
Future<List<LeaderboardEntry>> leaderboard(
  LeaderboardRef ref, {
  required LeaderboardPeriod period,
}) async {
  debugPrint(
    '🏆 [LEADERBOARD_PROVIDER] Loading leaderboard for period: $period',
  );
  final serviceAsync = ref.watch(leaderboardServiceProvider);
  return await serviceAsync.when(
    data: (service) async {
      debugPrint(
        '🏆 [LEADERBOARD_PROVIDER] Service loaded, getting leaderboard page',
      );
      final page = await service.getLeaderboardPage(page: 1);
      debugPrint(
        '🏆 [LEADERBOARD_PROVIDER] Got ${page.entries.length} entries',
      );
      return page.entries;
    },
    loading: () {
      debugPrint('🏆 [LEADERBOARD_PROVIDER] Service still loading');
      return <LeaderboardEntry>[];
    },
    error: (error, stack) {
      debugPrint('🏆 [LEADERBOARD_PROVIDER] Service error: $error');
      return <LeaderboardEntry>[];
    },
  );
}

/// Provider for achievement cards
@riverpod
List<AchievementCard> achievementCards(AchievementCardsRef ref) {
  return [];
}

/// Provider for leaderboard stream
@riverpod
Stream<LeaderboardPage> leaderboardStream(LeaderboardStreamRef ref) async* {
  final serviceAsync = ref.watch(leaderboardServiceProvider);
  await for (final service in serviceAsync.when(
    data: (service) => Stream.value(service),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  )) {
    yield* service.leaderboardStream;
  }
}

/// Provider for user rank stream
@riverpod
Stream<int?> userRankStream(UserRankStreamRef ref) async* {
  final serviceAsync = ref.watch(leaderboardServiceProvider);
  await for (final service in serviceAsync.when(
    data: (service) => Stream.value(service),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  )) {
    yield* service.userRankStream;
  }
}

/// Provider for sync status stream
@riverpod
Stream<SyncStatus> syncStatusStream(SyncStatusStreamRef ref) async* {
  final serviceAsync = ref.watch(leaderboardServiceProvider);
  await for (final service in serviceAsync.when(
    data: (service) => Stream.value(service),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  )) {
    yield* service.syncStatusStream;
  }
}

/// Provider for SharedPreferences
@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}

/// Provider for current user rank
@riverpod
Future<int?> currentUserRank(Ref ref) async {
  final serviceAsync = ref.watch(leaderboardServiceProvider);
  return await serviceAsync.when(
    data: (service) async {
      return await service.getUserRank();
    },
    loading: () => null,
    error: (_, __) => null,
  );
}
