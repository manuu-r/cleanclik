import 'dart:async';
import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:synchronized/synchronized.dart';

import 'package:cleanclik/core/models/camera_mode.dart';
import 'package:cleanclik/core/models/camera_exceptions.dart';

/// Request model for camera access
class CameraRequest {
  final CameraMode mode;
  final Completer<CameraController> completer;
  final DateTime timestamp;
  final String requestId;

  CameraRequest({
    required this.mode,
    required this.completer,
    required this.timestamp,
    required this.requestId,
  });
}

/// Singleton camera resource manager that handles all camera operations
class CameraResourceManager {
  static final CameraResourceManager _instance =
      CameraResourceManager._internal();
  factory CameraResourceManager() => _instance;
  CameraResourceManager._internal();

  // Thread safety
  final Lock _cameraLock = Lock();

  // Camera state
  CameraController? _activeController;
  CameraMode _currentMode = CameraMode.none;
  CameraStatus _currentStatus = CameraStatus.uninitialized;
  String? _currentError;
  bool _hasPermission = false;

  // State notifications
  final StreamController<CameraState> _stateController =
      StreamController<CameraState>.broadcast();

  // Request queue for concurrent access protection
  final List<CameraRequest> _requestQueue = [];
  bool _isProcessingQueue = false;

  // Performance management
  Timer? _idleTimer;
  bool _isPaused = false;
  static const Duration _idleTimeout = Duration(seconds: 30);
  static const Duration _initTimeout = Duration(seconds: 10);

  // Getters
  Stream<CameraState> get stateStream => _stateController.stream;
  CameraMode get currentMode => _currentMode;
  bool get isInitialized => _currentStatus == CameraStatus.ready;
  CameraController? get activeController => _activeController;

  /// Request camera access for a specific mode
  Future<CameraController> requestCamera(CameraMode mode) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    developer.log(
      'Camera request: $mode (ID: $requestId)',
      name: 'CameraResourceManager',
    );

    final completer = Completer<CameraController>();
    final request = CameraRequest(
      mode: mode,
      completer: completer,
      timestamp: DateTime.now(),
      requestId: requestId,
    );

    _requestQueue.add(request);
    _processRequestQueue();

