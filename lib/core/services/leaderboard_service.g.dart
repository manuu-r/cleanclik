// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leaderboardServiceHash() =>
    r'61c19eac6b56b4f25d3bff37cf8323dab3fa71da';

/// Provider for LeaderboardService
///
/// Copied from [leaderboardService].
@ProviderFor(leaderboardService)
final leaderboardServiceProvider =
    AutoDisposeFutureProvider<LeaderboardService>.internal(
      leaderboardService,
      name: r'leaderboardServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaderboardServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeaderboardServiceRef =
    AutoDisposeFutureProviderRef<LeaderboardService>;
String _$leaderboardHash() => r'4591c572330ecde71c1bf1b8041fa3128d973538';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider for leaderboard page data
///
/// Copied from [leaderboard].
@ProviderFor(leaderboard)
const leaderboardProvider = LeaderboardFamily();

/// Provider for leaderboard page data
///
/// Copied from [leaderboard].
class LeaderboardFamily extends Family<AsyncValue<List<LeaderboardEntry>>> {
  /// Provider for leaderboard page data
  ///
  /// Copied from [leaderboard].
  const LeaderboardFamily();

  /// Provider for leaderboard page data
  ///
  /// Copied from [leaderboard].
  LeaderboardProvider call({required LeaderboardPeriod period}) {
    return LeaderboardProvider(period: period);
  }

  @override
  LeaderboardProvider getProviderOverride(
    covariant LeaderboardProvider provider,
  ) {
    return call(period: provider.period);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'leaderboardProvider';
}

/// Provider for leaderboard page data
///
/// Copied from [leaderboard].
class LeaderboardProvider
    extends AutoDisposeFutureProvider<List<LeaderboardEntry>> {
  /// Provider for leaderboard page data
  ///
  /// Copied from [leaderboard].
  LeaderboardProvider({required LeaderboardPeriod period})
    : this._internal(
        (ref) => leaderboard(ref as LeaderboardRef, period: period),
        from: leaderboardProvider,
        name: r'leaderboardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leaderboardHash,
        dependencies: LeaderboardFamily._dependencies,
        allTransitiveDependencies: LeaderboardFamily._allTransitiveDependencies,
        period: period,
      );

  LeaderboardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.period,
  }) : super.internal();

  final LeaderboardPeriod period;

  @override
  Override overrideWith(
    FutureOr<List<LeaderboardEntry>> Function(LeaderboardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeaderboardProvider._internal(
        (ref) => create(ref as LeaderboardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        period: period,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<LeaderboardEntry>> createElement() {
    return _LeaderboardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaderboardProvider && other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LeaderboardRef on AutoDisposeFutureProviderRef<List<LeaderboardEntry>> {
  /// The parameter `period` of this provider.
  LeaderboardPeriod get period;
}

class _LeaderboardProviderElement
    extends AutoDisposeFutureProviderElement<List<LeaderboardEntry>>
    with LeaderboardRef {
  _LeaderboardProviderElement(super.provider);

  @override
  LeaderboardPeriod get period => (origin as LeaderboardProvider).period;
}

String _$achievementCardsHash() => r'3e2b3c34f76e346533455819d6ff1a1dfac2cbd1';

/// Provider for achievement cards
///
/// Copied from [achievementCards].
@ProviderFor(achievementCards)
final achievementCardsProvider =
    AutoDisposeProvider<List<AchievementCard>>.internal(
      achievementCards,
      name: r'achievementCardsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$achievementCardsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AchievementCardsRef = AutoDisposeProviderRef<List<AchievementCard>>;
String _$leaderboardStreamHash() => r'2f15c128324bd1372af4d60fcfbbd3f39f267346';

/// Provider for leaderboard stream
///
/// Copied from [leaderboardStream].
@ProviderFor(leaderboardStream)
final leaderboardStreamProvider =
    AutoDisposeStreamProvider<LeaderboardPage>.internal(
      leaderboardStream,
      name: r'leaderboardStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaderboardStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeaderboardStreamRef = AutoDisposeStreamProviderRef<LeaderboardPage>;
String _$userRankStreamHash() => r'1f75a98a381104d1e842da25ae4b73eef905ad97';

/// Provider for user rank stream
///
/// Copied from [userRankStream].
@ProviderFor(userRankStream)
final userRankStreamProvider = AutoDisposeStreamProvider<int?>.internal(
  userRankStream,
  name: r'userRankStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRankStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRankStreamRef = AutoDisposeStreamProviderRef<int?>;
String _$syncStatusStreamHash() => r'a67a50acc4e47f7d228af8d91348950d1e8c017a';

/// Provider for sync status stream
///
/// Copied from [syncStatusStream].
@ProviderFor(syncStatusStream)
final syncStatusStreamProvider = AutoDisposeStreamProvider<SyncStatus>.internal(
  syncStatusStream,
  name: r'syncStatusStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncStatusStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncStatusStreamRef = AutoDisposeStreamProviderRef<SyncStatus>;
String _$sharedPreferencesHash() => r'dc403fbb1d968c7d5ab4ae1721a29ffe173701c7';

/// Provider for SharedPreferences
///
/// Copied from [sharedPreferences].
@ProviderFor(sharedPreferences)
final sharedPreferencesProvider =
    AutoDisposeFutureProvider<SharedPreferences>.internal(
      sharedPreferences,
      name: r'sharedPreferencesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sharedPreferencesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPreferencesRef = AutoDisposeFutureProviderRef<SharedPreferences>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
