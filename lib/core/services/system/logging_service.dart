import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Logging levels for controlling verbosity
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  none(4);

  const LogLevel(this.value);
  final int value;
}

/// Logging categories for better organization
enum LogCategory {
  ar('AR'),
  ml('ML'),
  tracking('TRACK'),
  ui('UI'),
  network('NET'),
  performance('PERF'),
  gesture('GESTURE'),
  storage('STORAGE'),
  general('GENERAL');

  const LogCategory(this.prefix);
  final String prefix;
}

/// Rate limiting configuration for high-frequency logs
class RateLimitConfig {
  final Duration window;
  final int maxMessages;

  const RateLimitConfig({
    this.window = const Duration(seconds: 1),
    this.maxMessages = 5,
  });
}

/// Centralized logging service with rate limiting and categorization
class LoggingService {
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();

  LoggingService._();

  // Configuration
  LogLevel _currentLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Get the current logging level
  LogLevel get currentLevel => _currentLevel;
  final Map<LogCategory, RateLimitConfig> _rateLimits = {};
  final Map<LogCategory, List<DateTime>> _messageHistory = {};

  // Performance tracking
  final Map<String, DateTime> _performanceMarkers = {};
  final List<PerformanceMetric> _performanceMetrics = [];

  /// Set the global logging level
  void setLogLevel(LogLevel level) {
    _currentLevel = level;
    _log(
      LogLevel.info,
      LogCategory.general,
      'Logging level set to ${level.name}',
    );
  }

  /// Configure rate limiting for a category
  void setRateLimit(LogCategory category, RateLimitConfig config) {
    _rateLimits[category] = config;
  }

  /// Check if a message should be logged based on rate limiting
  bool _shouldLog(LogLevel level, LogCategory category) {
    // Check log level
    if (level.value < _currentLevel.value) return false;

    // Check rate limiting
    final config = _rateLimits[category];
    if (config != null) {
      final now = DateTime.now();
      final history = _messageHistory[category] ??= [];

      // Remove old messages outside the window
      history.removeWhere((time) => now.difference(time) > config.window);

      // Check if we've exceeded the limit
      if (history.length >= config.maxMessages) {
        return false;
      }

      // Add current message to history
      history.add(now);
    }

    return true;
  }

  /// Core logging method
  void _log(
    LogLevel level,
    LogCategory category,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_shouldLog(level, category)) return;

    final timestamp = DateTime.now().toIso8601String().substring(
      11,
      23,
    ); // HH:mm:ss.SSS
    final prefix = '[${timestamp}] [${category.prefix}]';
    final fullMessage = '$prefix $message';

    switch (level) {
      case LogLevel.debug:
        if (kDebugMode) {
          developer.log(fullMessage, name: category.prefix, level: 500);
        }
        break;
      case LogLevel.info:
        developer.log(fullMessage, name: category.prefix, level: 800);
        break;
      case LogLevel.warning:
        developer.log(
          fullMessage,
          name: category.prefix,
          level: 900,
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case LogLevel.error:
        developer.log(
          fullMessage,
          name: category.prefix,
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case LogLevel.none:
        break;
    }
  }

  // Convenience methods for different log levels
  void debug(LogCategory category, String message) =>
      _log(LogLevel.debug, category, message);
  void info(LogCategory category, String message) =>
      _log(LogLevel.info, category, message);
  void warning(
    LogCategory category,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _log(LogLevel.warning, category, message, error, stackTrace);
  void error(
    LogCategory category,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _log(LogLevel.error, category, message, error, stackTrace);

  // Performance tracking methods
  void startPerformanceTimer(String operation) {
    _performanceMarkers[operation] = DateTime.now();
  }

  void endPerformanceTimer(String operation, {String? details}) {
    final startTime = _performanceMarkers.remove(operation);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      final metric = PerformanceMetric(
        operation: operation,
        duration: duration,
        timestamp: DateTime.now(),
        details: details,
      );

      _performanceMetrics.add(metric);

      // Keep only last 100 metrics
      if (_performanceMetrics.length > 100) {
        _performanceMetrics.removeAt(0);
      }

      // Log slow operations
      if (duration.inMilliseconds > 100) {
        warning(
          LogCategory.performance,
          'Slow operation: $operation took ${duration.inMilliseconds}ms${details != null ? ' ($details)' : ''}',
        );
      } else {
        debug(
          LogCategory.performance,
          'Operation: $operation took ${duration.inMilliseconds}ms${details != null ? ' ($details)' : ''}',
        );
      }
    }
  }

  /// Get recent performance metrics
  List<PerformanceMetric> getRecentMetrics({Duration? since}) {
    if (since == null) return List.from(_performanceMetrics);

    final cutoff = DateTime.now().subtract(since);
    return _performanceMetrics
        .where((m) => m.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Initialize with default rate limits for high-frequency categories
  void initializeDefaults() {
    // Limit AR and ML logs to prevent spam
    setRateLimit(
      LogCategory.ar,
      const RateLimitConfig(window: Duration(seconds: 1), maxMessages: 2),
    );

    setRateLimit(
      LogCategory.ml,
      const RateLimitConfig(window: Duration(seconds: 1), maxMessages: 2),
    );

    setRateLimit(
      LogCategory.ui,
      const RateLimitConfig(window: Duration(seconds: 1), maxMessages: 3),
    );

    setRateLimit(
      LogCategory.tracking,
      const RateLimitConfig(window: Duration(seconds: 2), maxMessages: 5),
    );

    info(
      LogCategory.general,
      'LoggingService initialized with default rate limits',
    );
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final String? details;

  const PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.details,
  });

  @override
  String toString() {
    return 'PerformanceMetric(operation: $operation, duration: ${duration.inMilliseconds}ms, details: $details)';
  }
}

/// Global logging instance for easy access
final logger = LoggingService.instance;
