import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage configuration constants
/// Requirements: 1.2, 1.4
class StorageKeys {
  // User profile data
  static const String userProfile = 'user_profile';
  static const String userAchievements = 'user_achievements';
  static const String dashboardStatsCache = 'dashboard_stats_cache';
  
  // Inventory data
  static const String userInventory = 'user_inventory';
  static const String inventoryItems = 'inventory_items';
  
  // Pending operations for offline support
  static const String pendingOperations = 'pending_operations';
  static const String pendingDatabaseOps = 'pending_database_operations';
  
  // Service-specific data
  static const String wasteCategorizerCorrections = 'waste_categorizer_corrections';
  static const String locationServiceCache = 'location_service_cache';
  static const String binLocationCache = 'bin_location_cache';
  
  // App configuration
  static const String appSettings = 'app_settings';
  static const String userPreferences = 'user_preferences';
  static const String onboardingCompleted = 'onboarding_completed';
  
  // Performance and analytics
  static const String performanceMetrics = 'performance_metrics';
  static const String analyticsData = 'analytics_data';
  static const String errorLogs = 'error_logs';
}

/// Centralized local storage service for all SharedPreferences operations
/// Provides typed storage operations with proper error handling and logging
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5
class LocalStorageService {
  static const String _logTag = 'LOCAL_STORAGE_SERVICE';
  
  // Singleton pattern for consistent access
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();
  
  LocalStorageService._();
  
  // Cached SharedPreferences instance
  SharedPreferences? _prefs;
  
