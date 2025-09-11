class LeaderboardUser {
  final String id;
  final String username;
  final String displayName;
  final int totalPoints;
  final int level;
  final String profileImageUrl;
  final int rank;
  final int itemsCategorized;
  final int itemsCollected;
  final double co2Saved;
  final int currentStreak;
  final DateTime lastActivity;
  final DateTime lastActiveAt;
  final double accuracyPercentage;
  final String highestBadge;
  final bool isCurrentUser;
  final int rankChange;

  const LeaderboardUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.totalPoints,
    required this.level,
    required this.profileImageUrl,
    required this.rank,
    required this.itemsCategorized,
    required this.itemsCollected,
    required this.co2Saved,
    required this.currentStreak,
    required this.lastActivity,
    required this.lastActiveAt,
    required this.accuracyPercentage,
    required this.highestBadge,
    required this.isCurrentUser,
    required this.rankChange,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      totalPoints: json['totalPoints'] as int,
      level: json['level'] as int,
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      rank: json['rank'] as int,
      itemsCategorized: json['itemsCategorized'] as int,
      itemsCollected: json['itemsCollected'] as int? ?? 0,
      co2Saved: (json['co2Saved'] as num).toDouble(),
      currentStreak: json['currentStreak'] as int,
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : DateTime.parse(json['lastActivity'] as String),
      accuracyPercentage:
          (json['accuracyPercentage'] as num?)?.toDouble() ?? 0.0,
      highestBadge: json['highestBadge'] as String? ?? '',
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      rankChange: json['rankChange'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'totalPoints': totalPoints,
      'level': level,
      'profileImageUrl': profileImageUrl,
      'rank': rank,
      'itemsCategorized': itemsCategorized,
      'itemsCollected': itemsCollected,
      'co2Saved': co2Saved,
      'currentStreak': currentStreak,
      'lastActivity': lastActivity.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'accuracyPercentage': accuracyPercentage,
      'highestBadge': highestBadge,
      'isCurrentUser': isCurrentUser,
      'rankChange': rankChange,
    };
  }

  LeaderboardUser copyWith({
    String? id,
    String? username,
    String? displayName,
    int? totalPoints,
    int? level,
    String? profileImageUrl,
    int? rank,
    int? itemsCategorized,
    int? itemsCollected,
    double? co2Saved,
    int? currentStreak,
    DateTime? lastActivity,
    DateTime? lastActiveAt,
    double? accuracyPercentage,
    String? highestBadge,
    bool? isCurrentUser,
    int? rankChange,
  }) {
    return LeaderboardUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rank: rank ?? this.rank,
      itemsCategorized: itemsCategorized ?? this.itemsCategorized,
      itemsCollected: itemsCollected ?? this.itemsCollected,
      co2Saved: co2Saved ?? this.co2Saved,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivity: lastActivity ?? this.lastActivity,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      highestBadge: highestBadge ?? this.highestBadge,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      rankChange: rankChange ?? this.rankChange,
    );
  }
}
