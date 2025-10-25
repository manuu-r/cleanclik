// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_link_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deepLinkServiceHash() => r'339338edfe65cb34f7a9ee4f031d973ba1976446';

/// Provider for DeepLinkService
///
/// Copied from [deepLinkService].
@ProviderFor(deepLinkService)
final deepLinkServiceProvider =
    AutoDisposeFutureProvider<DeepLinkService>.internal(
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
typedef DeepLinkServiceRef = AutoDisposeFutureProviderRef<DeepLinkService>;
String _$deepLinkInitializationHash() =>
    r'047b6a00f72b8a551b6dc58be9bb9ac8b6e370cf';

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
