import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/env_config.dart';

/// Service for configuring and managing Supabase client initialization
/// Follows security patterns from supabase-security-guidelines
class SupabaseConfigService {
  static late Supabase _instance;
  static bool _isInitialized = false;

  /// Initialize Supabase with secure configuration
  /// Loads credentials from environment variables following security guidelines
  /// Falls back to demo mode if credentials are missing
  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Load environment configuration
      await EnvConfig.load();

      // Load environment variables securely
      final supabaseUrl = EnvConfig.get('SUPABASE_URL');
      final supabaseAnonKey = EnvConfig.get('SUPABASE_PUBLISHABLE_KEY');

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        if (kDebugMode) {
          print(
            'Warning: Missing Supabase configuration. '
            'App will run in demo mode. '
            'Please set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY for full functionality.',
          );
        }

        // Mark as initialized but without actual Supabase connection
        _isInitialized = true;
        return;
      }

      // Initialize Supabase with secure configuration
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // Use PKCE for security
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: kDebugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
        ),
      );

      _instance = Supabase.instance;
      _isInitialized = true;

      // Validate connection
      await validateConnection();
    } catch (e) {
      throw SupabaseConfigException(
        'Failed to initialize Supabase: ${e.toString()}',
      );
    }
  }

  /// Get Supabase client instance
  /// Throws exception if not initialized or if running in demo mode
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw SupabaseConfigException(
        'Supabase not initialized. Call SupabaseConfigService.initialize() first.',
      );
    }

    if (_instance == null) {
      throw SupabaseConfigException(
        'Supabase is running in demo mode. '
        'Please configure SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY for full functionality.',
      );
    }

    return _instance.client;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if Supabase is fully configured (not in demo mode)
  static bool get isFullyConfigured => _isInitialized && _instance != null;

  /// Check if running in demo mode
  static bool get isDemoMode => _isInitialized && _instance == null;

  /// Validate Supabase connection and configuration
  static Future<bool> validateConnection() async {
    if (isDemoMode) {
      if (kDebugMode) {
        print('Running in demo mode, skipping connection validation');
      }
      return false;
    }

    try {
      // Test connection by making a simple query
      await client.from('users').select('count').limit(1);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase connection validation failed: $e');
      }
      return false;
    }
  }

  /// Perform health check on Supabase connection
  static Future<SupabaseHealthStatus> healthCheck() async {
    if (isDemoMode) {
      return SupabaseHealthStatus(
        isHealthy: false,
        responseTimeMs: -1,
        authServiceHealthy: false,
        timestamp: DateTime.now(),
        error: 'Running in demo mode - Supabase not configured',
      );
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Test database connection
      await client.from('users').select('count').limit(1);

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      // Test authentication service
      final authHealthy =
          client.auth.currentSession != null || await _testAuthService();

      return SupabaseHealthStatus(
        isHealthy: true,
        responseTimeMs: responseTime,
        authServiceHealthy: authHealthy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return SupabaseHealthStatus(
        isHealthy: false,
        responseTimeMs: -1,
        authServiceHealthy: false,
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Test authentication service availability
  static Future<bool> _testAuthService() async {
    if (isDemoMode) {
      return false;
    }

    try {
      // This will return current session or null without throwing
      client.auth.currentSession;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset initialization state (for testing purposes)
  @visibleForTesting
  static void reset() {
    _isInitialized = false;
  }
}

/// Exception thrown when Supabase configuration fails
class SupabaseConfigException implements Exception {
  final String message;

  const SupabaseConfigException(this.message);

  @override
  String toString() => 'SupabaseConfigException: $message';
}

/// Health status information for Supabase connection
class SupabaseHealthStatus {
  final bool isHealthy;
  final int responseTimeMs;
  final bool authServiceHealthy;
  final DateTime timestamp;
  final String? error;

  const SupabaseHealthStatus({
    required this.isHealthy,
    required this.responseTimeMs,
    required this.authServiceHealthy,
    required this.timestamp,
    this.error,
  });

  @override
  String toString() {
    return 'SupabaseHealthStatus('
        'healthy: $isHealthy, '
        'responseTime: ${responseTimeMs}ms, '
        'authHealthy: $authServiceHealthy, '
        'timestamp: $timestamp'
        '${error != null ? ', error: $error' : ''}'
        ')';
  }
}
