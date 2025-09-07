import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/ml_detection_service.dart';
import '../../../core/services/hand_tracking_service.dart';
import '../../../core/services/platform_hand_tracking_factory.dart';
import '../../../core/services/enhanced_gesture_recognition_service.dart';
import '../../../core/services/object_management_service.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/performance_service.dart';

/// Manages initialization and lifecycle of AR camera services
class ARCameraServices {
  // Services
  MLDetectionService? _mlService;
  HandTrackingService? _handService;
  EnhancedGestureRecognitionService? _enhancedGestureService;
  ObjectManagementService? _objectManagementService;
  InventoryService? _inventoryService;
  PerformanceService? _performanceService;

  // Initialization state
  bool _isInitialized = false;
  String? _initializationError;
  final List<String> _initializationLogs = [];

  // Getters for services
  MLDetectionService? get mlService => _mlService;
  HandTrackingService? get handService => _handService;
  EnhancedGestureRecognitionService? get enhancedGestureService =>
      _enhancedGestureService;
  ObjectManagementService? get objectManagementService =>
      _objectManagementService;

  PerformanceService? get performanceService => _performanceService;

  // Status getters
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;
  List<String> get initializationLogs => List.unmodifiable(_initializationLogs);

  // Service availability checks
  bool get hasMLService => _mlService != null && _mlService!.isInitialized;
  bool get hasHandService =>
      _handService != null && _handService!.isInitialized;
  bool get hasGestureService => _enhancedGestureService != null;
  bool get hasObjectManagementService => _objectManagementService != null;

  bool get hasPerformanceService => _performanceService != null;

  /// Initialize all AR camera services
  Future<void> initializeServices({
    InventoryService? inventoryService,
  }) async {
    if (_isInitialized) {
      print('📱 [SERVICES] Already initialized');
      return;
    }

    print('📱 [SERVICES] Starting initialization...');
    _initializationLogs.clear();
    _initializationError = null;

    // Store inventory service for pickup integration
    _inventoryService = inventoryService;
    if (_inventoryService != null) {
      print('📦 [SERVICES] Inventory service provided for pickup integration');
    } else {
      print(
        '⚠️ [SERVICES] No inventory service provided - pickups will not be added to inventory',
      );
    }

    try {
      // Initialize services in order of dependency
      await _initializePerformanceService();
      await _initializeMLServices();
      await _initializeHandTrackingService();

      await _initializeGestureService();
      await _initializeObjectManagementService();

      _isInitialized = true;
      print('✅ [SERVICES] All services initialized successfully');

      _logServiceStatus();
    } catch (e) {
      _initializationError = e.toString();
      print('❌ [SERVICES] Initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize performance monitoring service
  Future<void> _initializePerformanceService() async {
    try {
      _performanceService = PerformanceService();
      // Performance service doesn't need async initialization
      _addLog('✅ Performance service initialized');
    } catch (e) {
      _addLog('⚠️ Performance service failed: $e');
      print('⚠️ [SERVICES] Performance service initialization failed: $e');
      // Continue without performance service - not critical
    }
  }

  /// Initialize ML detection service
  Future<void> _initializeMLServices() async {
    try {
      _mlService = MLDetectionService();
      await _mlService!.initialize();
      _addLog('✅ ML service initialized');
      print('✅ [SERVICES] ML detection service ready');
    } catch (e) {
      _addLog('❌ ML service failed: $e');
      print('❌ [SERVICES] ML service failed: $e');
      _mlService = null;
      throw Exception('Failed to initialize ML detection service: $e');
    }
  }

  /// Initialize hand tracking service
  Future<void> _initializeHandTrackingService() async {
    try {
      if (PlatformHandTrackingFactory.isSupported) {
        _handService = PlatformHandTrackingFactory.create();
        await _handService!.initialize();
        _addLog('✅ Hand tracking service initialized');
        print(
          '✅ [SERVICES] Hand tracking ready: ${_handService!.platformInfo}',
        );
      } else {
        _addLog('⚠️ Hand tracking not supported on this platform');
        print('⚠️ [SERVICES] Hand tracking not supported on this platform');
      }
    } catch (e) {
      _addLog('⚠️ Hand tracking service failed: $e');
      print('⚠️ [SERVICES] Hand tracking initialization failed: $e');
      _handService = null;
      // Continue without hand tracking - not critical for basic functionality
    }
  }

  /// Initialize gesture recognition service
  Future<void> _initializeGestureService() async {
    try {
      if (_handService != null && _handService!.isInitialized) {
        _enhancedGestureService = EnhancedGestureRecognitionService();
        await _enhancedGestureService!.initialize();
        _addLog('✅ Gesture recognition service initialized');
        print('✅ [SERVICES] Enhanced gesture recognition ready');
      } else {
        _addLog('⚠️ Gesture service skipped - no hand tracking');
        print(
          '⚠️ [SERVICES] Skipping gesture service - hand tracking unavailable',
        );
      }
    } catch (e) {
      _addLog('⚠️ Gesture recognition service failed: $e');
      print('⚠️ [SERVICES] Gesture recognition initialization failed: $e');
      _enhancedGestureService = null;
      // Continue without gesture recognition - not critical
    }
  }

  /// Initialize unified pickup detection service
  Future<void> _initializeObjectManagementService() async {
    try {
      if (_hasRequiredServicesForPickup()) {
        _objectManagementService = ObjectManagementService();
        await _objectManagementService!.initialize(
          inventoryService: _inventoryService,
        );
        _addLog('✅ Unified pickup detection service initialized');
        print('✅ [SERVICES] Unified pickup detection ready');

        if (_inventoryService != null) {
          print(
            '🔗 [SERVICES] Pickup detection connected to inventory service',
          );
        } else {
          print(
            '⚠️ [SERVICES] Pickup detection running without inventory integration',
          );
        }
      } else {
        _addLog('⚠️ Pickup service skipped - missing dependencies');
        print(
          '⚠️ [SERVICES] Skipping pickup service - missing required dependencies',
        );
      }
    } catch (e) {
      _addLog('⚠️ Pickup detection service failed: $e');
      print('⚠️ [SERVICES] Pickup detection initialization failed: $e');
      _objectManagementService = null;
      // Continue without pickup detection - not critical
    }
  }

  /// Check if required services are available for pickup detection
  bool _hasRequiredServicesForPickup() {
    final hasML = _mlService != null;
    final hasHands = _handService != null && _handService!.isInitialized;
    return hasML && hasHands;
  }

  /// Dispose of all services and clean up resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    print('📱 [SERVICES] Disposing all services...');

    // Dispose in reverse order of initialization
    final disposalFutures = <Future>[];

    if (_objectManagementService != null) {
      disposalFutures.add(
        _objectManagementService!.dispose().catchError((e) {
          print('⚠️ [SERVICES] Error disposing pickup service: $e');
        }),
      );
    }

    if (_enhancedGestureService != null) {
      disposalFutures.add(
        _enhancedGestureService!.dispose().catchError((e) {
          print('⚠️ [SERVICES] Error disposing gesture service: $e');
        }),
      );
    }

    if (_handService != null) {
      disposalFutures.add(
        _handService!.dispose().catchError((e) {
          print('⚠️ [SERVICES] Error disposing hand service: $e');
        }),
      );
    }

    if (_mlService != null) {
      disposalFutures.add(
        _mlService!.dispose().catchError((e) {
          print('⚠️ [SERVICES] Error disposing ML service: $e');
        }),
      );
    }

    if (_performanceService != null) {
      try {
        _performanceService!.dispose();
        print('✅ [SERVICES] Performance service disposed');
      } catch (e) {
        print('⚠️ [SERVICES] Error disposing performance service: $e');
      }
    }

    // Wait for all disposals to complete
    await Future.wait(disposalFutures);

    // Clear references
    _mlService = null;
    _handService = null;
    _enhancedGestureService = null;
    _objectManagementService = null;

    _performanceService = null;

    _isInitialized = false;
    _initializationLogs.clear();
    _initializationError = null;

    print('✅ [SERVICES] All services disposed');
  }

  /// Get a summary of service status for debugging
  Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': _isInitialized,
      'initialization_error': _initializationError,
      'services': {
        'ml_service': _mlService != null,
        'hand_service': hasHandService,
        'gesture_service': _enhancedGestureService != null,
        'object_management_service': _objectManagementService != null,

        'performance_service': _performanceService != null,
      },
      'service_info': {
        'ml_service_type': _mlService != null ? 'ml_detection' : 'none',
        'hand_tracking_platform': _handService?.platformInfo ?? 'none',
        'total_services': _getActiveServiceCount(),
      },
    };
  }

