import 'package:flutter/foundation.dart';
import '../models/waste_category.dart';
import 'qr_bin_service.dart';
import 'inventory_service.dart';

/// Service for intelligent bin matching logic between carried inventory and scanned bins
class BinMatchingService {
  static const String _logTag = 'BIN_MATCHING';

  /// Analyze match between user's inventory items and scanned bin
  static BinMatchResult analyzeMatch(
    BinInfo binInfo,
    List<InventoryItem> inventoryItems,
  ) {
    print(
      '🎯 [$_logTag] Analyzing match for bin: ${binInfo.binId} (${binInfo.category.id})',
    );
    print('🎯 [$_logTag] User carrying ${inventoryItems.length} items');

    if (inventoryItems.isEmpty) {
      print('📭 [$_logTag] Empty inventory - no items to dispose');
      return BinMatchResult(
        matchType: BinMatchType.emptyInventory,
        binInfo: binInfo,
        inventoryItems: inventoryItems,
        matchingItems: [],
        nonMatchingItems: [],
        message:
            'No Items: Scan objects with camera first, then return to dispose',
        icon: '📱',
      );
    }

    // Categorize items based on bin category
    final matchingItems = inventoryItems
        .where((item) => item.category == binInfo.category.id)
        .toList();
    final nonMatchingItems = inventoryItems
        .where((item) => item.category != binInfo.category.id)
        .toList();

    print('🎯 [$_logTag] Matching items: ${matchingItems.length}');
    print('🎯 [$_logTag] Non-matching items: ${nonMatchingItems.length}');

    // Log detailed item breakdown
    if (kDebugMode) {
      for (final item in matchingItems) {
        print('✅ [$_logTag] Matching: ${item.displayName} (${item.category})');
      }
      for (final item in nonMatchingItems) {
        print(
          '❌ [$_logTag] Non-matching: ${item.displayName} (${item.category})',
        );
      }
    }

    // Determine match type and create result
    if (matchingItems.isNotEmpty && nonMatchingItems.isEmpty) {
      // Perfect match - all items match the bin
      print('✅ [$_logTag] Perfect match detected');
      return BinMatchResult(
        matchType: BinMatchType.perfectMatch,
        binInfo: binInfo,
        inventoryItems: inventoryItems,
        matchingItems: matchingItems,
        nonMatchingItems: nonMatchingItems,
        message:
            'Perfect Match! Ready to dispose ${matchingItems.length} ${binInfo.category.codeName}',
        icon: '✅',
      );
    } else if (matchingItems.isNotEmpty && nonMatchingItems.isNotEmpty) {
      // Partial match - some items match, some don't
      print('⚠️ [$_logTag] Partial match detected');
      final nonMatchingCategories = nonMatchingItems
          .map(
            (item) =>
                WasteCategory.fromId(item.category)?.codeName ?? item.category,
          )
          .toSet()
          .join(', ');
      return BinMatchResult(
        matchType: BinMatchType.partialMatch,
        binInfo: binInfo,
        inventoryItems: inventoryItems,
        matchingItems: matchingItems,
        nonMatchingItems: nonMatchingItems,
        message:
            'Partial Match: ${matchingItems.length} items match, ${nonMatchingItems.length} items need different bin',
        icon: '⚠️',
        additionalInfo: 'Non-matching items: $nonMatchingCategories',
      );
    } else {
      // No match - no items match the bin
      print('❌ [$_logTag] No match detected');
      final userCategories = inventoryItems
          .map(
            (item) =>
                WasteCategory.fromId(item.category)?.codeName ?? item.category,
          )
          .toSet()
          .join(', ');
      return BinMatchResult(
        matchType: BinMatchType.noMatch,
        binInfo: binInfo,
        inventoryItems: inventoryItems,
        matchingItems: matchingItems,
        nonMatchingItems: nonMatchingItems,
        message:
            'Wrong Bin: This is for ${binInfo.category.codeName}, you\'re carrying $userCategories',
        icon: '❌',
        additionalInfo: _getSuggestedBinTypes(inventoryItems),
      );
    }
  }

  /// Analyze match with CarriedItem list (backward compatibility)
  static BinMatchResult analyzeMatchWithCarriedItems(
    BinInfo binInfo,
    List<CarriedItem> carriedItems,
  ) {
    print(
      '🔄 [$_logTag] Converting CarriedItems to InventoryItems for analysis...',
    );

    // Convert CarriedItem to InventoryItem for analysis
    final inventoryItems = carriedItems
        .map((carriedItem) => InventoryItem.fromCarriedItem(carriedItem))
        .toList();

    return analyzeMatch(binInfo, inventoryItems);
  }

  /// Get suggested bin types for user's carried items
  static String _getSuggestedBinTypes(List<InventoryItem> inventoryItems) {
    final categories = inventoryItems
        .map((item) => WasteCategory.fromId(item.category))
        .where((category) => category != null)
        .cast<WasteCategory>()
        .toSet();

    if (categories.isEmpty) return 'No valid categories detected';

    final suggestions = categories
        .map((category) => '${category.codeName} bin')
        .join(', ');
    return 'You need: $suggestions';
  }

