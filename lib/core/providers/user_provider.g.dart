// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserProfileHash() =>
    r'5aca8f722b0fa095559feadbdf3a394eae880eb4';

/// See also [currentUserProfile].
@ProviderFor(currentUserProfile)
final currentUserProfileProvider = AutoDisposeProvider<UserProfile?>.internal(
  currentUserProfile,
  name: r'currentUserProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserProfileRef = AutoDisposeProviderRef<UserProfile?>;
String _$userProfileStreamHash() => r'7fb27a7425dc8ae0a7ae6816671563dd83e53258';

/// See also [userProfileStream].
@ProviderFor(userProfileStream)
final userProfileStreamProvider =
    AutoDisposeStreamProvider<UserProfile>.internal(
      userProfileStream,
      name: r'userProfileStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userProfileStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserProfileStreamRef = AutoDisposeStreamProviderRef<UserProfile>;
String _$dashboardStatsHash() => r'8623309875f12d90a7516d7d9de578fe660897a2';

/// See also [dashboardStats].
@ProviderFor(dashboardStats)
final dashboardStatsProvider =
    AutoDisposeFutureProvider<DashboardStats>.internal(
      dashboardStats,
      name: r'dashboardStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dashboardStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DashboardStatsRef = AutoDisposeFutureProviderRef<DashboardStats>;
String _$refreshDashboardStatsHash() =>
    r'dcedc3eb3f7e8a243330d566d3f907e99f476ed3';

/// See also [refreshDashboardStats].
@ProviderFor(refreshDashboardStats)
final refreshDashboardStatsProvider =
    AutoDisposeFutureProvider<DashboardStats>.internal(
      refreshDashboardStats,
      name: r'refreshDashboardStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$refreshDashboardStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RefreshDashboardStatsRef = AutoDisposeFutureProviderRef<DashboardStats>;
String _$syncedCurrentUserHash() => r'2930ef2893235e3ba946e8e2b5265b4067cf41db';

/// See also [syncedCurrentUser].
@ProviderFor(syncedCurrentUser)
final syncedCurrentUserProvider = AutoDisposeFutureProvider<User?>.internal(
  syncedCurrentUser,
  name: r'syncedCurrentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncedCurrentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncedCurrentUserRef = AutoDisposeFutureProviderRef<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
