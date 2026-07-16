/// Waste categorization models for the CleanClik system
///
/// Defines the waste disposal categories and their visual properties.
/// Label-to-category classification lives in WasteCategorizer
/// (lib/core/services/camera/waste_categorizer.dart) and the on-device VLM
/// classifier (lib/core/services/camera/vlm_waste_classifier.dart).

import 'dart:ui';

/// Waste disposal categories with their visual properties
enum WasteCategory {
  recycle('recycle', 'EcoGems', Color(0xFF4CAF50)),
  organic('organic', 'BioShards', Color(0xFF8BC34A)),
  ewaste('ewaste', 'TechCores', Color(0xFFFF9800)),
  hazardous('hazardous', 'ToxicVials', Color(0xFFE91E63));

  const WasteCategory(this.id, this.codeName, this.color);

  final String id;
  final String codeName;
  final Color color;

  /// Get category by ID
  static WasteCategory? fromId(String id) {
    try {
      return WasteCategory.values.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get category by codeName (EcoGems, BioShards, etc.)
  static WasteCategory? fromCodeName(String codeName) {
    try {
      return WasteCategory.values.firstWhere(
        (category) => category.codeName == codeName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get category by either ID or codeName (flexible parsing)
  static WasteCategory? fromString(String value) {
    // Try ID first (recycle, organic, etc.)
    final byId = fromId(value);
    if (byId != null) return byId;

    // Try codeName (EcoGems, BioShards, etc.)
    final byCodeName = fromCodeName(value);
    if (byCodeName != null) return byCodeName;

    return null;
  }
}

/// Points awarded per disposed item, by category ID.
///
/// Single source of truth — disposal, QR scanning, and user stats must all
/// award the same points for the same category.
class CategoryPoints {
  CategoryPoints._();

  static const Map<String, int> _points = {
    'hazardous': 20,
    'ewaste': 15,
    'recycle': 10,
    'organic': 8,
    'landfill': 5,
  };

  static int of(String categoryId) =>
      _points[categoryId.toLowerCase()] ?? 5;
}
