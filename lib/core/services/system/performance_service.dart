import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Performance monitoring and battery awareness service
class PerformanceService {
  final StreamController<PerformanceMetrics> _metricsController =
      StreamController<PerformanceMetrics>.broadcast();

  Timer? _monitoringTimer;
  PerformanceLevel _currentLevel = PerformanceLevel.high;
  bool _isBatteryLow = false;
  bool _isLowMemory = false;

  /// Stream of performance metrics
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  /// Current performance level
  PerformanceLevel get currentLevel => _currentLevel;

  /// Whether battery is low
  bool get isBatteryLow => _isBatteryLow;

  /// Whether memory is low
  bool get isLowMemory => _isLowMemory;

  /// Whether animations should be shown based on performance level
  bool get shouldShowAnimations => _currentLevel != PerformanceLevel.low;

  /// Start performance monitoring
  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateMetrics(),
    );

    // Initial metrics
    _updateMetrics();
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
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
    );

    _updatePerformanceLevel(metrics);
    _metricsController.add(metrics);
  }

  void _updatePerformanceLevel(PerformanceMetrics metrics) {
    final oldLevel = _currentLevel;

    // Determine performance level based on metrics
    if (metrics.batteryLevel < 0.2 ||
        metrics.memoryUsage > 0.8 ||
        metrics.frameRate < 20) {
      _currentLevel = PerformanceLevel.low;
    } else if (metrics.batteryLevel < 0.4 ||
        metrics.memoryUsage > 0.6 ||
        metrics.frameRate < 45) {
      _currentLevel = PerformanceLevel.medium;
    } else {
      _currentLevel = PerformanceLevel.high;
    }

    _isBatteryLow = metrics.batteryLevel < 0.2;
    _isLowMemory = metrics.memoryUsage > 0.8;

    // Notify if level changed
    if (oldLevel != _currentLevel) {
      debugPrint('Performance level changed: $oldLevel -> $_currentLevel');
    }
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

  void dispose() {
    stopMonitoring();
    _metricsController.close();
  }
}

/// Performance metrics data
class PerformanceMetrics {
  final double frameRate;
  final double memoryUsage; // 0.0 to 1.0
  final double batteryLevel; // 0.0 to 1.0
  final double cpuUsage; // 0.0 to 1.0
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.frameRate,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.cpuUsage,
    required this.timestamp,
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
