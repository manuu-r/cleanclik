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
