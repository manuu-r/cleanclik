import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cleanclik/core/services/auth/supabase_config_service.dart';

part 'supabase_provider.g.dart';

/// Supabase configuration state
enum SupabaseStatus { uninitialized, initializing, ready, error }

/// Supabase configuration state
class SupabaseState {
  final SupabaseStatus status;
  final String? errorMessage;
  final SupabaseHealthStatus? healthStatus;

  const SupabaseState({
    required this.status,
    this.errorMessage,
    this.healthStatus,
  });

  const SupabaseState.initial()
    : status = SupabaseStatus.uninitialized,
      errorMessage = null,
      healthStatus = null;

  SupabaseState copyWith({
    SupabaseStatus? status,
    String? errorMessage,
    SupabaseHealthStatus? healthStatus,
  }) {
    return SupabaseState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      healthStatus: healthStatus ?? this.healthStatus,
    );
  }

  bool get isReady => status == SupabaseStatus.ready;
  bool get isInitializing => status == SupabaseStatus.initializing;
  bool get hasError => status == SupabaseStatus.error;
}

/// Supabase configuration notifier provider
@riverpod
class SupabaseNotifier extends _$SupabaseNotifier {
  @override
  SupabaseState build() {
    // Initialize Supabase when provider is created
    _initializeSupabase();

    // Cleanup when provider is disposed
    ref.onDispose(() {
      developer.log('SupabaseNotifier disposed', name: 'SupabaseProvider');
    });

    return const SupabaseState.initial();
  }

  /// Initialize Supabase configuration
  Future<void> _initializeSupabase() async {
    if (state.status == SupabaseStatus.initializing) {
      return; // Already initializing
    }

    try {
      state = state.copyWith(
        status: SupabaseStatus.initializing,
        errorMessage: null,
      );

      await SupabaseConfigService.initialize();

      // Perform health check after initialization
      final healthStatus = await SupabaseConfigService.healthCheck();

      state = state.copyWith(
        status: SupabaseStatus.ready,
        healthStatus: healthStatus,
      );

      developer.log(
        'Supabase initialized successfully',
        name: 'SupabaseProvider',
      );
    } catch (e) {
      final errorMessage = e.toString();
      state = state.copyWith(
        status: SupabaseStatus.error,
        errorMessage: errorMessage,
      );

      developer.log(
        'Failed to initialize Supabase: $errorMessage',
        name: 'SupabaseProvider',
      );
    }
  }

  /// Retry initialization after error
  Future<void> retryInitialization() async {
    if (state.status == SupabaseStatus.initializing) {
      return; // Already initializing
    }

    developer.log('Retrying Supabase initialization', name: 'SupabaseProvider');
    await _initializeSupabase();
  }

  /// Perform health check
  Future<void> performHealthCheck() async {
    if (!SupabaseConfigService.isInitialized) {
      developer.log(
        'Cannot perform health check: Supabase not initialized',
        name: 'SupabaseProvider',
      );
      return;
    }

    try {
      final healthStatus = await SupabaseConfigService.healthCheck();
      state = state.copyWith(healthStatus: healthStatus);

      developer.log(
        'Health check completed: ${healthStatus.isHealthy}',
        name: 'SupabaseProvider',
      );
    } catch (e) {
      developer.log('Health check failed: $e', name: 'SupabaseProvider');
    }
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        status: SupabaseStatus.uninitialized,
        errorMessage: null,
      );
    }
  }
}

/// Provider for accessing Supabase state
@riverpod
SupabaseState supabaseState(Ref ref) {
  return ref.watch(supabaseNotifierProvider);
}

/// Provider for checking if Supabase is ready
@riverpod
bool isSupabaseReady(Ref ref) {
  final state = ref.watch(supabaseStateProvider);
  return state.isReady;
}

/// Provider for accessing Supabase client
@riverpod
SupabaseClient? supabaseClient(Ref ref) {
  final state = ref.watch(supabaseStateProvider);

  if (state.isReady && SupabaseConfigService.isInitialized) {
    return SupabaseConfigService.client;
  }

  return null;
}

/// Provider for Supabase health status
@riverpod
SupabaseHealthStatus? supabaseHealthStatus(Ref ref) {
  final state = ref.watch(supabaseStateProvider);
  return state.healthStatus;
}
