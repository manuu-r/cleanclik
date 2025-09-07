import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/leaderboard_user.dart';
import '../models/achievement.dart';
import '../models/achievement_card.dart';
import '../models/user.dart';
import 'user_service.dart';

part 'leaderboard_service.g.dart';

enum LeaderboardPeriod { daily, weekly, monthly, allTime }

extension LeaderboardPeriodExtension on LeaderboardPeriod {
  String get displayName {
    switch (this) {
      case LeaderboardPeriod.daily:
        return 'Daily';
      case LeaderboardPeriod.weekly:
        return 'Weekly';
      case LeaderboardPeriod.monthly:
        return 'Monthly';
      case LeaderboardPeriod.allTime:
        return 'All Time';
    }
  }
}

/// Service for managing leaderboard, achievements, and social sharing
class LeaderboardService {
  static const String _logTag = 'LEADERBOARD_SERVICE';

  // Storage keys
  static const String _achievementsKey = 'user_achievements';
  static const String _badgesKey = 'user_badges';
  static const String _streakKey = 'user_streak';
  static const String _accuracyKey = 'user_accuracy';
  static const String _lastRankKey = 'user_last_rank';
  static const String _achievementCardsKey = 'achievement_cards';

  final UserService _userService;
  SharedPreferences? _prefs;

  // State
  List<Achievement> _unlockedAchievements = [];
  List<String> _unlockedBadges = [];
  int _currentStreak = 0;
  double _accuracyPercentage = 0.0;
  int? _lastKnownRank;
  List<AchievementCard> _generatedCards = [];

  // Stream controllers
  final StreamController<Achievement> _achievementUnlockedController =
      StreamController<Achievement>.broadcast();
  final StreamController<List<LeaderboardUser>> _leaderboardController =
      StreamController<List<LeaderboardUser>>.broadcast();

  LeaderboardService(this._userService) {
    _loadFromStorage();
  }

  /// Stream of newly unlocked achievements
  Stream<Achievement> get achievementUnlockedStream =>
      _achievementUnlockedController.stream;

  /// Stream of leaderboard updates
  Stream<List<LeaderboardUser>> get leaderboardStream =>
      _leaderboardController.stream;

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements =>
      List.unmodifiable(_unlockedAchievements);

  /// Get unlocked badge IDs
  List<String> get unlockedBadges => List.unmodifiable(_unlockedBadges);

  /// Get current streak
  int get currentStreak => _currentStreak;

  /// Get accuracy percentage
  double get accuracyPercentage => _accuracyPercentage;

  /// Get generated achievement cards
  List<AchievementCard> get generatedCards =>
      List.unmodifiable(_generatedCards);

  // ===== LEADERBOARD METHODS =====

  /// Get leaderboard for specific period
  Future<List<LeaderboardUser>> getLeaderboard({
    required LeaderboardPeriod period,
  }) async {
    print(
      '📊 [$_logTag] Getting leaderboard for period: ${period.displayName}',
    );

    try {
      final currentUser = _userService.currentUser;
      final currentUserId = currentUser?.id;

      // Generate dummy leaderboard with current user integrated
      final leaderboard = _generateDummyLeaderboard(
        period: period,
        currentUserId: currentUserId,
      );

      // If we have a current user, integrate their real data
      if (currentUser != null) {
        final userRank = _calculateUserRank(
          currentUser.totalPoints,
          leaderboard,
        );
        final userEntry = _createUserLeaderboardEntry(currentUser, userRank);

        // Replace or insert user entry
        final existingIndex = leaderboard.indexWhere((u) => u.isCurrentUser);
        if (existingIndex != -1) {
          leaderboard[existingIndex] = userEntry;
        } else {
          // Insert user at correct position and adjust ranks
          leaderboard.insert(userRank - 1, userEntry);
          _adjustRanksAfterInsertion(leaderboard, userRank);
        }

        // Check for rank changes
        await _checkRankChange(userRank);
      }

      // Sort by points to ensure correct order
      leaderboard.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

      // Update ranks after sorting
      for (int i = 0; i < leaderboard.length; i++) {
        leaderboard[i] = leaderboard[i].copyWith(rank: i + 1);
      }

      // Emit leaderboard update
      _leaderboardController.add(leaderboard);

      print(
        '✅ [$_logTag] Leaderboard generated with ${leaderboard.length} users',
      );
      return leaderboard;
    } catch (e) {
      print('❌ [$_logTag] Failed to get leaderboard: $e');
      return [];
    }
  }

