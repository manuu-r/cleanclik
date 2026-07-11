import 'package:flutter/material.dart';

/// Base bottom sheet component with consistent styling
///
/// Provides drag handle, glassmorphism, and swipe-to-dismiss
class BaseBottomSheet extends StatelessWidget {
  final Widget content;
  final double heightFraction; // 0.3, 0.5, 0.7, 0.9
  final bool isDismissible;
  final VoidCallback? onDismiss;
  final String? title;

  const BaseBottomSheet({
    super.key,
    required this.content,
    this.heightFraction = 0.5,
    this.isDismissible = true,
    this.onDismiss,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * heightFraction;

    return GestureDetector(
      onTap: () {
        if (isDismissible && onDismiss != null) {
          onDismiss!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: () {}, // Prevent tap from dismissing when tapping sheet
            child: Container(
              height: sheetHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  if (isDismissible)
                    GestureDetector(
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity! > 0 && onDismiss != null) {
                          onDismiss!();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Title
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a bottom sheet with this component
  static void show({
    required BuildContext context,
    required Widget content,
    double heightFraction = 0.5,
    bool isDismissible = true,
    String? title,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      builder: (context) => BaseBottomSheet(
        content: content,
        heightFraction: heightFraction,
        isDismissible: isDismissible,
        onDismiss: () => Navigator.of(context).pop(),
        title: title,
      ),
    );
  }
}
