import 'package:flutter/material.dart';

import 'package:cleanclik/core/models/camera_models.dart' hide DetectionSource;
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/camera/qr_bin_service.dart';

/// Disposal handling service
///
/// Focus: Single place for disposal logic, point calculation, metadata creation
/// and detection metadata extraction. This refactor DRYs repeated maps and
/// helper logic into shared constants and small helpers.
class DisposalHandlingService {
  static const String _logTag = 'DISPOSAL_HANDLING';

  // --- Centralized configuration maps/constants (single source of truth) ---
  static const Map<String, int> _categoryPoints = {
    'recycle': 10,
    'organic': 8,
    'landfill': 5,
    'ewaste': 15,
    'hazardous': 20,
  };

  static const Map<String, String> _categoryDisplayNames = {
    'recycle': 'Recycle',
    'organic': 'Organic',
    'landfill': 'Landfill',
    'ewaste': 'E-Waste',
    'hazardous': 'Hazardous',
  };

  // UI color approximations are provided here to keep mapping centralized.
  // If you prefer to keep UI colors in the theme layer, convert these to
  // lightweight keys (enums/strings) and map them in the UI instead.
  static const Map<String, Color> _categoryColors = {
    'recycle': Color(0xFF00FF99),
    'organic': Color(0xFF00B2FF),
    'landfill': Color(0xFF9E9E9E),
    'ewaste': Color(0xFFFF8C42),
    'hazardous': Color(0xFF9B59B6),
  };

  static const Map<String, String> _detectionSourceLabels = {
    'combined': 'ML+IMG',
    'image_labeling': 'IMG',
    'manual': 'MANUAL',
    'ml_detection': 'ML',
  };

  static const Map<String, Color> _detectionSourceColors = {
    'combined': Colors.purple,
    'image_labeling': Colors.blue,
    'manual': Colors.orange,
    'ml_detection': Colors.green,
  };

  // Confidence thresholds used across helpers
  static const double _confidenceHigh = 0.8;
  static const double _confidenceMedium = 0.6;

  // --- State ---
  BinInfo? _currentBin;
  int _consecutiveCorrectDisposals = 0;
  double _sessionAccuracy = 1.0;

  // --- Public API: Disposal flow ------------------------------------------------

  void setCurrentBin(BinInfo? binInfo) {
    _currentBin = binInfo;
    _log('Current bin set: ${binInfo?.binId ?? 'none'}');
  }

  /// Validate which items are disposable in `binInfo` and return a
  /// DisposalResult if any disposals are possible. Returns null if none.
  DisposalResult? validateDisposal(
    List<InventoryItem> inventoryItems,
    BinInfo binInfo,
  ) {
    if (inventoryItems.isEmpty) {
      _log('No items provided for disposal validation', level: LogLevel.warn);
      return null;
    }

    final disposableItems = inventoryItems
        .where((i) => i.category == binInfo.category.id)
        .toList();

    if (disposableItems.isEmpty) {
      _log(
        'No matching items to dispose in ${binInfo.category.id} bin',
        level: LogLevel.warn,
      );
      return null;
    }

    for (final item in disposableItems) {
      _logItemDetectionHistory(item);
    }

    final result = _createDisposalResult(disposableItems, binInfo);
    _updateStatistics(result);

    _log(
      'Disposal validated: ${result.itemsDisposed.length} items, ${result.pointsEarned} points',
    );

    return result;
  }

