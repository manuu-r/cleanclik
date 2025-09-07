import 'dart:async';
import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/camera_mode.dart';
import '../services/camera_resource_manager.dart';

part 'camera_provider.g.dart';

/// Camera state notifier provider
@riverpod
class CameraNotifier extends _$CameraNotifier {
  late final CameraResourceManager _manager;
  StreamSubscription<CameraState>? _stateSubscription;

  @override
  CameraState build() {
    _manager = CameraResourceManager();
    
    // Listen to camera state changes
    _stateSubscription = _manager.stateStream.listen((newState) {
      // Check if the provider is still active before updating state
      if (!ref.exists(cameraNotifierProvider)) return;
      state = newState;
    });
    
    // Cleanup when provider is disposed
    ref.onDispose(() {
      _stateSubscription?.cancel();
      developer.log('CameraNotifier disposed', name: 'CameraProvider');
    });
    
    return CameraState.initial;
  }

  /// Switch to QR scanning mode
  Future<void> switchToQRMode() async {
    if (state.status == CameraStatus.switching) {
      developer.log('Camera already switching, ignoring QR mode request', name: 'CameraProvider');
      return;
    }

    try {
      state = state.copyWith(
        status: CameraStatus.switching,
        errorMessage: null,
      );
      
      await _manager.requestCamera(CameraMode.qrScanning);
      developer.log('Successfully switched to QR mode', name: 'CameraProvider');
    } catch (e) {
      developer.log('Failed to switch to QR mode: $e', name: 'CameraProvider');
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Switch to ML detection mode
  Future<void> switchToMLMode() async {
    if (state.status == CameraStatus.switching) {
      developer.log('Camera already switching, ignoring ML mode request', name: 'CameraProvider');
      return;
    }

    try {
      state = state.copyWith(
        status: CameraStatus.switching,
        errorMessage: null,
      );
      
      await _manager.requestCamera(CameraMode.mlDetection);
      developer.log('Successfully switched to ML mode', name: 'CameraProvider');
    } catch (e) {
      developer.log('Failed to switch to ML mode: $e', name: 'CameraProvider');
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Release camera resources
  Future<void> releaseCamera() async {
    try {
      await _manager.releaseCamera();
      developer.log('Camera resources released', name: 'CameraProvider');
    } catch (e) {
      developer.log('Failed to release camera: $e', name: 'CameraProvider');
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Pause camera for app lifecycle
  Future<void> pauseCamera() async {
    try {
      await _manager.pauseCamera();
      developer.log('Camera paused', name: 'CameraProvider');
    } catch (e) {
      developer.log('Failed to pause camera: $e', name: 'CameraProvider');
    }
  }

  /// Resume camera from pause
  Future<void> resumeCamera() async {
    try {
      await _manager.resumeCamera();
      developer.log('Camera resumed', name: 'CameraProvider');
    } catch (e) {
      developer.log('Failed to resume camera: $e', name: 'CameraProvider');
    }
  }

  /// Clear error state
  void clearError() {
    if (state.status == CameraStatus.error) {
      state = state.copyWith(
        status: CameraStatus.uninitialized,
        errorMessage: null,
      );
    }
  }

  /// Get camera controller for direct access (use with caution)
  CameraController? getCameraController() {
    return _manager.activeController;
  }
}

/// Provider for accessing camera state
@riverpod
CameraState cameraState(Ref ref) {
  return ref.watch(cameraNotifierProvider);
}

/// Provider for checking if camera is ready
@riverpod
bool isCameraReady(Ref ref) {
  final state = ref.watch(cameraStateProvider);
  return state.isReady;
}

/// Provider for checking if camera can switch modes
@riverpod
bool canSwitchCameraMode(Ref ref) {
  final state = ref.watch(cameraStateProvider);
  return state.canSwitch;
}

/// Provider for current camera mode
@riverpod
CameraMode currentCameraMode(Ref ref) {
  final state = ref.watch(cameraStateProvider);
  return state.mode;
}