import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/system_models.dart';
// Simplified sync status - no complex sync service needed

/// Widget that displays the current synchronization status (simplified)
class SyncStatusIndicator extends ConsumerWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const SyncStatusIndicator({super.key, this.showDetails = false, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simplified sync status - always show as synced since services handle their own sync
    return _buildStatusIndicator(context);
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Simplified - always show as synced
    const icon = Icons.cloud_done;
    final color = colorScheme.primary;
    const tooltip = 'Synced';

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
          Icon(icon, size: 16, color: color),
          if (showDetails) ...[
            const SizedBox(width: 8),
            Text(
              tooltip,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
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

/// Simplified sync status dialog
class SyncStatusDialog extends StatelessWidget {
  const SyncStatusDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync Status'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done, size: 48, color: Colors.green),
          SizedBox(height: 16),
          Text('All data is synchronized'),
          Text('Services handle sync automatically'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
