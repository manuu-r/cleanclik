import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/routing/app_router.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/services/user_service.dart';
import 'package:cleanclik/core/services/logging_service.dart';

class CleanClikApp extends ConsumerStatefulWidget {
  const CleanClikApp({super.key});

  @override
  ConsumerState<CleanClikApp> createState() => _CleanClikAppState();
}

class _CleanClikAppState extends ConsumerState<CleanClikApp> {
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
    
    // Initialize demo user after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDemoUser();
    });
  }

  Future<void> _initializeDemoUser() async {
    try {
      final userService = ref.read(userServiceProvider);
      
      // Check if user is already authenticated
      if (!userService.isAuthenticated) {
        await userService.initializeWithDemoUser();
      }
    } catch (e) {
      debugPrint('Failed to initialize demo user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'CleanClik',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}