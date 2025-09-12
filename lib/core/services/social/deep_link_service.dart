import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app_links/app_links.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/services/auth/supabase_config_service.dart';

part 'deep_link_service.g.dart';

/// Service for handling deep links and app-to-app navigation
class DeepLinkService {
  final AuthService _authService;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkStreamSubscription;

  // Callback for navigation actions
  void Function(String route, {Map<String, dynamic>? extra})? onNavigate;

  // Callback for showing messages to user
  void Function(String message, {bool isError})? onShowMessage;

  DeepLinkService(this._authService);

  /// Initialize deep link handling
  Future<void> initialize() async {
    if (SupabaseConfigService.isDemoMode) {
      debugPrint('Demo mode: Deep link service disabled');
      return;
    }

    try {
      // Handle initial link (when app is opened via deep link)
      await _handleInitialLink();

      // Listen for incoming links while app is running
      _listenForIncomingLinks();

      debugPrint('Deep link service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing deep link service: $e');
    }
  }

  /// Check for pending deep links (call when app resumes)
  Future<void> checkForPendingLinks() async {
    if (SupabaseConfigService.isDemoMode) return;
    
    try {
      debugPrint('Checking for pending deep links...');
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        debugPrint('Found pending deep link: $initialLink');
        await _processDeepLink(initialLink.toString());
      } else {
        debugPrint('No pending deep links found');
      }
    } catch (e) {
      debugPrint('Error checking for pending links: $e');
    }
  }

  /// Manually process a deep link URL (for testing or direct calls)
  Future<void> processDeepLinkUrl(String url) async {
    debugPrint('Manually processing deep link: $url');
    await _processDeepLink(url);
  }

  /// Handle the initial link when app is launched via deep link
  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        debugPrint('Initial deep link received: $initialLink');
        await _processDeepLink(initialLink.toString());
      }
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }
  }

  /// Listen for incoming deep links while app is running
  void _listenForIncomingLinks() {
    debugPrint('Setting up deep link listener...');
    _linkStreamSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('Incoming deep link received: $uri');
        _processDeepLink(uri.toString());
      },
      onError: (error) {
        debugPrint('Deep link stream error: $error');
      },
    );
    debugPrint('Deep link listener setup complete');
  }

  /// Process and handle deep links
  Future<void> _processDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);
      debugPrint('Processing deep link - Host: ${uri.host}, Path: ${uri.path}');

      // Handle different types of deep links
      switch (uri.host) {
        case 'auth':
          await _handleAuthDeepLink(uri);
          break;
        case 'invite':
          await _handleInviteDeepLink(uri);
          break;
        case 'share':
          await _handleShareDeepLink(uri);
          break;
        default:
          debugPrint('Unhandled deep link host: ${uri.host}');
          _showMessage('Invalid link received', isError: true);
      }
    } catch (e) {
      debugPrint('Error processing deep link: $e');
      _showMessage('Failed to process link', isError: true);
    }
  }

  /// Handle authentication-related deep links
  Future<void> _handleAuthDeepLink(Uri uri) async {
    switch (uri.path) {
      case '/confirm':
        await _handleEmailVerification(uri);
        break;
      case '/reset-password':
        await _handlePasswordReset(uri);
        break;
      default:
        debugPrint('Unhandled auth deep link path: ${uri.path}');
        _showMessage('Invalid authentication link', isError: true);
    }
  }

  /// Handle email verification deep link
  Future<void> _handleEmailVerification(Uri uri) async {
    try {
      debugPrint('Processing email verification deep link');
      debugPrint('URI: $uri');
      debugPrint('Available parameters: ${uri.queryParameters}');
      
      _showMessage('Verifying your email...', isError: false);

      // Let Supabase handle the auth callback directly
      await _authService.handleAuthCallback(uri.toString());
      
      // Show success message and let the auth wrapper handle navigation
      _showMessage('Email verified successfully!');
      
      // Don't navigate manually - let the AuthWrapper detect the authentication
      // and navigate automatically. This prevents race conditions with service disposal.
    } catch (e) {
      debugPrint('Error during email verification: $e');
      _showMessage(
        'An error occurred during verification. Please try again.',
        isError: true,
      );
      _navigate('/login');
    }
  }

  /// Handle password reset deep link
  Future<void> _handlePasswordReset(Uri uri) async {
    try {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];

      if (token == null || email == null) {
        debugPrint('Password reset link missing required parameters');
        _showMessage('Invalid password reset link', isError: true);
        return;
      }

      debugPrint('Processing password reset for: $email');

      // Navigate to password reset screen with token and email
      _navigate('/reset-password', extra: {'token': token, 'email': email});
    } catch (e) {
      debugPrint('Error handling password reset: $e');
      _showMessage('Failed to process password reset link', isError: true);
    }
  }

  /// Handle invite deep links (future feature)
  Future<void> _handleInviteDeepLink(Uri uri) async {
    debugPrint('Invite deep link received: ${uri.toString()}');
    // TODO: Implement invite handling
    _showMessage('Invite feature coming soon!');
  }

  /// Handle share deep links (future feature)
  Future<void> _handleShareDeepLink(Uri uri) async {
    debugPrint('Share deep link received: ${uri.toString()}');
    // TODO: Implement share handling
    _showMessage('Share feature coming soon!');
  }

  /// Helper method to navigate
  void _navigate(String route, {Map<String, dynamic>? extra}) {
    onNavigate?.call(route, extra: extra);
  }

  /// Helper method to show messages
  void _showMessage(String message, {bool isError = false}) {
    onShowMessage?.call(message, isError: isError);
  }

  /// Set navigation callback
  void setNavigationCallback(
    void Function(String route, {Map<String, dynamic>? extra}) callback,
  ) {
    onNavigate = callback;
  }

  /// Set message callback
  void setMessageCallback(
    void Function(String message, {bool isError}) callback,
  ) {
    onShowMessage = callback;
  }

  /// Check if a link is a valid deep link for this app
  static bool isValidDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.scheme == 'cleanclik' &&
          ['auth', 'invite', 'share'].contains(uri.host);
    } catch (e) {
      return false;
    }
  }

  /// Generate a test deep link for development
  static String generateTestEmailVerificationLink({
    required String email,
    required String token,
  }) {
    return 'cleanclik://auth/confirm?token=$token&email=$email&type=signup';
  }

  /// Dispose resources
  void dispose() {
    debugPrint('Disposing deep link service...');
    _linkStreamSubscription?.cancel();
    _linkStreamSubscription = null;
    onNavigate = null;
    onShowMessage = null;
  }
}

/// Provider for DeepLinkService
@riverpod
DeepLinkService deepLinkService(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  final service = DeepLinkService(authService);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider for deep link initialization status
@riverpod
class DeepLinkInitialization extends _$DeepLinkInitialization {
  @override
  Future<bool> build() async {
    final deepLinkService = ref.watch(deepLinkServiceProvider);

    try {
      await deepLinkService.initialize();
      return true;
    } catch (e) {
      debugPrint('Failed to initialize deep link service: $e');
      return false;
    }
  }

  /// Reinitialize the deep link service
  Future<void> reinitialize() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final deepLinkService = ref.read(deepLinkServiceProvider);
      await deepLinkService.initialize();
      return true;
    });
  }
}
