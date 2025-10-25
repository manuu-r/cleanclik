import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Performance monitoring and battery awareness service
class PerformanceService {
  final StreamController<PerformanceMetrics> _metricsController =
      StreamController<PerformanceMetrics>.broadcast();

  Timer? _monitoringTimer;
  Timer? _memoryCheckTimer;
  PerformanceLevel _currentLevel = PerformanceLevel.high;
  bool _isBatteryLow = false;
  bool _isLowMemory = false;

  // Memory pressure detection fields
  double _availableMemoryMB = 0.0;
  double _totalMemoryMB = 0.0;
  DateTime _lastMemoryCheck = DateTime.now();
  static const Duration _memoryCheckInterval = Duration(seconds: 5);

  /// Stream of performance metrics
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  /// Current performance level
  PerformanceLevel get currentLevel => _currentLevel;

  /// Whether battery is low
  bool get isBatteryLow => _isBatteryLow;

  /// Whether memory is low
  bool get isLowMemory => _isLowMemory;

  /// Whether memory is critically low (< 100MB available)
  bool get isCriticalMemory => _availableMemoryMB < 100.0;

  /// Available memory in MB
  double get availableMemoryMB => _availableMemoryMB;

  /// Total device memory in MB
  double get totalMemoryMB => _totalMemoryMB;

  /// Whether animations should be shown based on performance level
  bool get shouldShowAnimations => _currentLevel != PerformanceLevel.low;

