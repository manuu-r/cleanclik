# Design Document

## Overview

This design implements a centralized camera resource management system for VibeSweep that ensures proper camera passing between QR scanning mode and ML mode (object/hand detection). The solution uses a singleton camera manager with state synchronization, resource pooling, and robust error recovery to prevent crashes and resource conflicts during mode transitions.

## Architecture

### Centralized Camera Resource Manager
- Implement a singleton `CameraResourceManager` that controls all camera access across the app
- Use a state machine pattern to manage camera mode transitions
- Implement resource pooling to reuse camera instances when possible
- Add queue-based request handling to prevent concurrent camera access conflicts

### Camera State Synchronization
- Use Riverpod providers for reactive state management across all camera-dependent components
- Implement a unified `CameraState` model that tracks current mode, initialization status, and resource availability
- Add event-driven notifications for camera state changes to keep all components synchronized

### Thread-Safe Operations
- Use mutex locks for critical camera operations to prevent race conditions
- Implement async/await patterns with proper error handling for all camera operations
- Add timeout mechanisms to prevent indefinite blocking on camera operations

## Components and Interfaces

### 1. Camera Resource Manager (Singleton)
```dart
class CameraResourceManager {
  static final CameraResourceManager _instance = CameraResourceManager._internal();
  factory CameraResourceManager() => _instance;
  CameraResourceManager._internal();

  final Mutex _cameraLock = Mutex();
  CameraController? _activeController;
  CameraMode _currentMode = CameraMode.none;
  final StreamController<CameraState> _stateController = StreamController.broadcast();

  Stream<CameraState> get stateStream => _stateController.stream;
  CameraMode get currentMode => _currentMode;
  bool get isInitialized => _activeController?.value.isInitialized ?? false;

  Future<CameraController> requestCamera(CameraMode mode) async {
    return await _cameraLock.protect(() async {
      await _switchToMode(mode);
      return _activeController!;
    });
  }

  Future<void> releaseCamera() async {
    await _cameraLock.protect(() async {
      await _disposeCurrentCamera();
    });
  }

  Future<void> _switchToMode(CameraMode mode) async {
    if (_currentMode == mode && _activeController?.value.isInitialized == true) {
      return; // Already in correct mode
    }

    await _disposeCurrentCamera();
    await _initializeCameraForMode(mode);
    _currentMode = mode;
    _notifyStateChange();
  }
}
```

### 2. Enhanced Camera State Model
```dart
enum CameraMode { none, qrScanning, mlDetection }

enum CameraStatus { 
  uninitialized, 
  initializing, 
  ready, 
  switching, 
  error, 
  disposed 
}

class CameraState {
  final CameraMode mode;
  final CameraStatus status;
  final String? errorMessage;
  final bool hasPermission;
  final DateTime lastUpdated;

  const CameraState({
    required this.mode,
    required this.status,
    this.errorMessage,
    required this.hasPermission,
    required this.lastUpdated,
  });

  bool get isReady => status == CameraStatus.ready;
  bool get canSwitch => status == CameraStatus.ready || status == CameraStatus.error;
}
```

### 3. Camera Provider (Riverpod)
```dart
@riverpod
class CameraNotifier extends _$CameraNotifier {
  late final CameraResourceManager _manager;

  @override
  CameraState build() {
    _manager = CameraResourceManager();
    _manager.stateStream.listen((state) {
      this.state = state;
    });
    
    return const CameraState(
      mode: CameraMode.none,
      status: CameraStatus.uninitialized,
      hasPermission: false,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> switchToQRMode() async {
    state = state.copyWith(status: CameraStatus.switching);
    try {
      await _manager.requestCamera(CameraMode.qrScanning);
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> switchToMLMode() async {
    state = state.copyWith(status: CameraStatus.switching);
    try {
      await _manager.requestCamera(CameraMode.mlDetection);
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
```

### 4. QR Scanner Integration
```dart
class QRScannerWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends ConsumerState<QRScannerWidget> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = await CameraResourceManager().requestCamera(CameraMode.qrScanning);
      if (mounted) setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    // Camera disposal is handled by CameraResourceManager
    super.dispose();
  }
}
```

### 5. ML Detection Integration
```dart
class MLDetectionWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MLDetectionWidget> createState() => _MLDetectionWidgetState();
}

class _MLDetectionWidgetState extends ConsumerState<MLDetectionWidget> {
  CameraController? _controller;
  ObjectDetector? _objectDetector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = await CameraResourceManager().requestCamera(CameraMode.mlDetection);
      _objectDetector = ObjectDetector(options: ObjectDetectorOptions());
      if (mounted) setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _objectDetector?.close();
    // Camera disposal is handled by CameraResourceManager
    super.dispose();
  }
}
```

## Data Models

### Camera Request Model
```dart
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
```

### Camera Configuration Model
```dart
class CameraConfiguration {
  final ResolutionPreset resolution;
  final bool enableAudio;
  final CameraLensDirection lensDirection;
  final ImageFormatGroup? imageFormatGroup;

  const CameraConfiguration({
    this.resolution = ResolutionPreset.medium,
    this.enableAudio = false,
    this.lensDirection = CameraLensDirection.back,
    this.imageFormatGroup,
  });

  static CameraConfiguration forQRScanning() => const CameraConfiguration(
    resolution: ResolutionPreset.medium,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );

  static CameraConfiguration forMLDetection() => const CameraConfiguration(
    resolution: ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.nv21,
  );
}
```

## Error Handling

### Camera Initialization Errors
- Implement exponential backoff retry mechanism with maximum 3 attempts
- Provide specific error messages for permission denied, hardware unavailable, and initialization timeout
- Offer fallback options like manual QR code entry or photo upload for ML detection

### Resource Conflict Resolution
- Detect when multiple components request camera access simultaneously
- Queue requests and process them sequentially with timeout handling
- Implement priority system where user-initiated actions take precedence

### Memory and Performance Management
- Monitor camera resource usage and implement automatic cleanup for idle cameras
- Use weak references where possible to prevent memory leaks
- Implement camera preview pausing when not visible to conserve resources

### Lifecycle Management
- Handle app backgrounding/foregrounding with proper camera pause/resume
- Manage device orientation changes without losing camera state
- Implement proper cleanup on app termination

## Testing Strategy

### Unit Tests
- Test camera resource manager singleton behavior
- Test state synchronization across multiple components
- Test error handling and retry mechanisms
- Test thread safety with concurrent access scenarios

### Widget Tests
- Test QR scanner widget with mocked camera controller
- Test ML detection widget with mocked camera and detector
- Test error state rendering and recovery UI
- Test camera permission request flows

### Integration Tests
- Test complete mode switching flow from QR to ML and back
- Test camera resource cleanup during app lifecycle changes
- Test performance under rapid mode switching scenarios
- Test error recovery with actual camera hardware

### Performance Tests
- Measure mode switching latency on various device tiers
- Test memory usage during extended camera sessions
- Verify camera resource cleanup prevents memory leaks
- Test battery impact of camera management optimizations