  /// Calculate user's rank based on points
  int _calculateUserRank(int userPoints, List<LeaderboardUser> leaderboard) {
    int rank = 1;
    for (final user in leaderboard) {
      if (user.totalPoints > userPoints) {
        rank++;
      } else {
        break;
      }
    }
    return rank;
  }

  /// Create leaderboard entry for current user
  LeaderboardUser _createUserLeaderboardEntry(User user, int rank) {
    final rankChange = _lastKnownRank != null ? rank - _lastKnownRank! : null;

    return LeaderboardUser(
      id: user.id,
      username: user.username,
      displayName: user.username,
      profileImageUrl: user.avatarUrl ?? '',
      totalPoints: user.totalPoints,
      level: (user.totalPoints / 1000).floor() + 1,
      itemsCategorized: user.totalItemsCollected,
      itemsCollected: user.totalItemsCollected,
      co2Saved: (user.totalItemsCollected * 0.15), // Estimate
      currentStreak: _currentStreak,
      lastActivity: user.lastActiveAt,
      lastActiveAt: user.lastActiveAt,
      accuracyPercentage: _accuracyPercentage,
      rank: rank,
      highestBadge: _getHighestBadge() ?? '',
      isCurrentUser: true,
      rankChange: rankChange ?? 0,
    );
  }

  /// Adjust ranks after inserting user
  void _adjustRanksAfterInsertion(
    List<LeaderboardUser> leaderboard,
    int insertedRank,
  ) {
    for (int i = insertedRank; i < leaderboard.length; i++) {
      leaderboard[i] = leaderboard[i].copyWith(rank: i + 1);
    }
  }

  /// Check for rank changes and trigger achievements
  Future<void> _checkRankChange(int newRank) async {
    if (_lastKnownRank != null && newRank != _lastKnownRank) {
      print('📈 [$_logTag] Rank changed from $_lastKnownRank to $newRank');

      // Check for ranking achievements
      await _checkRankingAchievements(newRank);

      // Generate rank achievement card if significant improvement
      if (_lastKnownRank! > newRank && (_lastKnownRank! - newRank) >= 5) {
        await _generateRankAchievementCard(newRank);
      }
    }

    _lastKnownRank = newRank;
    await _saveToStorage();
  }

  // ===== ACHIEVEMENT METHODS =====

  /// Check and unlock achievements based on user progress
  Future<void> checkAchievements({
    int? points,
    int? itemsCollected,
    String? category,
    int? streak,
    double? accuracy,
    int? rank,
  }) async {
    print('🏆 [$_logTag] Checking achievements...');

    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final userPoints = points ?? currentUser.totalPoints;
    final userItems = itemsCollected ?? currentUser.totalItemsCollected;
    final userStreak = streak ?? _currentStreak;
    final userAccuracy = accuracy ?? _accuracyPercentage;

    // Check points-based achievements
    await _checkPointsAchievements(userPoints);

    // Check category-specific achievements
    if (category != null) {
      await _checkCategoryAchievements(
        category,
        currentUser.categoryStats[category] ?? 0,
      );
    }

    // Check streak achievements
    await _checkStreakAchievements(userStreak);

    // Check accuracy achievements
    await _checkAccuracyAchievements(userAccuracy);

    // Check ranking achievements
    if (rank != null) {
      await _checkRankingAchievements(rank);
    }

    // Check special achievements
    await _checkSpecialAchievements(userItems);

    await _saveToStorage();
  }

  /// Check points-based achievements
  Future<void> _checkPointsAchievements(int points) async {
    final pointsAchievements = Achievements.getByType(AchievementType.points);

    if (pointsAchievements != null) {
      final achievement = pointsAchievements;
      if (points >= achievement.pointsRequired &&
          !_isAchievementUnlocked(achievement.id)) {
        await _unlockAchievement(achievement);
        await _generatePointsMilestoneCard(points);
      }
    }
  }

  /// Check category-specific achievements
  Future<void> _checkCategoryAchievements(
    String category,
    int itemCount,
  ) async {
    final categoryAchievements = Achievements.getByType(
      AchievementType.category,
    );

    if (categoryAchievements != null) {
      final achievement = categoryAchievements;
      // Match achievement to category (simplified logic)
      final isRelevant = _isCategoryAchievementRelevant(
        achievement.id,
        category,
      );

      if (isRelevant &&
          itemCount >= achievement.pointsRequired &&
          !_isAchievementUnlocked(achievement.id)) {
        await _unlockAchievement(achievement);
        await _generateCategoryMasterCard(category, itemCount);
      }
    }
  }

