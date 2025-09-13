import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'mock_services.mocks.dart';

// Import CleanClik services for mocking
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/services/camera/ml_detection_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/location/location_service.dart';
import 'package:cleanclik/core/services/social/leaderboard_service.dart';
import 'package:cleanclik/core/services/data/database_service.dart';
import 'package:cleanclik/core/services/data/local_storage_service.dart';
import 'package:cleanclik/core/services/data/sync_service.dart';

// Generate mocks for all services and external dependencies
@GenerateMocks([
  // Router mocks
  GoRouter,
  
  // CleanClik service mocks
  AuthService,
  MLDetectionService,
  InventoryService,
  LocationService,
  LeaderboardService,
  DatabaseService,
  LocalStorageService,
  SyncService,
  
  // External service mocks
  ObjectDetector,
  CameraController,
  Position,
  SupabaseClient,
  GoTrueClient,
  PostgrestQueryBuilder,
  SupabaseStorageClient,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
])
class MockServices {}

// Mock provider definitions are handled in individual test files

// Mock BinLocationService for testing
class MockBinLocationService extends Mock {
  List<BinLocation> get nearbyBins => [];
  List<BinLocation> get allBins => [];
}

// Mock data classes for testing
class BinLocation {
  final String id;
  final double latitude;
  final double longitude;
  final String type;
  
  BinLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
  });
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final int points;
  final int rank;
  
  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.points,
    required this.rank,
  });
}



