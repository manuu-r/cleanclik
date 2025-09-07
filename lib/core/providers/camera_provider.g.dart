// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cameraStateHash() => r'eacf0d8516341c74bd0bebdf966f97d75628c058';

/// Provider for accessing camera state
///
/// Copied from [cameraState].
@ProviderFor(cameraState)
final cameraStateProvider = AutoDisposeProvider<CameraState>.internal(
  cameraState,
  name: r'cameraStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cameraStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CameraStateRef = AutoDisposeProviderRef<CameraState>;
String _$isCameraReadyHash() => r'eb673f217a7f8bdef9a6905f72bc73ce75eb7317';

/// Provider for checking if camera is ready
///
/// Copied from [isCameraReady].
@ProviderFor(isCameraReady)
final isCameraReadyProvider = AutoDisposeProvider<bool>.internal(
  isCameraReady,
  name: r'isCameraReadyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isCameraReadyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsCameraReadyRef = AutoDisposeProviderRef<bool>;
String _$canSwitchCameraModeHash() =>
    r'011c5c8231491dd68943dd49229010f97c830865';

/// Provider for checking if camera can switch modes
///
/// Copied from [canSwitchCameraMode].
@ProviderFor(canSwitchCameraMode)
final canSwitchCameraModeProvider = AutoDisposeProvider<bool>.internal(
  canSwitchCameraMode,
  name: r'canSwitchCameraModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canSwitchCameraModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanSwitchCameraModeRef = AutoDisposeProviderRef<bool>;
String _$currentCameraModeHash() => r'5fd5ffce171603e486b46d8f8ea29f8fbe612461';

/// Provider for current camera mode
///
/// Copied from [currentCameraMode].
@ProviderFor(currentCameraMode)
final currentCameraModeProvider = AutoDisposeProvider<CameraMode>.internal(
  currentCameraMode,
  name: r'currentCameraModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentCameraModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentCameraModeRef = AutoDisposeProviderRef<CameraMode>;
String _$cameraNotifierHash() => r'90929df07e121766d20ab19a49c34f0261ff716f';

/// Camera state notifier provider
///
/// Copied from [CameraNotifier].
@ProviderFor(CameraNotifier)
final cameraNotifierProvider =
    AutoDisposeNotifierProvider<CameraNotifier, CameraState>.internal(
      CameraNotifier.new,
      name: r'cameraNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cameraNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CameraNotifier = AutoDisposeNotifier<CameraState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
