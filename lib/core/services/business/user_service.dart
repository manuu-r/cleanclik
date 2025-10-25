import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cleanclik/core/services/business/database_helper.dart';
import 'package:cleanclik/core/services/data/local_storage_service.dart';

part 'user_service.g.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final int totalPoints;
  final int level;
  final int? rank;
  final String? avatarUrl;
  final DateTime lastActiveAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.totalPoints,
    required this.level,
    this.rank,
    this.avatarUrl,
    required this.lastActiveAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      rank: json['rank'] as int?,
      avatarUrl: json['avatarUrl'] as String?,
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
    );
  }

  factory UserProfile.fromDatabaseRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['auth_id'] as String,
      name: row['username'] as String,
      email: row['email'] as String? ?? '',
      totalPoints: row['total_points'] as int? ?? 0,
      level: row['level'] as int? ?? 1,
      rank: null,
      avatarUrl: row['avatar_url'] as String?,
      lastActiveAt: row['last_active_at'] != null
          ? DateTime.parse(row['last_active_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'totalPoints': totalPoints,
      'level': level,
      'rank': rank,
      'avatarUrl': avatarUrl,
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    int? totalPoints,
    int? level,
    int? rank,
    String? avatarUrl,
    DateTime? lastActiveAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      rank: rank ?? this.rank,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  static int calculateLevel(int points) {
    if (points < 100) return 1;
    if (points < 500) return 2;
    if (points < 1000) return 3;
    if (points < 2500) return 4;
    if (points < 5000) return 5;
    return 6;
  }

  int get pointsToNextLevel {
    if (level >= 6) return 0;
    final nextLevelThreshold = _getLevelThreshold(level + 1);
    return nextLevelThreshold - totalPoints;
  }

  double get levelProgress {
    if (level >= 6) return 1.0;
    final currentLevelThreshold = _getLevelThreshold(level);
    final nextLevelThreshold = _getLevelThreshold(level + 1);
    final pointsInCurrentLevel = totalPoints - currentLevelThreshold;
    final pointsNeededForLevel = nextLevelThreshold - currentLevelThreshold;
    return pointsInCurrentLevel / pointsNeededForLevel;
  }

  int _getLevelThreshold(int level) {
    switch (level) {
      case 1:
        return 0;
      case 2:
        return 100;
      case 3:
        return 500;
      case 4:
        return 1000;
      case 5:
        return 2500;
      case 6:
        return 5000;
      default:
        return 10000;
    }
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, level: $level, points: $totalPoints)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final int pointsRequired;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
  });

  static const List<Achievement> basicAchievements = [
    Achievement(
      id: 'first_disposal',
      name: 'First Steps',
      description: 'Complete your first disposal',
      pointsRequired: 1,
    ),
    Achievement(
      id: 'eco_warrior',
      name: 'Eco Warrior',
      description: 'Earn 100 points',
      pointsRequired: 100,
    ),
    Achievement(
      id: 'green_champion',
      name: 'Green Champion',
      description: 'Earn 500 points',
      pointsRequired: 500,
    ),
    Achievement(
      id: 'earth_guardian',
      name: 'Earth Guardian',
      description: 'Earn 1000 points',
      pointsRequired: 1000,
    ),
  ];
}

class DisposalResult {
  final bool success;
  final int pointsEarned;
  final List<String> disposedItemIds;
  final DateTime disposalTime;
  final String? errorMessage;

  const DisposalResult({
    required this.success,
    required this.pointsEarned,
    required this.disposedItemIds,
    required this.disposalTime,
    this.errorMessage,
  });

  factory DisposalResult.success({
    required int pointsEarned,
    required List<String> disposedItemIds,
  }) {
    return DisposalResult(
      success: true,
      pointsEarned: pointsEarned,
      disposedItemIds: disposedItemIds,
      disposalTime: DateTime.now(),
    );
  }

  factory DisposalResult.failure(String errorMessage) {
    return DisposalResult(
      success: false,
      pointsEarned: 0,
      disposedItemIds: [],
      disposalTime: DateTime.now(),
      errorMessage: errorMessage,
    );
  }
}

class DashboardStats {
  final int totalPoints;
  final int? rank;
  final int totalItemsDisposed;
  final List<RecentActivity> recentActivity;
  final Map<String, int> categoryBreakdown;
  final DateTime lastUpdated;
  final bool isStale;

