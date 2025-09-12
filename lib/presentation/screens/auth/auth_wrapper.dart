import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/services/auth/supabase_config_service.dart';
import 'package:cleanclik/presentation/screens/auth/login_screen.dart';

/// Wrapper widget that handles authentication state and route protection
class AuthWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  Timer? _timeoutTimer;
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    // Set a timeout for initialization (shorter for release builds)
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _hasTimedOut = true;
        });
        debugPrint('Auth initialization timed out after 5 seconds');
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If timed out, show the app in demo mode
    if (_hasTimedOut) {
      debugPrint('Auth timed out, showing app in demo mode');
      return widget.child;
    }

    // Check if Supabase is in demo mode - if so, skip auth entirely
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Running in demo mode, skipping authentication');
      _timeoutTimer?.cancel();
      return widget.child;
    }

    // Watch authentication state
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        // Cancel timeout timer since we got a result
        _timeoutTimer?.cancel();
        
        switch (authState.status) {
          case AuthStatus.loading:
            return const AuthLoadingScreen();
            
          case AuthStatus.authenticated:
            return widget.child;
            
          case AuthStatus.unauthenticated:
            // If running in demo mode, show the child
            if (authState.isDemoMode) {
              return widget.child;
            }
            // Otherwise show login screen
            return const LoginScreen();
            
          case AuthStatus.error:
            // If there's an auth error but we're in demo mode, show the child
            if (authState.isDemoMode) {
              return widget.child;
            }
            // In release mode, show the app anyway (demo mode)
            debugPrint('Auth error in release mode, showing app in demo mode: ${authState.error}');
            return widget.child;
        }
      },
      loading: () => const AuthLoadingScreen(),
      error: (error, stackTrace) {
        // Cancel timeout timer since we got a result
        _timeoutTimer?.cancel();
        
        debugPrint('Auth state error: $error');

        // In any error case, show the app in demo mode for release builds
        debugPrint('Auth error, showing app in demo mode');
        return widget.child;
      },
    );
  }
}

/// Loading screen shown while checking authentication state
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'CleanClik',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when authentication initialization fails
class AuthErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const AuthErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Authentication Error',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'There was a problem initializing the authentication system.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate back to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Back to Login'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
