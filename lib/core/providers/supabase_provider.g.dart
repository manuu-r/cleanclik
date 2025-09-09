// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supabaseStateHash() => r'107e86232eb2fc5931ff1f7126d10131e8db40ad';

/// Provider for accessing Supabase state
///
/// Copied from [supabaseState].
@ProviderFor(supabaseState)
final supabaseStateProvider = AutoDisposeProvider<SupabaseState>.internal(
  supabaseState,
  name: r'supabaseStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supabaseStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupabaseStateRef = AutoDisposeProviderRef<SupabaseState>;
String _$isSupabaseReadyHash() => r'65b7e1c4b95639ba084edb85091fa721eae3c5d9';

/// Provider for checking if Supabase is ready
///
/// Copied from [isSupabaseReady].
@ProviderFor(isSupabaseReady)
final isSupabaseReadyProvider = AutoDisposeProvider<bool>.internal(
  isSupabaseReady,
  name: r'isSupabaseReadyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSupabaseReadyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSupabaseReadyRef = AutoDisposeProviderRef<bool>;
String _$supabaseClientHash() => r'3fc26547a9335bc9ce6481dcffdad368263ba8a1';

/// Provider for accessing Supabase client
///
/// Copied from [supabaseClient].
@ProviderFor(supabaseClient)
final supabaseClientProvider = AutoDisposeProvider<SupabaseClient?>.internal(
  supabaseClient,
  name: r'supabaseClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supabaseClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupabaseClientRef = AutoDisposeProviderRef<SupabaseClient?>;
String _$supabaseHealthStatusHash() =>
    r'604a1f6ca9b178f7c809c89456e3cca5c489e057';

/// Provider for Supabase health status
///
/// Copied from [supabaseHealthStatus].
@ProviderFor(supabaseHealthStatus)
final supabaseHealthStatusProvider =
    AutoDisposeProvider<SupabaseHealthStatus?>.internal(
      supabaseHealthStatus,
      name: r'supabaseHealthStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$supabaseHealthStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupabaseHealthStatusRef = AutoDisposeProviderRef<SupabaseHealthStatus?>;
String _$supabaseNotifierHash() => r'04d498c07c6e71298b836a9b253e178335007411';

/// Supabase configuration notifier provider
///
/// Copied from [SupabaseNotifier].
@ProviderFor(SupabaseNotifier)
final supabaseNotifierProvider =
    AutoDisposeNotifierProvider<SupabaseNotifier, SupabaseState>.internal(
      SupabaseNotifier.new,
      name: r'supabaseNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$supabaseNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SupabaseNotifier = AutoDisposeNotifier<SupabaseState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
