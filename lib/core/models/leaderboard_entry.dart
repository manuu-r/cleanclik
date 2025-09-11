import 'user.dart';

/// Represents a leaderboard entry with user ranking information
class LeaderboardEntry {
  final String id;
  final String username;
  final int totalPoints;
  final int level;
  final int rank;
  final String? avatarUrl;
  final DateTime lastActiveAt;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.id,
    required this.username,
    required this.totalPoints,
    required this.level,
    required this.rank,
    this.avatarUrl,
    required this.lastActiveAt,
    this.isCurrentUser = false,
  });

  /// Create from Supabase leaderboard view
  factory LeaderboardEntry.fromSupabase(
    Map<String, dynamic> data, {
    String? currentUserId,
  }) {
    return LeaderboardEntry(
      id: data['id'] as String,
      username: data['username'] as String,
      totalPoints: data['total_points'] as int,
      level: data['level'] as int,
      rank: data['rank'] as int,
      avatarUrl: data['avatar_url'] as String?,
      lastActiveAt: DateTime.parse(data['last_active_at'] as String),
      isCurrentUser: currentUserId != null && data['id'] == currentUserId,
    );
  }

  /// Create from User model
  factory LeaderboardEntry.fromUser(User user, int rank) {
    return LeaderboardEntry(
      id: user.id,
      username: user.username,
      totalPoints: user.totalPoints,
      level: user.level,
      rank: rank,
      avatarUrl: user.avatarUrl,
      lastActiveAt: user.lastActiveAt,
      isCurrentUser: false,
    );
  }

  /// Convert to JSON for local caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'totalPoints': totalPoints,
      'level': level,
      'rank': rank,
      'avatarUrl': avatarUrl,
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isCurrentUser': isCurrentUser,
    };
  }

  /// Create from JSON for local caching
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      username: json['username'] as String,
      totalPoints: json['totalPoints'] as int,
      level: json['level'] as int,
      rank: json['rank'] as int,
      avatarUrl: json['avatarUrl'] as String?,
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  /// Create a copy with updated fields
  LeaderboardEntry copyWith({
    String? id,
    String? username,
    int? totalPoints,
    int? level,
    int? rank,
    String? avatarUrl,
    DateTime? lastActiveAt,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      username: username ?? this.username,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      rank: rank ?? this.rank,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  /// Get display name with rank prefix
  String get displayName => '#$rank $username';

  /// Get points formatted as string
  String get pointsFormatted {
    if (totalPoints >= 1000000) {
      return '${(totalPoints / 1000000).toStringAsFixed(1)}M';
    } else if (totalPoints >= 1000) {
      return '${(totalPoints / 1000).toStringAsFixed(1)}K';
    }
    return totalPoints.toString();
  }

  /// Check if user is active (last active within 7 days)
  bool get isActive {
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt);
    return difference.inDays <= 7;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LeaderboardEntry(id: $id, username: $username, rank: $rank, points: $totalPoints)';
  }
}

/// Leaderboard pagination information
class LeaderboardPage {
  final List<LeaderboardEntry> entries;
  final int currentPage;
  final int totalPages;
  final int totalEntries;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final DateTime lastUpdated;

  const LeaderboardPage({
    required this.entries,
    required this.currentPage,
    required this.totalPages,
    required this.totalEntries,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.lastUpdated,
  });

  /// Create empty page
  factory LeaderboardPage.empty() {
    return LeaderboardPage(
      entries: const [],
      currentPage: 1,
      totalPages: 0,
      totalEntries: 0,
      hasNextPage: false,
      hasPreviousPage: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalEntries': totalEntries,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON for caching
  factory LeaderboardPage.fromJson(Map<String, dynamic> json) {
    return LeaderboardPage(
      entries: (json['entries'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalEntries: json['totalEntries'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Create a copy with updated fields
  LeaderboardPage copyWith({
    List<LeaderboardEntry>? entries,
    int? currentPage,
    int? totalPages,
    int? totalEntries,
    bool? hasNextPage,
    bool? hasPreviousPage,
    DateTime? lastUpdated,
  }) {
    return LeaderboardPage(
      entries: entries ?? this.entries,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalEntries: totalEntries ?? this.totalEntries,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'LeaderboardPage(entries: ${entries.length}, page: $currentPage/$totalPages)';
  }
}

/// Enum for different leaderboard time periods
enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  allTime;

  /// Get display name for the period
  String get displayName {
    switch (this) {
      case LeaderboardPeriod.daily:
        return 'Today';
      case LeaderboardPeriod.weekly:
        return 'This Week';
      case LeaderboardPeriod.monthly:
        return 'This Month';
      case LeaderboardPeriod.allTime:
        return 'All Time';
    }
  }

  /// Get short display name for the period
  String get shortName {
    switch (this) {
      case LeaderboardPeriod.daily:
        return 'Day';
      case LeaderboardPeriod.weekly:
        return 'Week';
      case LeaderboardPeriod.monthly:
        return 'Month';
      case LeaderboardPeriod.allTime:
        return 'All';
    }
  }

  /// Get duration in days (null for all time)
  int? get durationInDays {
    switch (this) {
      case LeaderboardPeriod.daily:
        return 1;
      case LeaderboardPeriod.weekly:
        return 7;
      case LeaderboardPeriod.monthly:
        return 30;
      case LeaderboardPeriod.allTime:
        return null;
    }
  }

  /// Check if this is a time-limited period
  bool get isTimeLimited => durationInDays != null;
}

/// Leaderboard filter options
enum LeaderboardFilter { all, friends, thisWeek, thisMonth, allTime }

/// Leaderboard sort options
enum LeaderboardSort { points, level, recent }
