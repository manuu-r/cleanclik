import 'package:cleanclik/core/models/camera_mode.dart';
import '../test_data_factory.dart';
import '../../test_config.dart';

/// Comprehensive mock camera states for all testing scenarios
class MockCameraStates {
  /// Get all predefined camera state fixtures
  static Map<String, Map<String, dynamic>> getAllCameraStates() {
    return TestDataFactory.createCameraStateFixtures();
  }

  /// Get initializing camera state
  static Map<String, dynamic> getInitializingState({
    CameraMode mode = CameraMode.mlDetection,
  }) {
    return TestDataFactory.createMockCameraState(
      mode: mode,
      status: 'initializing',
      isInitialized: false,
      isDetecting: false,
    );
  }

  /// Get ready camera state
  static Map<String, dynamic> getReadyState({
    CameraMode mode = CameraMode.mlDetection,
  }) {
    return TestDataFactory.createMockCameraState(
      mode: mode,
      status: 'ready',
      isInitialized: true,
      isDetecting: false,
    );
  }

  /// Get detecting/scanning state
  static Map<String, dynamic> getDetectingState({
    CameraMode mode = CameraMode.mlDetection,
  }) {
    final status = mode == CameraMode.mlDetection ? 'detecting' : 'scanning';
    return TestDataFactory.createMockCameraState(
      mode: mode,
      status: status,
      isInitialized: true,
      isDetecting: true,
    );
  }

  /// Get camera error state
  static Map<String, dynamic> getErrorState({
    CameraMode mode = CameraMode.mlDetection,
    String? customError,
  }) {
    return TestDataFactory.createMockCameraState(
      mode: mode,
      status: 'error',
      isInitialized: false,
      isDetecting: false,
      error: customError ?? 'Camera initialization failed',
    );
  }

  /// Get permission denied state
  static Map<String, dynamic> getPermissionDeniedState() {
    return TestDataFactory.createMockCameraState(
      mode: CameraMode.mlDetection,
      status: 'error',
      isInitialized: false,
      isDetecting: false,
      error: 'Camera permission denied',
    );
  }

  /// Get camera unavailable state
  static Map<String, dynamic> getCameraUnavailableState() {
    return TestDataFactory.createMockCameraState(
      mode: CameraMode.mlDetection,
      status: 'error',
      isInitialized: false,
      isDetecting: false,
      error: 'Camera not available on this device',
    );
  }

  /// Get paused camera state
  static Map<String, dynamic> getPausedState({
    CameraMode mode = CameraMode.mlDetection,
  }) {
    return TestDataFactory.createMockCameraState(
      mode: mode,
      status: 'paused',
      isInitialized: true,
      isDetecting: false,
    );
  }

  /// Get disposed camera state
  static Map<String, dynamic> getDisposedState() {
    return TestDataFactory.createMockCameraState(
      mode: CameraMode.mlDetection,
      status: 'disposed',
      isInitialized: false,
      isDetecting: false,
    );
  }

  /// Create camera state transition sequence for testing flows
  static List<Map<String, dynamic>> createCameraFlowSequence({
    required String flowType,
    CameraMode mode = CameraMode.mlDetection,
  }) {
    switch (flowType) {
      case 'initialization':
        return [
          getInitializingState(mode: mode),
          getReadyState(mode: mode),
        ];
      
      case 'start_detection':
        return [
          getReadyState(mode: mode),
          getDetectingState(mode: mode),
        ];
      
      case 'stop_detection':
        return [
          getDetectingState(mode: mode),
          getReadyState(mode: mode),
        ];
      
      case 'mode_switch':
        final otherMode = mode == CameraMode.mlDetection 
            ? CameraMode.qrScanning 
            : CameraMode.mlDetection;
        return [
          getDetectingState(mode: mode),
          getReadyState(mode: mode),
          getInitializingState(mode: otherMode),
          getReadyState(mode: otherMode),
        ];
      
      case 'pause_resume':
        return [
          getDetectingState(mode: mode),
          getPausedState(mode: mode),
          getReadyState(mode: mode),
          getDetectingState(mode: mode),
        ];
      
      case 'error_recovery':
        return [
          getReadyState(mode: mode),
          getErrorState(mode: mode),
          getInitializingState(mode: mode),
          getReadyState(mode: mode),
        ];
      
      case 'permission_flow':
        return [
          getPermissionDeniedState(),
          getInitializingState(mode: mode),
          getReadyState(mode: mode),
        ];
      
      case 'disposal':
        return [
          getDetectingState(mode: mode),
          getPausedState(mode: mode),
          getDisposedState(),
        ];
      
      default:
        return [getReadyState(mode: mode)];
    }
  }

