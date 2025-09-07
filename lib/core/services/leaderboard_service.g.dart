// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leaderboardServiceHash() =>
    r'de332e10afb9e61edc40e170fb59c19b68f1ada6';

/// Provider for LeaderboardService
///
/// Copied from [leaderboardService].
@ProviderFor(leaderboardService)
final leaderboardServiceProvider =
    AutoDisposeProvider<LeaderboardService>.internal(
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
typedef LeaderboardServiceRef = AutoDisposeProviderRef<LeaderboardService>;
String _$leaderboardHash() => r'3e1eb8b64de33f84d920faabc0b5a13531ace83b';

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

/// Provider for leaderboard data
///
/// Copied from [leaderboard].
@ProviderFor(leaderboard)
const leaderboardProvider = LeaderboardFamily();

/// Provider for leaderboard data
///
/// Copied from [leaderboard].
class LeaderboardFamily extends Family<AsyncValue<List<LeaderboardUser>>> {
  /// Provider for leaderboard data
  ///
  /// Copied from [leaderboard].
  const LeaderboardFamily();

  /// Provider for leaderboard data
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

/// Provider for leaderboard data
///
/// Copied from [leaderboard].
class LeaderboardProvider
    extends AutoDisposeFutureProvider<List<LeaderboardUser>> {
  /// Provider for leaderboard data
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
    FutureOr<List<LeaderboardUser>> Function(LeaderboardRef provider) create,
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
  AutoDisposeFutureProviderElement<List<LeaderboardUser>> createElement() {
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
mixin LeaderboardRef on AutoDisposeFutureProviderRef<List<LeaderboardUser>> {
  /// The parameter `period` of this provider.
  LeaderboardPeriod get period;
}

class _LeaderboardProviderElement
    extends AutoDisposeFutureProviderElement<List<LeaderboardUser>>
    with LeaderboardRef {
  _LeaderboardProviderElement(super.provider);

  @override
  LeaderboardPeriod get period => (origin as LeaderboardProvider).period;
}

String _$unlockedAchievementsHash() =>
    r'37e4a5e59f8abc8f88c7112803fbdb841d2d5e84';

/// Provider for unlocked achievements
///
/// Copied from [unlockedAchievements].
@ProviderFor(unlockedAchievements)
final unlockedAchievementsProvider =
    AutoDisposeProvider<List<Achievement>>.internal(
      unlockedAchievements,
      name: r'unlockedAchievementsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$unlockedAchievementsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnlockedAchievementsRef = AutoDisposeProviderRef<List<Achievement>>;
String _$achievementCardsHash() => r'fde6ae89ebf8421b8e91a183f282b0496ca9533e';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
