import 'dart:ui';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// Import CleanClik models
import 'package:cleanclik/core/models/user.dart';
import 'package:cleanclik/core/models/detected_object.dart' as cleanclik;
import 'package:cleanclik/core/models/bin_location.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import 'package:cleanclik/core/models/camera_mode.dart';
import 'package:cleanclik/core/models/achievement.dart';
import 'package:cleanclik/core/models/category_stats.dart';
import 'package:cleanclik/core/models/leaderboard_entry.dart';

// Import test configuration
import '../test_config.dart';

/// Factory class for creating test data objects
class TestDataFactory {
  /// Create a mock user for testing
  static User createMockUser({
    String? id,
    String? authId,
    String? email,
    String? username,
    String? avatarUrl,
    int? totalPoints,
    int? level,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, int>? categoryStats,
    List<String>? achievements,
    bool? isOnline,
  }) {
    return User(
      id: id ?? 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      authId: authId,
      email: email ?? 'test@example.com',
      username: username ?? 'testuser',
      avatarUrl: avatarUrl,
      totalPoints: totalPoints ?? 100,
      level: level ?? 1,
      createdAt: createdAt ?? DateTime.now(),
      lastActiveAt: lastActiveAt ?? DateTime.now(),
      categoryStats: categoryStats ?? {'recycle': 5, 'organic': 3},
      achievements: achievements ?? ['first_pickup'],
      isOnline: isOnline ?? false,
    );
  }

  /// Create a mock detected object for testing
  static cleanclik.DetectedObject createMockDetectedObject({
    String? trackingId,
    WasteCategory? category,
    double? confidence,
    String? codeName,
    Rect? boundingBox,
    DateTime? detectedAt,
    Color? overlayColor,
  }) {
    return cleanclik.DetectedObject(
      trackingId: trackingId ?? 'detected-${DateTime.now().millisecondsSinceEpoch}',
      category: (category ?? WasteCategory.recycle).name,
      confidence: confidence ?? 0.85,
      codeName: codeName ?? 'PLASTIC_BOTTLE',
      boundingBox: boundingBox ?? const Rect.fromLTWH(100, 100, 200, 300),
      detectedAt: detectedAt ?? DateTime.now(),
      overlayColor: overlayColor ?? const Color(0xFF4CAF50),
    );
  }

  /// Create a mock bin location for testing
  static BinLocation createMockBinLocation({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    WasteCategory? category,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    double? fillLevel,
    bool? isActive,
  }) {
    final lat = latitude ?? 37.7749;
    final lng = longitude ?? -122.4194;
    
    return BinLocation(
      id: id ?? 'bin-${DateTime.now().millisecondsSinceEpoch}',
      geohash: GeohashUtils.encode(lat, lng),
      coordinates: LatLng(lat, lng),
      category: (category ?? WasteCategory.recycle).name,
      name: name ?? 'Test Recycling Bin',
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata ?? {'description': 'A test recycling bin for unit testing'},
      fillLevel: fillLevel ?? 0.5,
      isActive: isActive ?? true,
    );
  }

  /// Create a mock inventory item for testing
  static Map<String, dynamic> createMockInventoryItem({
    String? id,
    String? objectId,
    WasteCategory? category,
    String? label,
    DateTime? pickedUpAt,
    DateTime? disposedAt,
    String? binId,
    int? points,
    bool? isSynced,
  }) {
    return {
      'id': id ?? 'inventory-${DateTime.now().millisecondsSinceEpoch}',
      'object_id': objectId ?? 'object-123',
      'category': (category ?? WasteCategory.recycle).name,
      'label': label ?? 'Plastic Bottle',
      'picked_up_at': (pickedUpAt ?? DateTime.now()).toIso8601String(),
      'disposed_at': disposedAt?.toIso8601String(),
      'bin_id': binId,
      'points': points ?? 10,
      'is_synced': isSynced ?? false,
    };
  }

