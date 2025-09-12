import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanclik/core/routing/routes.dart';

/// Utility class for safe authentication navigation
class AuthNavigationUtils {
  /// Safely navigate back to login screen with error recovery
  static void navigateToLogin(BuildContext context, {String? errorMessage}) {
    try {
      // Try GoRouter first
      context.go(Routes.login);
    } catch (e) {
      // Fallback to Navigator if GoRouter fails
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.login,
        (route) => false,
      );
    }
  }

  /// Show error dialog with option to return to login
  static void showAuthErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              navigateToLogin(context);
            },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}