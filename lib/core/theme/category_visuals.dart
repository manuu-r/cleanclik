import 'package:flutter/material.dart';

import 'package:cleanclik/core/models/waste_models.dart';

/// Single source of truth for waste-category visuals across the UI.
///
/// Colors come from [WasteCategory.color] so chips, markers, and sheets match
/// the AR overlay colors drawn on detected objects. Widgets must not define
/// their own category→color/icon/name switches.
class CategoryVisuals {
  CategoryVisuals._();

  static const Color _landfillColor = Color(0xFF9E9E9E);

  static Color color(String categoryId) =>
      WasteCategory.fromId(categoryId.toLowerCase())?.color ?? _landfillColor;

  static IconData icon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'recycle':
        return Icons.recycling;
      case 'organic':
        return Icons.compost;
      case 'ewaste':
        return Icons.devices;
      case 'hazardous':
        return Icons.warning_amber_rounded;
      case 'landfill':
        return Icons.delete_outline;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  static String displayName(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'recycle':
        return 'Recycle';
      case 'organic':
        return 'Organic';
      case 'ewaste':
        return 'E-Waste';
      case 'hazardous':
        return 'Hazardous';
      case 'landfill':
        return 'Landfill';
      default:
        return 'Unknown';
    }
  }

  static Color colorOf(WasteCategory category) => category.color;

  static IconData iconOf(WasteCategory category) => icon(category.id);
}
