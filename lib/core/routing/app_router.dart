import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanclik/core/routing/routes.dart';
import 'package:cleanclik/core/models/camera_mode.dart';
import 'package:cleanclik/presentation/navigation/ar_navigation_shell.dart';
import 'package:cleanclik/presentation/navigation/home/home_screen.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_screen.dart';
import 'package:cleanclik/presentation/screens/map/map_screen.dart';
import 'package:cleanclik/presentation/screens/leaderboard/leaderboard_screen.dart';
import 'package:cleanclik/presentation/screens/profile/profile_screen.dart';
import 'package:cleanclik/presentation/screens/auth/login_screen.dart';
import 'package:cleanclik/presentation/screens/auth/signup_screen.dart';
import 'package:cleanclik/presentation/screens/auth/email_verification_screen.dart';
import 'package:cleanclik/presentation/screens/auth/auth_wrapper.dart';

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
        Routes.leaderboard,
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

      // Protected routes wrapped with AuthWrapper
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AuthWrapper(
            child: ARNavigationShell(navigationShell: navigationShell),
          );
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Map Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.map,
                name: 'map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),

          // Leaderboard Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.leaderboard,
                name: 'leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),

          // Profile Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
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