  /// Create a mock leaderboard entry for testing
  static LeaderboardEntry createMockLeaderboardEntry({
    String? id,
    String? username,
    String? avatarUrl,
    int? totalPoints,
    int? level,
    int? rank,
    DateTime? lastActiveAt,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      id: id ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      username: username ?? 'testuser',
      avatarUrl: avatarUrl,
      totalPoints: totalPoints ?? 100,
      level: level ?? 1,
      rank: rank ?? 1,
      lastActiveAt: lastActiveAt ?? DateTime.now(),
      isCurrentUser: isCurrentUser ?? false,
    );
  }

  /// Create a mock achievement for testing
  static Achievement createMockAchievement({
    String? id,
    String? title,
    String? description,
    String? iconUrl,
    AchievementType? type,
    AchievementRarity? rarity,
    int? pointsRequired,
    String? category,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? 'achievement-${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'First Recycler',
      description: description ?? 'Recycle your first item',
      iconUrl: iconUrl ?? 'assets/icons/achievement_recycle.svg',
      type: type ?? AchievementType.firstScan,
      rarity: rarity ?? AchievementRarity.common,
      pointsRequired: pointsRequired ?? 10,
      category: category ?? 'Getting Started',
      isUnlocked: isUnlocked ?? false,
      unlockedAt: unlockedAt,
    );
  }

