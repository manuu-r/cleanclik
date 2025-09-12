import 'package:flutter/material.dart';

/// Enhanced Material 3 expressive color system for AR-first UI with improved contrast ratios
class NeonColors {
  // Material 3 expressive environmental colors (enhanced contrast)
  static const Color electricGreen = Color(0xFF2E7D32); // Improved contrast ratio
  static const Color oceanBlue = Color(0xFF1976D2); // Improved contrast ratio
  static const Color earthOrange = Color(0xFFE65100); // Improved contrast ratio
  static const Color solarYellow = Color(0xFFF57F17); // Improved contrast ratio
  static const Color cosmicPurple = Color(0xFF7B1FA2); // Improved contrast ratio
  static const Color toxicPurple = Color(0xFF512DA8); // Improved contrast ratio

  // Material 3 category colors (enhanced contrast versions)
  static const Color neonEcoGems = Color(0xFF388E3C); // Better contrast
  static const Color neonFuelShards = Color(0xFF1976D2); // Better contrast
  static const Color neonVoidDust = Color(0xFF616161); // Better contrast
  static const Color neonSparkCores = Color(0xFFE65100); // Better contrast
  static const Color neonToxicCrystals = Color(0xFF7B1FA2); // Better contrast

  // Enhanced glow effects with better visibility
  static const Color glowWhite = Color(0xFFFFFFFF);
  static const Color glowBlue = Color(0xFF42A5F5);
  static const Color glowGreen = Color(0xFF66BB6A);
  static const Color glowOrange = Color(0xFFFF9800);
  static const Color glowRed = Color(0xFFE91E63);
  
  // Material 3 State Layer Colors (for interactive elements)
  static const double stateLayerOpacityHover = 0.08;
  static const double stateLayerOpacityFocus = 0.12;
  static const double stateLayerOpacityPressed = 0.16;
  static const double stateLayerOpacityDragged = 0.16;
  static const double stateLayerOpacitySelected = 0.12;
  static const double stateLayerOpacityActivated = 0.12;
  
  // Material 3 Surface Tint Colors
  static const Color surfaceTintLight = Color(0xFF2E7D32);
  static const Color surfaceTintDark = Color(0xFF81C784);
  
  // Material 3 Outline Colors (enhanced contrast)
  static const Color outlineLight = Color(0xFF79747E);
  static const Color outlineDark = Color(0xFF938F99);
  static const Color outlineVariantLight = Color(0xFFCAC4D0);
  static const Color outlineVariantDark = Color(0xFF49454F);

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
    return baseColor.withValues(alpha: opacity);
  }
  
  /// Get hover state layer color
  static Color getHoverStateLayer(Color baseColor) {
    return baseColor.withValues(alpha: stateLayerOpacityHover);
  }
  
  /// Get focus state layer color
  static Color getFocusStateLayer(Color baseColor) {
    return baseColor.withValues(alpha: stateLayerOpacityFocus);
  }
  
  /// Get pressed state layer color
  static Color getPressedStateLayer(Color baseColor) {
    return baseColor.withValues(alpha: stateLayerOpacityPressed);
  }
  
  /// Get selected state layer color
  static Color getSelectedStateLayer(Color baseColor) {
    return baseColor.withValues(alpha: stateLayerOpacitySelected);
  }
  
  /// Get activated state layer color
  static Color getActivatedStateLayer(Color baseColor) {
    return baseColor.withValues(alpha: stateLayerOpacityActivated);
  }
  
  /// Get dragged state layer color
  static Color getDraggedStateLayer(Color baseColor) {
    return baseColor.withValues(alpha: stateLayerOpacityDragged);
  }
}
