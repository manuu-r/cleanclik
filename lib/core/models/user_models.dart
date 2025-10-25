/// User-related models for the CleanClik system
///
/// This file consolidates all user-related data models including:
/// - User: Main user class with Supabase integration
/// - CategoryStats: User category statistics

/// Represents a user in the VibeSweep system with Supabase integration
class User {
  final String id;
  final String? authId; // Supabase auth.users(id) reference
  final String username;
  final String email;
  final String? fullName; // For backward compatibility with tests
  final String? avatarUrl;
  final int totalPoints;
  final int level;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, int> categoryStats;
  final List<String> achievements;
  final bool isOnline;
  final Map<String, dynamic>? metadata; // For additional user data

  const User({
    required this.id,
    this.authId,
    required this.username,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.totalPoints = 0,
    this.level = 1,
    required this.createdAt,
    required this.lastActiveAt,
    this.categoryStats = const {},
    this.achievements = const [],
    this.isOnline = false,
    this.metadata,
  });

  /// Create from JSON (local storage format)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      authId: json['authId'] as String?,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      categoryStats: Map<String, int>.from(json['categoryStats'] as Map? ?? {}),
      achievements: List<String>.from(json['achievements'] as List? ?? []),
      isOnline: json['isOnline'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create from Supabase database row
  factory User.fromSupabase(Map<String, dynamic> data) {
    return User(
      id: data['id'] as String,
      authId: data['auth_id'] as String?,
      username: data['username'] as String,
      email: data['email'] as String,
      fullName: null, // full_name column doesn't exist in database schema
      avatarUrl: data['avatar_url'] as String?,
      totalPoints: data['total_points'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      createdAt: DateTime.parse(data['created_at'] as String),
      lastActiveAt: DateTime.parse(data['last_active_at'] as String),
      categoryStats:
          const {}, // Will be loaded separately from category_stats table
      achievements:
          const [], // Will be loaded separately from achievements table
      isOnline: data['is_online'] as bool? ?? false,
      metadata: null, // metadata column doesn't exist in database schema
    );
  }

  /// Convert to JSON (local storage format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authId': authId,
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'categoryStats': categoryStats,
      'achievements': achievements,
      'isOnline': isOnline,
      'metadata': metadata,
    };
  }

  /// Convert to Supabase database format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'auth_id': authId,
      'username': username,
      'email': email,
      // 'full_name': fullName, // Removed - column doesn't exist in database schema
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'level': level,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
      'is_online': isOnline,
      // 'metadata': metadata, // Removed - column doesn't exist in database schema
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? authId,
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
      authId: authId ?? this.authId,
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
    if (level >= 6) return 0; // Max level reached
    final nextLevelThreshold = _getLevelThreshold(level + 1);
    return nextLevelThreshold - totalPoints;
  }

  /// Get progress to next level (0.0 to 1.0)
  double get levelProgress {
    if (level >= 6) return 1.0; // Max level reached
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

  /// Get total items collected across all categories
  int get totalItemsCollected {
    return categoryStats.values.fold(0, (sum, count) => sum + count);
  }

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

/// Represents category statistics for a user in the VibeSweep system
class CategoryStats {
  final String id;
  final String userId;
  final String category;
  final int itemCount;
  final int totalPoints;
  final DateTime updatedAt;

  const CategoryStats({
    required this.id,
    required this.userId,
    required this.category,
    required this.itemCount,
    required this.totalPoints,
    required this.updatedAt,
  });

  /// Create from JSON (local storage format)
  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      itemCount: json['itemCount'] as int,
      totalPoints: json['totalPoints'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create from Supabase database row
  factory CategoryStats.fromSupabase(Map<String, dynamic> data) {
    return CategoryStats(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      category: data['category'] as String,
      itemCount: data['item_count'] as int,
      totalPoints: data['total_points'] as int,
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  /// Convert to JSON (local storage format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'itemCount': itemCount,
      'totalPoints': totalPoints,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to Supabase database format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'item_count': itemCount,
      'total_points': totalPoints,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CategoryStats copyWith({
    String? id,
    String? userId,
    String? category,
    int? itemCount,
    int? totalPoints,
    DateTime? updatedAt,
  }) {
    return CategoryStats(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      itemCount: itemCount ?? this.itemCount,
      totalPoints: totalPoints ?? this.totalPoints,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryStats &&
        other.id == id &&
        other.userId == userId &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(id, userId, category);

  @override
  String toString() {
    return 'CategoryStats(id: $id, userId: $userId, category: $category, itemCount: $itemCount, totalPoints: $totalPoints)';
  }
}
