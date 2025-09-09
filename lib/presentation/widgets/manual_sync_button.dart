import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/sync_service.dart';

/// Manual sync button widget for triggering data synchronization
class ManualSyncButton extends ConsumerStatefulWidget {
  final String dataType;
  final Widget child;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const ManualSyncButton({
    super.key,
    required this.dataType,
    required this.child,
    this.onSuccess,
    this.onError,
  });

  @override
  ConsumerState<ManualSyncButton> createState() => _ManualSyncButtonState();
}

class _ManualSyncButtonState extends ConsumerState<ManualSyncButton> {
  bool _isLoading = false;

  Future<void> _triggerSync() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final syncService = ref.read(syncServiceNotifierProvider);
      await syncService.syncDataType(widget.dataType);
      if (mounted && widget.onSuccess != null) {
        widget.onSuccess!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        if (widget.onError != null) {
          widget.onError!();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _triggerSync,
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.child,
    );
  }
}