  const DashboardStats({
    required this.totalPoints,
    this.rank,
    required this.totalItemsDisposed,
    required this.recentActivity,
    required this.categoryBreakdown,
    required this.lastUpdated,
    this.isStale = false,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalPoints: 0,
      rank: null,
      totalItemsDisposed: 0,
      recentActivity: [],
      categoryBreakdown: {},
      lastUpdated: DateTime.now(),
      isStale: false,
    );
  }

  DashboardStats copyWithStale() {
    return DashboardStats(
      totalPoints: totalPoints,
      rank: rank,
      totalItemsDisposed: totalItemsDisposed,
      recentActivity: recentActivity,
      categoryBreakdown: categoryBreakdown,
      lastUpdated: lastUpdated,
      isStale: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'rank': rank,
      'totalItemsDisposed': totalItemsDisposed,
      'recentActivity': recentActivity.map((a) => a.toJson()).toList(),
      'categoryBreakdown': categoryBreakdown,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isStale': isStale,
    };
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalPoints: json['totalPoints'] as int? ?? 0,
      rank: json['rank'] as int?,
      totalItemsDisposed: json['totalItemsDisposed'] as int? ?? 0,
      recentActivity: (json['recentActivity'] as List<dynamic>? ?? [])
          .map((a) => RecentActivity.fromJson(a as Map<String, dynamic>))
          .toList(),
      categoryBreakdown: Map<String, int>.from(
        json['categoryBreakdown'] as Map<String, dynamic>? ?? {},
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isStale: json['isStale'] as bool? ?? false,
    );
  }
}

class RecentActivity {
  final String id;
  final String displayName;
  final String category;
  final DateTime timestamp;
  final int pointsEarned;

  const RecentActivity({
    required this.id,
    required this.displayName,
    required this.category,
    required this.timestamp,
    required this.pointsEarned,
  });

  factory RecentActivity.fromInventoryRow(Map<String, dynamic> row) {
    return RecentActivity(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      category: row['category'] as String,
      timestamp: DateTime.parse(row['picked_up_at'] as String),
      pointsEarned: _calculatePointsForCategory(row['category'] as String),
    );
  }

  static int _calculatePointsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'hazardous':
        return 20;
      case 'ewaste':
        return 15;
      case 'recycle':
        return 10;
      case 'organic':
        return 8;
      case 'landfill':
        return 5;
      default:
        return 5;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'pointsEarned': pointsEarned,
    };
  }

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      category: json['category'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      pointsEarned: json['pointsEarned'] as int,
    );
  }
}

@Riverpod(keepAlive: true)
class UserService extends _$UserService {
  static const String _logTag = 'USER_SERVICE';

  UserProfile? _currentProfile;
  List<String> _earnedAchievements = [];
  bool _isInitialized = false;

  final StreamController<UserProfile> _profileController =
      StreamController<UserProfile>.broadcast();

  final LocalStorageService _storageService = LocalStorageService.instance;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  UserService build() {
    ref.onDispose(() async {
      await dispose();
    });

    _initialize()
        .then((_) {
          debugPrint('✅ [$_logTag] Async initialization completed');
        })
        .catchError((e) {
          debugPrint('❌ [$_logTag] Async initialization failed: $e');
        });
    return this;
  }

