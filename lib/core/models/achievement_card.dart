import 'package:flutter/material.dart';
import 'package:cleanclik/core/models/achievement.dart';

class AchievementCard {
  final String id;
  final Achievement achievement;
  final String cardImageUrl;
  final String shareText;
  final DateTime createdAt;
  final bool isShared;
  final Map<String, dynamic> customData;

  const AchievementCard({
    required this.id,
    required this.achievement,
    required this.cardImageUrl,
    required this.shareText,
    required this.createdAt,
    this.isShared = false,
    this.customData = const {},
  });

  factory AchievementCard.fromJson(Map<String, dynamic> json) {
    return AchievementCard(
      id: json['id'] as String,
      achievement: Achievement.fromJson(
        json['achievement'] as Map<String, dynamic>,
      ),
      cardImageUrl: json['cardImageUrl'] as String,
      shareText: json['shareText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isShared: json['isShared'] as bool? ?? false,
      customData: json['customData'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'achievement': achievement.toJson(),
      'cardImageUrl': cardImageUrl,
      'shareText': shareText,
      'createdAt': createdAt.toIso8601String(),
      'isShared': isShared,
      'customData': customData,
    };
  }

  AchievementCard copyWith({
    String? id,
    Achievement? achievement,
    String? cardImageUrl,
    String? shareText,
    DateTime? createdAt,
    bool? isShared,
    Map<String, dynamic>? customData,
  }) {
    return AchievementCard(
      id: id ?? this.id,
      achievement: achievement ?? this.achievement,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      shareText: shareText ?? this.shareText,
      createdAt: createdAt ?? this.createdAt,
      isShared: isShared ?? this.isShared,
      customData: customData ?? this.customData,
    );
  }

  // Factory methods for different card types
  factory AchievementCard.pointsMilestone({
    required int points,
    required String username,
    required int totalItems,
    required double accuracy,
  }) {
    final achievement = Achievement(
      id: 'points_${points}',
      title: 'Points Milestone',
      description: 'Reached $points points!',
      type: AchievementType.points,
      rarity: AchievementRarity.common,
      iconUrl: '',
      unlockedAt: DateTime.now(),
    );

    return AchievementCard(
      id: 'card_points_${points}_${DateTime.now().millisecondsSinceEpoch}',
      achievement: achievement,
      cardImageUrl: '',
      shareText:
          '🎉 Just reached $points points on CleanClik! Join me in making our city cleaner! #CleanClik #CleanCity',
      createdAt: DateTime.now(),
      customData: {
        'points': points,
        'username': username,
        'totalItems': totalItems,
        'accuracy': accuracy,
      },
    );
  }

  factory AchievementCard.rankAchievement({
    required int rank,
    required String username,
    required int totalPoints,
    required int totalItems,
  }) {
    final achievement = Achievement(
      id: 'rank_$rank',
      title: 'Leaderboard Achievement',
      description: 'Reached rank #$rank!',
      type: AchievementType.ranking,
      rarity: rank <= 3 ? AchievementRarity.legendary : AchievementRarity.rare,
      iconUrl: '',
      unlockedAt: DateTime.now(),
    );

    return AchievementCard(
      id: 'card_rank_${rank}_${DateTime.now().millisecondsSinceEpoch}',
      achievement: achievement,
      cardImageUrl: '',
      shareText:
          '🏆 Reached rank #$rank on the VibeSweep leaderboard! #VibeSweep #CleanCity',
      createdAt: DateTime.now(),
      customData: {
        'rank': rank,
        'username': username,
        'totalPoints': totalPoints,
        'totalItems': totalItems,
      },
    );
  }

  factory AchievementCard.categoryMaster({
    required String category,
    required int itemsCount,
    required String username,
    required double accuracy,
  }) {
    final achievement = Achievement(
      id: 'category_$category',
      title: 'Category Master',
      description: 'Mastered $category sorting!',
      type: AchievementType.category,
      rarity: AchievementRarity.rare,
      iconUrl: '',
      unlockedAt: DateTime.now(),
    );

    return AchievementCard(
      id: 'card_category_${category}_${DateTime.now().millisecondsSinceEpoch}',
      achievement: achievement,
      cardImageUrl: '',
      shareText:
          '♻️ Became a $category sorting master with $itemsCount items! #VibeSweep #CleanCity',
      createdAt: DateTime.now(),
      customData: {
        'category': category,
        'itemsCount': itemsCount,
        'username': username,
        'accuracy': accuracy,
      },
    );
  }

  factory AchievementCard.streakAchievement({
    required int streakDays,
    required String username,
    required int totalPoints,
    required int totalItems,
  }) {
    final achievement = Achievement(
      id: 'streak_$streakDays',
      title: 'Streak Achievement',
      description: '$streakDays day streak!',
      type: AchievementType.streak,
      rarity: streakDays >= 30
          ? AchievementRarity.legendary
          : AchievementRarity.rare,
      iconUrl: '',
      unlockedAt: DateTime.now(),
    );

    return AchievementCard(
      id: 'card_streak_${streakDays}_${DateTime.now().millisecondsSinceEpoch}',
      achievement: achievement,
      cardImageUrl: '',
      shareText:
          '🔥 $streakDays day streak on VibeSweep! Consistency is key! #VibeSweep #CleanCity',
      createdAt: DateTime.now(),
      customData: {
        'streakDays': streakDays,
        'username': username,
        'totalPoints': totalPoints,
        'totalItems': totalItems,
      },
    );
  }

  factory AchievementCard.accuracyAchievement({
    required double accuracy,
    required String username,
    required int totalItems,
    required int totalPoints,
  }) {
    final achievement = Achievement(
      id: 'accuracy_${accuracy.toInt()}',
      title: 'Accuracy Achievement',
      description: '${accuracy.toStringAsFixed(1)}% accuracy!',
      type: AchievementType.accuracy,
      rarity: accuracy >= 95
          ? AchievementRarity.legendary
          : AchievementRarity.rare,
      iconUrl: '',
      unlockedAt: DateTime.now(),
    );

    return AchievementCard(
      id: 'card_accuracy_${accuracy.toInt()}_${DateTime.now().millisecondsSinceEpoch}',
      achievement: achievement,
      cardImageUrl: '',
      shareText:
          '🎯 Achieved ${accuracy.toStringAsFixed(1)}% sorting accuracy on VibeSweep! #VibeSweep #CleanCity',
      createdAt: DateTime.now(),
      customData: {
        'accuracy': accuracy,
        'username': username,
        'totalItems': totalItems,
        'totalPoints': totalPoints,
      },
    );
  }

  // Getters for card display properties
  String get title => achievement.title;
  String get subtitle => achievement.description;
  String get description => shareText;

  CardBackground get background => CardBackground(
    gradientColors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
  );

  AchievementType get type => achievement.type;
}

class CardBackground {
  final List<Color> gradientColors;

  const CardBackground({required this.gradientColors});
}
