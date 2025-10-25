import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cleanclik/core/services/camera/waste_detection_service.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/services/platform/hand_tracking.dart'
    as hand_tracking;
import 'package:cleanclik/core/services/platform/enhanced_gesture_recognition_service.dart';
import 'package:cleanclik/core/services/business/pickup_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/services/camera/ml_config.dart'
    show ProcessingMode;

/// Custom exceptions for AR camera services
class ARServiceInitializationException implements Exception {
  final String message;
  final String serviceName;
  final dynamic cause;

  ARServiceInitializationException(
    this.serviceName,
    this.message, [
    this.cause,
  ]);

  @override
  String toString() =>
      'ARServiceInitializationException($serviceName): $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Structured logging utility for AR camera services
class ARLogger {
  static const String _tag = '[SERVICES]';

  static void debug(String message, [Map<String, dynamic>? context]) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' ${context.toString()}' : '';
    print('$timestamp $_tag [DEBUG] $message$contextStr');
  }

  static void info(String message, [Map<String, dynamic>? context]) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' ${context.toString()}' : '';
    print('$timestamp $_tag [INFO] $message$contextStr');
  }

  static void warning(
    String message, [
    Map<String, dynamic>? context,
    dynamic error,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' ${context.toString()}' : '';
    final errorStr = error != null ? ' Error: $error' : '';
    print('$timestamp $_tag [WARNING] $message$contextStr$errorStr');
  }

  static void error(
    String message, [
    Map<String, dynamic>? context,
    dynamic error,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' ${context.toString()}' : '';
    final errorStr = error != null ? ' Error: $error' : '';
    print('$timestamp $_tag [ERROR] $message$contextStr$errorStr');
  }
}

/// Manages initialization and lifecycle of AR camera services
class ARCameraServices {
  // Services
  WasteDetectionService? _wasteDetectionService;
  HandTrackingService? _handService;
  EnhancedGestureRecognitionService? _enhancedGestureService;
  PickupService? _pickupService;
  InventoryService? _inventoryService;

  // Initialization state
  bool _isInitialized = false;
  String? _initializationError;
  final List<String> _initializationLogs = [];
  final Map<String, ServiceInitializationState> _serviceStates = {};

  // Initialization progress tracking
  StreamController<ServiceInitializationProgress>? _progressController;
  Stream<ServiceInitializationProgress>? _progressStream;

  // Getters for services
  WasteDetectionService? get wasteDetectionService => _wasteDetectionService;
  HandTrackingService? get handService => _handService;
  EnhancedGestureRecognitionService? get enhancedGestureService =>
      _enhancedGestureService;
  PickupService? get pickupService => _pickupService;

  // Status getters
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;
  List<String> get initializationLogs => List.unmodifiable(_initializationLogs);
  Map<String, ServiceInitializationState> get serviceStates =>
      Map.unmodifiable(_serviceStates);
  Stream<ServiceInitializationProgress>? get initializationProgress =>
      _progressStream;

  // Service availability checks
  bool get hasWasteDetectionService =>
      _wasteDetectionService != null && _wasteDetectionService!.isInitialized;
  bool get hasHandService =>
      _handService != null && _handService!.isInitialized;
  bool get hasGestureService => _enhancedGestureService != null;
  bool get hasPickupService => _pickupService != null;

  /// Initialize all AR camera services with parallel processing and enhanced error handling
  Future<void> initializeServices({InventoryService? inventoryService}) async {
    if (_isInitialized) {
      ARLogger.info('Already initialized, skipping initialization');
      return;
    }

    final stopwatch = Stopwatch()..start();
    ARLogger.info('Starting parallel initialization...', {
      'inventory_service_provided': inventoryService != null,
    });

    _initializationLogs.clear();
    _initializationError = null;
    _serviceStates.clear();

    // Initialize progress tracking
    _progressController =
        StreamController<ServiceInitializationProgress>.broadcast();
    _progressStream = _progressController!.stream;

    // Store inventory service for pickup integration
    _inventoryService = inventoryService;
    if (_inventoryService != null) {
      ARLogger.debug('Inventory service provided for pickup integration');
    } else {
      ARLogger.warning(
        'No inventory service provided - pickups will not be added to inventory',
      );
    }

    try {
      // Phase 1: Initialize core services in parallel (no dependencies)
      await _initializeCoreServicesParallel();

      // Phase 2: Initialize dependent services
      await _initializeDependentServices();

      _isInitialized = true;
      stopwatch.stop();

      ARLogger.info('All services initialized successfully', {
        'initialization_time_ms': stopwatch.elapsedMilliseconds,
        'total_services': _getActiveServiceCount(),
        'success_rate': _getInitializationSuccessRate(),
      });

      // Emit completion progress
      _emitProgress('Initialization Complete', 1.0, isComplete: true);

      _logServiceStatus();
    } catch (e) {
      stopwatch.stop();
      _initializationError = _getUserFriendlyErrorMessage(e);

      ARLogger.error('Initialization failed', {
        'initialization_time_ms': stopwatch.elapsedMilliseconds,
        'failed_services': _getFailedServiceCount(),
        'error_type': e.runtimeType.toString(),
      }, e);

      // Emit error progress with user-friendly message
      _emitProgress(_initializationError!, 0.0, hasError: true);

      rethrow;
    } finally {
      // Clean up progress controller
      await _progressController?.close();
      _progressController = null;
      _progressStream = null;
    }
  }

  /// Get user-friendly error message for initialization failures
  String _getUserFriendlyErrorMessage(dynamic error) {
    if (error is ARServiceInitializationException) {
      switch (error.serviceName) {
        case 'ml_pipeline':
          return 'Camera detection is temporarily unavailable. Please restart the app or check your device permissions.';
        case 'hand_tracking':
          return 'Hand tracking is not available on this device. Basic object detection will still work.';
        case 'gesture_service':
          return 'Gesture recognition is temporarily unavailable. Object detection will continue to work normally.';
        case 'object_management':
          return 'Pickup detection is temporarily unavailable. You can still scan objects manually.';
        default:
          return 'A service failed to start. Some features may be limited. Try restarting the app.';
      }
    } else if (error.toString().contains('permission')) {
      return 'Camera permission is required. Please grant camera access in your device settings.';
    } else if (error.toString().contains('timeout')) {
      return 'Service startup is taking longer than expected. Please try again or restart the app.';
    } else {
      return 'Failed to start AR services. Please restart the app or contact support if the problem persists.';
    }
  }

  /// Initialize core services that have no dependencies in parallel
  Future<void> _initializeCoreServicesParallel() async {
    print('📱 [SERVICES] Phase 1: Initializing core services in parallel...');

    // Emit initial progress
    _emitProgress('Starting core services...', 0.1);

    // Create initialization tasks for core services
    final initializationTasks = <String, Future<void>>{};

    // ML Pipeline Service - critical core service
    initializationTasks['ml_pipeline'] = _initializeMLServiceWithTracking();

    // Hand Tracking Service - independent core service
    initializationTasks['hand_tracking'] =
        _initializeHandTrackingServiceWithTracking();

    // Wait for all core services with timeout and error handling
    final results = await _waitForServicesWithTimeout(
      initializationTasks,
      timeout: const Duration(seconds: 20),
      phase: 'Core Services',
    );

    // Check if critical services succeeded
    if (!results['ml_pipeline']!) {
      throw Exception('Critical ML pipeline service failed to initialize');
    }

    print('✅ [SERVICES] Phase 1 complete - Core services initialized');
    _emitProgress('Core services ready', 0.6);
  }

  /// Initialize services that depend on core services
  Future<void> _initializeDependentServices() async {
    print('📱 [SERVICES] Phase 2: Initializing dependent services...');

    _emitProgress('Starting dependent services...', 0.7);

    // Create initialization tasks for dependent services
    final initializationTasks = <String, Future<void>>{};

    // Gesture Service - depends on hand tracking
    initializationTasks['gesture_service'] =
        _initializeGestureServiceWithTracking();

    // Pickup Service - depends on ML and hand tracking
    initializationTasks['pickup'] = _initializePickupServiceWithTracking();

    // Wait for dependent services with timeout
    await _waitForServicesWithTimeout(
      initializationTasks,
      timeout: const Duration(seconds: 8),
      phase: 'Dependent Services',
    );

    print('✅ [SERVICES] Phase 2 complete - Dependent services initialized');
    _emitProgress('All services ready', 0.9);
  }

  /// Wait for multiple services to initialize with timeout and error recovery
  Future<Map<String, bool>> _waitForServicesWithTimeout(
    Map<String, Future<void>> tasks, {
    required Duration timeout,
    required String phase,
  }) async {
    final results = <String, bool>{};
    final completedTasks = <String, Future<bool>>{};

    // Convert each task to return success/failure instead of throwing
    for (final entry in tasks.entries) {
      completedTasks[entry.key] = entry.value.then((_) => true).catchError((e) {
        print('⚠️ [SERVICES] ${entry.key} failed in $phase: $e');
        return false;
      });
    }

    try {
      // Wait for all tasks with overall timeout
      final taskResults = await Future.wait(
        completedTasks.values,
        eagerError: false,
      ).timeout(timeout);

      // Map results back to service names
      int index = 0;
      for (final serviceName in completedTasks.keys) {
        results[serviceName] = taskResults[index];
        index++;
      }
    } catch (e) {
      print('⚠️ [SERVICES] $phase initialization timed out: $e');

      // Mark all incomplete services as failed
      for (final serviceName in completedTasks.keys) {
        results[serviceName] = false;
      }
    }

    return results;
  }

  /// Emit initialization progress update
  void _emitProgress(
    String message,
    double progress, {
    bool isComplete = false,
    bool hasError = false,
  }) {
    if (_progressController != null && !_progressController!.isClosed) {
      final progressUpdate = ServiceInitializationProgress(
        message: message,
        progress: progress,
        serviceStates: Map.from(_serviceStates),
        isComplete: isComplete,
        hasError: hasError,
      );

      _progressController!.add(progressUpdate);
    }
  }

  /// Initialize ML pipeline service with state tracking and enhanced error handling
  Future<void> _initializeMLServiceWithTracking() async {
    _serviceStates['ml_pipeline'] = ServiceInitializationState.initializing;
    _emitProgress('Initializing ML pipeline...', 0.2);

    final stopwatch = Stopwatch()..start();

    try {
      ARLogger.debug('Starting waste detection service initialization');

      // Initialize waste detection service
      _wasteDetectionService = WasteDetectionService();
      await _wasteDetectionService!.initialize();

      stopwatch.stop();
      _serviceStates['ml_pipeline'] = ServiceInitializationState.completed;
      _addLog('✅ ML pipeline service initialized');

      ARLogger.info('ML pipeline service ready', {
        'initialization_time_ms': stopwatch.elapsedMilliseconds,
      });
    } catch (e) {
      stopwatch.stop();
      _serviceStates['ml_pipeline'] = ServiceInitializationState.failed;
      _addLog('❌ ML pipeline service failed: $e');

      ARLogger.error('ML pipeline service initialization failed', {
        'initialization_time_ms': stopwatch.elapsedMilliseconds,
        'error_type': e.runtimeType.toString(),
      }, e);

      _wasteDetectionService = null;
      throw ARServiceInitializationException(
        'ml_pipeline',
        'Failed to initialize ML pipeline service',
        e,
      );
    }
  }

  /// Initialize hand tracking service with state tracking and enhanced error handling
  Future<void> _initializeHandTrackingServiceWithTracking() async {
    _serviceStates['hand_tracking'] = ServiceInitializationState.initializing;
    _emitProgress('Initializing hand tracking...', 0.3);

    final stopwatch = Stopwatch()..start();

    try {
      if (hand_tracking.PlatformHandTrackingFactory.isSupported) {
        ARLogger.debug('Starting hand tracking service initialization');

        _handService = hand_tracking.PlatformHandTrackingFactory.create();
        await _handService!.initialize();

        stopwatch.stop();
        _serviceStates['hand_tracking'] = ServiceInitializationState.completed;
        _addLog('✅ Hand tracking service initialized');

        ARLogger.info('Hand tracking ready', {
          'initialization_time_ms': stopwatch.elapsedMilliseconds,
          'platform_info': _handService!.platformInfo,
        });
      } else {
        stopwatch.stop();
        _serviceStates['hand_tracking'] = ServiceInitializationState.skipped;
        _addLog('⚠️ Hand tracking not supported on this platform');

        ARLogger.warning('Hand tracking not supported on this platform', {
          'initialization_time_ms': stopwatch.elapsedMilliseconds,
        });
      }
    } catch (e) {
      stopwatch.stop();
      _serviceStates['hand_tracking'] = ServiceInitializationState.failed;
      _addLog('⚠️ Hand tracking service failed: $e');

      ARLogger.warning(
        'Hand tracking initialization failed - continuing without hand tracking',
        {
          'initialization_time_ms': stopwatch.elapsedMilliseconds,
          'error_type': e.runtimeType.toString(),
        },
        e,
      );

      _handService = null;
      // Continue without hand tracking - not critical for basic functionality
    }
  }

  /// Initialize gesture recognition service with state tracking
  Future<void> _initializeGestureServiceWithTracking() async {
    _serviceStates['gesture_service'] = ServiceInitializationState.initializing;
    _emitProgress('Initializing gesture recognition...', 0.8);

    try {
      if (_handService != null && _handService!.isInitialized) {
        _enhancedGestureService = EnhancedGestureRecognitionService();
        await _enhancedGestureService!.initialize();

        _serviceStates['gesture_service'] =
            ServiceInitializationState.completed;
        _addLog('✅ Gesture recognition service initialized');
        print('✅ [SERVICES] Enhanced gesture recognition ready');
      } else {
        _serviceStates['gesture_service'] = ServiceInitializationState.skipped;
        _addLog('⚠️ Gesture service skipped - no hand tracking');
        print(
          '⚠️ [SERVICES] Skipping gesture service - hand tracking unavailable',
        );
      }
    } catch (e) {
      _serviceStates['gesture_service'] = ServiceInitializationState.failed;
      _addLog('⚠️ Gesture recognition service failed: $e');
      print('⚠️ [SERVICES] Gesture recognition initialization failed: $e');
      _enhancedGestureService = null;
      // Continue without gesture recognition - not critical
    }
  }

  /// Initialize pickup detection service with state tracking
  Future<void> _initializePickupServiceWithTracking() async {
    _serviceStates['pickup'] = ServiceInitializationState.initializing;
    _emitProgress('Initializing pickup detection...', 0.85);

    try {
      if (_hasRequiredServicesForPickup()) {
        _pickupService = PickupService();
        await _pickupService!.initialize();

        _serviceStates['pickup'] = ServiceInitializationState.completed;
        _addLog('✅ Pickup detection service initialized');
        print('✅ [SERVICES] Pickup detection ready');
      } else {
        _serviceStates['pickup'] = ServiceInitializationState.skipped;
        _addLog('⚠️ Pickup service skipped - missing dependencies');
        print(
          '⚠️ [SERVICES] Skipping pickup service - missing required dependencies',
        );
      }
    } catch (e) {
      _serviceStates['pickup'] = ServiceInitializationState.failed;
      _addLog('⚠️ Pickup detection service failed: $e');
      print('⚠️ [SERVICES] Pickup detection initialization failed: $e');
      _pickupService = null;
      // Continue without pickup detection - not critical
    }
  }

  /// Check if required services are available for pickup detection
  bool _hasRequiredServicesForPickup() {
    final hasML =
        _wasteDetectionService != null && _wasteDetectionService!.isInitialized;
    final hasHands = _handService != null && _handService!.isInitialized;
    return hasML && hasHands;
  }

  /// Dispose of all services and clean up resources with timeout handling
  Future<void> dispose() async {
    if (!_isInitialized) return;

    print('📱 [SERVICES] Disposing all services...');

    // Dispose in reverse order of initialization with individual timeouts
    final disposalTasks = <Future>[];

    if (_pickupService != null) {
      disposalTasks.add(
        _pickupService!
            .dispose()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                print('⚠️ [SERVICES] Pickup service disposal timed out');
              },
            )
            .catchError((e) {
              print('⚠️ [SERVICES] Error disposing pickup service: $e');
            }),
      );
    }

    if (_enhancedGestureService != null) {
      disposalTasks.add(
        _enhancedGestureService!
            .dispose()
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                print('⚠️ [SERVICES] Gesture service disposal timed out');
              },
            )
            .catchError((e) {
              print('⚠️ [SERVICES] Error disposing gesture service: $e');
            }),
      );
    }

    if (_handService != null) {
      disposalTasks.add(
        _handService!
            .dispose()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                print('⚠️ [SERVICES] Hand service disposal timed out');
              },
            )
            .catchError((e) {
              print('⚠️ [SERVICES] Error disposing hand service: $e');
            }),
      );
    }

    if (_wasteDetectionService != null) {
      disposalTasks.add(
        _wasteDetectionService!
            .dispose()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('⚠️ [SERVICES] ML service disposal timed out');
              },
            )
            .catchError((e) {
              print('⚠️ [SERVICES] Error disposing ML service: $e');
            }),
      );
    }

    // Wait for all disposals to complete with overall timeout
    try {
      await Future.wait(disposalTasks).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ [SERVICES] Overall service disposal timed out');
          return <dynamic>[];
        },
      );
    } catch (e) {
      print('⚠️ [SERVICES] Some service disposals failed: $e');
    }

    // Clear references regardless of disposal success
    _wasteDetectionService = null;
    _handService = null;
    _enhancedGestureService = null;
    _pickupService = null;

    _isInitialized = false;
    _initializationLogs.clear();
    _initializationError = null;

    print('✅ [SERVICES] All services disposal completed');
  }

  /// Get consolidated performance metrics from all services
  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{};

    if (_wasteDetectionService != null) {
      metrics['ml_service'] = {
        'status': 'available',
        'initialized': _wasteDetectionService!.isInitialized,
      };
    } else {
      metrics['ml_service'] = {'error': 'ML service not available'};
    }

    // Add AR services specific metrics
    metrics['ar_services'] = {
      'initialization_state': {
        'is_initialized': _isInitialized,
        'initialization_error': _initializationError,
        'service_states': Map.from(_serviceStates),
        'active_services': _getActiveServiceCount(),
        'failed_services': _getFailedServiceCount(),
        'success_rate': _getInitializationSuccessRate(),
      },
      'service_availability': {
        'ml_service': hasWasteDetectionService,
        'hand_service': hasHandService,
        'gesture_service': hasGestureService,
        'pickup_service': hasPickupService,
        'core_services': hasCoreServices,
        'full_ar_capabilities': hasFullARCapabilities,
      },
      'service_execution': {
        'last_pickup_execution_decision': _lastPickupExecutionDecision,
        'pickup_skip_log_throttled': _lastPickupSkipLog != null,
      },
    };

    // Add service-specific performance data
    if (_handService != null && _handService!.isInitialized) {
      metrics['hand_tracking'] = {
        'platform_info': _handService!.platformInfo,
        'is_initialized': _handService!.isInitialized,
      };
    }

    if (_enhancedGestureService != null) {
      metrics['gesture_recognition'] = {'is_available': true};
    }

    if (_pickupService != null) {
      metrics['pickup'] = {'is_available': true};
    }

    return metrics;
  }

  /// Get performance recommendations from all services
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];

    if (_wasteDetectionService != null) {
      if (!_wasteDetectionService!.isInitialized) {
        recommendations.add(
          'Waste detection service not initialized - restart the app',
        );
      }
    } else {
      recommendations.add('ML service not available - restart the app');
    }

    // Add AR services specific recommendations
    if (!_isInitialized) {
      recommendations.add(
        'AR services not initialized - check initialization logs',
      );
    }

    if (_getFailedServiceCount() > 0) {
      recommendations.add(
        'Some services failed to initialize - consider restarting failed services',
      );
    }

    if (!hasFullARCapabilities) {
      recommendations.add(
        'Limited AR capabilities - some features may not be available',
      );
    }

    if (_initializationError != null) {
      recommendations.add(
        'Initialization error detected - check permissions and device compatibility',
      );
    }

    return recommendations;
  }

  /// Get a summary of service status for debugging
  Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': _isInitialized,
      'initialization_error': _initializationError,
      'service_states': Map.from(_serviceStates),
      'services': {
        'ml_service': _wasteDetectionService != null,
        'hand_service': hasHandService,
        'gesture_service': _enhancedGestureService != null,
        'pickup_service': _pickupService != null,
      },
      'service_info': {
        'ml_service_type': _wasteDetectionService != null
            ? 'waste_detection_service'
            : 'none',
        'hand_tracking_platform': _handService?.platformInfo ?? 'none',
        'total_services': _getActiveServiceCount(),
        'failed_services': _getFailedServiceCount(),
        'initialization_success_rate': _getInitializationSuccessRate(),
      },
    };
  }

  /// Get count of failed services
  int _getFailedServiceCount() {
    return _serviceStates.values
        .where((state) => state == ServiceInitializationState.failed)
        .length;
  }

  /// Get initialization success rate
  double _getInitializationSuccessRate() {
    if (_serviceStates.isEmpty) return 0.0;

    final successfulCount = _serviceStates.values
        .where(
          (state) =>
              state == ServiceInitializationState.completed ||
              state == ServiceInitializationState.skipped,
        )
        .length;

    return successfulCount / _serviceStates.length;
  }

  /// Get count of active services
  int _getActiveServiceCount() {
    int count = 0;
    if (_wasteDetectionService != null) count++;
    if (hasHandService) count++;
    if (_enhancedGestureService != null) count++;
    if (_pickupService != null) count++;
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
    print('   Pickup Detection: ${status['services']['pickup_service']}');
  }

  /// Restart services (useful for error recovery)
  Future<void> restartServices({InventoryService? inventoryService}) async {
    print('🔄 [SERVICES] Restarting all services...');
    await dispose();
    await initializeServices(inventoryService: inventoryService);
  }

  /// Retry failed services only (more efficient than full restart)
  Future<void> retryFailedServices() async {
    final failedServices = _serviceStates.entries
        .where((entry) => entry.value == ServiceInitializationState.failed)
        .map((entry) => entry.key)
        .toList();

    if (failedServices.isEmpty) {
      print('📱 [SERVICES] No failed services to retry');
      return;
    }

    print(
      '🔄 [SERVICES] Retrying failed services: ${failedServices.join(', ')}',
    );

    // Initialize progress tracking for retry
    _progressController =
        StreamController<ServiceInitializationProgress>.broadcast();
    _progressStream = _progressController!.stream;

    try {
      _emitProgress('Retrying failed services...', 0.1);

      // Retry each failed service individually
      for (final serviceName in failedServices) {
        try {
          switch (serviceName) {
            case 'ml_service':
              await _initializeMLServiceWithTracking();
              break;
            case 'hand_tracking':
              await _initializeHandTrackingServiceWithTracking();
              break;
            case 'gesture_service':
              await _initializeGestureServiceWithTracking();
              break;
            case 'pickup':
              await _initializePickupServiceWithTracking();
              break;
          }
        } catch (e) {
          print('⚠️ [SERVICES] Retry failed for $serviceName: $e');
          // Continue with other services
        }
      }

      _emitProgress('Retry complete', 1.0, isComplete: true);
      print('✅ [SERVICES] Failed service retry completed');
    } catch (e) {
      _emitProgress('Retry failed: $e', 0.0, hasError: true);
      print('❌ [SERVICES] Failed service retry encountered error: $e');
    } finally {
      // Clean up progress controller
      await _progressController?.close();
      _progressController = null;
      _progressStream = null;
    }
  }

  /// Get initialization timeout for a specific service
  @visibleForTesting
  Duration getServiceTimeout(String serviceName) {
    switch (serviceName) {
      case 'ml_service':
        return const Duration(seconds: 10); // ML service needs more time
      case 'hand_tracking':
        return const Duration(seconds: 5);
      case 'gesture_service':
        return const Duration(seconds: 3);
      case 'object_management':
        return const Duration(seconds: 5);
      default:
        return const Duration(seconds: 5);
    }
  }

  /// Check if core services are available for basic AR functionality
  bool get hasCoreServices {
    return _wasteDetectionService != null &&
        _wasteDetectionService!.isInitialized;
  }

  /// Check if full AR functionality is available
  bool get hasFullARCapabilities {
    return hasCoreServices && hasHandService;
  }

  // Service execution logging state to prevent spam
  DateTime? _lastPickupSkipLog;
  bool _lastPickupExecutionDecision = false;
  static const Duration _logThrottleDuration = Duration(seconds: 5);

  /// Intelligent pickup service execution check with spam-free logging
  /// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
  bool shouldExecutePickupService(
    List<DetectedObject> objects,
    List<HandLandmark> hands,
  ) {
    // Create service execution context
    final context = ServiceExecutionContext(
      detectedObjects: objects,
      handLandmarks: hands,
      currentMode:
          ProcessingMode.full, // TODO: Get from pipeline service when available
      isMemoryPressure: false, // TODO: Get from pipeline service when available
      timestamp: DateTime.now(),
      isBatteryLow: false, // TODO: Get from pipeline service when available
    );

    final shouldExecute = context.shouldExecutePickupService();

    // Only log when decision changes or after throttle period
    final now = DateTime.now();
    final shouldLog =
        _lastPickupExecutionDecision != shouldExecute ||
        _lastPickupSkipLog == null ||
        now.difference(_lastPickupSkipLog!) > _logThrottleDuration;

    if (shouldLog && !shouldExecute) {
      _lastPickupSkipLog = now;

      final reason = <String>[];
      if (objects.isEmpty) reason.add('no objects detected');
      if (hands.isEmpty) reason.add('no hands detected');
      if (context.isMemoryPressure) reason.add('memory pressure');
      if (context.currentMode == ProcessingMode.cached)
        reason.add('cached mode');

      ARLogger.debug('Pickup service execution skipped', {
        'reason': reason.join(', '),
        'objects_count': objects.length,
        'hands_count': hands.length,
        'processing_mode': context.currentMode.name,
        'memory_pressure': context.isMemoryPressure,
      });
    } else if (shouldLog && shouldExecute && !_lastPickupExecutionDecision) {
      ARLogger.debug('Pickup service execution resumed', {
        'objects_count': objects.length,
        'hands_count': hands.length,
        'processing_mode': context.currentMode.name,
      });
    }

    _lastPickupExecutionDecision = shouldExecute;
    return shouldExecute;
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
