class CardData {
  final String userName;
  final String userLevel;
  final int totalPoints;
  final int currentStreak;
  final List<String> recentBadges;
  final EnvironmentalImpact impact;
  final String profileImageUrl;
  final DateTime lastActivity;
  final String locationName;
  final List<RecentActivity> recentActivity;
  final String motivationalMessage;
  final String callToAction;

  const CardData({
    required this.userName,
    required this.userLevel,
    required this.totalPoints,
    required this.currentStreak,
    required this.recentBadges,
    required this.impact,
    required this.profileImageUrl,
    required this.lastActivity,
    required this.locationName,
    required this.recentActivity,
    required this.motivationalMessage,
    required this.callToAction,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      userName: json['userName'] as String,
      userLevel: json['userLevel'] as String,
      totalPoints: json['totalPoints'] as int,
      currentStreak: json['currentStreak'] as int,
      recentBadges: (json['recentBadges'] as List<dynamic>).cast<String>(),
      impact: EnvironmentalImpact.fromJson(
        json['impact'] as Map<String, dynamic>,
      ),
      profileImageUrl: json['profileImageUrl'] as String,
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      locationName: json['locationName'] as String,
      recentActivity: (json['recentActivity'] as List<dynamic>)
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      motivationalMessage: json['motivationalMessage'] as String,
      callToAction: json['callToAction'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userLevel': userLevel,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'recentBadges': recentBadges,
      'impact': impact.toJson(),
      'profileImageUrl': profileImageUrl,
      'lastActivity': lastActivity.toIso8601String(),
      'locationName': locationName,
      'recentActivity': recentActivity.map((e) => e.toJson()).toList(),
      'motivationalMessage': motivationalMessage,
      'callToAction': callToAction,
    };
  }

  CardData copyWith({
    String? userName,
    String? userLevel,
    int? totalPoints,
    int? currentStreak,
    List<String>? recentBadges,
    EnvironmentalImpact? impact,
    String? profileImageUrl,
    DateTime? lastActivity,
    String? locationName,
    List<RecentActivity>? recentActivity,
    String? motivationalMessage,
    String? callToAction,
  }) {
    return CardData(
      userName: userName ?? this.userName,
      userLevel: userLevel ?? this.userLevel,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      recentBadges: recentBadges ?? this.recentBadges,
      impact: impact ?? this.impact,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lastActivity: lastActivity ?? this.lastActivity,
      locationName: locationName ?? this.locationName,
      recentActivity: recentActivity ?? this.recentActivity,
      motivationalMessage: motivationalMessage ?? this.motivationalMessage,
      callToAction: callToAction ?? this.callToAction,
    );
  }
}

class EnvironmentalImpact {
  final int itemsCategorized;
  final double co2Saved; // in kg
  final int treesEquivalent;
  final String impactMessage;

  const EnvironmentalImpact({
    required this.itemsCategorized,
    required this.co2Saved,
    required this.treesEquivalent,
    required this.impactMessage,
  });

  factory EnvironmentalImpact.fromJson(Map<String, dynamic> json) {
    return EnvironmentalImpact(
      itemsCategorized: json['itemsCategorized'] as int,
      co2Saved: (json['co2Saved'] as num).toDouble(),
      treesEquivalent: json['treesEquivalent'] as int,
      impactMessage: json['impactMessage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemsCategorized': itemsCategorized,
      'co2Saved': co2Saved,
      'treesEquivalent': treesEquivalent,
      'impactMessage': impactMessage,
    };
  }
}

class RecentActivity {
  final String type;
  final String description;
  final DateTime timestamp;
  final int pointsEarned;

  const RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
    required this.pointsEarned,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      pointsEarned: json['pointsEarned'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'pointsEarned': pointsEarned,
    };
  }
}

class CardDimensions {
  final double width;
  final double height;
  final double aspectRatio;

  const CardDimensions({
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  factory CardDimensions.fromJson(Map<String, dynamic> json) {
    return CardDimensions(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      aspectRatio: (json['aspectRatio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height, 'aspectRatio': aspectRatio};
  }
}
