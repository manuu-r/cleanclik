import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/sync_status.dart';
import 'package:cleanclik/core/services/data/sync_service.dart';

/// Widget that displays the current synchronization status
class SyncStatusIndicator extends ConsumerWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const SyncStatusIndicator({super.key, this.showDetails = false, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSyncStatus = ref.watch(globalSyncStatusProvider);

    return globalSyncStatus.when(
      data: (status) => _buildStatusIndicator(context, status),
      loading: () => _buildLoadingIndicator(),
      error: (error, _) => _buildErrorIndicator(context, error.toString()),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, GlobalSyncStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine overall status
    IconData icon;
    Color color;
    String tooltip;

    if (!status.isOnline) {
      icon = Icons.cloud_off;
      color = colorScheme.error;
      tooltip = 'Offline';
    } else if (status.isAnySyncing) {
      icon = Icons.sync;
      color = colorScheme.primary;
      tooltip = 'Syncing...';
    } else if (status.hasAnyErrors) {
      icon = Icons.sync_problem;
      color = colorScheme.error;
      tooltip = 'Sync error';
    } else if (status.hasAnyConflicts) {
      icon = Icons.merge_type;
      color = colorScheme.tertiary;
      tooltip = 'Sync conflicts';
    } else {
      icon = Icons.cloud_done;
      color = colorScheme.primary;
      tooltip = 'Synced';
    }

    Widget indicator = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          status.isAnySyncing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Icon(icon, size: 16, color: color),
          if (showDetails) ...[
            const SizedBox(width: 8),
            Text(
              tooltip,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
            if (status.totalPendingChanges > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${status.totalPendingChanges}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );

    if (onTap != null) {
      indicator = GestureDetector(onTap: onTap, child: indicator);
    }

    return Tooltip(message: tooltip, child: indicator);
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorIndicator(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
      ),
      child: Icon(Icons.error_outline, size: 16, color: colorScheme.error),
    );
  }
}

/// Detailed sync status dialog
class SyncStatusDialog extends ConsumerWidget {
  const SyncStatusDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSyncStatus = ref.watch(globalSyncStatusProvider);
    final syncStats = ref.watch(syncStatisticsProvider);

    return AlertDialog(
      title: const Text('Sync Status'),
      content: globalSyncStatus.when(
        data: (status) => syncStats.when(
          data: (stats) => _buildStatusDetails(context, status, stats),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Stats error: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('Error: $error'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () async {
            try {
              final service = ref.read(syncServiceNotifierProvider);
              service.syncAllData(forceSync: true);
              Navigator.of(context).pop();
            } catch (e) {
              // Service not ready, ignore
              Navigator.of(context).pop();
            }
          },
          child: const Text('Force Sync'),
        ),
      ],
    );
  }

  Widget _buildStatusDetails(
    BuildContext context,
    GlobalSyncStatus status,
    Map<String, dynamic> stats,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall status
          _buildStatusRow(
            'Overall Status',
            status.isOnline ? 'Online' : 'Offline',
            status.isOnline ? Icons.cloud_done : Icons.cloud_off,
            status.isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),

          // Individual data type statuses
          Text('Data Types', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          ...status.dataTypeStatus.entries.map((entry) {
            final dataType = entry.key;
            final syncStatus = entry.value;

            return _buildDataTypeStatus(dataType, syncStatus);
          }),

          const SizedBox(height: 16),

          // Statistics
          Text('Statistics', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          Text('Last Global Sync: ${_formatDateTime(status.lastGlobalSync)}'),
          Text('Total Pending Changes: ${status.totalPendingChanges}'),
          Text('Has Errors: ${status.hasAnyErrors ? 'Yes' : 'No'}'),
          Text('Has Conflicts: ${status.hasAnyConflicts ? 'Yes' : 'No'}'),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text('$label: '),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDataTypeStatus(String dataType, SyncStatus status) {
    IconData icon;
    Color color;

    switch (status.state) {
      case SyncState.idle:
        icon = Icons.pause_circle_outline;
        color = Colors.grey;
        break;
      case SyncState.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        break;
      case SyncState.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case SyncState.error:
        icon = Icons.error;
        color = Colors.red;
        break;
      case SyncState.conflict:
        icon = Icons.merge_type;
        color = Colors.orange;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dataType.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            status.state.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Manual sync trigger button
class ManualSyncButton extends ConsumerWidget {
  final String? dataType;
  final Widget? child;

  const ManualSyncButton({super.key, this.dataType, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalStatus = ref.watch(globalSyncStatusProvider);

    return globalStatus.when(
      data: (status) {
        final isSyncing = dataType != null
            ? status.getStatus(dataType!).isSyncing
            : status.isAnySyncing;

        return ElevatedButton(
          onPressed: isSyncing
              ? null
              : () async {
                  try {
                    final syncService = ref.read(syncServiceNotifierProvider);
                    if (dataType != null) {
                      syncService.syncDataType(dataType!);
                    } else {
                      syncService.syncAllData(forceSync: true);
                    }
                  } catch (e) {
                    // Service not ready, ignore
                  }
                },
          child: isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : child ?? const Text('Sync'),
        );
      },
      loading: () => const ElevatedButton(
        onPressed: null,
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => ElevatedButton(
        onPressed: () async {
          try {
            final service = ref.read(syncServiceNotifierProvider);
            service.syncAllData(forceSync: true);
          } catch (e) {
            // Service not ready, ignore
          }
        },
        child: child ?? const Text('Retry'),
      ),
    );
  }
}
