// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tokenServiceHash() => r'3caad32df5095eafc8e5661df4a3acf0fbe61e35';

/// Provider for TokenService
///
/// Copied from [tokenService].
@ProviderFor(tokenService)
final tokenServiceProvider = AutoDisposeProvider<TokenService>.internal(
  tokenService,
  name: r'tokenServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tokenServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TokenServiceRef = AutoDisposeProviderRef<TokenService>;
String _$tokenValidityHash() => r'e658b5be1dbcda5e4e8c1058e96453e9364e0926';

/// Provider for token validity stream
///
/// Copied from [tokenValidity].
@ProviderFor(tokenValidity)
final tokenValidityProvider = AutoDisposeStreamProvider<bool>.internal(
  tokenValidity,
  name: r'tokenValidityProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tokenValidityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TokenValidityRef = AutoDisposeStreamProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
