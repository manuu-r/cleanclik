/// Waste categorization service for pure label-to-category mapping
///
/// This service maps ML Kit labels to waste categories using a comprehensive
/// mapping table. It filters out non-waste labels and uses ML Kit confidence
/// directly without additional calculations.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10
library;

import 'package:flutter/foundation.dart';

import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/services/camera/ml_config.dart';

/// Pure waste categorizer with ML Kit label mapping
/// 
/// This service provides pure label-to-category mapping without user corrections,
/// confidence calculations, or statistics tracking. It filters out non-waste labels
/// and uses ML Kit confidence directly.
class WasteCategorizer {
  static WasteCategorizer? _instance;
  static WasteCategorizer get instance => _instance ??= WasteCategorizer._();

  WasteCategorizer._();

  /// Non-waste label categories to filter out
  /// These labels represent people, places, activities, and other non-waste items
  /// Requirements: 5.4
  static const Set<String> _nonWasteLabels = {
    // People-related
    'people', 'person', 'crowd', 'selfie', 'smile', 'face', 'portrait',
    'human', 'man', 'woman', 'child', 'baby', 'hand', 'finger', 'thumb',
    'palm', 'fist', 'gesture', 'pointing', 'wrist', 'knuckle', 'nail',
    
    // Places
    'place', 'beach', 'lake', 'mountain', 'stadium', 'building', 'city',
    'street', 'park', 'landscape', 'scenery', 'sky', 'cloud', 'sunset', 'sunrise',
    
    // Activities
    'activity', 'dancing', 'eating', 'surfing', 'sports', 'running',
    'swimming', 'playing', 'walking', 'exercise', 'workout',
    
    // Events and context
    'event', 'leisure', 'party', 'celebration', 'concert', 'festival',
    
    // Other non-waste
    'net', 'water', 'fire', 'light', 'shadow',
  };

  /// Comprehensive mapping table for ML Kit labels to waste categories
  /// Requirements: 5.3
  static const Map<String, WasteCategory> _labelToWasteMapping = {
    // Recycle category
    'bottle': WasteCategory.recycle, 'plastic bottle': WasteCategory.recycle,
    'water bottle': WasteCategory.recycle, 'soda bottle': WasteCategory.recycle,
    'glass bottle': WasteCategory.recycle, 'can': WasteCategory.recycle,
    'aluminum can': WasteCategory.recycle, 'paper': WasteCategory.recycle,
    'cardboard': WasteCategory.recycle, 'box': WasteCategory.recycle,
    'plastic': WasteCategory.recycle, 'container': WasteCategory.recycle,
    'glass': WasteCategory.recycle, 'jar': WasteCategory.recycle,
    'metal': WasteCategory.recycle, 'aluminum': WasteCategory.recycle,
    'textile': WasteCategory.recycle, 'clothing': WasteCategory.recycle,
    'fashion_good': WasteCategory.recycle, 'home_good': WasteCategory.recycle,
    
    // Organic category
    'food': WasteCategory.organic, 'fruit': WasteCategory.organic,
    'apple': WasteCategory.organic, 'banana': WasteCategory.organic,
    'vegetable': WasteCategory.organic, 'bread': WasteCategory.organic,
    'plant': WasteCategory.organic, 'leaf': WasteCategory.organic,
    'organic': WasteCategory.organic, 'compost': WasteCategory.organic,
    
    // E-waste category
    'phone': WasteCategory.ewaste, 'smartphone': WasteCategory.ewaste,
    'computer': WasteCategory.ewaste, 'laptop': WasteCategory.ewaste,
    'tablet': WasteCategory.ewaste, 'television': WasteCategory.ewaste,
    'camera': WasteCategory.ewaste, 'electronics': WasteCategory.ewaste,
    'battery': WasteCategory.ewaste, 'charger': WasteCategory.ewaste,
    
    // Hazardous category
    'chemical': WasteCategory.hazardous, 'toxic': WasteCategory.hazardous,
    'paint': WasteCategory.hazardous, 'medicine': WasteCategory.hazardous,
    'oil': WasteCategory.hazardous, 'aerosol': WasteCategory.hazardous,
  };

