import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/app.dart';
import 'package:cleanclik/core/services/auth/supabase_config_service.dart';
import 'package:cleanclik/core/services/data/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize core services
    await LocalStorageService.instance.initialize();
    debugPrint('LocalStorageService initialized successfully');
    
    // Initialize Supabase configuration
    await SupabaseConfigService.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize services: $e');
    // Continue with app initialization even if services fail
    // This allows the app to work in demo mode
  }

  runApp(const ProviderScope(child: CleanClikApp()));
}
