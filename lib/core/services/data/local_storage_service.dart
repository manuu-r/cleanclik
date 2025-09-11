import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'local_storage_service.g.dart';

/// Service for local data persistence
class LocalStorageService {
  static const String _inventoryKey = 'user_inventory';
  static const String _sessionKey = 'user_session';
  static const String _settingsKey = 'app_settings';

  /// Save user inventory to local storage
  Future<void> saveInventory(Map<String, dynamic> inventoryData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(inventoryData);
      await prefs.setString(_inventoryKey, jsonString);
      debugPrint('Inventory saved to local storage');
    } catch (e) {
      debugPrint('Failed to save inventory: $e');
      rethrow;
    }
  }

  /// Load user inventory from local storage
  Future<Map<String, dynamic>?> getInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_inventoryKey);

      if (jsonString == null) {
        return null;
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to load inventory: $e');
      return null;
    }
  }

  /// Clear inventory from local storage
  Future<void> clearInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_inventoryKey);
      debugPrint('Inventory cleared from local storage');
    } catch (e) {
      debugPrint('Failed to clear inventory: $e');
      rethrow;
    }
  }

  /// Save session data
  Future<void> saveSession(Map<String, dynamic> sessionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(sessionData);
      await prefs.setString(_sessionKey, jsonString);
      debugPrint('Session saved to local storage');
    } catch (e) {
      debugPrint('Failed to save session: $e');
      rethrow;
    }
  }

  /// Load session data
  Future<Map<String, dynamic>?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sessionKey);

      if (jsonString == null) {
        return null;
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to load session: $e');
      return null;
    }
  }

  /// Clear session data
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      debugPrint('Session cleared from local storage');
    } catch (e) {
      debugPrint('Failed to clear session: $e');
      rethrow;
    }
  }

  /// Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings);
      await prefs.setString(_settingsKey, jsonString);
      debugPrint('Settings saved to local storage');
    } catch (e) {
      debugPrint('Failed to save settings: $e');
      rethrow;
    }
  }

  /// Load app settings
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString == null) {
        return null;
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      return null;
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('All local storage cleared');
    } catch (e) {
      debugPrint('Failed to clear all storage: $e');
      rethrow;
    }
  }

  /// Check if inventory exists
  Future<bool> hasInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_inventoryKey);
    } catch (e) {
      debugPrint('Failed to check inventory existence: $e');
      return false;
    }
  }

  /// Check if session exists
  Future<bool> hasSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_sessionKey);
    } catch (e) {
      debugPrint('Failed to check session existence: $e');
      return false;
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final stats = <String, dynamic>{
        'totalKeys': keys.length,
        'hasInventory': keys.contains(_inventoryKey),
        'hasSession': keys.contains(_sessionKey),
        'hasSettings': keys.contains(_settingsKey),
        'keys': keys.toList(),
      };

      // Calculate approximate storage size
      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          totalSize += value.length;
        }
      }
      stats['approximateSize'] = totalSize;

      return stats;
    } catch (e) {
      debugPrint('Failed to get storage stats: $e');
      return {'error': e.toString()};
    }
  }
}

/// Provider for LocalStorageService
@riverpod
LocalStorageService localStorageService(LocalStorageServiceRef ref) {
  return LocalStorageService();
}
