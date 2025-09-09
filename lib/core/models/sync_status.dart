/// Represents the synchronization status of data
enum SyncState {
  idle,
  syncing,
  success,
  error,
  conflict,
}

/// Sync status for different data types
class SyncStatus {
  final SyncState state;
  final DateTime lastSyncAt;
  final String? error;
  final int pendingChanges;
  final Map<String, dynamic>? conflictData;

  const SyncStatus({
    required this.state,
    required this.lastSyncAt,
    this.error,
    this.pendingChanges = 0,
    this.conflictData,
  });

  /// Create initial sync status
  factory SyncStatus.initial() {
    return SyncStatus(
      state: SyncState.idle,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Create syncing status
  factory SyncStatus.syncing() {
    return SyncStatus(
      state: SyncState.syncing,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Create success status
  factory SyncStatus.success() {
    return SyncStatus(
      state: SyncState.success,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Create error status
  factory SyncStatus.error(String error) {
    return SyncStatus(
      state: SyncState.error,
      lastSyncAt: DateTime.now(),
      error: error,
    );
  }

  /// Create conflict status
  factory SyncStatus.conflict(Map<String, dynamic> conflictData) {
    return SyncStatus(
      state: SyncState.conflict,
      lastSyncAt: DateTime.now(),
      conflictData: conflictData,
    );
  }

  /// Check if sync is in progress
  bool get isSyncing => state == SyncState.syncing;

  /// Check if sync has error
  bool get hasError => state == SyncState.error;

  /// Check if sync has conflicts
  bool get hasConflict => state == SyncState.conflict;

  /// Check if sync is successful
  bool get isSuccess => state == SyncState.success;

  /// Check if sync is idle
  bool get isIdle => state == SyncState.idle;

  /// Get time since last sync
  Duration get timeSinceLastSync => DateTime.now().difference(lastSyncAt);

  /// Check if sync is stale (older than threshold)
  bool isStale(Duration threshold) => timeSinceLastSync > threshold;

  /// Create a copy with updated fields
  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSyncAt,
    String? error,
    int? pendingChanges,
    Map<String, dynamic>? conflictData,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error ?? this.error,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      conflictData: conflictData ?? this.conflictData,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'state': state.name,
      'lastSyncAt': lastSyncAt.toIso8601String(),
      'error': error,
      'pendingChanges': pendingChanges,
      'conflictData': conflictData,
    };
  }

  /// Create from JSON
  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      state: SyncState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => SyncState.idle,
      ),
      lastSyncAt: DateTime.parse(json['lastSyncAt'] as String),
      error: json['error'] as String?,
      pendingChanges: json['pendingChanges'] as int? ?? 0,
      conflictData: json['conflictData'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'SyncStatus(state: $state, lastSync: $lastSyncAt, error: $error)';
  }
}

/// Overall sync status for all data types
class GlobalSyncStatus {
  final Map<String, SyncStatus> dataTypeStatus;
  final DateTime lastGlobalSync;
  final bool isOnline;

  const GlobalSyncStatus({
    required this.dataTypeStatus,
    required this.lastGlobalSync,
    required this.isOnline,
  });

  /// Create initial global sync status
  factory GlobalSyncStatus.initial() {
    return GlobalSyncStatus(
      dataTypeStatus: {
        'user': SyncStatus.initial(),
        'inventory': SyncStatus.initial(),
        'achievements': SyncStatus.initial(),
        'leaderboard': SyncStatus.initial(),
        'categoryStats': SyncStatus.initial(),
      },
      lastGlobalSync: DateTime.now(),
      isOnline: true,
    );
  }

  /// Get sync status for specific data type
  SyncStatus getStatus(String dataType) {
    return dataTypeStatus[dataType] ?? SyncStatus.initial();
  }

  /// Update sync status for specific data type
  GlobalSyncStatus updateStatus(String dataType, SyncStatus status) {
    final updatedStatus = Map<String, SyncStatus>.from(dataTypeStatus);
    updatedStatus[dataType] = status;

    return GlobalSyncStatus(
      dataTypeStatus: updatedStatus,
      lastGlobalSync: DateTime.now(),
      isOnline: isOnline,
    );
  }

  /// Check if any data type is syncing
  bool get isAnySyncing {
    return dataTypeStatus.values.any((status) => status.isSyncing);
  }

  /// Check if any data type has errors
  bool get hasAnyErrors {
    return dataTypeStatus.values.any((status) => status.hasError);
  }

  /// Check if any data type has conflicts
  bool get hasAnyConflicts {
    return dataTypeStatus.values.any((status) => status.hasConflict);
  }

  /// Get total pending changes across all data types
  int get totalPendingChanges {
    return dataTypeStatus.values
        .map((status) => status.pendingChanges)
        .fold(0, (sum, count) => sum + count);
  }

  /// Update online status
  GlobalSyncStatus updateOnlineStatus(bool online) {
    return GlobalSyncStatus(
      dataTypeStatus: dataTypeStatus,
      lastGlobalSync: lastGlobalSync,
      isOnline: online,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'dataTypeStatus': dataTypeStatus.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'lastGlobalSync': lastGlobalSync.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  /// Create from JSON
  factory GlobalSyncStatus.fromJson(Map<String, dynamic> json) {
    final statusMap = <String, SyncStatus>{};
    final dataTypeStatusJson = json['dataTypeStatus'] as Map<String, dynamic>;
    
    for (final entry in dataTypeStatusJson.entries) {
      statusMap[entry.key] = SyncStatus.fromJson(entry.value);
    }

    return GlobalSyncStatus(
      dataTypeStatus: statusMap,
      lastGlobalSync: DateTime.parse(json['lastGlobalSync'] as String),
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'GlobalSyncStatus(online: $isOnline, syncing: $isAnySyncing, errors: $hasAnyErrors)';
  }
}