/// Represents a user in the VibeSweep system
class User {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final int totalPoints;
  final int level;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, int> categoryStats;
  final List<String> achievements;
  final bool isOnline;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.totalPoints = 0,
    this.level = 1,
    required this.createdAt,
    required this.lastActiveAt,
    this.categoryStats = const {},
    this.achievements = const [],
    this.isOnline = false,
  });

  /// Create a default user (for testing/demo purposes)
  factory User.defaultUser() {
    return User(
      id: 'demo_user_001',
      username: 'EcoWarrior',
      email: 'demo@vibesweep.com',
      avatarUrl: null,
      totalPoints: 1250,
      level: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActiveAt: DateTime.now(),
      categoryStats: {
        'recycle': 45,
        'organic': 32,
        'ewaste': 26, // Combined landfill items into ewaste
        'hazardous': 3,
      },
      achievements: [
        'first_pickup',
        'eco_novice',
        'recycling_champion',
      ],
      isOnline: true,
    );
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      categoryStats: Map<String, int>.from(json['categoryStats'] as Map? ?? {}),
      achievements: List<String>.from(json['achievements'] as List? ?? []),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'categoryStats': categoryStats,
      'achievements': achievements,
      'isOnline': isOnline,
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    int? totalPoints,
    int? level,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, int>? categoryStats,
    List<String>? achievements,
    bool? isOnline,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      categoryStats: categoryStats ?? this.categoryStats,
      achievements: achievements ?? this.achievements,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  /// Calculate level based on points
  static int calculateLevel(int points) {
    if (points < 100) return 1;
    if (points < 500) return 2;
    if (points < 1000) return 3;
    if (points < 2500) return 4;
    if (points < 5000) return 5;
    return 6; // Max level for now
  }

  /// Get points needed for next level
  int get pointsToNextLevel {
    final nextLevel = level + 1;
    final nextLevelThreshold = _getLevelThreshold(nextLevel);
    return nextLevelThreshold - totalPoints;
  }

  /// Get progress to next level (0.0 to 1.0)
  double get levelProgress {
    final currentLevelThreshold = _getLevelThreshold(level);
    final nextLevelThreshold = _getLevelThreshold(level + 1);
    final pointsInCurrentLevel = totalPoints - currentLevelThreshold;
    final pointsNeededForLevel = nextLevelThreshold - currentLevelThreshold;
    return pointsInCurrentLevel / pointsNeededForLevel;
  }

  int _getLevelThreshold(int level) {
    switch (level) {
      case 1: return 0;
      case 2: return 100;
      case 3: return 500;
      case 4: return 1000;
      case 5: return 2500;
      case 6: return 5000;
      default: return 10000;
    }
  }

  /// Get total items collected across all categories
  int get totalItemsCollected {
    return categoryStats.values.fold(0, (sum, count) => sum + count);
  }

  /// Get user's rank based on points (placeholder - would be calculated from leaderboard)
  int get rank => 42; // Placeholder

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username, level: $level, points: $totalPoints)';
  }
}