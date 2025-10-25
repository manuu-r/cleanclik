// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inventoryServiceHash() => r'162f94227a3398c59babd39eb36347fbac0a62d7';

/// Provider for InventoryService
/// Requirements: 2.1, 3.1
///
/// Copied from [inventoryService].
@ProviderFor(inventoryService)
final inventoryServiceProvider = AutoDisposeProvider<InventoryService>.internal(
  inventoryService,
  name: r'inventoryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inventoryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InventoryServiceRef = AutoDisposeProviderRef<InventoryService>;
String _$inventoryItemsHash() => r'b1d60d414fac5b0526f3a41f28bbf3d7ffdc4973';

/// Provider for current inventory items
/// Requirements: 2.1, 3.1
///
/// Copied from [inventoryItems].
@ProviderFor(inventoryItems)
final inventoryItemsProvider =
    AutoDisposeProvider<List<InventoryItem>>.internal(
      inventoryItems,
      name: r'inventoryItemsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$inventoryItemsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InventoryItemsRef = AutoDisposeProviderRef<List<InventoryItem>>;
String _$inventoryItemsByCategoryHash() =>
    r'61262606b1bc549aca0fcfe4572979a889050b08';

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

/// Provider for inventory items by category
/// Requirements: 2.1, 3.1
///
/// Copied from [inventoryItemsByCategory].
@ProviderFor(inventoryItemsByCategory)
const inventoryItemsByCategoryProvider = InventoryItemsByCategoryFamily();

/// Provider for inventory items by category
/// Requirements: 2.1, 3.1
///
/// Copied from [inventoryItemsByCategory].
class InventoryItemsByCategoryFamily extends Family<List<InventoryItem>> {
  /// Provider for inventory items by category
  /// Requirements: 2.1, 3.1
  ///
  /// Copied from [inventoryItemsByCategory].
  const InventoryItemsByCategoryFamily();

  /// Provider for inventory items by category
  /// Requirements: 2.1, 3.1
  ///
  /// Copied from [inventoryItemsByCategory].
  InventoryItemsByCategoryProvider call(String category) {
    return InventoryItemsByCategoryProvider(category);
  }

  @override
  InventoryItemsByCategoryProvider getProviderOverride(
    covariant InventoryItemsByCategoryProvider provider,
  ) {
    return call(provider.category);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'inventoryItemsByCategoryProvider';
}

/// Provider for inventory items by category
/// Requirements: 2.1, 3.1
///
/// Copied from [inventoryItemsByCategory].
class InventoryItemsByCategoryProvider
    extends AutoDisposeProvider<List<InventoryItem>> {
  /// Provider for inventory items by category
  /// Requirements: 2.1, 3.1
  ///
  /// Copied from [inventoryItemsByCategory].
  InventoryItemsByCategoryProvider(String category)
    : this._internal(
        (ref) => inventoryItemsByCategory(
          ref as InventoryItemsByCategoryRef,
          category,
        ),
        from: inventoryItemsByCategoryProvider,
        name: r'inventoryItemsByCategoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$inventoryItemsByCategoryHash,
        dependencies: InventoryItemsByCategoryFamily._dependencies,
        allTransitiveDependencies:
            InventoryItemsByCategoryFamily._allTransitiveDependencies,
        category: category,
      );

  InventoryItemsByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final String category;

  @override
  Override overrideWith(
    List<InventoryItem> Function(InventoryItemsByCategoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InventoryItemsByCategoryProvider._internal(
        (ref) => create(ref as InventoryItemsByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<InventoryItem>> createElement() {
    return _InventoryItemsByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryItemsByCategoryProvider &&
        other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin InventoryItemsByCategoryRef
    on AutoDisposeProviderRef<List<InventoryItem>> {
  /// The parameter `category` of this provider.
  String get category;
}

class _InventoryItemsByCategoryProviderElement
    extends AutoDisposeProviderElement<List<InventoryItem>>
    with InventoryItemsByCategoryRef {
  _InventoryItemsByCategoryProviderElement(super.provider);

  @override
  String get category => (origin as InventoryItemsByCategoryProvider).category;
}

String _$isInventoryEmptyHash() => r'aff20820cfa533605545072393a36c20727a181b';

/// Provider for inventory empty state
/// Requirements: 2.1, 3.1
///
/// Copied from [isInventoryEmpty].
@ProviderFor(isInventoryEmpty)
final isInventoryEmptyProvider = AutoDisposeProvider<bool>.internal(
  isInventoryEmpty,
  name: r'isInventoryEmptyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isInventoryEmptyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsInventoryEmptyRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