  /// Check if category achievement is relevant to the category
  bool _isCategoryAchievementRelevant(String achievementId, String category) {
    final categoryMappings = {
      'bottle_collector': 'recycle',
      'compost_creator': 'organic',
      'tech_recycler': 'ewaste',
      'safety_first': 'hazardous',
    };

    return categoryMappings[achievementId] == category;
  }

  /// Check streak achievements
  Future<void> _checkStreakAchievements(int streak) async {
    final streakAchievements = Achievements.getByType(AchievementType.streak);

    if (streakAchievements != null) {
      final achievement = streakAchievements;
      if (streak >= achievement.pointsRequired &&
          !_isAchievementUnlocked(achievement.id)) {
        await _unlockAchievement(achievement);
        await _generateStreakAchievementCard(streak);
      }
    }
  }

  /// Check accuracy achievements
  Future<void> _checkAccuracyAchievements(double accuracy) async {
    final accuracyAchievements = Achievements.getByType(
      AchievementType.accuracy,
    );

    if (accuracyAchievements != null) {
      final achievement = accuracyAchievements;
      if (accuracy >= achievement.pointsRequired &&
          !_isAchievementUnlocked(achievement.id)) {
        await _unlockAchievement(achievement);
        await _generateAccuracyAchievementCard(accuracy);
      }
    }
  }

  /// Check ranking achievements
  Future<void> _checkRankingAchievements(int rank) async {
    final rankingAchievements = Achievements.getByType(AchievementType.ranking);

    if (rankingAchievements != null) {
      final achievement = rankingAchievements;
      if (rank <= achievement.pointsRequired &&
          !_isAchievementUnlocked(achievement.id)) {
        await _unlockAchievement(achievement);
        await _generateRankAchievementCard(rank);
      }
    }
  }

  /// Check special achievements
  Future<void> _checkSpecialAchievements(int totalItems) async {
    final specialAchievements = Achievements.getByType(AchievementType.special);

    if (specialAchievements != null) {
      final achievement = specialAchievements;
      if (achievement.id == 'first_disposal' &&
          totalItems >= 1 &&
          !_isAchievementUnlocked(achievement.id)) {
        await _unlockAchievement(achievement);
      }
    }
  }

  /// Unlock achievement and notify
  Future<void> _unlockAchievement(Achievement achievement) async {
    print('🎉 [$_logTag] Achievement unlocked: ${achievement.name}');

    final unlockedAchievement = achievement.copyWith(
      unlockedAt: DateTime.now(),
    );
    _unlockedAchievements.add(unlockedAchievement);
    _unlockedBadges.add(achievement.id);

    // Emit achievement unlocked event
    _achievementUnlockedController.add(unlockedAchievement);

    // Update user service with new achievement
    await _userService.addAchievement(achievement.id);
  }

  /// Check if achievement is already unlocked
  bool _isAchievementUnlocked(String achievementId) {
    return _unlockedAchievements.any((a) => a.id == achievementId);
  }

  /// Get highest badge for display
  String? _getHighestBadge() {
    if (_unlockedBadges.isEmpty) return null;

    // Return the most recent badge (simplified logic)
    return _unlockedBadges.last;
  }

  // ===== ACHIEVEMENT CARD GENERATION =====

  /// Generate points milestone card
  Future<void> _generatePointsMilestoneCard(int points) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final card = AchievementCard.pointsMilestone(
      points: points,
      username: currentUser.username,
      totalItems: currentUser.totalItemsCollected,
      accuracy: _accuracyPercentage,
    );

    _generatedCards.add(card);
    await _saveToStorage();