  /// Start performance monitoring
  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateMetrics(),
    );

    // Start memory monitoring timer
    _startMemoryMonitoring();

    // Initial metrics
    _updateMetrics();
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = null;
  }

  /// Get recommended settings for current performance level
  PerformanceSettings getRecommendedSettings() {
    switch (_currentLevel) {
      case PerformanceLevel.high:
        return const PerformanceSettings(
          enableParticles: true,
          enableGlowEffects: true,
          enableBreathingAnimations: true,
          maxParticleCount: 50,
          animationDuration: Duration(milliseconds: 300),
          frameRateTarget: 60,
        );
      case PerformanceLevel.medium:
        return const PerformanceSettings(
          enableParticles: true,
          enableGlowEffects: true,
          enableBreathingAnimations: false,
          maxParticleCount: 25,
          animationDuration: Duration(milliseconds: 400),
          frameRateTarget: 30,
        );
      case PerformanceLevel.low:
        return const PerformanceSettings(
          enableParticles: false,
          enableGlowEffects: false,
          enableBreathingAnimations: false,
          maxParticleCount: 0,
          animationDuration: Duration(milliseconds: 200),
          frameRateTarget: 15,
        );
    }
  }

  /// Update performance level based on device capabilities
  void _updateMetrics() {
    // In a real implementation, this would use platform channels
    // to get actual device metrics

    final metrics = PerformanceMetrics(
      frameRate: _estimateFrameRate(),
      memoryUsage: _estimateMemoryUsage(),
      batteryLevel: _estimateBatteryLevel(),
      cpuUsage: _estimateCpuUsage(),
      timestamp: DateTime.now(),
      availableMemoryMB: _availableMemoryMB,
      totalMemoryMB: _totalMemoryMB,
    );

    _updatePerformanceLevel(metrics);
    _metricsController.add(metrics);
  }

  void _updatePerformanceLevel(PerformanceMetrics metrics) {
    final oldLevel = _currentLevel;

    // Determine performance level based on metrics
    // Priority: Memory pressure > Battery > Frame rate
    if (metrics.availableMemoryMB < 50.0 || // Critical memory threshold
        metrics.batteryLevel < 0.2 ||
        metrics.memoryUsage > 0.8 ||
        metrics.frameRate < 20) {
      _currentLevel = PerformanceLevel.low;
    } else if (metrics.availableMemoryMB <
            100.0 || // High memory pressure threshold
        metrics.batteryLevel < 0.4 ||
        metrics.memoryUsage > 0.6 ||
        metrics.frameRate < 45) {
      _currentLevel = PerformanceLevel.medium;
    } else {
      _currentLevel = PerformanceLevel.high;
    }

    _isBatteryLow = metrics.batteryLevel < 0.2;
    _isLowMemory =
        metrics.memoryUsage > 0.8 || metrics.availableMemoryMB < 150.0;

    // Notify if level changed
    if (oldLevel != _currentLevel) {
      debugPrint('Performance level changed: $oldLevel -> $_currentLevel');
      debugPrint(
        '  Available Memory: ${metrics.availableMemoryMB.toStringAsFixed(1)}MB',
      );
      debugPrint(
        '  Battery Level: ${(metrics.batteryLevel * 100).toStringAsFixed(1)}%',
      );
      debugPrint('  Frame Rate: ${metrics.frameRate.toStringAsFixed(1)}fps');
    }
  }

  /// Start memory monitoring timer
  void _startMemoryMonitoring() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = Timer.periodic(_memoryCheckInterval, (_) {
      _checkMemoryUsage();
    });

    // Initial memory check
    _checkMemoryUsage();
  }

  /// Check current memory usage using platform-specific methods
  Future<void> _checkMemoryUsage() async {
    final now = DateTime.now();
    if (now.difference(_lastMemoryCheck) < _memoryCheckInterval) {
      return; // Skip if checked too recently
    }

    _lastMemoryCheck = now;

    try {
      if (Platform.isAndroid) {
        await _checkAndroidMemoryUsage();
      } else if (Platform.isIOS) {
        await _checkIOSMemoryUsage();
      } else {
        // Fallback for other platforms
        _availableMemoryMB = _estimateAvailableMemory();
      }

      // Log significant memory changes
      if (kDebugMode) {
        debugPrint(
          '📊 [Performance] Available Memory: ${_availableMemoryMB.toStringAsFixed(1)}MB / ${_totalMemoryMB.toStringAsFixed(1)}MB',
        );

        if (_availableMemoryMB < 50.0) {
          debugPrint('⚠️ [Performance] CRITICAL memory pressure detected!');
        } else if (_availableMemoryMB < 100.0) {
          debugPrint('⚠️ [Performance] High memory pressure detected');
        } else if (_availableMemoryMB < 150.0) {
          debugPrint('⚠️ [Performance] Low memory detected');
        }
      }
    } catch (e) {
      debugPrint('❌ [Performance] Error checking memory usage: $e');
      // Fallback to estimation
      _availableMemoryMB = _estimateAvailableMemory();
    }
  }

  /// Check memory usage on Android using /proc/meminfo
  Future<void> _checkAndroidMemoryUsage() async {
    try {
      final result = await Process.run('cat', ['/proc/meminfo']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');

        double memTotal = 0.0;
        double memAvailable = 0.0;
        double memFree = 0.0;
        double buffers = 0.0;
        double cached = 0.0;

        for (final line in lines) {
          if (line.startsWith('MemTotal:')) {
            memTotal = _parseMemoryLine(line);
          } else if (line.startsWith('MemAvailable:')) {
            memAvailable = _parseMemoryLine(line);
          } else if (line.startsWith('MemFree:')) {
            memFree = _parseMemoryLine(line);
          } else if (line.startsWith('Buffers:')) {
            buffers = _parseMemoryLine(line);
          } else if (line.startsWith('Cached:')) {
            cached = _parseMemoryLine(line);
          }
        }

        _totalMemoryMB = memTotal / 1024; // Convert KB to MB

        // Use MemAvailable if available (more accurate), otherwise calculate
        if (memAvailable > 0) {
          _availableMemoryMB = memAvailable / 1024;
        } else {
          // Fallback calculation: MemFree + Buffers + Cached
          _availableMemoryMB = (memFree + buffers + cached) / 1024;
        }
      } else {
        throw Exception('Failed to read /proc/meminfo');
      }
    } catch (e) {
      debugPrint('❌ [Performance] Android memory check failed: $e');
      _availableMemoryMB = _estimateAvailableMemory();
    }
  }

  /// Check memory usage on iOS using vm_stat (if available)
  Future<void> _checkIOSMemoryUsage() async {
    try {
      // iOS memory monitoring is more restricted
      // Use a conservative estimation based on device capabilities
      _availableMemoryMB = _estimateAvailableMemory();

      // For iOS, we can try to get some system info, but it's limited
      // In a production app, you might use platform channels to get more accurate data
      if (Platform.isIOS) {
        // Estimate total memory based on device type (this is approximate)
        _totalMemoryMB = _estimateIOSTotalMemory();
      }
    } catch (e) {
      debugPrint('❌ [Performance] iOS memory check failed: $e');
      _availableMemoryMB = _estimateAvailableMemory();
    }
  }

  /// Parse memory line from /proc/meminfo (format: "MemTotal: 1234567 kB")
  double _parseMemoryLine(String line) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return double.tryParse(parts[1]) ?? 0.0;
    }
    return 0.0;
  }

  /// Estimate available memory when platform-specific methods fail
  double _estimateAvailableMemory() {
    // Conservative estimation based on platform and performance level
    if (Platform.isIOS) {
      // iOS typically has better memory management
      return _currentLevel == PerformanceLevel.high
          ? 200.0
          : _currentLevel == PerformanceLevel.medium
          ? 120.0
          : 80.0;
    } else {
      // Android varies more widely
      return _currentLevel == PerformanceLevel.high
          ? 180.0
          : _currentLevel == PerformanceLevel.medium
          ? 100.0
          : 60.0;
    }
  }

  /// Estimate total iOS memory based on device capabilities
  double _estimateIOSTotalMemory() {
    // This is a rough estimation - in a real app you'd use device detection
    // Modern iOS devices typically have 3-8GB RAM
    return _currentLevel == PerformanceLevel.high
        ? 6144.0
        : // 6GB
          _currentLevel == PerformanceLevel.medium
        ? 4096.0
        : // 4GB
          3072.0; // 3GB
  }

  // Mock implementations - in real app, these would use platform channels

  double _estimateFrameRate() {
    // Mock frame rate based on platform
    if (Platform.isIOS) {
      return 60.0; // iOS typically has better performance
    } else {
      return 45.0; // Android varies more
    }
  }

  double _estimateMemoryUsage() {
    // Mock memory usage (0.0 to 1.0)
    return 0.4;
  }

  double _estimateBatteryLevel() {
    // Mock battery level (0.0 to 1.0)
    return 0.7;
  }

  double _estimateCpuUsage() {
    // Mock CPU usage (0.0 to 1.0)
    return 0.3;
  }

  /// Perform garbage collection optimization by cleaning up old data
  void performGarbageCollectionOptimization() {
    print('🧹 [Performance-GC] Performing garbage collection optimization');

    // No specific performance history to clean up in this service
    // The main optimization is in the ML service

    // Force a memory check to update current state
    _checkMemoryUsage();

    print('🧹 [Performance-GC] Performance service cleanup completed');
  }

  /// Get garbage collection statistics
  Map<String, dynamic> getGarbageCollectionStats() {
    return {
      'available_memory_mb': _availableMemoryMB,
      'total_memory_mb': _totalMemoryMB,
      'is_low_memory': _isLowMemory,
      'is_critical_memory': isCriticalMemory,
      'current_performance_level': _currentLevel.name,
      'is_battery_low': _isBatteryLow,
      'last_memory_check': _lastMemoryCheck.toIso8601String(),
    };
  }

  void dispose() {
    stopMonitoring();
    _metricsController.close();
  }
}

