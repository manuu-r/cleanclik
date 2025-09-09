import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/sync_status.dart';
import 'user_service.dart';
import 'inventory_service.dart';
import 'leaderboard_service.dart';
import 'data_migration_service.dart';

part 'sync_service.g.dart';

/// Comprehensive synchronization service for all app data
class SyncService {
  final UserService _userService;
  final InventoryService _inventoryService;
  final LeaderboardService _leaderboardService;
  final DataMigrationService _migrationService;

  // State management
  final StreamController<GlobalSyncStatus> _globalSyncController =
      StreamController<GlobalSyncStatus>.broadcast();

  GlobalSyncStatus _currentStatus = GlobalSyncStatus.initial();

  // Network monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  // Sync configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration conflictResolutionTimeout = Duration(seconds: 30);

  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  bool _isDisposed = false;

  SyncService(
    this._userService,
    this._inventoryService,
    this._leaderboardService,
    this._migrationService,
  ) {
    debugPrint('Creating new SyncService instance');
    _initializeSync();
  }

  /// Stream for global sync status updates
  Stream<GlobalSyncStatus> get globalSyncStream => _globalSyncController.stream;

  /// Current global sync status
  GlobalSyncStatus get currentStatus => _currentStatus;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Check if online
  bool get isOnline => _isOnline;

  /// Initialize synchronization service
  void _initializeSync() {
    _setupNetworkMonitoring();
    _startPeriodicSync();
    _listenToServiceUpdates();
  }

