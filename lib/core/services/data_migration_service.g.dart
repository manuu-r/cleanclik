// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_migration_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dataMigrationServiceHash() =>
    r'2e7820d2f3d371f813740cb326df7fdae66e326c';

/// Provider for DataMigrationService
///
/// Copied from [dataMigrationService].
@ProviderFor(dataMigrationService)
final dataMigrationServiceProvider =
    AutoDisposeProvider<DataMigrationService>.internal(
      dataMigrationService,
      name: r'dataMigrationServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dataMigrationServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DataMigrationServiceRef = AutoDisposeProviderRef<DataMigrationService>;
String _$migrationStatusStreamHash() =>
    r'059d4305e8d87252b4d2536a74ec56b2954a5530';

/// Provider for migration status stream
///
/// Copied from [migrationStatusStream].
@ProviderFor(migrationStatusStream)
final migrationStatusStreamProvider =
    AutoDisposeStreamProvider<SyncStatus>.internal(
      migrationStatusStream,
      name: r'migrationStatusStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$migrationStatusStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MigrationStatusStreamRef = AutoDisposeStreamProviderRef<SyncStatus>;
String _$sharedPreferencesProviderHash() =>
    r'376c8f5d29f1f9ebe7ae053414a61a402cc7683e';

/// Provider for SharedPreferences
///
/// Copied from [sharedPreferencesProvider].
@ProviderFor(sharedPreferencesProvider)
final sharedPreferencesProviderProvider =
    AutoDisposeFutureProvider<SharedPreferences>.internal(
      sharedPreferencesProvider,
      name: r'sharedPreferencesProviderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sharedPreferencesProviderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPreferencesProviderRef =
    AutoDisposeFutureProviderRef<SharedPreferences>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
