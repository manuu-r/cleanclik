import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class for loading environment configuration
/// Supports both .env files (development) and system environment variables (production)
class EnvConfig {
  static final Map<String, String> _cache = {};
  static bool _isLoaded = false;

  /// Load environment configuration
  /// This should be called once during app initialization
  static Future<void> load() async {
    if (_isLoaded) return;

    // Load from system environment variables first
    _cache.addAll(Platform.environment);

    // In debug mode, also try to load from .env file
    if (kDebugMode) {
      await _loadFromEnvFile();
    }

    _isLoaded = true;
  }

  /// Get environment variable value
  /// Returns empty string if not found
  static String get(String key) {
    if (!_isLoaded) {
      throw StateError('EnvConfig not loaded. Call EnvConfig.load() first.');
    }
    return _cache[key] ?? '';
  }

  /// Get environment variable value with default
  static String getOrDefault(String key, String defaultValue) {
    if (!_isLoaded) {
      throw StateError('EnvConfig not loaded. Call EnvConfig.load() first.');
    }
    return _cache[key] ?? defaultValue;
  }

  /// Check if environment variable exists
  static bool has(String key) {
    if (!_isLoaded) {
      throw StateError('EnvConfig not loaded. Call EnvConfig.load() first.');
    }
    return _cache.containsKey(key) && _cache[key]!.isNotEmpty;
  }

  /// Get all environment variables (for debugging)
  static Map<String, String> getAll() {
    if (!_isLoaded) {
      throw StateError('EnvConfig not loaded. Call EnvConfig.load() first.');
    }
    return Map.unmodifiable(_cache);
  }

  /// Load environment variables from .env file (development only)
  static Future<void> _loadFromEnvFile() async {
    try {
      final envContent = await rootBundle.loadString('.env');
      final lines = envContent.split('\n');
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        // Skip empty lines and comments
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
          continue;
        }
        
        // Parse key=value pairs
        final equalIndex = trimmedLine.indexOf('=');
        if (equalIndex > 0) {
          final key = trimmedLine.substring(0, equalIndex).trim();
          final value = trimmedLine.substring(equalIndex + 1).trim();
          
          // Remove quotes if present
          final cleanValue = _removeQuotes(value);
          
          // Only add if not already present (system env vars take precedence)
          if (!_cache.containsKey(key)) {
            _cache[key] = cleanValue;
          }
        }
      }
    } catch (e) {
      // .env file not found or not readable
      if (kDebugMode) {
        print('Could not load .env file: $e');
      }
    }
  }

  /// Remove surrounding quotes from value
  static String _removeQuotes(String value) {
    if (value.length >= 2) {
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        return value.substring(1, value.length - 1);
      }
    }
    return value;
  }

  /// Reset configuration (for testing)
  @visibleForTesting
  static void reset() {
    _cache.clear();
    _isLoaded = false;
  }
}