    print('📱 [$_logTag] Generated points milestone card: $points points');
  }

  /// Generate rank achievement card
  Future<void> _generateRankAchievementCard(int rank) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final card = AchievementCard.rankAchievement(
      rank: rank,
      username: currentUser.username,
      totalPoints: currentUser.totalPoints,
      totalItems: currentUser.totalItemsCollected,
    );

    _generatedCards.add(card);
    await _saveToStorage();

    print('📱 [$_logTag] Generated rank achievement card: #$rank');
  }

  /// Generate category master card
  Future<void> _generateCategoryMasterCard(
    String category,
    int itemCount,
  ) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final card = AchievementCard.categoryMaster(
      category: category,
      itemsCount: itemCount,
      username: currentUser.username,
      accuracy: _accuracyPercentage,
    );

    _generatedCards.add(card);
    await _saveToStorage();

    print(
      '📱 [$_logTag] Generated category master card: $category ($itemCount items)',
    );
  }

  /// Generate streak achievement card
  Future<void> _generateStreakAchievementCard(int streakDays) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final card = AchievementCard.streakAchievement(
      streakDays: streakDays,
      username: currentUser.username,
      totalPoints: currentUser.totalPoints,
      totalItems: currentUser.totalItemsCollected,
    );

    _generatedCards.add(card);
    await _saveToStorage();

    print('📱 [$_logTag] Generated streak achievement card: $streakDays days');
  }

  /// Generate accuracy achievement card
  Future<void> _generateAccuracyAchievementCard(double accuracy) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final card = AchievementCard.accuracyAchievement(
      accuracy: accuracy,
      username: currentUser.username,
      totalItems: currentUser.totalItemsCollected,
      totalPoints: currentUser.totalPoints,
    );

    _generatedCards.add(card);
    await _saveToStorage();

    print(
      '📱 [$_logTag] Generated accuracy achievement card: ${accuracy.toStringAsFixed(1)}%',
    );
  }

  // ===== STATS UPDATE METHODS =====

  /// Update user streak
  Future<void> updateStreak(int streak) async {
    if (streak != _currentStreak) {
      _currentStreak = streak;
      await _saveToStorage();

      // Check for streak achievements
      await _checkStreakAchievements(streak);
    }
  }

  /// Update accuracy percentage
  Future<void> updateAccuracy(double accuracy) async {
    if (accuracy != _accuracyPercentage) {
      _accuracyPercentage = accuracy;
      await _saveToStorage();

      // Check for accuracy achievements
      await _checkAccuracyAchievements(accuracy);
    }
  }

  /// Update stats after disposal
  Future<void> updateStatsAfterDisposal({
    required int pointsEarned,
    required int itemsDisposed,
    required String category,
    required bool wasAccurate,
  }) async {
    // Update accuracy
    final currentUser = _userService.currentUser;
    if (currentUser != null) {
      final totalDisposals = currentUser.totalItemsCollected;
      if (totalDisposals > 0) {
        // Simplified accuracy calculation
        final newAccuracy = wasAccurate
            ? ((_accuracyPercentage * (totalDisposals - 1)) + 100) /
                  totalDisposals
            : ((_accuracyPercentage * (totalDisposals - 1)) + 0) /
                  totalDisposals;
        await updateAccuracy(newAccuracy);
      }
    }

    // Update streak (simplified - assume daily activity)
    await updateStreak(_currentStreak + 1);

    // Check all achievements
    await checkAchievements(
      points: currentUser?.totalPoints,
      itemsCollected: currentUser?.totalItemsCollected,
      category: category,
      streak: _currentStreak,
      accuracy: _accuracyPercentage,
    );
  }

  // ===== STORAGE METHODS =====

  /// Load data from storage
  Future<void> _loadFromStorage() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Load achievements
      final achievementsJson = _prefs!.getString(_achievementsKey);
      if (achievementsJson != null) {
        final List<dynamic> achievementsData = jsonDecode(achievementsJson);
        _unlockedAchievements = achievementsData
            .map((data) => Achievement.fromJson(data))
            .toList();
      }

      // Load badges
      _unlockedBadges = _prefs!.getStringList(_badgesKey) ?? [];

      // Load stats
      _currentStreak = _prefs!.getInt(_streakKey) ?? 0;
      _accuracyPercentage = _prefs!.getDouble(_accuracyKey) ?? 0.0;
      _lastKnownRank = _prefs!.getInt(_lastRankKey);

      // Load achievement cards
      final cardsJson = _prefs!.getString(_achievementCardsKey);
      if (cardsJson != null) {
        final List<dynamic> cardsData = jsonDecode(cardsJson);
        _generatedCards = cardsData
            .map((data) => AchievementCard.fromJson(data))
            .toList();
      }

      print('✅ [$_logTag] Loaded data from storage');
    } catch (e) {
      print('❌ [$_logTag] Failed to load from storage: $e');
    }
  }

  /// Save data to storage
  Future<void> _saveToStorage() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Save achievements
      final achievementsData = _unlockedAchievements
          .map((a) => a.toJson())
          .toList();
      await _prefs!.setString(_achievementsKey, jsonEncode(achievementsData));

      // Save badges
      await _prefs!.setStringList(_badgesKey, _unlockedBadges);

      // Save stats
      await _prefs!.setInt(_streakKey, _currentStreak);
      await _prefs!.setDouble(_accuracyKey, _accuracyPercentage);
      if (_lastKnownRank != null) {
        await _prefs!.setInt(_lastRankKey, _lastKnownRank!);
      }

      // Save achievement cards
      final cardsData = _generatedCards.map((c) => c.toJson()).toList();
      await _prefs!.setString(_achievementCardsKey, jsonEncode(cardsData));

      print('💾 [$_logTag] Saved data to storage');
    } catch (e) {
      print('❌ [$_logTag] Failed to save to storage: $e');
    }
  }

  /// Clear all achievement cards
  Future<void> clearAchievementCards() async {
    _generatedCards.clear();
    await _saveToStorage();
    print('🗑️ [$_logTag] Cleared all achievement cards');
  }

  /// Get achievement progress for specific achievement
  double getAchievementProgress(String achievementId) {
    final achievement = Achievements.getById(achievementId);
    if (achievement == null) return 0.0;

    final currentUser = _userService.currentUser;
    if (currentUser == null) return 0.0;

    switch (achievement.type) {
      case AchievementType.points:
        return (currentUser.totalPoints / achievement.pointsRequired).clamp(
          0.0,
          1.0,
        );
      case AchievementType.streak:
        return (_currentStreak / achievement.pointsRequired).clamp(0.0, 1.0);
      case AchievementType.accuracy:
        return (_accuracyPercentage / achievement.pointsRequired).clamp(
          0.0,
          1.0,
        );
      case AchievementType.category:
        // Simplified - would need category-specific logic
        return 0.5;
      case AchievementType.ranking:
        final currentRank = _lastKnownRank ?? 999;
        return currentRank <= achievement.pointsRequired ? 1.0 : 0.0;
      case AchievementType.special:
      case AchievementType.firstScan:
        return _isAchievementUnlocked(achievementId) ? 1.0 : 0.0;
      default:
        return 0.0;
    }
  }

  /// Dispose resources
  void dispose() {
    _achievementUnlockedController.close();
    _leaderboardController.close();
    print('🗑️ [$_logTag] Leaderboard service disposed');
  }
}

