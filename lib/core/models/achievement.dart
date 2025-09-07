enum AchievementType {
  firstScan,
  streakMaster,
  ecoWarrior,
  recyclingChampion,
  compostKing,
  ewasteExpert,
  hazardousHandler,
  pointsCollector,
  levelUp,
  socialSharer,
  points,
  streak,
  accuracy,
  category,
  ranking,
  special,
}

enum AchievementRarity { common, rare, epic, legendary }

extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  int get color {
    switch (this) {
      case AchievementRarity.common:
        return 0xFF9E9E9E; // Grey
      case AchievementRarity.rare:
        return 0xFF2196F3; // Blue
      case AchievementRarity.epic:
        return 0xFF9C27B0; // Purple
      case AchievementRarity.legendary:
        return 0xFFFFD700; // Gold
    }
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final String iconUrl;
  final AchievementType type;
  final AchievementRarity rarity;
  final int pointsRequired;
  final int level;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String category;
  final Map<String, dynamic> metadata;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.iconPath = '',
    this.iconUrl = '',
    required this.type,
    this.rarity = AchievementRarity.common,
    this.pointsRequired = 0,
    this.level = 1,
    this.isUnlocked = false,
    this.unlockedAt,
    this.category = '',
    this.metadata = const {},
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      type: AchievementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AchievementType.firstScan,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      pointsRequired: json['pointsRequired'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      category: json['category'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'iconUrl': iconUrl,
      'type': type.name,
      'rarity': rarity.name,
      'pointsRequired': pointsRequired,
      'level': level,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'category': category,
      'metadata': metadata,
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    String? iconUrl,
    AchievementType? type,
    AchievementRarity? rarity,
    int? pointsRequired,
    int? level,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      iconUrl: iconUrl ?? this.iconUrl,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      level: level ?? this.level,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getter for name (for backward compatibility)
  String get name => title;
}

// Static achievements data
class Achievements {
  static const Map<AchievementType, Achievement> _achievements = {
    AchievementType.firstScan: Achievement(
      id: 'first_scan',
      title: 'First Steps',
      description: 'Complete your first item scan',
      iconPath: 'assets/icons/first_scan.png',
      type: AchievementType.firstScan,
      pointsRequired: 0,
      level: 1,
      isUnlocked: false,
      category: 'Getting Started',
    ),
    AchievementType.streakMaster: Achievement(
      id: 'streak_master',
      title: 'Streak Master',
      description: 'Maintain a 7-day scanning streak',
      iconPath: 'assets/icons/streak.png',
      type: AchievementType.streakMaster,
      pointsRequired: 0,
      level: 1,
      isUnlocked: false,
      category: 'Consistency',
    ),
    AchievementType.ecoWarrior: Achievement(
      id: 'eco_warrior',
      title: 'Eco Warrior',
      description: 'Categorize 100 items correctly',
      iconPath: 'assets/icons/eco_warrior.png',
      type: AchievementType.ecoWarrior,
      pointsRequired: 1000,
      level: 1,
      isUnlocked: false,
      category: 'Impact',
    ),
  };

  static Achievement? getByType(AchievementType type) {
    return _achievements[type];
  }

  static List<Achievement> getByTypeList(AchievementType type) {
    return _achievements.values.where((a) => a.type == type).toList();
  }

  static Achievement? getById(String id) {
    return _achievements.values.firstWhere(
      (achievement) => achievement.id == id,
      orElse: () => _achievements.values.first,
    );
  }

  static List<Achievement> getAll() {
    return _achievements.values.toList();
  }
}