/// Performance metrics data
class PerformanceMetrics {
  final double frameRate;
  final double memoryUsage; // 0.0 to 1.0 (percentage)
  final double batteryLevel; // 0.0 to 1.0
  final double cpuUsage; // 0.0 to 1.0
  final DateTime timestamp;
  final double availableMemoryMB; // Available memory in MB
  final double totalMemoryMB; // Total memory in MB

  const PerformanceMetrics({
    required this.frameRate,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.cpuUsage,
    required this.timestamp,
    required this.availableMemoryMB,
    required this.totalMemoryMB,
  });
}

/// Performance level enum
enum PerformanceLevel { high, medium, low }

/// Performance settings based on current level
class PerformanceSettings {
  final bool enableParticles;
  final bool enableGlowEffects;
  final bool enableBreathingAnimations;
  final int maxParticleCount;
  final Duration animationDuration;
  final int frameRateTarget;

  const PerformanceSettings({
    required this.enableParticles,
    required this.enableGlowEffects,
    required this.enableBreathingAnimations,
    required this.maxParticleCount,
    required this.animationDuration,
    required this.frameRateTarget,
  });
}

/// Provider for performance service
final performanceServiceProvider = Provider<PerformanceService>((ref) {
  final service = PerformanceService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for current performance settings
final performanceSettingsProvider = Provider<PerformanceSettings>((ref) {
  final service = ref.watch(performanceServiceProvider);
  return service.getRecommendedSettings();
});
