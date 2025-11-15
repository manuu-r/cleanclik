// Consolidated router + route constants
// Previously route constants lived in a separate `routes.dart` file.
// They've been moved here to keep routing definitions colocated with the router.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/presentation/navigation/ar_navigation_shell.dart';
import 'package:cleanclik/presentation/navigation/home/home_screen.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_screen.dart';
import 'package:cleanclik/presentation/screens/camera/unified_camera_screen.dart';
import 'package:cleanclik/presentation/screens/map/map_screen.dart';
import 'package:cleanclik/presentation/screens/profile/profile_screen.dart';
import 'package:cleanclik/presentation/screens/auth/login_screen.dart';
import 'package:cleanclik/presentation/screens/auth/signup_screen.dart';
import 'package:cleanclik/presentation/screens/auth/email_verification_screen.dart';
import 'package:cleanclik/presentation/screens/auth/auth_wrapper.dart';

/// Application route constants (consolidated)
class Routes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String map = '/map';
  static const String profile = '/profile';

  // Authentication routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';

  // Future routes for additional features
  static const String settings = '/settings';
  static const String achievements = '/achievements';
  static const String missions = '/missions';
  static const String tutorial = '/tutorial';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    // Navigation guards and state restoration
    redirect: (context, state) {
      // Prevent navigation loops and invalid states
      final location = state.uri.path;

      // Ensure valid routes only
      final validRoutes = [
        Routes.home,
        Routes.map,
        Routes.profile,
        Routes.camera,
        Routes.login,
        Routes.signup,
        Routes.emailVerification,
      ];

      if (!validRoutes.contains(location)) {
        return Routes.home;
      }

      return null; // Allow navigation
    },
    routes: [
      // Authentication routes (not protected)
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: Routes.emailVerification,
        name: 'emailVerification',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),

      // NEW: Single camera-first screen as home
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const AuthWrapper(
          child: UnifiedCameraScreen(),
        ),
      ),

      // Legacy routes (kept for backwards compatibility, will become slide panels)
      GoRoute(
        path: Routes.map,
        name: 'map',
        builder: (context, state) => const AuthWrapper(
          child: MapScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const AuthWrapper(
          child: ProfileScreen(),
        ),
      ),

      // Camera Route (full screen, protected)
      GoRoute(
        path: Routes.camera,
        name: 'camera',
        builder: (context, state) {
          // Parse mode parameter from query string
          final modeParam = state.uri.queryParameters['mode'];
          final initialMode = CameraModeExtension.fromString(modeParam);

          return AuthWrapper(child: ARCameraScreen(initialMode: initialMode));
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you\'re looking for doesn\'t exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