  /// Perform complete data synchronization
  Future<void> syncAllData({bool forceSync = false}) async {
    if (_isDisposed) {
      debugPrint('SyncService is disposed, skipping sync');
      return;
    }

    if (_isSyncing && !forceSync) {
      debugPrint('Sync already in progress, skipping');
      return;
    }

    if (!_isOnline) {
      debugPrint('Device is offline, skipping sync');
      _updateGlobalStatus('offline', SyncStatus.error('Device is offline'));
      return;
    }

    if (!_userService.isAuthenticated) {
      debugPrint('User not authenticated, skipping sync');
      _updateGlobalStatus('auth', SyncStatus.error('User not authenticated'));
      return;
    }

    _isSyncing = true;
    debugPrint('Starting complete data synchronization...');

    try {
      // Update global status to syncing
      _updateGlobalStatus('global', SyncStatus.syncing());

      // Step 1: Handle data migration if needed
      await _handleDataMigration();

      // Step 2: Sync user data
      await _syncUserData();

      // Step 3: Sync inventory data
      await _syncInventoryData();

      // Step 4: Sync leaderboard data
      await _syncLeaderboardData();

      // Step 5: Handle any conflicts
      await _resolveDataConflicts();

      // Mark sync as successful
      _updateGlobalStatus('global', SyncStatus.success());
      debugPrint('Complete data synchronization finished successfully');
    } catch (e) {
      debugPrint('Data synchronization failed: $e');
      _updateGlobalStatus('global', SyncStatus.error(e.toString()));
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync specific data type
  Future<void> syncDataType(String dataType) async {
    if (!_isOnline) {
      _updateGlobalStatus(dataType, SyncStatus.error('Device is offline'));
      return;
    }

    if (!_userService.isAuthenticated) {
      _updateGlobalStatus(dataType, SyncStatus.error('User not authenticated'));
      return;
    }

    try {
      _updateGlobalStatus(dataType, SyncStatus.syncing());

      switch (dataType) {
        case 'user':
          await _syncUserData();
          break;
        case 'inventory':
          await _syncInventoryData();
          break;
        case 'leaderboard':
          await _syncLeaderboardData();
          break;
        default:
          throw Exception('Unknown data type: $dataType');
      }

      _updateGlobalStatus(dataType, SyncStatus.success());
    } catch (e) {
      debugPrint('Failed to sync $dataType: $e');
      _updateGlobalStatus(dataType, SyncStatus.error(e.toString()));
    }
  }

  /// Handle optimistic updates with conflict resolution
  Future<void> handleOptimisticUpdate({
    required String dataType,
    required String operation,
    required Map<String, dynamic> localData,
    required Future<void> Function() serverUpdate,
  }) async {
    try {
      // Apply optimistic update locally first
      debugPrint('Applying optimistic update for $dataType: $operation');

      // Attempt server update
      await serverUpdate();

      // If successful, mark as synced
      _updateGlobalStatus(dataType, SyncStatus.success());
    } catch (e) {
      debugPrint('Optimistic update failed for $dataType: $e');

      // Handle conflict resolution
      final conflictData = {
        'dataType': dataType,
        'operation': operation,
        'localData': localData,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      _updateGlobalStatus(dataType, SyncStatus.conflict(conflictData));

      // Schedule conflict resolution
      _scheduleConflictResolution(dataType, conflictData);
    }
  }

  /// Force refresh all cached data
  Future<void> refreshAllData() async {
    debugPrint('Refreshing all cached data...');

    try {
      // Refresh user data
      await _userService.syncUserData();

      // Refresh inventory data
      await _inventoryService.syncInventoryData();

      // Refresh leaderboard data
      await _leaderboardService.refreshLeaderboard();

      debugPrint('All data refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      throw e;
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    final stats = <String, dynamic>{};

    for (final entry in _currentStatus.dataTypeStatus.entries) {
      final dataType = entry.key;
      final status = entry.value;

      stats[dataType] = {
        'state': status.state.name,
        'lastSync': status.lastSyncAt.toIso8601String(),
        'timeSinceLastSync': status.timeSinceLastSync.inMinutes,
        'pendingChanges': status.pendingChanges,
        'hasError': status.hasError,
        'hasConflict': status.hasConflict,
      };
    }

    stats['global'] = {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'lastGlobalSync': _currentStatus.lastGlobalSync.toIso8601String(),
      'totalPendingChanges': _currentStatus.totalPendingChanges,
      'hasAnyErrors': _currentStatus.hasAnyErrors,
      'hasAnyConflicts': _currentStatus.hasAnyConflicts,
    };

    return stats;
  }

  /// Private methods

  /// Handle data migration if needed
  Future<void> _handleDataMigration() async {
    if (_migrationService.isMigrationNeeded) {
      debugPrint('Data migration needed, performing migration...');
      _updateGlobalStatus('migration', SyncStatus.syncing());

      final migrationSuccess = await _migrationService.migrateAllData();

      if (migrationSuccess) {
        _updateGlobalStatus('migration', SyncStatus.success());
        debugPrint('Data migration completed successfully');
      } else {
        _updateGlobalStatus('migration', SyncStatus.error('Migration failed'));
        throw Exception('Data migration failed');
      }
    }
  }

  /// Sync user data
  Future<void> _syncUserData() async {
    debugPrint('Syncing user data...');
    _updateGlobalStatus('user', SyncStatus.syncing());

    try {
      await _userService.syncUserData();
      _updateGlobalStatus('user', SyncStatus.success());
    } catch (e) {
      _updateGlobalStatus('user', SyncStatus.error(e.toString()));
      rethrow;
    }
  }

  /// Sync inventory data
  Future<void> _syncInventoryData() async {
    debugPrint('Syncing inventory data...');
    _updateGlobalStatus('inventory', SyncStatus.syncing());

    try {
      await _inventoryService.syncInventoryData();
      _updateGlobalStatus('inventory', SyncStatus.success());
    } catch (e) {
      _updateGlobalStatus('inventory', SyncStatus.error(e.toString()));
      rethrow;
    }
  }

  /// Sync leaderboard data
  Future<void> _syncLeaderboardData() async {
    debugPrint('Syncing leaderboard data...');
    _updateGlobalStatus('leaderboard', SyncStatus.syncing());

    try {
      await _leaderboardService.syncLeaderboardData();
      _updateGlobalStatus('leaderboard', SyncStatus.success());
    } catch (e) {
      _updateGlobalStatus('leaderboard', SyncStatus.error(e.toString()));
      rethrow;
    }
  }

  /// Resolve data conflicts
  Future<void> _resolveDataConflicts() async {
    final conflictedTypes = _currentStatus.dataTypeStatus.entries
        .where((entry) => entry.value.hasConflict)
        .map((entry) => entry.key)
        .toList();

    if (conflictedTypes.isEmpty) return;

    debugPrint('Resolving conflicts for: ${conflictedTypes.join(', ')}');

    for (final dataType in conflictedTypes) {
      try {
        await _resolveConflictForDataType(dataType);
      } catch (e) {
        debugPrint('Failed to resolve conflict for $dataType: $e');
      }
    }
  }

  /// Resolve conflict for specific data type
  Future<void> _resolveConflictForDataType(String dataType) async {
    final status = _currentStatus.getStatus(dataType);
    if (!status.hasConflict || status.conflictData == null) return;

    debugPrint('Resolving conflict for $dataType...');

    try {
      // For now, we'll use server-wins strategy
      // In a more sophisticated implementation, we could:
      // 1. Show user a conflict resolution UI
      // 2. Use last-write-wins based on timestamps
      // 3. Merge changes intelligently

      // Force refresh from server
      await syncDataType(dataType);

      debugPrint('Conflict resolved for $dataType using server-wins strategy');
    } catch (e) {
      debugPrint('Failed to resolve conflict for $dataType: $e');
      _updateGlobalStatus(
        dataType,
        SyncStatus.error('Conflict resolution failed: $e'),
      );
    }
  }

  /// Schedule conflict resolution
  void _scheduleConflictResolution(
    String dataType,
    Map<String, dynamic> conflictData,
  ) {
    Timer(conflictResolutionTimeout, () async {
      try {
        await _resolveConflictForDataType(dataType);
      } catch (e) {
        debugPrint('Scheduled conflict resolution failed for $dataType: $e');
      }
    });
  }

  /// Setup network monitoring
  void _setupNetworkMonitoring() {
    if (_isDisposed) return;

    final connectivity = Connectivity();
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Check if service is disposed before processing
      if (_isDisposed || _globalSyncController.isClosed) {
        return;
      }

      final wasOnline = _isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);

      debugPrint('Network status changed: ${_isOnline ? 'online' : 'offline'}');

      _currentStatus = _currentStatus.updateOnlineStatus(_isOnline);
      _globalSyncController.add(_currentStatus);

      // If we just came back online, trigger a sync
      if (!wasOnline && _isOnline && !_isDisposed) {
        debugPrint('Device came back online, triggering sync...');
        Timer(const Duration(seconds: 2), () {
          if (!_isDisposed) {
            syncAllData();
          }
        });
      }
    });

    // Initial connectivity check
    connectivity.checkConnectivity().then((results) {
      // Check if service is disposed before processing
      if (_isDisposed || _globalSyncController.isClosed) {
        return;
      }

      _isOnline = results.any((result) => result != ConnectivityResult.none);
      _currentStatus = _currentStatus.updateOnlineStatus(_isOnline);
      _globalSyncController.add(_currentStatus);
    });
  }

  /// Start periodic synchronization
  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(syncInterval, (timer) {
      if (_isOnline && _userService.isAuthenticated && !_isSyncing) {
        debugPrint('Performing periodic sync...');
        syncAllData();
      }
    });
  }

  /// Listen to individual service updates
  void _listenToServiceUpdates() {
    // Listen to user service auth state changes
    _userService.authStateStream.listen((isAuthenticated) {
      if (isAuthenticated) {
        debugPrint('User authenticated, triggering initial sync...');
        Timer(const Duration(seconds: 1), () => syncAllData());
      }
    });
  }

  /// Update global sync status
  void _updateGlobalStatus(String dataType, SyncStatus status) {
    // Check if service is disposed before updating
    if (_isDisposed || _globalSyncController.isClosed) {
      return;
    }

    _currentStatus = _currentStatus.updateStatus(dataType, status);
    _globalSyncController.add(_currentStatus);
  }

  /// Dispose resources
  void dispose() {
    if (_isDisposed) {
      debugPrint('SyncService already disposed, skipping');
      return;
    }

    debugPrint('Disposing SyncService resources...');
    _isDisposed = true;

    try {
      // Cancel timers first
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = null;

      // Cancel connectivity subscription
      _connectivitySubscription?.cancel();
      _connectivitySubscription = null;

      // Close stream controller if not already closed
      if (!_globalSyncController.isClosed) {
        _globalSyncController.close();
      }

      // Reset sync state
      _isSyncing = false;

      debugPrint('SyncService disposed successfully');
    } catch (e) {
      debugPrint('Error disposing SyncService: $e');
    }
  }
}

/// Provider for SyncService - using keepAlive to prevent frequent recreation
@riverpod
class SyncServiceNotifier extends _$SyncServiceNotifier {
  SyncService? _service;