  /// Get count of active services
  int _getActiveServiceCount() {
    int count = 0;
    if (_mlService != null) count++;
    if (hasHandService) count++;
    if (_enhancedGestureService != null) count++;
    if (_objectManagementService != null) count++;

    if (_performanceService != null) count++;
    return count;
  }

  /// Add a log entry
  void _addLog(String message) {
    _initializationLogs.add('${DateTime.now()}: $message');
    if (kDebugMode) {
      print('📱 [SERVICES] $message');
    }
  }

  /// Log service status summary
  void _logServiceStatus() {
    final status = getServiceStatus();
    print('📊 [SERVICES] Service Status Summary:');
    print('   Initialized: ${status['initialized']}');
    print('   Active Services: ${status['service_info']['total_services']}');
    print('   ML Type: ${status['service_info']['ml_service_type']}');
    print(
      '   Hand Tracking: ${status['service_info']['hand_tracking_platform']}',
    );
    print('   Gesture Recognition: ${status['services']['gesture_service']}');
    print(
      '   Pickup Detection: ${status['services']['object_management_service']}',
    );

    print(
      '   Performance Monitoring: ${status['services']['performance_service']}',
    );
  }

  /// Restart services (useful for error recovery)
  Future<void> restartServices() async {
    print('🔄 [SERVICES] Restarting all services...');
    await dispose();
    await initializeServices();
  }

  /// Check if core services are available for basic AR functionality
  bool get hasCoreServices {
    return _mlService != null;
  }

  /// Check if full AR functionality is available
  bool get hasFullARCapabilities {
    return hasCoreServices && hasHandService;
  }

  /// Pause services (for QR scanning mode)
  void pauseServices() {
    print('⏸️ [SERVICES] Pausing AR services for QR mode...');
    // Services remain initialized but processing is paused
    // This is handled by stopping the image stream in the camera screen
  }

  /// Resume services (return from QR scanning mode)
  void resumeServices() {
    print('▶️ [SERVICES] Resuming AR services from QR mode...');
    // Services resume when image stream is restarted
    // This is handled by restarting the image stream in the camera screen
  }
}
