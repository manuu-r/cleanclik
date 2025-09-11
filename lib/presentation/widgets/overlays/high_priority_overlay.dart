import 'package:flutter/material.dart';

/// A high-priority overlay that appears above all other UI elements including floating action hubs
class HighPriorityOverlay extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBackgroundTap;
  final Color? backgroundColor;
  final bool dismissible;

  const HighPriorityOverlay({
    super.key,
    required this.child,
    this.onBackgroundTap,
    this.backgroundColor,
    this.dismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // High-priority background
          Positioned.fill(
            child: GestureDetector(
              onTap: dismissible
                  ? (onBackgroundTap ??
                        () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        })
                  : null,
              child: Container(color: backgroundColor ?? Colors.black54),
            ),
          ),

          // Content
          child,
        ],
      ),
    );
  }

  /// Show this overlay with maximum priority
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    VoidCallback? onBackgroundTap,
    Color? backgroundColor,
    bool dismissible = true,
    bool useRootNavigator = true,
  }) {
    try {
      return showDialog<T>(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: dismissible,
        useRootNavigator: useRootNavigator,
        builder: (context) => HighPriorityOverlay(
          onBackgroundTap: onBackgroundTap,
          backgroundColor: backgroundColor,
          dismissible: dismissible,
          child: child,
        ),
      );
    } catch (e) {
      print('Error showing high priority overlay: $e');
      return Future.value(null);
    }
  }
}
