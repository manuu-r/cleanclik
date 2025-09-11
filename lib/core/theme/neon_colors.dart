import 'package:flutter/material.dart';

/// Material 3 expressive color system for AR-first UI
class NeonColors {
  // Material 3 expressive environmental colors
  static const Color electricGreen = Color(0xFF4CAF50);
  static const Color oceanBlue = Color(0xFF2196F3);
  static const Color earthOrange = Color(0xFFFF9800);
  static const Color solarYellow = Color(0xFFFFC107);
  static const Color cosmicPurple = Color(0xFF9C27B0);
  static const Color toxicPurple = Color(0xFF673AB7);

  // Material 3 category colors (expressive versions)
  static const Color neonEcoGems = Color(0xFF66BB6A);
  static const Color neonFuelShards = Color(0xFF42A5F5);
  static const Color neonVoidDust = Color(0xFF9E9E9E);
  static const Color neonSparkCores = Color(0xFFFFB74D);
  static const Color neonToxicCrystals = Color(0xFFBA68C8);

  // Glow effects
  static const Color glowWhite = Color(0xFFFFFFFF);
  static const Color glowBlue = Color(0xFF64B5F6);
  static const Color glowGreen = Color(0xFF81C784);
  static const Color glowOrange = Color(0xFFFFB74D);
  static const Color glowRed = Color(0xFFF06292);

  /// Get neon color for category
  static Color getNeonCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
      case 'ecogems':
        return neonEcoGems;
      case 'organic':
      case 'fuelshards':
        return neonFuelShards;
      case 'landfill':
      case 'voiddust':
        return neonVoidDust;
      case 'ewaste':
      case 'sparkcores':
        return neonSparkCores;
      case 'hazardous':
      case 'toxiccrystals':
        return neonToxicCrystals;
      default:
        return glowWhite;
    }
  }

  /// Get glow color for category
  static Color getGlowColor(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
      case 'ecogems':
        return glowGreen;
      case 'organic':
      case 'fuelshards':
        return glowBlue;
      case 'landfill':
      case 'voiddust':
        return glowWhite;
      case 'ewaste':
      case 'sparkcores':
        return glowOrange;
      case 'hazardous':
      case 'toxiccrystals':
        return glowRed;
      default:
        return glowWhite;
    }
  }

  /// Create Material 3 surface treatment (no shadows)
  static List<BoxShadow> createNeonGlow(Color color, {double intensity = 1.0}) {
    // Return empty list - no shadows in Material 3 expressive design
    return [];
  }

  /// Get Material 3 state layer color for interactive elements
  static Color getStateLayerColor(Color baseColor, {double opacity = 0.12}) {
    return baseColor.withOpacity(opacity);
  }
}