  Future<void> _initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ [$_logTag] Already initialized, skipping');
      return;
    }

    try {
      await _loadFromLocalStorage();

      await _syncWithDatabase();

      _isInitialized = true;
      debugPrint('✅ [$_logTag] Service initialized successfully');
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to initialize: $e');

      // If sync failed due to missing user profile, we need to handle it
      if (e.toString().contains('Failed to create user profile')) {
        debugPrint('❌ [$_logTag] Critical error: User profile creation failed');
        // Mark as initialized to prevent retry loops
        _isInitialized = true;
        // Re-throw to allow upper layers to handle (e.g., logout)
        rethrow;
      }

      _isInitialized = true;
    }
  }

  Future<void> _syncWithDatabase() async {
    if (!_databaseHelper.isAuthenticated) {
      debugPrint(
        '⚠️ [$_logTag] User not authenticated, skipping database sync',
      );
      return;
    }

    try {
      await _databaseHelper.syncPendingOperations();

      final userId = _databaseHelper.currentUserId!;

      final userRecord = await getUserProfile(userId);

      if (userRecord != null) {
        if (_currentProfile != null) {
          final resolvedProfile = await _databaseHelper.resolveConflict(
            'users',
            userRecord.id,
            _currentProfile!.toJson(),
            {
              'id': userRecord.id,
              'auth_id': userRecord.id,
              'username': userRecord.name,
              'email': userRecord.email,
              'total_points': userRecord.totalPoints,
              'level': userRecord.level,
              'avatar_url': userRecord.avatarUrl,
              'last_active_at': userRecord.lastActiveAt.toIso8601String(),
            },
          );

          if (resolvedProfile != null) {
            _currentProfile = UserProfile.fromDatabaseRow(resolvedProfile);
            await _saveToLocalStorage();
            _profileController.add(_currentProfile!);
            debugPrint('✅ [$_logTag] Synced profile with conflict resolution');
          }
        } else {
          _currentProfile = userRecord;
          await _saveToLocalStorage();
          _profileController.add(_currentProfile!);
          debugPrint('✅ [$_logTag] Synced profile from database');
        }
      } else {
        // User not found in database - create profile automatically
        debugPrint(
          '⚠️ [$_logTag] User not found in database, creating profile...',
        );

        // Get actual user data from DatabaseHelper
        final username = _databaseHelper.currentUserUsername;
        final email = _databaseHelper.currentUserEmail ?? '';

        debugPrint('✅ [$_logTag] Got user data from auth: $username ($email)');

        // Create the profile in database
        final createdProfile = await createProfile(userId, username, email);

        if (createdProfile == null) {
          debugPrint(
            '❌ [$_logTag] Failed to create user profile - user will be logged out',
          );
          // Profile creation failed - this is a critical error
          // The app should handle this by logging out the user
          throw Exception('Failed to create user profile in database');
        }

        debugPrint('✅ [$_logTag] User profile created successfully');
      }
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to sync with database: $e');
      // Re-throw to allow caller to handle the error
      rethrow;
    }
  }

  Future<void> syncWhenOnline() async {
    try {
      await _syncWithDatabase();
      debugPrint('✅ [$_logTag] Manual sync completed');
    } catch (e) {
      debugPrint('❌ [$_logTag] Manual sync failed: $e');
    }
  }

  UserProfile? get currentProfile => _currentProfile;

  Stream<UserProfile> get profileStream => _profileController.stream;

  Future<void> addPoints(int points) async {
    try {
      if (_currentProfile == null) {
        debugPrint('⚠️ [$_logTag] No current profile, cannot add points');
        return;
      }

      final newTotalPoints = _currentProfile!.totalPoints + points;
      final newLevel = UserProfile.calculateLevel(newTotalPoints);

      _currentProfile = _currentProfile!.copyWith(
        totalPoints: newTotalPoints,
        level: newLevel,
        lastActiveAt: DateTime.now(),
      );

      await _saveToLocalStorage();
      _profileController.add(_currentProfile!);

      if (_databaseHelper.isAuthenticated) {
        await updateProfile(_currentProfile!);
      }

      debugPrint(
        '✅ [$_logTag] Added $points points, total: $newTotalPoints, level: $newLevel',
      );
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to add points: $e');
    }
  }

  Future<bool> updateProfile(UserProfile profile) async {
    try {
      debugPrint('✅ [$_logTag] Updating profile for user: ${profile.id}');

      final users = await _databaseHelper.read(
        'users',
        filters: {'auth_id': profile.id},
      );

      if (users.isEmpty) {
        debugPrint('❌ [$_logTag] User not found in database for update');
        return false;
      }

      final dbId = users.first['id'] as String;

      final updateData = {
        'username': profile.name,
        'email': profile.email,
        'total_points': profile.totalPoints,
        'level': profile.level,
        'avatar_url': profile.avatarUrl,
        'last_active_at': DateTime.now().toIso8601String(),
      };

      final result = await _databaseHelper.update('users', dbId, updateData);

      if (result == null) {
        debugPrint('❌ [$_logTag] Failed to update profile in database');
        return false;
      }

      if (_databaseHelper.isAuthenticated &&
          _databaseHelper.currentUserId == profile.id) {
        _currentProfile = profile.copyWith(lastActiveAt: DateTime.now());
        await _saveToLocalStorage();
        _profileController.add(_currentProfile!);
      }

      debugPrint('✅ [$_logTag] Profile updated: ${profile.name}');
      return true;
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to update profile: $e');
      return false;
    }
  }

  Future<List<Achievement>> checkAchievements(DisposalResult disposal) async {
    if (_currentProfile == null) return [];

    final newAchievements = <Achievement>[];

    try {
      for (final achievement in Achievement.basicAchievements) {
        if (_earnedAchievements.contains(achievement.id)) continue;

        bool earned = false;
        switch (achievement.id) {
          case 'first_disposal':
            earned = disposal.success && disposal.pointsEarned > 0;
            break;
          default:
            earned = _currentProfile!.totalPoints >= achievement.pointsRequired;
            break;
        }

        if (earned) {
          _earnedAchievements.add(achievement.id);
          newAchievements.add(achievement);
          debugPrint('✅ [$_logTag] Achievement earned: ${achievement.name}');
        }
      }

      if (newAchievements.isNotEmpty) {
        await _saveAchievementsToLocalStorage();
      }
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to check achievements: $e');
    }

    return newAchievements;
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      debugPrint('✅ [$_logTag] Getting profile for user: $userId');

      final users = await _databaseHelper.read(
        'users',
        filters: {'auth_id': userId},
      );

      if (users.isEmpty) {
        debugPrint('⚠️ [$_logTag] User not found in database');
        return null;
      }

      final userData = users.first;
      debugPrint(
        '✅ [$_logTag] Found user data: ${userData['username']} with ${userData['total_points']} points',
      );

      final profile = UserProfile.fromDatabaseRow(userData);

      final rank = await _calculateUserRank(userId);
      final profileWithRank = profile.copyWith(rank: rank);

      if (_databaseHelper.isAuthenticated &&
          _databaseHelper.currentUserId == userId) {
        _currentProfile = profileWithRank;
        await _saveToLocalStorage();
        _profileController.add(_currentProfile!);
      }

      debugPrint(
        '✅ [$_logTag] User profile loaded: ${profileWithRank.name}, ${profileWithRank.totalPoints} points, rank ${profileWithRank.rank}',
      );
      return profileWithRank;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting user profile: $e');
      return null;
    }
  }

  Future<UserProfile> getCurrentUserProfile() async {
    try {
      if (!_databaseHelper.isAuthenticated) {
        debugPrint('❌ [$_logTag] No authenticated user');
        throw Exception('No authenticated user');
      }

      final currentUserId = _databaseHelper.currentUserId;
      if (currentUserId == null) {
        debugPrint('❌ [$_logTag] No current user ID available');
        throw Exception('No current user ID available');
      }

      final profile = await getUserProfile(currentUserId);

      if (profile == null) {
        debugPrint('❌ [$_logTag] User not found in database, creating profile');
        await _createUserProfileInDatabase(currentUserId);
        final retryProfile = await getUserProfile(currentUserId);
        if (retryProfile == null) {
          throw Exception('Failed to create user profile');
        }
        return retryProfile;
      }

      return profile;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting current user profile: $e');

      if (_currentProfile != null) {
        debugPrint('⚠️ [$_logTag] Returning cached profile as fallback');
        return _currentProfile!;
      }

      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<int?> _calculateUserRank(String userId) async {
    try {
      final users = await _databaseHelper.readAdvanced(
        'users',
        orderBy: 'total_points DESC',
      );

      final userIndex = users.indexWhere((u) => u['auth_id'] == userId);
      final rank = userIndex >= 0 ? userIndex + 1 : null;

      debugPrint(
        '✅ [$_logTag] Calculated user rank: $rank (out of ${users.length} users)',
      );
      return rank;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error calculating user rank: $e');
      return null;
    }
  }

  Future<void> _createUserProfileInDatabase(String currentUserId) async {
    try {
      String username = 'User';
      String email = '';

      try {
        username = currentUserId.split('@').first;
        email = currentUserId.contains('@') ? currentUserId : '';
      } catch (e) {
        debugPrint(
          '⚠️ [$_logTag] Could not get user details from auth service: $e',
        );
      }

      await createProfile(currentUserId, username, email);

      debugPrint(
        '✅ [$_logTag] User profile created in database for $currentUserId',
      );
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to create user profile in database: $e');
      throw Exception('Failed to create user profile in database: $e');
    }
  }

  Future<UserProfile?> createProfile(
    String userId,
    String name,
    String email,
  ) async {
    try {
      debugPrint('✅ [$_logTag] Creating profile for user: $userId');

      final result = await _databaseHelper.create('users', {
        'auth_id': userId,
        'username': name,
        'email': email.isNotEmpty ? email : name,
        'total_points': 0,
        'level': 1,
        'created_at': DateTime.now().toIso8601String(),
        'last_active_at': DateTime.now().toIso8601String(),
      });

      if (result == null) {
        debugPrint('❌ [$_logTag] Failed to create profile in database');
        return null;
      }

      final profile = UserProfile.fromDatabaseRow(result);

      if (_databaseHelper.isAuthenticated &&
          _databaseHelper.currentUserId == userId) {
        _currentProfile = profile;
        await _saveToLocalStorage();
        _profileController.add(_currentProfile!);
      }

      debugPrint('✅ [$_logTag] Profile created: $name');
      return profile;
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to create profile: $e');
      return null;
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final profileData = await _storageService.getUserProfile();
      if (profileData != null) {
        _currentProfile = UserProfile.fromJson(profileData);
        debugPrint(
          '✅ [$_logTag] Loaded profile from centralized storage: ${_currentProfile!.name}',
        );
      }

      final achievementsData = await _storageService.getJsonList(
        StorageKeys.userAchievements,
      );
      if (achievementsData.isNotEmpty) {
        _earnedAchievements = achievementsData
            .map((json) => json['id'] as String)
            .toList();
        debugPrint(
          '✅ [$_logTag] Loaded ${_earnedAchievements.length} achievements from centralized storage',
        );
      }
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to load from centralized storage: $e');
      _currentProfile = null;
      _earnedAchievements = [];
    }
  }

  Future<void> _saveToLocalStorage() async {
    try {
      if (_currentProfile != null) {
        final success = await _storageService.setUserProfile(
          _currentProfile!.toJson(),
        );
        if (success) {
          debugPrint('✅ [$_logTag] Saved profile to centralized storage');
        } else {
          debugPrint(
            '❌ [$_logTag] Failed to save profile to centralized storage',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '❌ [$_logTag] Failed to save profile to centralized storage: $e',
      );
    }
  }

  Future<void> _saveAchievementsToLocalStorage() async {
    try {
      final achievementsData = _earnedAchievements
          .map((id) => {'id': id, 'earnedAt': DateTime.now().toIso8601String()})
          .toList();
      final success = await _storageService.setJsonList(
        StorageKeys.userAchievements,
        achievementsData,
      );
      if (success) {
        debugPrint('✅ [$_logTag] Saved achievements to centralized storage');
      } else {
        debugPrint(
          '❌ [$_logTag] Failed to save achievements to centralized storage',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [$_logTag] Failed to save achievements to centralized storage: $e',
      );
    }
  }

  Future<DashboardStats> getDashboardStats() async {
    try {
      if (!_databaseHelper.isAuthenticated) {
        debugPrint('❌ [$_logTag] User not authenticated for dashboard stats');
        return await _getCachedDashboardStats() ?? DashboardStats.empty();
      }

      final currentUserId = _databaseHelper.currentUserId;
      if (currentUserId == null) {
        debugPrint('❌ [$_logTag] No current user ID for dashboard stats');
        return await _getCachedDashboardStats() ?? DashboardStats.empty();
      }

      final userProfile = await getCurrentUserProfile();
      debugPrint('✅ [$_logTag] Got user profile: ${userProfile.name}');

      final dashboardDataFuture =
          Future.wait([
            _getTotalItemsDisposed(currentUserId),
            _getRecentActivity(currentUserId),
            _getCategoryBreakdown(currentUserId),
          ]).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint(
                '⚠️ [$_logTag] Dashboard data loading timed out, using fallback values',
              );
              return [0, <RecentActivity>[], <String, int>{}];
            },
          );

      final dashboardData = await dashboardDataFuture;
      final totalItemsDisposed = dashboardData[0] as int;
      final recentActivity = dashboardData[1] as List<RecentActivity>;
      final categoryBreakdown = dashboardData[2] as Map<String, int>;

      final dashboardStats = DashboardStats(
        totalPoints: userProfile.totalPoints,
        rank: userProfile.rank,
        totalItemsDisposed: totalItemsDisposed,
        recentActivity: recentActivity,
        categoryBreakdown: categoryBreakdown,
        lastUpdated: DateTime.now(),
        isStale: false,
      );

      await _cacheDashboardStats(dashboardStats);

      debugPrint(
        '✅ [$_logTag] Dashboard stats loaded: ${dashboardStats.totalPoints} points, ${dashboardStats.totalItemsDisposed} items, rank ${dashboardStats.rank}',
      );
      return dashboardStats;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error loading dashboard stats: $e');

      final cachedStats = await _getCachedDashboardStats();
      if (cachedStats != null) {
        debugPrint(
          '⚠️ [$_logTag] Returning cached dashboard stats due to error',
        );
        return cachedStats.copyWithStale();
      }

      debugPrint('⚠️ [$_logTag] Returning empty dashboard stats as fallback');
      return DashboardStats.empty();
    }
  }

  Future<int> _getTotalItemsDisposed(String authId) async {
    try {
      final users = await _databaseHelper.readAdvanced(
        'users',
        filters: {'auth_id': authId},
      );

      if (users.isEmpty) {
        debugPrint('❌ [$_logTag] User not found for inventory query');
        return 0;
      }

      final userId = users.first['id'] as String;

      final inventoryItems = await _databaseHelper.readAdvanced(
        'inventory',
        filters: {'user_id': userId},
      );

      debugPrint(
        '✅ [$_logTag] Found ${inventoryItems.length} total items disposed',
      );
      return inventoryItems.length;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting total items disposed: $e');
      return 0;
    }
  }

  Future<List<RecentActivity>> _getRecentActivity(
    String authId, {
    int limit = 10,
  }) async {
    try {
      final users = await _databaseHelper.readAdvanced(
        'users',
        filters: {'auth_id': authId},
      );

      if (users.isEmpty) {
        debugPrint('❌ [$_logTag] User not found for recent activity query');
        return [];
      }

      final userId = users.first['id'] as String;

      final recentItems = await _databaseHelper.readAdvanced(
        'inventory',
        filters: {'user_id': userId},
        orderBy: 'picked_up_at DESC',
        limit: limit,
      );

      final recentActivity = recentItems
          .map((item) => RecentActivity.fromInventoryRow(item))
          .toList();

      debugPrint(
        '✅ [$_logTag] Found ${recentActivity.length} recent activities',
      );
      return recentActivity;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting recent activity: $e');
      return [];
    }
  }

  Future<Map<String, int>> _getCategoryBreakdown(String authId) async {
    try {
      final users = await _databaseHelper.readAdvanced(
        'users',
        filters: {'auth_id': authId},
      );

      if (users.isEmpty) {
        debugPrint('❌ [$_logTag] User not found for category breakdown query');
        return {};
      }

      final userId = users.first['id'] as String;

      final inventoryItems = await _databaseHelper.readAdvanced(
        'inventory',
        filters: {'user_id': userId},
      );

      final categoryBreakdown = <String, int>{};
      for (final item in inventoryItems) {
        final category = item['category'] as String;
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }

      debugPrint('✅ [$_logTag] Category breakdown: $categoryBreakdown');
      return categoryBreakdown;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting category breakdown: $e');
      return {};
    }
  }

  Future<void> _cacheDashboardStats(DashboardStats stats) async {
    try {
      final success = await _storageService.setJsonData(
        StorageKeys.dashboardStatsCache,
        stats.toJson(),
      );
      if (success) {
        debugPrint(
          '✅ [$_logTag] Dashboard stats cached in centralized storage',
        );
      } else {
        debugPrint(
          '❌ [$_logTag] Failed to cache dashboard stats in centralized storage',
        );
      }
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to cache dashboard stats: $e');
    }
  }

  Future<DashboardStats?> _getCachedDashboardStats() async {
    try {
      final statsData = await _storageService.getJsonData(
        StorageKeys.dashboardStatsCache,
      );
      if (statsData != null) {
        final cachedStats = DashboardStats.fromJson(statsData);
        debugPrint(
          '✅ [$_logTag] Retrieved cached dashboard stats from centralized storage: ${cachedStats.lastUpdated}',
        );
        return cachedStats;
      }
    } catch (e) {
      debugPrint(
        '❌ [$_logTag] Failed to get cached dashboard stats from centralized storage: $e',
      );
    }
    return null;
  }

  Future<DashboardStats> refreshDashboardStats() async {
    try {
      await _storageService.remove(StorageKeys.dashboardStatsCache);

      return await getDashboardStats();
    } catch (e) {
      debugPrint('❌ [$_logTag] Error refreshing dashboard stats: $e');
      return DashboardStats.empty();
    }
  }

  Future<void> dispose() async {
    try {
      await _saveToLocalStorage();
      await _saveAchievementsToLocalStorage();
      await _profileController.close();
      debugPrint('✅ [$_logTag] Service disposed');
    } catch (e) {
      debugPrint('❌ [$_logTag] Error during disposal: $e');
    }
  }
}