  @override
  SyncService build() {
    // Keep this provider alive to prevent frequent recreation
    ref.keepAlive();

    final userService = ref.watch(userServiceProvider);
    final inventoryService = ref.watch(inventoryServiceProvider);
    
    // Handle leaderboard service dependency more carefully
    final leaderboardServiceAsync = ref.watch(leaderboardServiceProvider);
    final leaderboardService = leaderboardServiceAsync.when(
      data: (service) => service,
      loading: () => null,
      error: (_, __) => null,
    );

    final migrationService = ref.watch(dataMigrationServiceProvider);

    // Only create service if we have all dependencies
    if (leaderboardService == null) {
      // Return a placeholder or throw - we'll handle this in the UI
      throw Exception('LeaderboardService not ready');
    }

    // Dispose previous service if it exists
    _service?.dispose();

    _service = SyncService(
      userService,
      inventoryService,
      leaderboardService,
      migrationService,
    );

    ref.onDispose(() {
      _service?.dispose();
      _service = null;
    });

    return _service!;
  }
}

/// Provider for global sync status stream - simplified
@riverpod
Stream<GlobalSyncStatus> globalSyncStatus(Ref ref) async* {
  try {
    final service = ref.watch(syncServiceNotifierProvider);
    yield* service.globalSyncStream;
  } catch (e) {
    // If service is not ready, yield initial status
    yield GlobalSyncStatus.initial();
  }
}

/// Provider for sync statistics
@riverpod
Future<Map<String, dynamic>> syncStatistics(Ref ref) async {
  try {
    final service = ref.watch(syncServiceNotifierProvider);
    return service.getSyncStatistics();
  } catch (e) {
    // Return empty stats if service is not ready
    return <String, dynamic>{};
  }
}