  /// Get camera states for performance testing
  static Map<String, Map<String, dynamic>> getPerformanceTestStates() {
    return {
      'high_performance': {
        ...getDetectingState(mode: CameraMode.mlDetection),
        'performance': {
          'fps': 30.0,
          'processingTime': 80, // milliseconds
          'memoryUsage': 45.2, // MB
          'cpuUsage': 25.5, // percentage
          'batteryDrain': 1.2, // percentage per minute
        },
      },
      'medium_performance': {
        ...getDetectingState(mode: CameraMode.mlDetection),
        'performance': {
          'fps': 20.0,
          'processingTime': 120, // milliseconds
          'memoryUsage': 65.8, // MB
          'cpuUsage': 45.2, // percentage
          'batteryDrain': 2.1, // percentage per minute
        },
      },
      'low_performance': {
        ...getDetectingState(mode: CameraMode.mlDetection),
        'performance': {
          'fps': 12.0,
          'processingTime': 180, // milliseconds
          'memoryUsage': 85.4, // MB
          'cpuUsage': 65.8, // percentage
          'batteryDrain': 3.5, // percentage per minute
        },
      },
      'performance_warning': {
        ...getDetectingState(mode: CameraMode.mlDetection),
        'performance': {
          'fps': 8.0,
          'processingTime': 250, // milliseconds
          'memoryUsage': 95.2, // MB
          'cpuUsage': 80.1, // percentage
          'batteryDrain': 5.2, // percentage per minute
        },
        'warnings': [
          'Low frame rate detected',
          'High memory usage',
          'Consider reducing detection frequency',
        ],
      },
    };
  }

  /// Get camera states for different device capabilities
  static Map<String, Map<String, dynamic>> getDeviceCapabilityStates() {
    return {
      'high_end_device': {
        ...getReadyState(mode: CameraMode.mlDetection),
        'capabilities': {
          'maxResolution': '4K',
          'hasAutoFocus': true,
          'hasFlash': true,
          'hasOpticalStabilization': true,
          'mlKitSupport': 'full',
          'arSupport': true,
          'maxSimultaneousObjects': TestConfig.maxSimultaneousObjects,
        },
      },
      'mid_range_device': {
        ...getReadyState(mode: CameraMode.mlDetection),
        'capabilities': {
          'maxResolution': '1080p',
          'hasAutoFocus': true,
          'hasFlash': true,
          'hasOpticalStabilization': false,
          'mlKitSupport': 'limited',
          'arSupport': false,
          'maxSimultaneousObjects': 5,
        },
      },
      'low_end_device': {
        ...getReadyState(mode: CameraMode.mlDetection),
        'capabilities': {
          'maxResolution': '720p',
          'hasAutoFocus': false,
          'hasFlash': false,
          'hasOpticalStabilization': false,
          'mlKitSupport': 'basic',
          'arSupport': false,
          'maxSimultaneousObjects': 2,
        },
      },
      'no_camera_device': {
        ...getCameraUnavailableState(),
        'capabilities': {
          'maxResolution': null,
          'hasAutoFocus': false,
          'hasFlash': false,
          'hasOpticalStabilization': false,
          'mlKitSupport': 'none',
          'arSupport': false,
          'maxSimultaneousObjects': 0,
        },
      },
    };
  }

  /// Get camera states for different lighting conditions
  static Map<String, Map<String, dynamic>> getLightingConditionStates() {
    return {
      'bright_lighting': {
        ...getDetectingState(mode: CameraMode.mlDetection),
        'lighting': {
          'condition': 'bright',
          'lux': 1000,
          'autoExposure': false,
          'flashRecommended': false,
          'detectionAccuracy': 0.95,
        },
      },
      'normal_lighting': {
        ...getDetectingState(mode: CameraMode.mlDetection),
        'lighting': {
          'condition': 'normal',
          'lux': 300,
          'autoExposure': true,
          'flashRecommended': false,
          'detectionAccuracy': 0.88,
        },
      },
      'low_lighting': {
        ...getDetectingState(mode: CameraMode.mlDetection),
        'lighting': {
          'condition': 'low',
          'lux': 50,
          'autoExposure': true,
          'flashRecommended': true,
          'detectionAccuracy': 0.65,
        },
        'warnings': [
          'Low light conditions detected',
          'Consider using flash for better detection',
        ],
      },
      'very_dark': {
        ...getDetectingState(mode: CameraMode.mlDetection),
        'lighting': {
          'condition': 'very_dark',
          'lux': 5,
          'autoExposure': true,
          'flashRecommended': true,
          'detectionAccuracy': 0.35,
        },
        'warnings': [
          'Very low light conditions',
          'Detection accuracy significantly reduced',
          'Flash strongly recommended',
        ],
      },
    };
  }

  /// Get camera states for error conditions
  static Map<String, Map<String, dynamic>> getErrorStates() {
    return {
      'permission_denied': getPermissionDeniedState(),
      'camera_unavailable': getCameraUnavailableState(),
      'initialization_failed': getErrorState(
        customError: 'Failed to initialize camera',
      ),
      'ml_kit_error': getErrorState(
        customError: 'ML Kit initialization failed',
      ),
      'memory_error': getErrorState(
        customError: 'Insufficient memory for camera operations',
      ),
      'hardware_error': getErrorState(
        customError: 'Camera hardware malfunction',
      ),
      'timeout_error': getErrorState(
        customError: 'Camera initialization timeout',
      ),
      'resource_busy': getErrorState(
        customError: 'Camera is being used by another application',
      ),
    };
  }