  /// Categorize waste from ML Kit image labels
  /// Requirements: 5.1, 5.2, 5.4, 5.5, 5.6, 5.7, 5.8
  WasteCategory? categorize(List<ImageLabel> labels) {
    if (labels.isEmpty) return null;

    final wasteLabels = _filterWasteRelevantLabels(labels);
    if (wasteLabels.isEmpty) {
      if (kDebugMode) {
        print('🗂️ [WasteCategorizer] All labels filtered out (non-waste)');
      }
      return null;
    }

    final sortedLabels = List<ImageLabel>.from(wasteLabels)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final labelTexts = sortedLabels.map((l) => l.text.toLowerCase()).toSet();
    if (labelTexts.contains('fashion_good') && labelTexts.contains('home_good')) {
      if (kDebugMode) {
        print('🗂️ [WasteCategorizer] Multi-category: fashion_good + home_good → ewaste');
      }
      return WasteCategory.ewaste;
    }

    for (final label in sortedLabels) {
      if (label.confidence < MLConfig.minCategorizationConfidence) continue;

      final category = categorizeSingleLabel(label);
      if (category != null) {
        if (kDebugMode) {
          print('🗂️ [WasteCategorizer] "${label.text}" → ${category.id} (${(label.confidence * 100).toStringAsFixed(1)}%)');
        }
        return category;
      }
    }

    if (kDebugMode) {
      print('🗂️ [WasteCategorizer] No categorization for: ${labels.map((l) => l.text).join(', ')}');
    }
    return null;
  }

  /// Categorize a single label
  /// Requirements: 5.8
  WasteCategory? categorizeSingleLabel(ImageLabel label) {
    final normalizedLabel = _normalizeLabel(label.text);
    if (_labelToWasteMapping.containsKey(normalizedLabel)) {
      return _labelToWasteMapping[normalizedLabel];
    }
    final fuzzyMatch = _findFuzzyMatch(normalizedLabel);
    if (fuzzyMatch != null) return fuzzyMatch;
    return _findPartialMatch(normalizedLabel);
  }

  /// Filter out non-waste labels
  /// Requirements: 5.4, 5.9
  List<ImageLabel> _filterWasteRelevantLabels(List<ImageLabel> labels) {
    return labels.where((label) {
      final text = label.text.toLowerCase();
      return !_nonWasteLabels.any((nonWasteLabel) => text.contains(nonWasteLabel));
    }).toList();
  }

  WasteCategory? _findFuzzyMatch(String normalizedLabel) {
    final variations = <String, String>{
      'bottel': 'bottle', 'mobil': 'mobile', 'aluminium': 'aluminum',
      'elektronics': 'electronics', 'devic': 'device', 'phon': 'phone',
    };
    final correctedLabel = variations[normalizedLabel];
    if (correctedLabel != null && _labelToWasteMapping.containsKey(correctedLabel)) {
      return _labelToWasteMapping[correctedLabel];
    }
    for (final entry in _labelToWasteMapping.entries) {
      if (entry.key.length >= 4 && normalizedLabel.length >= 4) {
        if (entry.key.contains(normalizedLabel) || normalizedLabel.contains(entry.key)) {
          if (_isValidSubstringMatch(normalizedLabel, entry.key)) {
            return entry.value;
          }
        }
      }
    }
    return null;
  }

  WasteCategory? _findPartialMatch(String normalizedLabel) {
    final words = normalizedLabel.split(' ');
    if (words.length < 2) return null;
    for (final word in words) {
      if (word.length >= 3 && _labelToWasteMapping.containsKey(word)) {
        return _labelToWasteMapping[word];
      }
    }
    for (int i = 0; i < words.length - 1; i++) {
      final combination = '${words[i]} ${words[i + 1]}';
      if (_labelToWasteMapping.containsKey(combination)) {
        return _labelToWasteMapping[combination];
      }
    }
    return null;
  }

  bool _isValidSubstringMatch(String label1, String label2) {
    final problematicPairs = {
      'grass': ['glass'], 'glass': ['grass'],
      'plant': ['plan'], 'plan': ['plant'],
    };
    if (problematicPairs[label1]?.contains(label2) == true ||
        problematicPairs[label2]?.contains(label1) == true) {
      return false;
    }
    final shorter = label1.length < label2.length ? label1 : label2;
    final longer = label1.length >= label2.length ? label1 : label2;
    return longer.contains(shorter) && shorter.length >= (longer.length * 0.7);
  }

  String _normalizeLabel(String label) {
    return label.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
