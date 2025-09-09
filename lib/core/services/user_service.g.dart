// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userServiceHash() => r'2a4da7916defc7691ed2f71000beb744984bf3c2';

/// Provider for UserService
///
/// Copied from [userService].
@ProviderFor(userService)
final userServiceProvider = AutoDisposeProvider<UserService>.internal(
  userService,
  name: r'userServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserServiceRef = AutoDisposeProviderRef<UserService>;
String _$currentUserHash() => r'6c3ffa408c05731997e273a063b01ea77a4b1d83';

/// Provider for current user
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeStreamProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeStreamProviderRef<User?>;
String _$authStateHash() => r'cc1079a19a2ca069615b6942ab12a3156390ba95';

/// Provider for authentication state
///
/// Copied from [authState].
@ProviderFor(authState)
final authStateProvider = AutoDisposeStreamProvider<bool>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateRef = AutoDisposeStreamProviderRef<bool>;
String _$userStatsHash() => r'd0b214cb029faa9a3919ee7fc4268055c1c46ad5';

/// Provider for user statistics
///
/// Copied from [userStats].
@ProviderFor(userStats)
final userStatsProvider = AutoDisposeProvider<Map<String, dynamic>>.internal(
  userStats,
  name: r'userStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserStatsRef = AutoDisposeProviderRef<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
