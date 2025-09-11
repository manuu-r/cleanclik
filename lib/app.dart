import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanclik/core/routing/app_router.dart';

import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/services/system/logging_service.dart';
import 'package:cleanclik/core/services/social/deep_link_service.dart';

class CleanClikApp extends ConsumerStatefulWidget {
  const CleanClikApp({super.key});

  @override
  ConsumerState<CleanClikApp> createState() => _CleanClikAppState();
}

class _CleanClikAppState extends ConsumerState<CleanClikApp> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();

    // Initialize logging service with production-appropriate defaults
    if (kDebugMode) {
      logger.initializeDefaults();
    } else {
      // Production: only log warnings and errors
      logger.setLogLevel(LogLevel.warning);
    }

    // Initialize services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize the auth service (will check for existing session)
      final authService = ref.read(authServiceProvider);
      await authService.initialize();

      // Initialize deep link service
      final deepLinkService = ref.read(deepLinkServiceProvider);
      await deepLinkService.initialize();

      // Set up deep link callbacks
      _setupDeepLinkCallbacks(deepLinkService);
    } catch (e) {
      debugPrint('Failed to initialize services: $e');
    }
  }

  void _setupDeepLinkCallbacks(DeepLinkService deepLinkService) {
    // Set navigation callback
    deepLinkService.setNavigationCallback((route, {extra}) {
      if (_router != null && mounted) {
        if (extra != null) {
          _router!.push(route, extra: extra);
        } else {
          _router!.go(route);
        }
      }
    });

    // Set message callback
    deepLinkService.setMessageCallback((message, {isError = false}) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: isError ? 5 : 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    _router = router; // Store reference for deep link navigation

    return MaterialApp.router(
      title: 'CleanClik',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Global scaffold messenger for deep link messages
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
  }
}
