import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/supabase_config_service.dart';
import 'login_screen.dart';

/// Wrapper widget that handles authentication state and route protection
class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authentication state
    final authStateAsync = ref.watch(authStateProvider);
    
    return authStateAsync.when(
      data: (isAuthenticated) {
        // If running in demo mode or user is authenticated, show the child
        if (SupabaseConfigService.isDemoMode || isAuthenticated) {
          return child;
        }
        
        // Otherwise, show login screen
        return const LoginScreen();
      },
      loading: () => const AuthLoadingScreen(),
      error: (error, stackTrace) {
        debugPrint('Auth state error: $error');
        
        // If there's an auth error but we're in demo mode, show the child
        if (SupabaseConfigService.isDemoMode) {
          return child;
        }
        
        // Otherwise show error screen with option to retry
        return AuthErrorScreen(
          error: error.toString(),
          onRetry: () {
            ref.invalidate(authStateProvider);
          },
        );
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
            Icon(
              Icons.eco,
              size: 80,
              color: theme.colorScheme.primary,
            ),
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
            ],
          ),
        ),
      ),
    );
  }
}