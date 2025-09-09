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
