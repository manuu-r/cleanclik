// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$globalSyncStatusHash() => r'55ce1c04fb29154de8b19e468bdd76148a161f48';

/// Provider for global sync status stream - simplified
///
/// Copied from [globalSyncStatus].
@ProviderFor(globalSyncStatus)
final globalSyncStatusProvider =
    AutoDisposeStreamProvider<GlobalSyncStatus>.internal(
      globalSyncStatus,
      name: r'globalSyncStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$globalSyncStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GlobalSyncStatusRef = AutoDisposeStreamProviderRef<GlobalSyncStatus>;
String _$syncStatisticsHash() => r'00282578dc931c3a8dc3db2d9e15bb7290894046';

/// Provider for sync statistics
///
/// Copied from [syncStatistics].
@ProviderFor(syncStatistics)
final syncStatisticsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
      syncStatistics,
      name: r'syncStatisticsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncStatisticsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncStatisticsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$syncServiceNotifierHash() =>
    r'62049efe6fac2e0812645d18792230051b0c7329';

/// Provider for SyncService - using keepAlive to prevent frequent recreation
///
/// Copied from [SyncServiceNotifier].
@ProviderFor(SyncServiceNotifier)
final syncServiceNotifierProvider =
    AutoDisposeNotifierProvider<SyncServiceNotifier, SyncService>.internal(
      SyncServiceNotifier.new,
      name: r'syncServiceNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncServiceNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SyncServiceNotifier = AutoDisposeNotifier<SyncService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
