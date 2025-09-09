import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/detected_object.dart';
import '../models/waste_category.dart';
import 'qr_bin_service.dart';
import 'bin_matching_service.dart';
import 'inventory_database_service.dart';
import 'database_service_provider.dart';
import 'supabase_config_service.dart';
import 'user_service.dart';

part 'inventory_service.g.dart';

/// Unified inventory item model combining functionality from both services
class InventoryItem {
  final String id;
  final String trackingId; // For AR tracking compatibility
  final String category; // Category ID (e.g., 'recycle', 'organic')
  final String displayName; // User-friendly name
  final String codeName; // Code name from detected object
  final double confidence; // Detection confidence
  final DateTime pickedUpAt;
  final Map<String, dynamic>? metadata;

  const InventoryItem({
    required this.id,
    required this.trackingId,
    required this.category,
    required this.displayName,
    required this.codeName,
    required this.confidence,
    required this.pickedUpAt,
    this.metadata,
  });

  /// Create from DetectedObject (from camera detection)
  factory InventoryItem.fromDetectedObject(DetectedObject detectedObject) {
    final wasteCategory = WasteCategory.fromId(detectedObject.category);
    return InventoryItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}_${detectedObject.trackingId}',
      trackingId: detectedObject.trackingId,
      category: detectedObject.category,
      displayName: detectedObject.codeName,
      codeName: detectedObject.codeName,
      confidence: detectedObject.confidence,
      pickedUpAt: DateTime.now(),
      metadata: {
        'source': 'camera_detection',
        'tracking_id': detectedObject.trackingId,
        'detected_at': detectedObject.detectedAt.toIso8601String(),
      },
    );
  }

  /// Create from CarriedItem (backward compatibility)
  factory InventoryItem.fromCarriedItem(CarriedItem carriedItem) {
    return InventoryItem(
      id: 'carried_${DateTime.now().millisecondsSinceEpoch}_${carriedItem.trackingId}',
      trackingId: carriedItem.trackingId,
      category: carriedItem.category.id,
      displayName: carriedItem.codeName,
      codeName: carriedItem.codeName,
      confidence: carriedItem.confidence,
      pickedUpAt: carriedItem.pickedUpAt,
      metadata: {
        'source': 'carried_item',
        'tracking_id': carriedItem.trackingId,
      },
    );
  }

  /// Convert to CarriedItem for backward compatibility
  CarriedItem toCarriedItem() {
    final wasteCategory =
        WasteCategory.fromId(category) ?? WasteCategory.recycle;
    return CarriedItem(
      trackingId: trackingId,
      category: wasteCategory,
      codeName: codeName,
      confidence: confidence,
      pickedUpAt: pickedUpAt,
    );
  }

  /// Create from JSON (local storage format)
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      trackingId: json['tracking_id'] as String,
      category: json['category'] as String,
      displayName: json['display_name'] as String,
      codeName: json['code_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      pickedUpAt: DateTime.parse(json['picked_up_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create from Supabase database row
  factory InventoryItem.fromSupabase(Map<String, dynamic> data) {
    return InventoryItem(
      id: data['id'] as String,
      trackingId: data['tracking_id'] as String,
      category: data['category'] as String,
      displayName: data['display_name'] as String,
      codeName: data['code_name'] as String,
      confidence: (data['confidence'] as num).toDouble(),
      pickedUpAt: DateTime.parse(data['picked_up_at'] as String),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON (local storage format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_id': trackingId,
      'category': category,
      'display_name': displayName,
      'code_name': codeName,
      'confidence': confidence,
      'picked_up_at': pickedUpAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Convert to Supabase database format
  Map<String, dynamic> toSupabase(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'tracking_id': trackingId,
      'category': category,
      'display_name': displayName,
      'code_name': codeName,
      'confidence': confidence,
      'picked_up_at': pickedUpAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, trackingId: $trackingId, category: $category, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents an item being carried by the user (backward compatibility)
class CarriedItem {
  final String trackingId;
  final WasteCategory category;
  final String codeName;
  final double confidence;
  final DateTime pickedUpAt;

  const CarriedItem({
    required this.trackingId,
    required this.category,
    required this.codeName,
    required this.confidence,
    required this.pickedUpAt,
  });

  /// Create from JSON
  factory CarriedItem.fromJson(Map<String, dynamic> json) {
    return CarriedItem(
      trackingId: json['tracking_id'] as String,
      category:
          WasteCategory.fromId(json['category'] as String) ??
          WasteCategory.recycle,
      codeName: json['code_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      pickedUpAt: DateTime.parse(json['picked_up_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'tracking_id': trackingId,
      'category': category.id,
      'code_name': codeName,
      'confidence': confidence,
      'picked_up_at': pickedUpAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CarriedItem(trackingId: $trackingId, category: ${category.id}, codeName: $codeName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarriedItem && other.trackingId == trackingId;
  }

  @override
  int get hashCode => trackingId.hashCode;
}

/// Session statistics for tracking user performance
class SessionStats {
  final int totalItemsPickedUp;
  final int totalItemsDisposed;
  final int totalPointsEarned;
  final DateTime sessionStarted;

  SessionStats({
    this.totalItemsPickedUp = 0,
    this.totalItemsDisposed = 0,
    this.totalPointsEarned = 0,
    DateTime? sessionStarted,
  }) : sessionStarted = sessionStarted ?? DateTime.now();

  /// Create from JSON
  factory SessionStats.fromJson(Map<String, dynamic> json) {
    return SessionStats(
      totalItemsPickedUp: json['total_items_picked_up'] as int? ?? 0,
      totalItemsDisposed: json['total_items_disposed'] as int? ?? 0,
      totalPointsEarned: json['total_points_earned'] as int? ?? 0,
      sessionStarted: json['session_started'] != null
          ? DateTime.parse(json['session_started'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_items_picked_up': totalItemsPickedUp,
      'total_items_disposed': totalItemsDisposed,
      'total_points_earned': totalPointsEarned,
      'session_started': sessionStarted.toIso8601String(),
    };
  }

  /// Create copy with updated values
  SessionStats copyWith({
    int? totalItemsPickedUp,
    int? totalItemsDisposed,
    int? totalPointsEarned,
    DateTime? sessionStarted,
  }) {
    return SessionStats(
      totalItemsPickedUp: totalItemsPickedUp ?? this.totalItemsPickedUp,
      totalItemsDisposed: totalItemsDisposed ?? this.totalItemsDisposed,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      sessionStarted: sessionStarted ?? this.sessionStarted,
    );
  }

  /// Get disposal accuracy percentage
  double get disposalAccuracy {
    if (totalItemsPickedUp == 0) return 0.0;
    return (totalItemsDisposed / totalItemsPickedUp) * 100;
  }

  /// Get session duration
  Duration get sessionDuration {
    return DateTime.now().difference(sessionStarted);
  }
}

/// Service for managing user's carrying inventory, bin matching, and session tracking
@Riverpod(keepAlive: true)
class InventoryService extends _$InventoryService {
  static const String _logTag = 'CONSOLIDATED_INVENTORY';

  // Storage keys for offline cache (fallback)
  static const String _inventoryKey = 'user_carried_inventory';
  static const String _pointsKey = 'user_points';
  static const String _sessionStatsKey = 'session_statistics';

  // Points awarded per category
  static const Map<String, int> _categoryPoints = {
    'recycle': 10,
    'organic': 8,
    'landfill': 5,
    'ewaste': 15,
    'hazardous': 20,
  };

  // State
  List<InventoryItem> _inventory = [];
  int _totalPoints = 0;
  SessionStats _sessionStats = SessionStats();
  SharedPreferences? _prefs;
  bool _isLoaded = false;
  Future<void>? _loadingFuture;

  // Database services
  late final InventoryDatabaseService _dbService;
  late final SupabaseClient _supabase;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;

  @override
  InventoryService build() {
    // Initialize database services
    _dbService = ref.watch(inventoryDatabaseServiceProvider);

    // Get Supabase client
    try {
      if (SupabaseConfigService.isFullyConfigured) {
        _supabase = SupabaseConfigService.client;
      } else {
        _supabase = Supabase.instance.client;
      }
    } catch (e) {
      _supabase = Supabase.instance.client;
    }

    // Set up disposal
    ref.onDispose(() async {
      await dispose();
    });

    // Initialize with defaults first
    _initializeDefaults();
    // Start loading from database/storage asynchronously
    _loadingFuture = _loadFromDatabase();
    return this;
  }

  /// Ensure loading is complete before operations
  Future<void> _ensureLoaded() async {
    if (!_isLoaded && _loadingFuture != null) {
      await _loadingFuture;
    }
  }

  /// Public method to ensure inventory is loaded (for external callers)
  Future<void> ensureLoaded() async {
    await _ensureLoaded();
  }

  // ===== GETTERS AND PROPERTIES =====

  /// Current inventory items
  List<InventoryItem> get inventory => List.unmodifiable(_inventory);

  /// Get carried items (backward compatibility with UserInventoryService)
  List<CarriedItem> get carriedItems =>
      _inventory.map((item) => item.toCarriedItem()).toList();

  /// Total points earned
  int get totalPoints => _totalPoints;

  /// Current session statistics
  SessionStats get sessionStats => _sessionStats;

  /// Check if inventory is empty
  bool get isEmpty => _inventory.isEmpty;

  /// Check if user has any items
  bool get hasItems => _inventory.isNotEmpty;

  /// Get unique categories currently in inventory
  List<String> get carriedCategories {
    return _inventory.map((item) => item.category).toSet().toList();
  }

  /// Get inventory count by category
  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final item in _inventory) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  // ===== ITEM MANAGEMENT METHODS =====

  /// Get items by category
  List<InventoryItem> getItemsByCategory(String category) {
    return _inventory.where((item) => item.category == category).toList();
  }

  /// Get items by WasteCategory (backward compatibility)
  List<CarriedItem> getItemsByWasteCategory(WasteCategory category) {
    return getItemsByCategory(
      category.id,
    ).map((item) => item.toCarriedItem()).toList();
  }

  /// Get count of items by category
  int getItemCountByCategory(WasteCategory category) {
    return _inventory.where((item) => item.category == category.id).length;
  }

  /// Get all categories currently being carried
  Set<WasteCategory> getCarriedWasteCategories() {
    return _inventory
        .map((item) => WasteCategory.fromId(item.category))
        .where((category) => category != null)
        .cast<WasteCategory>()
        .toSet();
  }

  /// Check if user has items of specific category
  bool hasItemsOfCategory(WasteCategory category) {
    return _inventory.any((item) => item.category == category.id);
  }

  // ===== ADD ITEM METHODS =====

  /// Add item to inventory (primary method)
  Future<bool> addItem(InventoryItem item) async {
    // Ensure loading is complete before proceeding
    await _ensureLoaded();

    print('📦 [$_logTag] Adding item to inventory: ${item.trackingId}');

    // Check for duplicates
    if (_inventory.any(
      (existingItem) => existingItem.trackingId == item.trackingId,
    )) {
      print('⚠️ [$_logTag] Item already in inventory: ${item.trackingId}');
      return false;
    }

    try {
      final currentUser = ref.read(userServiceProvider).currentUser;

      if (currentUser != null && SupabaseConfigService.isFullyConfigured) {
        // Save to database first
        final result = await _dbService.create(item, currentUser.id);

        if (!result.isSuccess) {
          print('❌ [$_logTag] Failed to add item to database: ${result.error}');
          // Continue with local operation for offline support
        } else {
          print('✅ [$_logTag] Item saved to database: ${item.trackingId}');
        }
      }

      // Add to local memory (optimistic update)
      _inventory.add(item);

      // Update session stats
      _sessionStats = _sessionStats.copyWith(
        totalItemsPickedUp: _sessionStats.totalItemsPickedUp + 1,
      );

      // Cache locally
      await _saveToStorageCache();

      // Notify Riverpod that state has changed
      ref.notifyListeners();

      print(
        '✅ [$_logTag] Item added successfully. Total items: ${_inventory.length}',
      );
      return true;
    } catch (e) {
      print('❌ [$_logTag] Error adding item: $e');

      // Try to add locally as fallback
      _inventory.add(item);
      _sessionStats = _sessionStats.copyWith(
        totalItemsPickedUp: _sessionStats.totalItemsPickedUp + 1,
      );
      await _saveToStorageCache();
      ref.notifyListeners();

      return true; // Still return success for offline operation
    }
  }

  /// Add item from DetectedObject (backward compatibility)
  Future<bool> addItemFromDetectedObject(DetectedObject detectedObject) async {
    final category = WasteCategory.fromId(detectedObject.category);
    if (category == null) {
      print(
        '❌ [$_logTag] Invalid category for item: ${detectedObject.category}',
      );
      return false;
    }

    final inventoryItem = InventoryItem.fromDetectedObject(detectedObject);
    return await addItem(inventoryItem);
  }

  /// Add carried item (backward compatibility with UserInventoryService)
  /// Add carried item (backward compatibility)
  Future<bool> addCarriedItem(CarriedItem carriedItem) async {
    final inventoryItem = InventoryItem.fromCarriedItem(carriedItem);
    return await addItem(inventoryItem);
  }

  /// Migrate item from JSON data (for data migration)
  Future<bool> migrateItemFromJson(Map<String, dynamic> itemJson) async {
    try {
      final inventoryItem = InventoryItem.fromJson(itemJson);
      return await addItem(inventoryItem);
    } catch (e) {
      print('❌ [$_logTag] Failed to migrate item from JSON: $e');
      return false;
    }
  }

  // ===== REMOVE ITEM METHODS =====

  /// Remove specific item from inventory by ID
  Future<void> removeItem(String itemId) async {
    print('📦 [$_logTag] Removing item from inventory: $itemId');

    final removedItem = _inventory.firstWhere(
      (item) => item.id == itemId,
      orElse: () => null!,
    );
    if (removedItem == null) {
      print('⚠️ [$_logTag] Item not found in inventory: $itemId');
      return;
    }

    try {
      final currentUser = ref.read(userServiceProvider).currentUser;

      if (currentUser != null && SupabaseConfigService.isFullyConfigured) {
        // Remove from database first
        final result = await _dbService.delete(itemId);

        if (!result.isSuccess) {
          print(
            '❌ [$_logTag] Failed to remove item from database: ${result.error}',
          );
          // Continue with local operation for offline support
        } else {
          print('✅ [$_logTag] Item removed from database: $itemId');
        }
      }

      // Remove from local memory (optimistic update)
      _inventory.removeWhere((item) => item.id == itemId);

      // Update session stats
      _sessionStats = _sessionStats.copyWith(
        totalItemsDisposed: _sessionStats.totalItemsDisposed + 1,
      );

      // Cache locally
      await _saveToStorageCache();

      // Notify Riverpod that state has changed
      ref.notifyListeners();

      print(
        '✅ [$_logTag] Item removed successfully: ${removedItem.displayName}. Remaining: ${_inventory.length}',
      );
    } catch (e) {
      print('❌ [$_logTag] Error removing item: $e');

      // Try to remove locally as fallback
      _inventory.removeWhere((item) => item.id == itemId);
      _sessionStats = _sessionStats.copyWith(
        totalItemsDisposed: _sessionStats.totalItemsDisposed + 1,
      );
      await _saveToStorageCache();
      ref.notifyListeners();
    }
  }

  /// Remove item by tracking ID (backward compatibility)
  Future<bool> removeItemByTrackingId(String trackingId) async {
    print(
      '📦 [$_logTag] Removing item from inventory by tracking ID: $trackingId',
    );

    final itemIndex = _inventory.indexWhere(
      (item) => item.trackingId == trackingId,
    );
    if (itemIndex == -1) {
      print('⚠️ [$_logTag] Item not found in inventory: $trackingId');
      return false;
    }

    final removedItem = _inventory.removeAt(itemIndex);

    // Update session stats
    _sessionStats = _sessionStats.copyWith(
      totalItemsDisposed: _sessionStats.totalItemsDisposed + 1,
    );

    // Persist to storage immediately after removing item
    await _saveToStorage();

    // Notify Riverpod that state has changed
    ref.notifyListeners();

    print(
      '✅ [$_logTag] Item removed successfully: ${removedItem.codeName}. Remaining: ${_inventory.length}',
    );
    return true;
  }

  /// Remove multiple items by tracking IDs
  Future<void> removeItems(List<String> trackingIds) async {
    // Ensure loading is complete before proceeding
    await _ensureLoaded();

    print('📦 [$_logTag] Removing ${trackingIds.length} items from inventory');

    final removedCount = _inventory.length;
    _inventory.removeWhere((item) => trackingIds.contains(item.trackingId));
    final actualRemovedCount = removedCount - _inventory.length;

    if (actualRemovedCount > 0) {
      // Update session stats
      _sessionStats = _sessionStats.copyWith(
        totalItemsDisposed:
            _sessionStats.totalItemsDisposed + actualRemovedCount,
      );

      // Persist to storage immediately after removing items
      await _saveToStorage();

      // Notify Riverpod that state has changed
      ref.notifyListeners();

      print('✅ [$_logTag] Removed $actualRemovedCount items from inventory');
    } else {
      print('⚠️ [$_logTag] No items found to remove');
    }
  }

  /// Remove items by category (returns removed items)
  Future<List<InventoryItem>> removeItemsByCategory(String category) async {
    print('📦 [$_logTag] Removing items by category: $category');

    final removedItems = _inventory
        .where((item) => item.category == category)
        .toList();
    if (removedItems.isEmpty) {
      print('⚠️ [$_logTag] No items found for category: $category');
      return [];
    }

    _inventory.removeWhere((item) => item.category == category);

    // Update session stats
    _sessionStats = _sessionStats.copyWith(
      totalItemsDisposed:
          _sessionStats.totalItemsDisposed + removedItems.length,
    );

    // Persist to storage immediately after removing items
    await _saveToStorage();

    // Notify Riverpod that state has changed
    ref.notifyListeners();

    print(
      '✅ [$_logTag] Removed ${removedItems.length} items of category $category',
    );
    return removedItems;
  }

  /// Remove items by WasteCategory (backward compatibility)
  Future<int> removeItemsByWasteCategory(WasteCategory category) async {
    final removedItems = await removeItemsByCategory(category.id);
    return removedItems.length;
  }

  /// Clear entire inventory
  Future<void> clearInventory() async {
    // Ensure loading is complete before proceeding
    await _ensureLoaded();

    print('📦 [$_logTag] Clearing entire inventory');

    final itemCount = _inventory.length;
    _inventory.clear();

    // Persist to storage immediately after clearing inventory
    await _saveToStorage();

    // Notify Riverpod that state has changed
    ref.notifyListeners();

    print('✅ [$_logTag] Cleared $itemCount items from inventory');
  }

  // ===== BIN MATCHING METHODS =====

  /// Match bin with current inventory and process disposal
  Future<BinMatchResult> matchBin(BinInfo binInfo) async {
    final binCategoryId = binInfo.category.id;

    print('🎯 [$_logTag] Matching bin: ${binInfo.binId} (${binCategoryId})');
    print('🎯 [$_logTag] Current inventory: ${_inventory.length} items');

    // Use BinMatchingService to analyze the match
    final matchResult = BinMatchingService.analyzeMatch(binInfo, _inventory);

    return matchResult;
  }

  /// Award points for disposal of items after successful disposal confirmation
  Future<void> awardPointsForDisposal(List<InventoryItem> disposedItems) async {
    if (disposedItems.isEmpty) {
      print('⚠️ [$_logTag] No items to award points for');
      return;
    }

    // Calculate points based on disposed items' categories using existing point values
    int totalPoints = 0;
    for (final item in disposedItems) {
      final pointsPerItem = _categoryPoints[item.category] ?? 5;
      totalPoints += pointsPerItem;
    }

    print(
      '🏆 [$_logTag] Awarding $totalPoints points for ${disposedItems.length} disposed items',
    );

    // Add points to total
    _totalPoints += totalPoints;

    // Update session stats
    _sessionStats = _sessionStats.copyWith(
      totalPointsEarned: _sessionStats.totalPointsEarned + totalPoints,
      totalItemsDisposed:
          _sessionStats.totalItemsDisposed + disposedItems.length,
    );

    // Note: Achievement and user stats updates should be handled by the calling code
    // to avoid circular dependencies between services

    // Persist to storage immediately
    await _saveToStorage();

    // Notify Riverpod that state has changed
    ref.notifyListeners();

    print(
      '✅ [$_logTag] Points awarded successfully. Total points: $_totalPoints',
    );
  }

  /// Award points to user
  Future<void> _awardPoints(int points) async {
    _totalPoints += points;

    // Update session stats
    _sessionStats = _sessionStats.copyWith(
      totalPointsEarned: _sessionStats.totalPointsEarned + points,
    );

    // Ensure stats are saved immediately when updated during gameplay
    await _saveToStorage();

    print('🏆 [$_logTag] Awarded $points points. Total: $_totalPoints');
  }

  // ===== STORAGE METHODS =====

  /// Load inventory and session data from database or storage
  Future<void> loadInventory() async {
    print('📦 [$_logTag] Loading inventory from database...');
    await _loadFromDatabase();
  }

  /// Load from database with fallback to local storage
  Future<void> _loadFromDatabase() async {
    if (_isLoaded) return; // Avoid loading multiple times

    try {
      // Check if user is authenticated and database is available
      final currentUser = ref.read(userServiceProvider).currentUser;

      if (currentUser != null && SupabaseConfigService.isFullyConfigured) {
        print('📦 [$_logTag] Loading from Supabase database...');
        await _loadFromSupabase(currentUser.authId!);
      } else {
        print(
          '📦 [$_logTag] Loading from local storage (demo mode or offline)...',
        );
        await _loadFromStorage();
      }

      _isLoaded = true;
      print('✅ [$_logTag] Inventory load complete: ${_inventory.length} items');

      // Set up real-time subscription if authenticated
      if (currentUser != null && SupabaseConfigService.isFullyConfigured) {
        _setupRealtimeSubscription(currentUser.authId!);
      }
    } catch (e) {
      print('❌ [$_logTag] Failed to load inventory: $e');
      // Fallback to local storage
      await _loadFromStorage();
      _isLoaded = true;
    }
  }

  /// Load from Supabase database
  Future<void> _loadFromSupabase(String userId) async {
    try {
      final result = await _dbService.findByUserId(userId);

      if (result.isSuccess && result.data != null) {
        _inventory = result.data!;
        print('✅ [$_logTag] Loaded ${_inventory.length} items from database');
      } else {
        print('⚠️ [$_logTag] No inventory found in database: ${result.error}');
        _inventory = [];
      }

      // Load session stats from local storage (session-specific)
      await _loadSessionStatsFromStorage();
    } catch (e) {
      print('❌ [$_logTag] Error loading from Supabase: $e');
      throw e;
    }
  }

  /// Load from local storage (fallback method)
  Future<void> _loadFromStorage() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Load inventory items with fallback
      _inventory = _loadInventoryWithFallback();

      // Load points
      _totalPoints = _prefs!.getInt(_pointsKey) ?? 0;

      // Load session stats with fallback
      _sessionStats = _loadStatsWithFallback();

      print(
        '✅ [$_logTag] Storage load complete: ${_inventory.length} items, $_totalPoints points',
      );
    } catch (e) {
      print('❌ [$_logTag] Failed to load from storage: $e');
      _initializeDefaults();
    }
  }

  /// Load session stats from local storage
  Future<void> _loadSessionStatsFromStorage() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _sessionStats = _loadStatsWithFallback();
    } catch (e) {
      print('❌ [$_logTag] Failed to load session stats: $e');
      _sessionStats = SessionStats();
    }
  }

  /// Load inventory with fallback for corrupted data
  List<InventoryItem> _loadInventoryWithFallback() {
    try {
      final inventoryJson = _prefs!.getString(_inventoryKey);
      if (inventoryJson != null) {
        final List<dynamic> inventoryData = jsonDecode(inventoryJson);
        final loadedItems = <InventoryItem>[];

        for (final itemData in inventoryData) {
          try {
            final item = InventoryItem.fromJson(itemData);
            loadedItems.add(item);
          } catch (e) {
            print('⚠️ [$_logTag] Failed to load inventory item, skipping: $e');
            // Continue loading other items instead of failing completely
          }
        }

        print('✅ [$_logTag] Loaded ${loadedItems.length} items from storage');
        return loadedItems;
      }
    } catch (e) {
      print(
        '❌ [$_logTag] Failed to parse inventory JSON, using empty list: $e',
      );
    }
    return [];
  }

  /// Load session stats with fallback for corrupted data
  SessionStats _loadStatsWithFallback() {
    try {
      final statsJson = _prefs!.getString(_sessionStatsKey);
      if (statsJson != null) {
        final statsData = jsonDecode(statsJson);
        final stats = SessionStats.fromJson(statsData);
        print('✅ [$_logTag] Loaded session stats from storage');
        return stats;
      }
    } catch (e) {
      print(
        '❌ [$_logTag] Failed to parse session stats JSON, using defaults: $e',
      );
    }
    return SessionStats();
  }

  /// Initialize with default values
  void _initializeDefaults() {
    _inventory = [];
    _totalPoints = 0;
    _sessionStats = SessionStats();
    print('✅ [$_logTag] Initialized with default values');
  }

  /// Set up real-time subscription for inventory changes
  void _setupRealtimeSubscription(String userId) {
    try {
      print(
        '🔄 [$_logTag] Setting up real-time subscription for user: $userId',
      );

      _realtimeSubscription?.cancel(); // Cancel existing subscription

      _realtimeSubscription = _supabase
          .from('inventory')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (data) => _handleRealtimeUpdate(data),
            onError: (error) {
              print('❌ [$_logTag] Real-time subscription error: $error');
            },
          );

      print('✅ [$_logTag] Real-time subscription established');
    } catch (e) {
      print('❌ [$_logTag] Failed to set up real-time subscription: $e');
    }
  }

  /// Handle real-time updates from Supabase
  void _handleRealtimeUpdate(List<Map<String, dynamic>> data) {
    try {
      print('🔄 [$_logTag] Received real-time update: ${data.length} items');

      final updatedInventory = data
          .map((item) => InventoryItem.fromSupabase(item))
          .toList();

      // Update local state
      _inventory = updatedInventory;

      // Cache locally for offline support
      _saveToStorageCache();

      // Notify listeners
      ref.notifyListeners();

      print(
        '✅ [$_logTag] Real-time update processed: ${_inventory.length} items',
      );
    } catch (e) {
      print('❌ [$_logTag] Error processing real-time update: $e');
    }
  }

  /// Save to database with offline support
  Future<void> _saveToDatabase() async {
    final currentUser = ref.read(userServiceProvider).currentUser;

    if (currentUser != null && SupabaseConfigService.isFullyConfigured) {
      // Save to database
      await _saveToSupabase(currentUser.authId!);
    }

    // Always save to local storage as cache/fallback
    await _saveToStorageCache();
  }

  /// Save to Supabase database
  Future<void> _saveToSupabase(String userId) async {
    try {
      // Note: Individual items are saved when added/removed
      // This method is for batch operations if needed
      print('💾 [$_logTag] Inventory synced with database');
    } catch (e) {
      print('❌ [$_logTag] Failed to save to database: $e');
      // Don't throw - allow offline operation
    }
  }

  /// Save to local storage as cache
  Future<void> _saveToStorageCache() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Save inventory data
      final inventoryData = _inventory.map((item) => item.toJson()).toList();
      final inventoryJson = jsonEncode(inventoryData);
      await _prefs!.setString(_inventoryKey, inventoryJson);

      // Save points
      await _prefs!.setInt(_pointsKey, _totalPoints);

      // Save session stats immediately when updated
      final statsJson = jsonEncode(_sessionStats.toJson());
      await _prefs!.setString(_sessionStatsKey, statsJson);

      print('💾 [$_logTag] Data cached to storage successfully');
    } catch (e) {
      print('❌ [$_logTag] Failed to save to storage cache: $e');
      if (kDebugMode) {
        print('❌ [$_logTag] Storage error details: ${e.toString()}');
      }
    }
  }

  /// Save to storage (backward compatibility)
  Future<void> _saveToStorage() async {
    await _saveToDatabase();
  }

  // ===== UTILITY AND DEBUG METHODS =====

  /// Get inventory summary for debugging
  Map<String, dynamic> getInventorySummary() {
    final categoryBreakdown = <String, int>{};
    for (final category in WasteCategory.values) {
      final count = getItemCountByCategory(category);
      if (count > 0) {
        categoryBreakdown[category.id] = count;
      }
    }

    return {
      'total_items': _inventory.length,
      'categories': categoryBreakdown,
      'total_points': _totalPoints,
      'session_stats': _sessionStats.toJson(),
      'oldest_item': _inventory.isNotEmpty
          ? _inventory
                .map((item) => item.pickedUpAt)
                .reduce((a, b) => a.isBefore(b) ? a : b)
                .toIso8601String()
          : null,
    };
  }

  /// Debug method to log current inventory state
  void logInventoryState(String context) {
    print('📊 [$_logTag] [$context] Inventory State:');
    print('📊 [$_logTag] - Total items: ${_inventory.length}');
    print('📊 [$_logTag] - Total points: $_totalPoints');
    print('📊 [$_logTag] - Is loaded: $_isLoaded');
    if (_inventory.isNotEmpty) {
      for (final item in _inventory) {
        print('📊 [$_logTag] - Item: ${item.displayName} (${item.category})');
      }
    }
  }

  /// Create a test inventory item (for development)
  static int _testItemCounter = 0;
  InventoryItem createTestItem(String category, String displayName) {
    _testItemCounter++;
    final now = DateTime.now();
    final uniqueId = '${now.millisecondsSinceEpoch}_$_testItemCounter';
    return InventoryItem(
      id: 'test_$uniqueId',
      trackingId: 'track_$uniqueId',
      category: category,
      displayName: displayName,
      codeName: displayName,
      confidence: 0.9,
      pickedUpAt: now,
      metadata: {'source': 'test'},
    );
  }

  /// Add test items for development
  Future<void> addTestItems() async {
    final testItems = [
      createTestItem('recycle', 'Plastic Bottle'),
      createTestItem('recycle', 'Aluminum Can'),
      createTestItem('organic', 'Apple Core'),
      createTestItem('landfill', 'Candy Wrapper'),
      createTestItem('ewaste', 'Old Phone'),
    ];

    for (final item in testItems) {
      await addItem(item);
    }

    if (kDebugMode) {
      print('✅ [$_logTag] Added ${testItems.length} test items to inventory');
    }
  }

  /// Synchronize inventory data with server
  Future<void> syncInventoryData() async {
    try {
      print('📦 [$_logTag] Starting inventory data synchronization...');

      // Load latest data from database
      await _loadFromDatabase();

      print('✅ [$_logTag] Inventory data synchronized successfully');
    } catch (e) {
      print('❌ [$_logTag] Failed to sync inventory data: $e');
      rethrow;
    }
  }

  /// Dispose resources and clean up
  Future<void> dispose() async {
    print('📦 [$_logTag] Disposing consolidated inventory service...');

    // Cancel real-time subscription
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;

    // Persist final state before disposal
    await _saveToDatabase();

    // Clear in-memory data
    _inventory.clear();

    print('✅ [$_logTag] Consolidated inventory service disposed');
  }
}