/// Provider for LeaderboardService
@riverpod
LeaderboardService leaderboardService(LeaderboardServiceRef ref) {
  final userService = ref.watch(userServiceProvider);
  final service = LeaderboardService(userService);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider for leaderboard data
@riverpod
Future<List<LeaderboardUser>> leaderboard(
  LeaderboardRef ref, {
  required LeaderboardPeriod period,
}) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboard(period: period);
}

/// Provider for unlocked achievements
@riverpod
List<Achievement> unlockedAchievements(UnlockedAchievementsRef ref) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.unlockedAchievements;
}

/// Provider for achievement cards
@riverpod
List<AchievementCard> achievementCards(AchievementCardsRef ref) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.generatedCards;
}

/// Generate dummy leaderboard data
List<LeaderboardUser> _generateDummyLeaderboard({
  required LeaderboardPeriod period,
  String? currentUserId,
  int count = 50,
}) {
  final users = <LeaderboardUser>[];
  final random = Random();

  final names = [
    'EcoWarrior',
    'GreenThumb',
    'RecycleKing',
    'CleanQueen',
    'EarthSaver',
    'WasteWatcher',
    'PlanetProtector',
    'GreenGuru',
    'EcoChampion',
    'CleanMachine',
    'SustainableSam',
    'RecycleRex',
    'GreenGoddess',
    'EcoExpert',
    'CleanCrusader',
  ];

  for (int i = 0; i < count; i++) {
    final basePoints = 5000 - (i * 50) + random.nextInt(100);
    final user = LeaderboardUser(
      id: 'user_$i',
      username: '${names[i % names.length]}${i + 1}',
      displayName: '${names[i % names.length]} ${i + 1}',
      totalPoints: basePoints,
      level: (basePoints / 1000).floor() + 1,
      profileImageUrl: '',
      rank: i + 1,
      itemsCategorized: basePoints ~/ 10,
      itemsCollected: basePoints ~/ 10,
      co2Saved: (basePoints / 100).toDouble(),
      currentStreak: random.nextInt(30) + 1,
      lastActivity: DateTime.now().subtract(
        Duration(hours: random.nextInt(24)),
      ),
      lastActiveAt: DateTime.now().subtract(
        Duration(hours: random.nextInt(24)),
      ),
      accuracyPercentage: 85.0 + random.nextDouble() * 15.0,
      highestBadge: 'Eco Warrior',
      isCurrentUser: false,
      rankChange: 0,
    );
    users.add(user);
  }

  return users;
}
