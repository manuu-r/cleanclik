// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_link_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deepLinkServiceHash() => r'c7ca9823090cac5d39391a0b6fbe338fa1c9a471';

/// Provider for DeepLinkService
///
/// Copied from [deepLinkService].
@ProviderFor(deepLinkService)
final deepLinkServiceProvider = AutoDisposeProvider<DeepLinkService>.internal(
  deepLinkService,
  name: r'deepLinkServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deepLinkServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeepLinkServiceRef = AutoDisposeProviderRef<DeepLinkService>;
String _$deepLinkInitializationHash() =>
    r'18cbd7b6a6838694962096abe6f80a506dd38641';

/// Provider for deep link initialization status
///
/// Copied from [DeepLinkInitialization].
@ProviderFor(DeepLinkInitialization)
final deepLinkInitializationProvider =
    AutoDisposeAsyncNotifierProvider<DeepLinkInitialization, bool>.internal(
      DeepLinkInitialization.new,
      name: r'deepLinkInitializationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$deepLinkInitializationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DeepLinkInitialization = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