  /// Create camera state with specific detection results
  static Map<String, dynamic> createStateWithDetections({
    CameraMode mode = CameraMode.mlDetection,
    int objectCount = 3,
    List<Map<String, dynamic>>? customDetections,
  }) {
    final detections = customDetections ?? 
        TestDataFactory.createMockDetectedObjects(count: objectCount);
    
    return {
      ...getDetectingState(mode: mode),
      'detections': detections,
      'detectionCount': detections.length,
      'lastDetectionTime': DateTime.now().toIso8601String(),
    };
  }

  /// Create camera state with QR scan result
  static Map<String, dynamic> createStateWithQRResult({
    String? qrData,
    bool scanSuccessful = true,
  }) {
    return {
      ...getDetectingState(mode: CameraMode.qrScanning),
      'qrResult': {
        'data': qrData ?? 'BIN_RECYCLE_001',
        'successful': scanSuccessful,
        'timestamp': DateTime.now().toIso8601String(),
        'format': 'QR_CODE',
      },
    };
  }

  /// Get camera state validation helpers
  static Map<String, bool Function(Map<String, dynamic>)> getValidationHelpers() {
    return {
      'isInitialized': (state) => state['isInitialized'] == true,
      'isDetecting': (state) => state['isDetecting'] == true,
      'hasError': (state) => state['error'] != null,
      'isMLMode': (state) => state['mode'] == CameraMode.mlDetection.name,
      'isQRMode': (state) => state['mode'] == CameraMode.qrScanning.name,
      'isReady': (state) => state['status'] == 'ready' && state['isInitialized'] == true,
      'isPaused': (state) => state['status'] == 'paused',
      'isDisposed': (state) => state['status'] == 'disposed',
      'hasPermission': (state) => state['error'] != 'Camera permission denied',
      'hasDetections': (state) => 
          state['detections'] != null && 
          (state['detections'] as List).isNotEmpty,
      'hasQRResult': (state) => state['qrResult'] != null,
      'isPerformant': (state) {
        final performance = state['performance'];
        if (performance == null) return true;
        return performance['fps'] >= 15.0 && 
               performance['processingTime'] <= TestConfig.mlProcessingThreshold.inMilliseconds;
      },
    };
  }

  /// Create camera state stream for testing real-time updates
  static Stream<Map<String, dynamic>> createCameraStateStream({
    Duration interval = const Duration(milliseconds: 100),
    List<Map<String, dynamic>>? stateSequence,
    CameraMode mode = CameraMode.mlDetection,
  }) async* {
    final sequence = stateSequence ?? [
      getInitializingState(mode: mode),
      getReadyState(mode: mode),
      getDetectingState(mode: mode),
    ];

    for (final state in sequence) {
      yield state;
      await Future.delayed(interval);
    }
  }

  /// Get camera states for integration testing
  static Map<String, Map<String, dynamic>> getIntegrationTestStates() {
    return {
      'fresh_start': getInitializingState(),
      'ready_for_detection': getReadyState(),
      'actively_detecting': createStateWithDetections(objectCount: 2),
      'qr_scanning_ready': getReadyState(mode: CameraMode.qrScanning),
      'qr_scan_successful': createStateWithQRResult(scanSuccessful: true),
      'qr_scan_failed': createStateWithQRResult(scanSuccessful: false),
      'mode_switching': getInitializingState(mode: CameraMode.qrScanning),
      'performance_degraded': getPerformanceTestStates()['low_performance']!,
      'error_recovery': getErrorStates()['initialization_failed']!,
      'clean_shutdown': getDisposedState(),
    };
  }

  /// Create camera configuration for testing
  static Map<String, dynamic> createCameraConfiguration({
    String deviceType = 'high_end',
    String lightingCondition = 'normal',
  }) {
    final deviceState = getDeviceCapabilityStates()[deviceType + '_device'] ?? 
                       getDeviceCapabilityStates()['mid_range_device']!;
    final lightingState = getLightingConditionStates()[lightingCondition + '_lighting'] ?? 
                         getLightingConditionStates()['normal_lighting']!;

    return {
      'device': deviceState['capabilities'],
      'lighting': lightingState['lighting'],
      'settings': {
        'resolution': deviceState['capabilities']['maxResolution'],
        'autoFocus': deviceState['capabilities']['hasAutoFocus'],
        'flash': lightingState['lighting']['flashRecommended'],
        'detectionFrequency': lightingState['lighting']['detectionAccuracy'] > 0.8 ? 'high' : 'medium',
      },
    };
  }
}