  /// Create mock category stats for testing
  static CategoryStats createMockCategoryStats({
    String? id,
    String? userId,
    WasteCategory? category,
    int? itemCount,
    int? totalPoints,
    DateTime? updatedAt,
  }) {
    return CategoryStats(
      id: id ?? 'stats-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? 'test-user-id',
      category: (category ?? WasteCategory.recycle).name,
      itemCount: itemCount ?? 5,
      totalPoints: totalPoints ?? 50,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create a mock position for testing
  static Position createMockPosition({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
  }) {
    return Position(
      latitude: latitude ?? 37.7749,
      longitude: longitude ?? -122.4194,
      timestamp: timestamp ?? DateTime.now(),
      accuracy: accuracy ?? 5.0,
      altitude: altitude ?? 0.0,
      heading: heading ?? 0.0,
      speed: speed ?? 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  /// Create mock auth state for testing
  static Map<String, dynamic> createMockAuthState({
    String? status,
    User? user,
    bool? isDemoMode,
    String? error,
  }) {
    return {
      'status': status ?? 'authenticated',
      'user': user?.toJson(),
      'isDemoMode': isDemoMode ?? false,
      'error': error,
    };
  }

  /// Create mock camera state for testing
  static Map<String, dynamic> createMockCameraState({
    CameraMode? mode,
    String? status,
    bool? isInitialized,
    bool? isDetecting,
    String? error,
  }) {
    return {
      'mode': (mode ?? CameraMode.mlDetection).name,
      'status': status ?? 'ready',
      'isInitialized': isInitialized ?? true,
      'isDetecting': isDetecting ?? false,
      'error': error,
    };
  }

  /// Create a list of mock detected objects for testing
  static List<cleanclik.DetectedObject> createMockDetectedObjects({
    int count = 3,
    WasteCategory? category,
  }) {
    return List.generate(count, (index) {
      return createMockDetectedObject(
        trackingId: 'detected-$index',
        category: category ?? WasteCategory.values[index % WasteCategory.values.length],
        confidence: 0.8 + (index * 0.05),
        codeName: 'TEST_OBJECT_$index',
        boundingBox: Rect.fromLTWH(
          100.0 + (index * 50),
          100.0 + (index * 50),
          200.0,
          300.0,
        ),
      );
    });
  }

  /// Create a list of mock bin locations for testing
  static List<BinLocation> createMockBinLocations({
    int count = 5,
    double? centerLat,
    double? centerLng,
  }) {
    final baseLat = centerLat ?? 37.7749;
    final baseLng = centerLng ?? -122.4194;
    
    return List.generate(count, (index) {
      return createMockBinLocation(
        id: 'bin-$index',
        name: 'Test Bin $index',
        latitude: baseLat + (index * 0.001),
        longitude: baseLng + (index * 0.001),
        category: WasteCategory.values[index % WasteCategory.values.length],
      );
    });
  }

  /// Create a list of mock inventory items for testing
  static List<Map<String, dynamic>> createMockInventoryItems({
    int count = 10,
    String? userId,
  }) {
    return List.generate(count, (index) {
      return createMockInventoryItem(
        id: 'inventory-$index',
        objectId: 'object-$index',
        category: WasteCategory.values[index % WasteCategory.values.length],
        label: 'Test Item $index',
        points: 10 + (index * 5),
      );
    });
  }

  /// Create a list of mock leaderboard entries for testing
  static List<LeaderboardEntry> createMockLeaderboardEntries({
    int count = 10,
  }) {
    return List.generate(count, (index) {
      return createMockLeaderboardEntry(
        id: 'user-$index',
        username: 'user$index',
        totalPoints: 1000 - (index * 100),
        level: (index ~/ 3) + 1,
        rank: index + 1,
      );
    });
  }

  /// Create mock Supabase database responses
  static Map<String, dynamic> createMockSupabaseResponse({
    List<Map<String, dynamic>>? data,
    String? error,
    int? count,
  }) {
    return {
      'data': data ?? [],
      'error': error,
      'count': count ?? data?.length ?? 0,
    };
  }

  /// Create mock ML Kit detection results
  static List<Map<String, dynamic>> createMockMLKitResults({
    int count = 3,
    double minConfidence = 0.7,
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      final labels = TestConfig.wasteCategories[category.name] ?? ['Unknown Object'];
      
      return {
        'trackingId': index,
        'labels': [
          {
            'text': labels[index % labels.length],
            'confidence': minConfidence + (Random().nextDouble() * (1.0 - minConfidence)),
          },
        ],
        'boundingBox': {
          'left': 100.0 + (index * 50),
          'top': 100.0 + (index * 50),
          'right': 300.0 + (index * 50),
          'bottom': 400.0 + (index * 50),
        },
      };
    });
  }

  /// Create comprehensive auth state fixtures for all scenarios
  static Map<String, Map<String, dynamic>> createAuthStateFixtures() {
    return {
      'signed_out': createMockAuthState(
        status: 'signed_out',
        user: null,
        isDemoMode: false,
      ),
      'signed_in': createMockAuthState(
        status: 'signed_in',
        user: createMockUser(
          id: 'auth-user-id',
          email: TestConfig.testUserEmail,
          username: TestConfig.testUserUsername,
        ),
        isDemoMode: false,
      ),
      'demo_mode': createMockAuthState(
        status: 'signed_in',
        user: createMockUser(
          id: 'demo-user-id',
          email: 'demo@cleanclik.com',
          username: 'demouser',
        ),
        isDemoMode: true,
      ),
      'google_signed_in': createMockAuthState(
        status: 'signed_in',
        user: createMockUser(
          id: 'google-user-id',
          email: 'google.user@gmail.com',
          username: 'googleuser',
          avatarUrl: 'https://lh3.googleusercontent.com/test-avatar',
        ),
        isDemoMode: false,
      ),
      'email_verification_pending': createMockAuthState(
        status: 'email_verification_pending',
        user: createMockUser(
          id: 'unverified-user-id',
          email: 'unverified@example.com',
          username: 'unverifieduser',
        ),
        isDemoMode: false,
      ),
      'auth_error': createMockAuthState(
        status: 'error',
        user: null,
        isDemoMode: false,
        error: 'Invalid login credentials',
      ),
    };
  }

  /// Create comprehensive camera state fixtures for all scenarios
  static Map<String, Map<String, dynamic>> createCameraStateFixtures() {
    return {
      'initializing': createMockCameraState(
        mode: CameraMode.mlDetection,
        status: 'initializing',
        isInitialized: false,
        isDetecting: false,
      ),
      'ready_ml_detection': createMockCameraState(
        mode: CameraMode.mlDetection,
        status: 'ready',
        isInitialized: true,
        isDetecting: false,
      ),
      'detecting_objects': createMockCameraState(
        mode: CameraMode.mlDetection,
        status: 'detecting',
        isInitialized: true,
        isDetecting: true,
      ),
      'ready_qr_scanning': createMockCameraState(
        mode: CameraMode.qrScanning,
        status: 'ready',
        isInitialized: true,
        isDetecting: false,
      ),
      'scanning_qr': createMockCameraState(
        mode: CameraMode.qrScanning,
        status: 'scanning',
        isInitialized: true,
        isDetecting: true,
      ),
      'camera_error': createMockCameraState(
        mode: CameraMode.mlDetection,
        status: 'error',
        isInitialized: false,
        isDetecting: false,
        error: 'Camera permission denied',
      ),
      'ml_processing_error': createMockCameraState(
        mode: CameraMode.mlDetection,
        status: 'error',
        isInitialized: true,
        isDetecting: false,
        error: 'ML Kit processing failed',
      ),
    };
  }

  /// Create user profile fixtures for different scenarios
  static Map<String, Map<String, dynamic>> createUserProfileFixtures() {
    return {
      'new_user': {
        ...createMockUser(
          id: 'new-user-id',
          email: 'newuser@example.com',
          username: 'newuser',
          totalPoints: 0,
          level: 1,
          categoryStats: {},
          achievements: [],
        ).toJson(),
        'isNewUser': true,
        'onboardingCompleted': false,
      },
      'active_user': {
        ...createMockUser(
          id: 'active-user-id',
          email: 'activeuser@example.com',
          username: 'activeuser',
          totalPoints: 1250,
          level: 5,
          categoryStats: {
            'recycle': 50,
            'organic': 30,
            'landfill': 20,
            'ewaste': 8,
            'hazardous': 2,
          },
          achievements: ['first_recycler', 'eco_warrior'],
        ).toJson(),
        'isNewUser': false,
        'onboardingCompleted': true,
        'streakDays': 15,
        'lastActiveAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      'premium_user': {
        ...createMockUser(
          id: 'premium-user-id',
          email: 'premium@example.com',
          username: 'premiumuser',
          totalPoints: 5000,
          level: 10,
          categoryStats: {
            'recycle': 200,
            'organic': 150,
            'landfill': 100,
            'ewaste': 50,
            'hazardous': 25,
          },
          achievements: ['first_recycler', 'eco_warrior', 'organic_expert', 'premium_member'],
        ).toJson(),
        'isPremium': true,
        'premiumExpiresAt': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'streakDays': 45,
      },
    };
  }

  /// Create comprehensive test scenarios for edge cases
  static Map<String, List<Map<String, dynamic>>> createEdgeCaseScenarios() {
    return {
      'empty_states': [
        // Empty inventory
        {'type': 'empty_inventory', 'data': <Map<String, dynamic>>[]},
        // Empty leaderboard
        {'type': 'empty_leaderboard', 'data': <Map<String, dynamic>>[]},
        // No nearby bins
        {'type': 'no_nearby_bins', 'data': <Map<String, dynamic>>[]},
        // No detected objects
        {'type': 'no_detected_objects', 'data': <Map<String, dynamic>>[]},
      ],
      'large_datasets': [
        // Large inventory (1000 items)
        {
          'type': 'large_inventory',
          'data': List.generate(1000, (index) => createMockInventoryItem(
            id: 'large-inventory-$index',
            category: WasteCategory.values[index % WasteCategory.values.length],
          )),
        },
        // Large leaderboard (10000 users)
        {
          'type': 'large_leaderboard',
          'data': List.generate(10000, (index) => createMockLeaderboardEntry(
            id: 'large-leaderboard-$index',
            username: 'user$index',
            totalPoints: 10000 - index,
            rank: index + 1,
          ).toJson()),
        },
      ],
      'network_conditions': [
        // Slow network simulation
        {
          'type': 'slow_network',
          'delay': TestConfig.networkDelayMax,
          'data': createMockInventoryItems(count: 10),
        },
        // Network failure simulation
        {
          'type': 'network_failure',
          'error': TestConfig.errorMessages['network_error'],
          'data': null,
        },
        // Intermittent connectivity
        {
          'type': 'intermittent_network',
          'failureRate': TestConfig.networkFailureRate,
          'data': createMockInventoryItems(count: 5),
        },
      ],
    };
  }

  /// Create performance test data sets
  static Map<String, List<Map<String, dynamic>>> createPerformanceTestData() {
    return {
      'ml_detection_performance': List.generate(TestConfig.performanceTestIterations, (index) => {
        'iteration': index,
        'objects': createMockDetectedObjects(count: Random().nextInt(TestConfig.maxSimultaneousObjects) + 1),
        'processingTime': Random().nextInt(TestConfig.mlProcessingThreshold.inMilliseconds),
        'memoryUsage': Random().nextInt(TestConfig.memoryUsageThreshold),
      }),
      'camera_switching_performance': List.generate(50, (index) => {
        'iteration': index,
        'fromMode': CameraMode.values[index % 2],
        'toMode': CameraMode.values[(index + 1) % 2],
        'switchingTime': Random().nextInt(TestConfig.cameraSwitchingThreshold.inMilliseconds),
      }),
      'supabase_sync_performance': List.generate(100, (index) => {
        'iteration': index,
        'itemCount': Random().nextInt(50) + 1,
        'syncTime': Random().nextInt(TestConfig.supabaseSyncThreshold.inMilliseconds),
        'networkLatency': Random().nextInt(1000) + 100, // 100-1100ms
      }),
    };
  }

  /// Create mock real-time subscription data
  static Stream<Map<String, dynamic>> createMockRealtimeStream({
    Duration interval = const Duration(seconds: 1),
    String eventType = 'UPDATE',
  }) async* {
    while (true) {
      yield {
        'eventType': eventType,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'leaderboard_update': createMockLeaderboardEntry().toJson(),
          'inventory_sync': createMockInventoryItem(),
          'bin_status_update': createMockBinLocation().toJson(),
        },
      };
      await Future.delayed(interval);
    }
  }

  /// Create comprehensive test image metadata
  static Map<String, Map<String, dynamic>> createTestImageMetadata() {
    return {
      'recycle_bottle': {
        'fileName': 'plastic_bottle_001.jpg',
        'category': 'recycle',
        'expectedConfidence': 0.92,
        'boundingBox': const Rect.fromLTWH(150, 200, 200, 300),
        'lighting': 'good',
        'background': 'simple',
        'angle': 'front',
      },
      'organic_apple': {
        'fileName': 'apple_core_001.jpg',
        'category': 'organic',
        'expectedConfidence': 0.88,
        'boundingBox': const Rect.fromLTWH(180, 180, 150, 150),
        'lighting': 'natural',
        'background': 'complex',
        'angle': 'side',
      },
      'ewaste_phone': {
        'fileName': 'smartphone_001.jpg',
        'category': 'ewaste',
        'expectedConfidence': 0.95,
        'boundingBox': const Rect.fromLTWH(200, 150, 100, 200),
        'lighting': 'artificial',
        'background': 'simple',
        'angle': 'front',
      },
      'edge_case_blurry': {
        'fileName': 'blurry_object_001.jpg',
        'category': 'landfill',
        'expectedConfidence': 0.45,
        'boundingBox': const Rect.fromLTWH(100, 100, 300, 400),
        'lighting': 'poor',
        'background': 'complex',
        'angle': 'unclear',
        'isEdgeCase': true,
      },
      'edge_case_multiple': {
        'fileName': 'multiple_objects_001.jpg',
        'category': 'mixed',
        'expectedObjects': 3,
        'lighting': 'good',
        'background': 'complex',
        'isEdgeCase': true,
      },
    };
  }
}