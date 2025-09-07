import 'package:flutter/material.dart';

/// Environmental color scheme for CleanCity Vibe
class AppColors {
  // Primary brand colors - Earth tones
  static const Color primary = Color(0xFF2E7D32); // Forest Green
  static const Color secondary = Color(0xFF4CAF50); // Eco Green
  static const Color accent = Color(0xFF81C784); // Light Green
  
  // Category colors for waste bins
  static const Color ecoGems = Color(0xFF4CAF50); // Recycle - Green
  static const Color fuelShards = Color(0xFF2196F3); // Organic - Blue
  static const Color voidDust = Color(0xFF757575); // Landfill - Gray
  static const Color sparkCores = Color(0xFFFF9800); // E-waste - Orange
  static const Color toxicCrystals = Color(0xFFE91E63); // Hazardous - Red
  
  // Surface colors
  static const Color surface = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF1B1B1B);
  static const Color outline = Color(0xFFE0E0E0);
  
  // Dark theme colors
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkOutline = Color(0xFF424242);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53E3E);
  static const Color info = Color(0xFF2196F3);
  
  // Gradient colors for AR overlays
  static const LinearGradient ecoGemsGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient fuelShardsGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient voidDustGradient = LinearGradient(
    colors: [Color(0xFF757575), Color(0xFF9E9E9E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient sparkCoresGradient = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient toxicCrystalsGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFF06292)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Get category color by name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
      case 'ecogems':
        return ecoGems;
      case 'organic':
      case 'fuelshards':
        return fuelShards;
      case 'landfill':
      case 'voiddust':
        return voidDust;
      case 'ewaste':
      case 'sparkcores':
        return sparkCores;
      case 'hazardous':
      case 'toxiccrystals':
        return toxicCrystals;
      default:
        return outline;
    }
  }
  
  /// Get category gradient by name
  static LinearGradient getCategoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
      case 'ecogems':
        return ecoGemsGradient;
      case 'organic':
      case 'fuelshards':
        return fuelShardsGradient;
      case 'landfill':
      case 'voiddust':
        return voidDustGradient;
      case 'ewaste':
      case 'sparkcores':
        return sparkCoresGradient;
      case 'hazardous':
      case 'toxiccrystals':
        return toxicCrystalsGradient;
      default:
        return const LinearGradient(colors: [outline, outline]);
    }
  }
}