    return completer.future.timeout(
      _initTimeout,
      onTimeout: () {
        _requestQueue.removeWhere((r) => r.requestId == requestId);
        throw const CameraTimeoutException('Camera request timed out');
      },
    );
  }

  /// Release camera resources
  Future<void> releaseCamera() async {
    return await _cameraLock.synchronized(() async {
      developer.log('Releasing camera', name: 'CameraResourceManager');
      await _disposeCurrentCamera();
      _currentMode = CameraMode.none;
      _currentStatus = CameraStatus.disposed;
      _notifyStateChange();
    });
  }

  /// Pause camera for lifecycle management
  Future<void> pauseCamera() async {
    return await _cameraLock.synchronized(() async {
      if (_activeController != null && !_isPaused) {
        developer.log('Pausing camera', name: 'CameraResourceManager');
        _isPaused = true;
        // Note: Camera plugin doesn't have pause/resume, so we keep it running
        // but mark as paused for state management
        _notifyStateChange();
      }
    });
  }

  /// Resume camera from pause
  Future<void> resumeCamera() async {
    return await _cameraLock.synchronized(() async {
      if (_activeController != null && _isPaused) {
        developer.log('Resuming camera', name: 'CameraResourceManager');
        _isPaused = false;
        _notifyStateChange();
      }
    });
  }

  /// Process the request queue
  Future<void> _processRequestQueue() async {
    if (_isProcessingQueue || _requestQueue.isEmpty) return;

    _isProcessingQueue = true;

    try {
      while (_requestQueue.isNotEmpty) {
        final request = _requestQueue.removeAt(0);

        try {
          await _cameraLock.synchronized(() async {
            await _switchToMode(request.mode);
            if (_activeController != null) {
              request.completer.complete(_activeController!);
            } else {
              request.completer.completeError(
                const CameraInitializationException(
                  'Failed to initialize camera controller',
                ),
              );
            }
          });
        } catch (e) {
          request.completer.completeError(e);
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Switch to a specific camera mode
  Future<void> _switchToMode(CameraMode mode) async {
    if (_currentMode == mode &&
        _activeController?.value.isInitialized == true) {
      developer.log(
        'Already in mode $mode, skipping switch',
        name: 'CameraResourceManager',
      );
      return;
    }

    developer.log('Switching to mode: $mode', name: 'CameraResourceManager');
    _currentStatus = CameraStatus.switching;
    _notifyStateChange();

    try {
      await _disposeCurrentCamera();
      await _initializeCameraForMode(mode);
      _currentMode = mode;
      _currentStatus = CameraStatus.ready;
      _currentError = null;
      _resetIdleTimer();
    } catch (e) {
      _currentStatus = CameraStatus.error;
      _currentError = e.toString();
      developer.log(
        'Camera mode switch failed: $e',
        name: 'CameraResourceManager',
      );
      rethrow;
    } finally {
      _notifyStateChange();
    }
  }

  /// Initialize camera for a specific mode with retry logic
  Future<void> _initializeCameraForMode(CameraMode mode) async {
    if (mode == CameraMode.none) {
      return;
    }

    // Check permissions first
    await _checkAndRequestPermissions();

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw const CameraHardwareException('No cameras available on device');
    }

    final camera = cameras.first;
    final config = _getConfigurationForMode(mode);

    _currentStatus = CameraStatus.initializing;
    _notifyStateChange();

    // Retry logic with exponential backoff
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        _activeController = CameraController(
          camera,
          config.resolution,
          enableAudio: config.enableAudio,
          imageFormatGroup: config.imageFormatGroup,
        );

        await _activeController!.initialize();
        developer.log(
          'Camera initialized successfully for mode: $mode',
          name: 'CameraResourceManager',
        );
        return;
      } catch (e) {
        retryCount++;
        developer.log(
          'Camera init attempt $retryCount failed: $e',
          name: 'CameraResourceManager',
        );

        if (_activeController != null) {
          try {
            await _activeController!.dispose();
          } catch (_) {}
          _activeController = null;
        }

        if (retryCount >= maxRetries) {
          throw CameraInitializationException(
            'Failed to initialize camera after $maxRetries attempts',
            details: e.toString(),
            originalError: e,
          );
        }

        // Exponential backoff
        await Future.delayed(
          Duration(milliseconds: 500 * (1 << (retryCount - 1))),
        );
      }
    }
  }

  /// Get camera configuration for a specific mode
  CameraConfiguration _getConfigurationForMode(CameraMode mode) {
    switch (mode) {
      case CameraMode.qrScanning:
        return CameraConfiguration.forQRScanning;
      case CameraMode.mlDetection:
        return CameraConfiguration.forMLDetection;
      case CameraMode.none:
        return const CameraConfiguration();
    }
  }

  /// Check and request camera permissions
  Future<void> _checkAndRequestPermissions() async {
    final status = await Permission.camera.status;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        throw const CameraPermissionException('Camera permission denied');
      }
    }

    if (status.isPermanentlyDenied) {
      throw const CameraPermissionException(
        'Camera permission permanently denied',
        details: 'Please enable camera permission in device settings',
      );
    }

    _hasPermission = status.isGranted;
  }

  /// Dispose current camera controller
  Future<void> _disposeCurrentCamera() async {
    if (_activeController != null) {
      developer.log(
        'Disposing camera controller',
        name: 'CameraResourceManager',
      );
      try {
        await _activeController!.dispose();
      } catch (e) {
        developer.log(
          'Error disposing camera: $e',
          name: 'CameraResourceManager',
        );
      }
      _activeController = null;
    }
    _cancelIdleTimer();
  }

  /// Build current camera state
  CameraState _buildCameraState() {
    return CameraState(
      mode: _currentMode,
      status: _isPaused ? CameraStatus.switching : _currentStatus,
      errorMessage: _currentError,
      hasPermission: _hasPermission,
      lastUpdated: DateTime.now(),
    );
  }

  /// Notify state change to listeners
  void _notifyStateChange() {
    if (!_stateController.isClosed) {
      final state = _buildCameraState();
      _stateController.add(state);
      developer.log(
        'Camera state changed: ${state.mode} - ${state.status}',
        name: 'CameraResourceManager',
      );
    }
  }

  /// Reset idle timer for performance management
  void _resetIdleTimer() {
    _cancelIdleTimer();
    _idleTimer = Timer(_idleTimeout, () {
      developer.log(
        'Camera idle timeout reached',
        name: 'CameraResourceManager',
      );
      _optimizeForLowMemory();
    });
  }

  /// Cancel idle timer
  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// Optimize camera for low memory situations
  Future<void> _optimizeForLowMemory() async {
    // For now, we'll just log this. In the future, we could:
    // - Reduce camera resolution
    // - Pause preview when not visible
    // - Clear camera buffers
    developer.log(
      'Optimizing camera for low memory',
      name: 'CameraResourceManager',
    );
  }

  /// Dispose the manager (for testing)
  Future<void> dispose() async {
    await _cameraLock.synchronized(() async {
      await _disposeCurrentCamera();
      _cancelIdleTimer();
      await _stateController.close();
      _requestQueue.clear();
    });
  }
}
