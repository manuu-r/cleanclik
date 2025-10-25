import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/services/business/database_helper.dart';
import 'package:cleanclik/core/services/camera/waste_categorizer.dart';
import 'package:cleanclik/core/services/data/local_storage_service.dart';

part 'inventory_service.g.dart';

sealed class InventoryEvent {
  const InventoryEvent();
}

class ItemAddedEvent extends InventoryEvent {
  final InventoryItem item;
  const ItemAddedEvent(this.item);
}

class ItemRemovedEvent extends InventoryEvent {
  final String itemId;
  const ItemRemovedEvent(this.itemId);
}

class ItemUpdatedEvent extends InventoryEvent {
  final String itemId;
  const ItemUpdatedEvent(this.itemId);
}

enum DetectionSource {
  mlKit,
  combined;

  String get value {
    switch (this) {
      case DetectionSource.mlKit:
        return 'mlKit';
      case DetectionSource.combined:
        return 'combined';
    }
  }
}

String _generateUuid() {
  final chars = '0123456789abcdef';
  return '${_randomString(8, chars)}-${_randomString(4, chars)}-${_randomString(4, chars)}-${_randomString(4, chars)}-${_randomString(12, chars)}';
}

String _randomString(int length, String chars) {
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

class InventoryItem {
  final String id;
  final String displayName;
  final String category;
  final double confidence;
  final DateTime timestamp;

  const InventoryItem({
    required this.id,
    required this.displayName,
    required this.category,
    required this.confidence,
    required this.timestamp,
  });

  String get trackingId => id;
  String get objectId => id;
  String get label => displayName;
  Map<String, dynamic>? get metadata => null;

  String getOriginalDetectionLabel() => displayName;
  double getCategoryConfidence() => confidence;
  String getCategorizationReasoning() =>
      'Detected as $category with ${(confidence * 100).toStringAsFixed(1)}% confidence';
  DetectionSource getDetectionSource() => DetectionSource.mlKit;
  List<ImageLabel> getImageLabels() => [];
  bool get hasDisposalInfo => false;
  Map<String, dynamic>? get disposalInfo => null;

  factory InventoryItem.fromDetectedObject(DetectedObject detectedObject) {
    final wasteCategorizer = WasteCategorizer.instance;

    final detectionLabel = detectedObject.codeName.isNotEmpty
        ? detectedObject.codeName
        : detectedObject.category;

    String validatedCategory;

    if (detectedObject.imageLabels.isNotEmpty) {
      final wasteCategory = wasteCategorizer.categorize(
        detectedObject.imageLabels,
      );

      if (wasteCategory != null) {
        validatedCategory = wasteCategory.id;
        debugPrint(
          '✅ [INVENTORY_ITEM] Image labels categorized: "${detectedObject.imageLabelsDebugString}" → "$validatedCategory"',
        );
      } else {
        validatedCategory = 'landfill';
        debugPrint(
          '⚠️ [INVENTORY_ITEM] No categorization found for "$detectionLabel", defaulting to landfill',
        );
      }
    } else {
      validatedCategory = 'landfill';
      debugPrint(
        '⚠️ [INVENTORY_ITEM] No image labels for "$detectionLabel", defaulting to landfill',
      );
    }

    return InventoryItem(
      id: _generateUuid(),
      displayName: detectionLabel,
      category: validatedCategory,
      confidence: detectedObject.confidence,
      timestamp: DateTime.now(),
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? json['label'] as String,
      category: json['category'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'category': category,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'display_name': displayName,
      'category': category,
      'confidence': confidence,
      'picked_up_at': timestamp.toIso8601String(),
    };
  }

  factory InventoryItem.fromDatabaseRow(Map<String, dynamic> row) {
    return InventoryItem(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      category: row['category'] as String,
      confidence: (row['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(row['picked_up_at'] as String),
    );
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, displayName: $displayName, category: $category, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@Riverpod(keepAlive: true)
class InventoryService extends _$InventoryService {
  static const String _logTag = 'INVENTORY_SERVICE';

  List<InventoryItem> _inventory = [];
  bool _isInitialized = false;

  final StreamController<InventoryEvent> _eventsController =
      StreamController<InventoryEvent>.broadcast();

  Stream<InventoryEvent> get eventsStream => _eventsController.stream;

  final LocalStorageService _storageService = LocalStorageService.instance;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  InventoryService build() {
    ref.onDispose(() async {
      await dispose();
    });

    _initialize();
    return this;
  }

  List<InventoryItem> get inventory => List.unmodifiable(_inventory);

  int get itemCount => _inventory.length;

  bool get isEmpty => _inventory.isEmpty;

  bool get hasItems => _inventory.isNotEmpty;

  List<String> get inventoryCategories {
    return _inventory.map((item) => item.category).toSet().toList();
  }

  Map<String, dynamic> getInventorySummary() {
    return {
      'total_items': _inventory.length,
      'categories': inventoryCategories,
      'items_by_category': {
        for (var category in inventoryCategories)
          category: getItemsByCategory(category).length,
      },
    };
  }

  void logInventoryState(String context) {
    if (kDebugMode) {
      debugPrint('📦 [$_logTag] $context:');
      debugPrint('  Total items: ${_inventory.length}');
      debugPrint('  Categories: $inventoryCategories');
      debugPrint(
        '  Items: ${_inventory.map((i) => '${i.displayName} (${i.category})').join(', ')}',
      );
    }
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      await _loadFromLocalStorage();

      await _syncWithDatabase();

      _isInitialized = true;
      debugPrint('✅ [$_logTag] Service initialized successfully');
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to initialize: $e');
      _isInitialized = true;
    }
  }

  Future<void> _syncWithDatabase() async {
    if (!_databaseHelper.isAuthenticated) {
      debugPrint(
        '⚠️ [$_logTag] User not authenticated, skipping database sync',
      );
      return;
    }

    try {
      await _databaseHelper.syncPendingOperations();

      final userId = _databaseHelper.currentUserId!;
      final databaseItems = await _databaseHelper.read(
        'inventory',
        userId: userId,
      );

      if (databaseItems.isNotEmpty) {
        final dbInventoryItems = databaseItems.map((data) {
          return InventoryItem.fromDatabaseRow(data);
        }).toList();

        final localItemIds = _inventory.map((item) => item.id).toSet();
        final newItems = dbInventoryItems
            .where((item) => !localItemIds.contains(item.id))
            .toList();

        if (newItems.isNotEmpty) {
          _inventory.addAll(newItems);
          await _saveToLocalStorage();
          ref.notifyListeners();
          debugPrint(
            '✅ [$_logTag] Synced ${newItems.length} items from database',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to sync with database: $e');
    }
  }

  Future<void> syncWhenOnline() async {
    try {
      await _syncWithDatabase();
      debugPrint('✅ [$_logTag] Manual sync completed');
    } catch (e) {
      debugPrint('❌ [$_logTag] Manual sync failed: $e');
    }
  }

  List<InventoryItem> getItemsByCategory(String category) {
    return _inventory.where((item) => item.category == category).toList();
  }

  InventoryItem? getItemById(String itemId) {
    try {
      return _inventory.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final item in _inventory) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> addItemFromDetectedObject(DetectedObject detectedObject) async {
    try {
      final item = InventoryItem.fromDetectedObject(detectedObject);
      await addItem(item);
      debugPrint(
        '✅ [$_logTag] Item added from DetectedObject: ${item.displayName}',
      );
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to add item from DetectedObject: $e');
      rethrow;
    }
  }

  Future<void> addItemFromPickupEvent(dynamic event) async {
    try {
      final item = InventoryItem(
        id: event.itemId,
        displayName: event.codeName,
        category: event.category,
        confidence: event.confidence,
        timestamp: DateTime.now(),
      );
      await addItem(item);
      debugPrint(
        '✅ [$_logTag] Item added from PickupEvent: ${item.displayName}',
      );
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to add item from PickupEvent: $e');
      rethrow;
    }
  }

  Future<void> addItem(InventoryItem item) async {
    try {
      if (_inventory.any((existingItem) => existingItem.id == item.id)) {
        debugPrint('⚠️ [$_logTag] Item already exists: ${item.id}');
        return;
      }

      _inventory.add(item);
      await _saveToLocalStorage();
      ref.notifyListeners();

      _eventsController.add(ItemAddedEvent(item));

      if (_databaseHelper.isAuthenticated) {
        final userId = _databaseHelper.currentUserId!;
        final data = {
          'id': item.id,
          'user_id': userId,
          'tracking_id': item.id,
          'display_name': item.displayName,
          'code_name': item.displayName,
          'category': item.category,
          'confidence': item.confidence,
          'picked_up_at': item.timestamp.toIso8601String(),
          'created_at': item.timestamp.toIso8601String(),
        };

        final result = await _databaseHelper.create('inventory', data);
        if (result != null) {
          debugPrint('✅ [$_logTag] Item saved to database: ${item.id}');
        } else {
          debugPrint(
            '⚠️ [$_logTag] Failed to save to database, using local storage only',
          );
        }
      }

      debugPrint(
        '✅ [$_logTag] Item added: ${item.displayName} (${item.category})',
      );
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to add item: $e');
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      _inventory.removeWhere((item) => item.id == itemId);
      await _saveToLocalStorage();
      ref.notifyListeners();

      _eventsController.add(ItemRemovedEvent(itemId));

      if (_databaseHelper.isAuthenticated) {
        final success = await _databaseHelper.deleteById('inventory', itemId);
        if (success) {
          debugPrint('✅ [$_logTag] Item removed from database: $itemId');
        } else {
          debugPrint(
            '⚠️ [$_logTag] Failed to remove from database, local removal successful',
          );
        }
      }

      debugPrint('✅ [$_logTag] Item removed: $itemId');
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to remove item: $e');
    }
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      final index = _inventory.indexWhere((item) => item.id == itemId);
      if (index == -1) {
        debugPrint('⚠️ [$_logTag] Item not found: $itemId');
        return;
      }

      await _saveToLocalStorage();
      ref.notifyListeners();

      _eventsController.add(ItemUpdatedEvent(itemId));

      if (_databaseHelper.isAuthenticated) {
        final result = await _databaseHelper.update(
          'inventory',
          itemId,
          updates,
        );
        if (result != null) {
          debugPrint('✅ [$_logTag] Item updated in database: $itemId');
        } else {
          debugPrint(
            '⚠️ [$_logTag] Failed to update in database, local update successful',
          );
        }
      }

      debugPrint('✅ [$_logTag] Item updated: $itemId');
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to update item: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final inventoryData = await _storageService.getInventoryItems();
      _inventory = inventoryData
          .map((json) => InventoryItem.fromJson(json))
          .toList();

      debugPrint(
        '✅ [$_logTag] Loaded ${_inventory.length} items from centralized storage',
      );
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to load from centralized storage: $e');
      _inventory = [];
    }
  }

  Future<void> _saveToLocalStorage() async {
    try {
      final inventoryData = _inventory.map((item) => item.toJson()).toList();
      final success = await _storageService.setInventoryItems(inventoryData);

      if (success) {
        debugPrint(
          '✅ [$_logTag] Saved ${_inventory.length} items to centralized storage',
        );
      } else {
        debugPrint('❌ [$_logTag] Failed to save to centralized storage');
      }
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to save to centralized storage: $e');
    }
  }

  Future<bool> removeItemByTrackingId(String trackingId) async {
    try {
      await removeItem(trackingId);
      return true;
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to remove item by tracking ID: $e');
      return false;
    }
  }

  Future<void> removeItems(List<String> itemIds) async {
    for (final itemId in itemIds) {
      await removeItem(itemId);
    }
  }

  Future<void> ensureLoaded() async {
    await _initialize();
  }

  Future<void> clearInventory() async {
    _inventory.clear();
    await _saveToLocalStorage();
    ref.notifyListeners();
    debugPrint('🗑️ [$_logTag] Inventory cleared');
  }

  Future<void> dispose() async {
    try {
      await _saveToLocalStorage();
      await _eventsController.close();
      debugPrint('✅ [$_logTag] Service disposed');
    } catch (e) {
      debugPrint('❌ [$_logTag] Error during disposal: $e');
    }
  }
}