  /// Initialize the service and cache SharedPreferences instance
  /// Requirements: 1.1, 1.5
  Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      debugPrint('✅ [$_logTag] Service initialized successfully');
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to initialize: $e');
      rethrow;
    }
  }
  
  /// Get SharedPreferences instance, initializing if necessary
  /// Requirements: 1.1, 1.5
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }
  
  // ===== CORE STORAGE OPERATIONS =====
  
  /// Generic get operation with JSON deserialization
  /// Requirements: 1.1, 1.3, 1.5
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(key);
      
      if (jsonString == null) {
        debugPrint('📖 [$_logTag] No data found for key: $key');
        return null;
      }
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = fromJson(jsonData);
      
      debugPrint('✅ [$_logTag] Retrieved data for key: $key');
      return result;
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to get data for key $key: $e');
      return null;
    }
  }
  
  /// Generic set operation with JSON serialization
  /// Requirements: 1.1, 1.3, 1.5
  Future<bool> set<T>(String key, T value, Map<String, dynamic> Function(T) toJson) async {
    try {
      final prefs = await _getPrefs();
      final jsonData = toJson(value);
      final jsonString = jsonEncode(jsonData);
      
      final success = await prefs.setString(key, jsonString);
      
      if (success) {
        debugPrint('✅ [$_logTag] Saved data for key: $key');
      } else {
        debugPrint('⚠️ [$_logTag] Failed to save data for key: $key');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error saving data for key $key: $e');
      return false;
    }
  }
  
  /// Remove a specific key
  /// Requirements: 1.1, 1.5
  Future<bool> remove(String key) async {
    try {
      final prefs = await _getPrefs();
      final success = await prefs.remove(key);
      
      if (success) {
        debugPrint('✅ [$_logTag] Removed data for key: $key');
      } else {
        debugPrint('⚠️ [$_logTag] Failed to remove data for key: $key');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error removing data for key $key: $e');
      return false;
    }
  }
  
  /// Clear all stored data
  /// Requirements: 1.1, 1.5
  Future<bool> clear() async {
    try {
      final prefs = await _getPrefs();
      final success = await prefs.clear();
      
      if (success) {
        debugPrint('✅ [$_logTag] Cleared all stored data');
      } else {
        debugPrint('⚠️ [$_logTag] Failed to clear all data');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error clearing all data: $e');
      return false;
    }
  }
  
  // ===== BATCH OPERATIONS =====
  
  /// Set multiple key-value pairs in a single operation
  /// Requirements: 1.1, 1.3, 1.5
  Future<bool> setBatch(Map<String, dynamic> data) async {
    try {
      final prefs = await _getPrefs();
      bool allSuccess = true;
      
      for (final entry in data.entries) {
        final jsonString = jsonEncode(entry.value);
        final success = await prefs.setString(entry.key, jsonString);
        if (!success) {
          allSuccess = false;
          debugPrint('⚠️ [$_logTag] Failed to save batch item: ${entry.key}');
        }
      }
      
      if (allSuccess) {
        debugPrint('✅ [$_logTag] Saved batch data: ${data.keys.join(', ')}');
      } else {
        debugPrint('⚠️ [$_logTag] Some batch operations failed');
      }
      
      return allSuccess;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error saving batch data: $e');
      return false;
    }
  }
  
  /// Get multiple values by keys
  /// Requirements: 1.1, 1.3, 1.5
  Future<Map<String, dynamic>> getBatch(List<String> keys) async {
    try {
      final prefs = await _getPrefs();
      final results = <String, dynamic>{};
      
      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            results[key] = jsonDecode(jsonString);
          } catch (e) {
            debugPrint('⚠️ [$_logTag] Failed to decode JSON for key $key: $e');
          }
        }
      }
      
      debugPrint('✅ [$_logTag] Retrieved batch data: ${results.keys.join(', ')}');
      return results;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting batch data: $e');
      return {};
    }
  }
  
  // ===== PRIMITIVE TYPE OPERATIONS =====
  
  /// Get string value
  /// Requirements: 1.1, 1.5
  Future<String?> getString(String key) async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.getString(key);
      debugPrint('📖 [$_logTag] Retrieved string for key: $key');
      return value;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting string for key $key: $e');
      return null;
    }
  }
  
  /// Set string value
  /// Requirements: 1.1, 1.5
  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await _getPrefs();
      final success = await prefs.setString(key, value);
      
      if (success) {
        debugPrint('✅ [$_logTag] Saved string for key: $key');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error saving string for key $key: $e');
      return false;
    }
  }
  
  /// Get integer value
  /// Requirements: 1.1, 1.5
  Future<int?> getInt(String key) async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.getInt(key);
      debugPrint('📖 [$_logTag] Retrieved int for key: $key');
      return value;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting int for key $key: $e');
      return null;
    }
  }
  
  /// Set integer value
  /// Requirements: 1.1, 1.5
  Future<bool> setInt(String key, int value) async {
    try {
      final prefs = await _getPrefs();
      final success = await prefs.setInt(key, value);
      
      if (success) {
        debugPrint('✅ [$_logTag] Saved int for key: $key');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error saving int for key $key: $e');
      return false;
    }
  }
  
  /// Get boolean value
  /// Requirements: 1.1, 1.5
  Future<bool?> getBool(String key) async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.getBool(key);
      debugPrint('📖 [$_logTag] Retrieved bool for key: $key');
      return value;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting bool for key $key: $e');
      return null;
    }
  }
  
  /// Set boolean value
  /// Requirements: 1.1, 1.5
  Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await _getPrefs();
      final success = await prefs.setBool(key, value);
      
      if (success) {
        debugPrint('✅ [$_logTag] Saved bool for key: $key');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error saving bool for key $key: $e');
      return false;
    }
  }
  
  /// Get double value
  /// Requirements: 1.1, 1.5
  Future<double?> getDouble(String key) async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.getDouble(key);
      debugPrint('📖 [$_logTag] Retrieved double for key: $key');
      return value;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting double for key $key: $e');
      return null;
    }
  }
  
  /// Set double value
  /// Requirements: 1.1, 1.5
  Future<bool> setDouble(String key, double value) async {
    try {
      final prefs = await _getPrefs();
      final success = await prefs.setDouble(key, value);
      
      if (success) {
        debugPrint('✅ [$_logTag] Saved double for key: $key');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error saving double for key $key: $e');
      return false;
    }
  }
  
  /// Get string list value
  /// Requirements: 1.1, 1.5
  Future<List<String>?> getStringList(String key) async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.getStringList(key);
      debugPrint('📖 [$_logTag] Retrieved string list for key: $key');
      return value;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting string list for key $key: $e');
      return null;
    }
  }
  
  /// Set string list value
  /// Requirements: 1.1, 1.5
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      final prefs = await _getPrefs();
      final success = await prefs.setStringList(key, value);
      
      if (success) {
        debugPrint('✅ [$_logTag] Saved string list for key: $key');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error saving string list for key $key: $e');
      return false;
    }
  }
  
  // ===== SPECIALIZED METHODS FOR COMMON DATA TYPES =====
  
  /// Get user profile data
  /// Requirements: 1.2, 1.4
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final jsonString = await getString(StorageKeys.userProfile);
      if (jsonString == null) return null;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting user profile: $e');
      return null;
    }
  }
  
  /// Set user profile data
  /// Requirements: 1.2, 1.4
  Future<bool> setUserProfile(Map<String, dynamic> profile) async {
    try {
      final jsonString = jsonEncode(profile);
      return await setString(StorageKeys.userProfile, jsonString);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error setting user profile: $e');
      return false;
    }
  }
  
  /// Get inventory items
  /// Requirements: 1.2, 1.4
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    try {
      final jsonString = await getString(StorageKeys.userInventory);
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting inventory items: $e');
      return [];
    }
  }
  
  /// Set inventory items
  /// Requirements: 1.2, 1.4
  Future<bool> setInventoryItems(List<Map<String, dynamic>> items) async {
    try {
      final jsonString = jsonEncode(items);
      return await setString(StorageKeys.userInventory, jsonString);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error setting inventory items: $e');
      return false;
    }
  }
  
  /// Get pending operations
  /// Requirements: 1.2, 1.4
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    try {
      final jsonString = await getString(StorageKeys.pendingOperations);
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting pending operations: $e');
      return [];
    }
  }
  
  /// Add pending operation
  /// Requirements: 1.2, 1.4
  Future<bool> addPendingOperation(Map<String, dynamic> operation) async {
    try {
      final existingOps = await getPendingOperations();
      existingOps.add({
        ...operation,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      return await setPendingOperations(existingOps);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error adding pending operation: $e');
      return false;
    }
  }
  
  /// Set pending operations
  /// Requirements: 1.2, 1.4
  Future<bool> setPendingOperations(List<Map<String, dynamic>> operations) async {
    try {
      final jsonString = jsonEncode(operations);
      return await setString(StorageKeys.pendingOperations, jsonString);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error setting pending operations: $e');
      return false;
    }
  }
  
  /// Remove pending operation by ID
  /// Requirements: 1.2, 1.4
  Future<bool> removePendingOperation(String operationId) async {
    try {
      final existingOps = await getPendingOperations();
      existingOps.removeWhere((op) => op['id'] == operationId);
      
      return await setPendingOperations(existingOps);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error removing pending operation: $e');
      return false;
    }
  }
  
  /// Clear all pending operations
  /// Requirements: 1.2, 1.4
  Future<bool> clearPendingOperations() async {
    try {
      return await remove(StorageKeys.pendingOperations);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error clearing pending operations: $e');
      return false;
    }
  }
  
  /// Get generic JSON data
  /// Requirements: 1.2, 1.3, 1.4
  Future<Map<String, dynamic>?> getJsonData(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return null;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting JSON data for key $key: $e');
      return null;
    }
  }
  
  /// Set generic JSON data
  /// Requirements: 1.2, 1.3, 1.4
  Future<bool> setJsonData(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      return await setString(key, jsonString);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error setting JSON data for key $key: $e');
      return false;
    }
  }
  
  /// Get generic JSON list
  /// Requirements: 1.2, 1.3, 1.4
  Future<List<Map<String, dynamic>>> getJsonList(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting JSON list for key $key: $e');
      return [];
    }
  }
  
  /// Set generic JSON list
  /// Requirements: 1.2, 1.3, 1.4
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> data) async {
    try {
      final jsonString = jsonEncode(data);
      return await setString(key, jsonString);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error setting JSON list for key $key: $e');
      return false;
    }
  }
  
  // ===== UTILITY METHODS =====
  
  /// Check if a key exists
  /// Requirements: 1.1, 1.5
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint('❌ [$_logTag] Error checking key existence for $key: $e');
      return false;
    }
  }
  
  /// Get all keys
  /// Requirements: 1.1, 1.5
  Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getKeys();
    } catch (e) {
      debugPrint('❌ [$_logTag] Error getting all keys: $e');
      return {};
    }
  }
  
  /// Get storage size estimate (in bytes)
  /// Requirements: 1.1, 1.5
  Future<int> getStorageSizeEstimate() async {
    try {
      final prefs = await _getPrefs();
      int totalSize = 0;
      
      for (final key in prefs.getKeys()) {
        final value = prefs.get(key);
        if (value is String) {
          totalSize += value.length * 2; // UTF-16 encoding estimate
        } else {
          totalSize += 8; // Estimate for primitive types
        }
      }
      
      debugPrint('📊 [$_logTag] Estimated storage size: $totalSize bytes');
      return totalSize;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error calculating storage size: $e');
      return 0;
    }
  }
  
  /// Clean up old data based on timestamp
  /// Requirements: 1.1, 1.5
  Future<int> cleanupOldData({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final prefs = await _getPrefs();
      final cutoffTime = DateTime.now().subtract(maxAge);
      int removedCount = 0;
      
      final keysToRemove = <String>[];
      
      for (final key in prefs.getKeys()) {
        final value = prefs.getString(key);
        if (value != null) {
          try {
            final jsonData = jsonDecode(value) as Map<String, dynamic>;
            final timestampStr = jsonData['timestamp'] as String?;
            
            if (timestampStr != null) {
              final timestamp = DateTime.parse(timestampStr);
              if (timestamp.isBefore(cutoffTime)) {
                keysToRemove.add(key);
              }
            }
          } catch (e) {
            // Skip non-JSON data
          }
        }
      }
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
        removedCount++;
      }
      
      debugPrint('🧹 [$_logTag] Cleaned up $removedCount old data entries');
      return removedCount;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error during cleanup: $e');
      return 0;
    }
  }
  
  /// Export all data for backup
  /// Requirements: 1.1, 1.5
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final prefs = await _getPrefs();
      final exportData = <String, dynamic>{};
      
      for (final key in prefs.getKeys()) {
        final value = prefs.get(key);
        exportData[key] = value;
      }
      
      debugPrint('📤 [$_logTag] Exported ${exportData.length} data entries');
      return exportData;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error exporting data: $e');
      return {};
    }
  }
  
  /// Import data from backup
  /// Requirements: 1.1, 1.5
  Future<bool> importData(Map<String, dynamic> data, {bool overwrite = false}) async {
    try {
      final prefs = await _getPrefs();
      int importedCount = 0;
      
      for (final entry in data.entries) {
        if (!overwrite && prefs.containsKey(entry.key)) {
          continue; // Skip existing keys if not overwriting
        }
        
        final value = entry.value;
        bool success = false;
        
        if (value is String) {
          success = await prefs.setString(entry.key, value);
        } else if (value is int) {
          success = await prefs.setInt(entry.key, value);
        } else if (value is double) {
          success = await prefs.setDouble(entry.key, value);
        } else if (value is bool) {
          success = await prefs.setBool(entry.key, value);
        } else if (value is List<String>) {
          success = await prefs.setStringList(entry.key, value);
        }
        
        if (success) {
          importedCount++;
        }
      }
      
      debugPrint('📥 [$_logTag] Imported $importedCount data entries');
      return importedCount > 0;
    } catch (e) {
      debugPrint('❌ [$_logTag] Error importing data: $e');
      return false;
    }
  }
}