  /// Confirm disposal: creates metadata, logs audit trail and updates stats.
  /// Returns true on success, false on failure.
  Future<bool> confirmDisposal(
    List<InventoryItem> items,
    BinInfo binInfo,
  ) async {
    try {
      final matching = items
          .where((i) => i.category == binInfo.category.id)
          .toList();
      if (matching.isEmpty) {
        _log(
          'No matching items for disposal confirmation',
          level: LogLevel.warn,
        );
        return false;
      }

      final validItems = <InventoryItem>[];
      for (final item in matching) {
        if (_hasValidBasicMetadata(item)) {
          validItems.add(item);
        } else {
          _log(
            'Item ${item.objectId} has invalid data; skipping',
            level: LogLevel.warn,
          );
        }
      }

      if (validItems.isEmpty) {
        _log(
          'No items with valid metadata for disposal confirmation',
          level: LogLevel.warn,
        );
        return false;
      }

      final totalPoints = calculateDisposalPoints(validItems, binInfo);
      final pointsPerItem = (totalPoints / validItems.length).round();

      for (final item in validItems) {
        final wasCorrect = item.category == binInfo.category.id;
        final accuracyScore = _calculateItemAccuracyScore(item, binInfo);
        final metadata = createDisposalMetadata(
          item,
          binInfo,
          pointsPerItem,
          wasCorrect,
          disposalNotes: 'Confirmed disposal via ${binInfo.binId}',
          accuracyScore: accuracyScore,
        );

        // In a real implementation, you'd persist metadata (e.g. via InventoryService).
        _log('Disposal metadata prepared for ${item.objectId}: $metadata');
        _logDisposalAuditTrail(
          item,
          binInfo,
          pointsPerItem,
          wasCorrect,
          accuracyScore,
        );
      }

      _consecutiveCorrectDisposals++;
      _sessionAccuracy = (_sessionAccuracy + 1.0) / 2.0;

      _log(
        'Disposal confirmed: ${validItems.length} items. Total points: ${pointsPerItem * validItems.length}',
      );
      return true;
    } catch (e, st) {
      _log('Error confirming disposal: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  int calculateDisposalPoints(
    List<InventoryItem> disposedItems,
    BinInfo binInfo,
  ) {
    return _calculatePointsForItems(disposedItems);
  }

  void reset() {
    _currentBin = null;
    _consecutiveCorrectDisposals = 0;
    _sessionAccuracy = 1.0;
  }

  Map<String, dynamic> getDebugInfo() => {
    'current_bin': _currentBin?.binId,
    'bin_category': _currentBin?.category.id,
    'consecutive_correct_disposals': _consecutiveCorrectDisposals,
    'session_accuracy': _sessionAccuracy,
  };

  String getDisposalSummary(List<InventoryItem> items, BinInfo binInfo) {
    final buffer = StringBuffer()
      ..writeln('Disposal Summary for ${binInfo.binId}:')
      ..writeln('Bin Category: ${binInfo.category.id}')
      ..writeln('Items to dispose: ${items.length}')
      ..writeln('');

    for (final item in items) {
      buffer
        ..writeln('Item: ${item.objectId}')
        ..writeln('  Display Name: ${item.displayName}')
        ..writeln(
          '  Original Label: ${_safe(() => item.getOriginalDetectionLabel(), fallback: 'unknown')}',
        )
        ..writeln('  Category: ${item.category}')
        ..writeln(
          '  Detection Confidence: ${(_safe(() => item.getCategoryConfidence(), fallback: item.confidence) * 100).toStringAsFixed(1)}%',
        )
        ..writeln(
          '  Detection Source: ${_safe(() => item.getDetectionSource().value, fallback: 'unknown')}',
        )
        ..writeln(
          '  Categorization Reasoning: ${_safe(() => item.getCategorizationReasoning(), fallback: '')}',
        );

      final imageLabels = _safe(
        () => item.getImageLabels(),
        fallback: <ImageLabel>[],
      );
      if (imageLabels.isNotEmpty) {
        buffer.writeln(
          '  Image Labels: ${imageLabels.map((l) => '${l.text}(${(l.confidence * 100).toStringAsFixed(1)}%)').join(', ')}',
        );
      }

      buffer.writeln(
        '  Correct Disposal: ${item.category == binInfo.category.id ? 'Yes' : 'No'}',
      );
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Map<String, dynamic> createDisposalMetadata(
    InventoryItem item,
    BinInfo binInfo,
    int pointsAwarded,
    bool wasCorrectDisposal, {
    String? disposalNotes,
    double? accuracyScore,
  }) {
    return _addDisposalMetadata(
      item,
      binInfo,
      pointsAwarded,
      wasCorrectDisposal,
      disposalNotes: disposalNotes,
      accuracyScore: accuracyScore,
    );
  }

  void dispose() {
    _log('Disposing disposal handling service...');
    reset();
    _log('Disposal handling service disposed');
  }

  // --- Private / helper methods (DRY implementations) -------------------------

  DisposalResult _createDisposalResult(
    List<InventoryItem> items,
    BinInfo binInfo,
  ) {
    final points = _calculatePointsForItems(items);
    return DisposalResult(
      binInfo: binInfo,
      itemsDisposed: items,
      pointsEarned: points,
      streakCount: _consecutiveCorrectDisposals + 1,
      accuracy: _sessionAccuracy,
      disposalTime: DateTime.now(),
      bonusMultiplier: _calculateBonusMultiplier(),
    );
  }

  int _calculatePointsForItems(List<InventoryItem> items) {
    var total = 0;
    for (final item in items) {
      total += _categoryPoints[item.category] ?? 5;
    }

    // Streak bonus
    if (_consecutiveCorrectDisposals > 0) {
      final multiplier = 1.0 + (_consecutiveCorrectDisposals * 0.1);
      total = (total * multiplier).round();
    }

    return total;
  }

  double _calculateBonusMultiplier() {
    var multiplier = 1.0;

    if (_consecutiveCorrectDisposals >= 5) {
      multiplier += 1.0;
    } else if (_consecutiveCorrectDisposals >= 3) {
      multiplier += 0.5;
    } else if (_consecutiveCorrectDisposals >= 2) {
      multiplier += 0.2;
    }

    if (_sessionAccuracy >= 0.9) {
      multiplier += 0.3;
    } else if (_sessionAccuracy >= 0.8) {
      multiplier += 0.1;
    }

    return multiplier;
  }

  Map<String, dynamic> _addDisposalMetadata(
    InventoryItem item,
    BinInfo binInfo,
    int pointsAwarded,
    bool wasCorrectDisposal, {
    String? disposalNotes,
    double? accuracyScore,
  }) {
    final base = item.metadata ?? <String, dynamic>{};
    return {
      ...base,
      'disposal': {
        'binId': binInfo.binId,
        'binCategory': binInfo.category.id,
        'pointsAwarded': pointsAwarded,
        'wasCorrectDisposal': wasCorrectDisposal,
        'disposalNotes': disposalNotes ?? 'Disposal completed',
        'accuracyScore': accuracyScore ?? 1.0,
        'disposalTime': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Extracts detection info with safe fallbacks. Keeps logic in one place.
  Map<String, dynamic> extractDetectionInfo(InventoryItem item) {
    final metadata = item.metadata;
    // Default values based on InventoryItem's accessors
    var source = _safe(
      () => item.getDetectionSource().value,
      fallback: 'ml_detection',
    );
    var imageLabels = <Map<String, dynamic>>[];
    var reasoning = _safe(
      () => item.getCategorizationReasoning(),
      fallback: 'Auto-categorized from detection',
    );
    var confidence = _safe(
      () => item.getCategoryConfidence(),
      fallback: item.confidence,
    );

    if (metadata != null) {
      try {
        final detection = metadata['detection'] as Map<String, dynamic>?;
        if (detection != null) {
          final s = detection['source'];
          if (s is Map && s['value'] is String) {
            source = s['value'] as String;
          }
          final labels = detection['imageLabels'];
          if (labels is List) {
            imageLabels = labels.map<Map<String, dynamic>>((l) {
              if (l is Map<String, dynamic>) return l;
              return {'text': l.toString(), 'confidence': 0.0};
            }).toList();
          }
        }

        final categorization =
            metadata['categorization'] as Map<String, dynamic>?;
        if (categorization != null) {
          reasoning = (categorization['reasoning'] as String?) ?? reasoning;
          final catConf = categorization['categoryConfidence'];
          if (catConf is num) confidence = catConf.toDouble();
        }
      } catch (e, st) {
        _log('Failed to extract detection info: $e\n$st', level: LogLevel.warn);
      }
    }

    return {
      'source': source,
      'imageLabels': imageLabels,
      'reasoning': reasoning,
      'confidence': confidence,
    };
  }

  Map<String, dynamic> detectionSourceInfo(String? source) {
    final key = (source ?? '').toLowerCase();
    final label =
        _detectionSourceLabels[key] ?? _detectionSourceLabels['ml_detection']!;
    final color =
        _detectionSourceColors[key] ?? _detectionSourceColors['ml_detection']!;
    return {'label': label, 'color': color};
  }

  // Backwards compatibility adapter used by older/UI code that expects this name.
  Map<String, dynamic> getDetectionSourceInfo(String? source) =>
      detectionSourceInfo(source);

  /// Compatibility wrapper: validate items metadata and log results.
  /// Many parts of the UI call `validateItemsMetadata` on the service. This
  /// method delegates to the existing `extractDetectionInfo` logic and logs
  /// friendly messages. Keeps behavior consistent with previous implementation.
  void validateItemsMetadata(List<InventoryItem> items) {
    for (final item in items) {
      try {
        final detectionInfo = extractDetectionInfo(item);
        _log(
          'Item ${item.displayName} metadata validation passed',
          level: LogLevel.info,
        );
        _log(
          ' - Detection source: ${detectionInfo['source']}',
          level: LogLevel.debug,
        );
        _log(
          ' - Image labels count: ${(detectionInfo['imageLabels'] as List).length}',
          level: LogLevel.debug,
        );
        _log(
          ' - Has reasoning: ${(detectionInfo['reasoning'] as String).isNotEmpty}',
          level: LogLevel.debug,
        );
        _log(
          ' - Confidence: ${detectionInfo['confidence']}',
          level: LogLevel.debug,
        );
      } catch (e) {
        _log(
          'Item ${item.displayName} metadata validation failed: $e',
          level: LogLevel.warn,
        );
      }
    }
  }

  Color getConfidenceColor(double confidence) {
    if (confidence >= _confidenceHigh) return Colors.green;
    if (confidence >= _confidenceMedium) return Colors.orange;
    return Colors.red;
  }

  String getConfidenceText(double confidence) {
    final pct = (confidence * 100).toStringAsFixed(0);
    if (confidence >= _confidenceHigh) return 'High ($pct%)';
    if (confidence >= _confidenceMedium) return 'Medium ($pct%)';
    return 'Low ($pct%)';
  }

  IconData getConfidenceIcon(double confidence) {
    if (confidence >= _confidenceHigh) return Icons.check_circle;
    if (confidence >= _confidenceMedium) return Icons.warning;
    return Icons.error;
  }

  Color getCategoryColor(String category) =>
      _categoryColors[category] ?? Colors.grey;
  String getCategoryDisplayName(String category) =>
      _categoryDisplayNames[category] ?? category.toUpperCase();

  int calculatePointsForItemsUI(List<InventoryItem> items) =>
      _calculatePointsForItems(items);

  void _logItemDetectionHistory(InventoryItem item) {
    _log('Detection History for ${item.objectId}:');
    _log(
      '  Original Label: ${_safe(() => item.getOriginalDetectionLabel(), fallback: 'unknown')}',
    );
    _log('  Category: ${item.category}');
    _log(
      '  Detection Source: ${_safe(() => item.getDetectionSource().value, fallback: 'unknown')}',
    );
    _log(
      '  Confidence: ${(_safe(() => item.getCategoryConfidence(), fallback: item.confidence) * 100).toStringAsFixed(1)}%',
    );
    _log(
      '  Reasoning: ${_safe(() => item.getCategorizationReasoning(), fallback: '')}',
    );

    final imageLabels = _safe(
      () => item.getImageLabels(),
      fallback: <ImageLabel>[],
    );
    if (imageLabels.isNotEmpty) {
      _log(
        '  Image Labels: ${imageLabels.map((l) => '${l.text}(${(l.confidence * 100).toStringAsFixed(1)}%)').join(', ')}',
      );
    }

    if (item.hasDisposalInfo) {
      final disposal = item.disposalInfo!;
      _log(
        '  Previous Disposal: ${disposal['binCategory']} bin (${disposal['pointsAwarded']} points)',
      );
    }
  }

  void _logDisposalAuditTrail(
    InventoryItem item,
    BinInfo binInfo,
    int pointsAwarded,
    bool wasCorrectDisposal,
    double accuracyScore,
  ) {
    _log('Disposal Audit Trail:');
    _log('  Item ID: ${item.objectId}');
    _log(
      '  Original Label: ${_safe(() => item.getOriginalDetectionLabel(), fallback: 'unknown')}',
    );
    _log('  Detected Category: ${item.category}');
    _log('  Disposal Bin: ${binInfo.binId} (${binInfo.category.id})');
    _log('  Points Awarded: $pointsAwarded');
    _log('  Correct Disposal: $wasCorrectDisposal');
    _log('  Accuracy Score: ${(accuracyScore * 100).toStringAsFixed(1)}%');
    _log(
      '  Detection Source: ${_safe(() => item.getDetectionSource().value, fallback: 'unknown')}',
    );
    _log(
      '  Categorization Reasoning: ${_safe(() => item.getCategorizationReasoning(), fallback: '')}',
    );
    _log('  Timestamp: ${DateTime.now().toIso8601String()}');
  }

  double _calculateItemAccuracyScore(InventoryItem item, BinInfo binInfo) {
    var score = 0.0;

    if (item.category == binInfo.category.id) score += 0.6;

    final confidence = _safe(
      () => item.getCategoryConfidence(),
      fallback: item.confidence,
    );
    if (confidence >= _confidenceHigh) {
      score += 0.2;
    } else if (confidence >= _confidenceMedium) {
      score += 0.1;
    }

    final imageLabels = _safe(
      () => item.getImageLabels(),
      fallback: <ImageLabel>[],
    );
    if (imageLabels.isNotEmpty) {
      final hasRelevant = imageLabels.any((label) {
        final text = label.text.toLowerCase();
        return text.contains(item.category.toLowerCase()) ||
            _safe(
              () => item.getCategorizationReasoning().toLowerCase(),
              fallback: '',
            ).contains(text);
      });
      if (hasRelevant) score += 0.1;
    }

    if (_safe(
      () => item.getDetectionSource() == DetectionSource.combined,
      fallback: false,
    )) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  // --- Utilities ---------------------------------------------------------------

  bool _hasValidBasicMetadata(InventoryItem item) {
    return (item.label.isNotEmpty || (item.displayName.isNotEmpty)) &&
        (item.category.isNotEmpty);
  }

  R _safe<R>(R Function() fn, {required R fallback}) {
    try {
      final res = fn();
      return res;
    } catch (_) {
      return fallback;
    }
  }

  void _updateStatistics(DisposalResult result) {
    _consecutiveCorrectDisposals++;
    _sessionAccuracy = (_sessionAccuracy + 1.0) / 2.0;
  }

  void _log(String message, {LogLevel level = LogLevel.info}) {
    final prefixes = {
      LogLevel.info: '✅',
      LogLevel.debug: '🔍',
      LogLevel.warn: '⚠️',
      LogLevel.error: '❌',
    };
    final prefix = prefixes[level] ?? 'ℹ️';
    // Keep logging simple; replace with structured logger if available.
    print('$prefix [$_logTag] $message');
  }
}

enum LogLevel { info, debug, warn, error }

/// Simplified result of a disposal validation/reflection.
/// Kept minimal; consumers can expand as needed.
class DisposalResult {
  final BinInfo binInfo;
  final List<InventoryItem> itemsDisposed;
  final int pointsEarned;
  final int streakCount;
  final double accuracy;
  final DateTime disposalTime;
  final double bonusMultiplier;

  const DisposalResult({
    required this.binInfo,
    required this.itemsDisposed,
    required this.pointsEarned,
    required this.streakCount,
    required this.accuracy,
    required this.disposalTime,
    required this.bonusMultiplier,
  });

  String getDisposalSummary() {
    final buffer = StringBuffer()
      ..writeln('Disposal Summary:')
      ..writeln('Bin: ${binInfo.binId} (${binInfo.category.id})')
      ..writeln('Items disposed: ${itemsDisposed.length}')
      ..writeln('Points earned: $pointsEarned')
      ..writeln('Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%')
      ..writeln('');

    for (final item in itemsDisposed) {
      buffer
        ..writeln('Item: ${item.id}')
        ..writeln('  Label: ${item.label}')
        ..writeln('  Category: ${item.category}')
        ..writeln(
          '  Confidence: ${(item.confidence * 100).toStringAsFixed(1)}%',
        )
        ..writeln('');
    }

    return buffer.toString();
  }

  /// Compatibility helper: return the original detection label for an item id.
  /// Falls back to the first disposed item if the id is not found.
  String getOriginalLabel(String itemId) {
    if (itemsDisposed.isEmpty) return 'Unknown';
    final item = itemsDisposed.firstWhere(
      (item) => item.id == itemId,
      orElse: () => itemsDisposed.first,
    );
    return item.getOriginalDetectionLabel();
  }

  /// Compatibility helper: return detection confidence for an item id.
  /// Falls back to the first disposed item if the id is not found.
  double getDetectionConfidence(String itemId) {
    if (itemsDisposed.isEmpty) return 0.0;
    final item = itemsDisposed.firstWhere(
      (item) => item.id == itemId,
      orElse: () => itemsDisposed.first,
    );
    return item.getCategoryConfidence();
  }

  /// Compatibility helper: return image labels for an item id.
  /// Falls back to the first disposed item if the id is not found.
  List<ImageLabel> getImageLabels(String itemId) {
    if (itemsDisposed.isEmpty) return <ImageLabel>[];
    final item = itemsDisposed.firstWhere(
      (item) => item.id == itemId,
      orElse: () => itemsDisposed.first,
    );
    return item.getImageLabels();
  }

  @override
  String toString() {
    return 'DisposalResult(bin: ${binInfo.binId}, items: ${itemsDisposed.length}, points: $pointsEarned, streak: $streakCount)';
  }
}
