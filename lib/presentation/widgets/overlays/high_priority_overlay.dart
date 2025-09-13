import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';
import 'package:cleanclik/presentation/widgets/overlays/base_material_overlay.dart';

/// A high-priority Material 3 overlay that appears above all other UI elements
class HighPriorityOverlay extends BaseMaterialOverlay {
  final Widget content;

  const HighPriorityOverlay({
    super.key,
    required this.content,
    super.onDismiss,
    super.backgroundColor,
    super.dismissible = true,
    super.hapticFeedback = false,
  });

  @override
  AnimationConfig getEntranceAnimation(BuildContext context) {
    return AnimationConfig(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget buildContent(BuildContext context, Animation<double> animation) {
    return content;
  }

  @override
  State<HighPriorityOverlay> createState() => _HighPriorityOverlayState();

  /// Show Material 3 high-priority overlay
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    VoidCallback? onDismiss,
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
          content: child,
          onDismiss: onDismiss,
          backgroundColor: backgroundColor,
          dismissible: dismissible,
        ),
      );
    } catch (e) {
      debugPrint('Error showing high priority overlay: $e');
      return Future.value(null);
    }
  }
}

class _HighPriorityOverlayState extends State<HighPriorityOverlay> {
  // State is managed by BaseMaterialOverlay
  @override
  Widget build(BuildContext context) {
    return Container(); // This will be handled by BaseMaterialOverlay
  }
}

/// Legacy high-priority overlay for backward compatibility
class LegacyHighPriorityOverlay extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBackgroundTap;
  final Color? backgroundColor;
  final bool dismissible;

  const LegacyHighPriorityOverlay({
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
          // High-priority background with Material 3 surface treatment
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
              child: Container(
                color: backgroundColor ?? 
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.6),
              ),
            ),
          ),

          // Content
          child,
        ],
      ),
    );
  }

  /// Show legacy overlay for backward compatibility
  static Future<T?> showLegacy<T>({
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
        builder: (context) => LegacyHighPriorityOverlay(
          onBackgroundTap: onBackgroundTap,
          backgroundColor: backgroundColor,
          dismissible: dismissible,
          child: child,
        ),
      );
    } catch (e) {
      debugPrint('Error showing legacy high priority overlay: $e');
      return Future.value(null);
    }
  }
}