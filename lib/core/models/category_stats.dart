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