  /// Get match confidence score (0.0 to 1.0)
  static double getMatchConfidence(BinMatchResult result) {
    switch (result.matchType) {
      case BinMatchType.perfectMatch:
        return 1.0;
      case BinMatchType.partialMatch:
        final totalItems = result.inventoryItems.length;
        final matchingItems = result.matchingItems.length;
        return totalItems > 0 ? matchingItems / totalItems : 0.0;
      case BinMatchType.noMatch:
        return 0.0;
      case BinMatchType.emptyInventory:
        return 0.0;
    }
  }

  /// Check if disposal should be allowed
  static bool shouldAllowDisposal(BinMatchResult result) {
    return result.matchType == BinMatchType.perfectMatch ||
        result.matchType == BinMatchType.partialMatch;
  }

  /// Get items that can be disposed in this bin
  static List<InventoryItem> getDisposableItems(BinMatchResult result) {
    return result.matchingItems;
  }

  /// Get detailed match analysis for debugging
  static Map<String, dynamic> getMatchAnalysis(BinMatchResult result) {
    return {
      'match_type': result.matchType.toString(),
      'bin_category': result.binInfo.category.id,
      'total_carried_items': result.inventoryItems.length,
      'matching_items': result.matchingItems.length,
      'non_matching_items': result.nonMatchingItems.length,
      'match_confidence': getMatchConfidence(result),
      'disposal_allowed': shouldAllowDisposal(result),
      'carried_categories': result.inventoryItems
          .map((item) => item.category)
          .toSet()
          .toList(),
      'matching_item_ids': result.matchingItems.map((item) => item.id).toList(),
      'non_matching_item_ids': result.nonMatchingItems
          .map((item) => item.id)
          .toList(),
      'bin_info': {
        'bin_id': result.binInfo.binId,
        'category': result.binInfo.category.id,
        'location': result.binInfo.locationName,
      },
    };
  }

  /// Log match result for analytics
  static void logMatchResult(BinMatchResult result) {
    if (kDebugMode) {
      final analysis = getMatchAnalysis(result);
      debugPrint('📊 [$_logTag] Match Analysis: ${analysis.toString()}');
    }
  }

  /// Validate bin matching prerequisites
  static bool validateMatchingPrerequisites(
    BinInfo binInfo,
    List<InventoryItem> inventoryItems,
  ) {
    if (binInfo.category == null) {
      print('❌ [$_logTag] Invalid bin category');
      return false;
    }

    // Check if any items have valid categories
    final validItems = inventoryItems
        .where((item) => WasteCategory.fromId(item.category) != null)
        .toList();
    if (validItems.length != inventoryItems.length) {
      print('⚠️ [$_logTag] Some items have invalid categories');
    }

    return true;
  }
}

/// Result of bin matching analysis
class BinMatchResult {
  final BinMatchType matchType;
  final BinInfo binInfo;
  final List<InventoryItem> inventoryItems;
  final List<InventoryItem> matchingItems;
  final List<InventoryItem> nonMatchingItems;
  final String message;
  final String icon;
  final String? additionalInfo;

  const BinMatchResult({
    required this.matchType,
    required this.binInfo,
    required this.inventoryItems,
    required this.matchingItems,
    required this.nonMatchingItems,
    required this.message,
    required this.icon,
    this.additionalInfo,
  });

  /// Get carried items for backward compatibility
  List<CarriedItem> get carriedItems =>
      inventoryItems.map((item) => item.toCarriedItem()).toList();

  /// Get primary color for UI feedback
  String get primaryColorName {
    switch (matchType) {
      case BinMatchType.perfectMatch:
        return 'electricGreen';
      case BinMatchType.partialMatch:
        return 'solarYellow';
      case BinMatchType.noMatch:
        return 'glowRed';
      case BinMatchType.emptyInventory:
        return 'oceanBlue';
    }
  }

  /// Get feedback intensity for haptics/animations
  double get feedbackIntensity {
    switch (matchType) {
      case BinMatchType.perfectMatch:
        return 1.0; // Strong positive feedback
      case BinMatchType.partialMatch:
        return 0.6; // Medium warning feedback
      case BinMatchType.noMatch:
        return 0.8; // Strong warning feedback
      case BinMatchType.emptyInventory:
        return 0.3; // Light informational feedback
    }
  }

  /// Check if this is a positive result
  bool get isPositiveResult {
    return matchType == BinMatchType.perfectMatch;
  }

  /// Check if this is a warning result
  bool get isWarningResult {
    return matchType == BinMatchType.partialMatch;
  }

  /// Check if this is an error result
  bool get isErrorResult {
    return matchType == BinMatchType.noMatch;
  }

  /// Check if this is an informational result
  bool get isInfoResult {
    return matchType == BinMatchType.emptyInventory;
  }

  /// Get disposal statistics
  Map<String, int> get disposalStats {
    return {
      'total_items': inventoryItems.length,
      'matching_items': matchingItems.length,
      'non_matching_items': nonMatchingItems.length,
    };
  }

  @override
  String toString() {
    return 'BinMatchResult(type: $matchType, bin: ${binInfo.binId}, message: $message, items: ${inventoryItems.length})';
  }
}

/// Types of bin matching results
enum BinMatchType {
  /// All carried items match the scanned bin category
  perfectMatch,

  /// Some carried items match, some don't
  partialMatch,

  /// No carried items match the scanned bin category
  noMatch,

  /// User has no carried items
  emptyInventory,
}
