import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

import 'package:cleanclik/core/services/data/data_service.dart';
import 'package:cleanclik/core/models/system_models.dart';
import 'package:cleanclik/core/models/social_models.dart';
import 'package:cleanclik/core/models/user_models.dart';
import 'package:cleanclik/core/models/location_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';

import '../fixtures/test_data_factory.dart';
import '../unit/data_service_test.mocks.dart';

/// Helper class for DataService testing with pre-configured mocks and utilities
class DataServiceTestHelper {
  late MockSupabaseClient mockSupabase;
  late MockSharedPreferences mockPrefs;
  late MockPostgrestQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late MockPostgrestBuilder mockBuilder;
  late MockPostgrestTransformBuilder mockTransformBuilder;
  late DataService dataService;

  /// Initialize all mocks and DataService instance
  void setUp({int cacheSize = 50}) {
    mockSupabase = MockSupabaseClient();
    mockPrefs = MockSharedPreferences();
    mockQueryBuilder = MockPostgrestQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    mockBuilder = MockPostgrestBuilder();
    mockTransformBuilder = MockPostgrestTransformBuilder();

    _setupDefaultMockBehaviors();

    dataService = DataService(
      supabase: mockSupabase,
      prefs: mockPrefs,
      cacheSize: cacheSize,
    );
  }

  /// Clean up resources
  void tearDown() {
    dataService.dispose();
  }

  /// Set up default mock behaviors for common operations
  void _setupDefaultMockBehaviors() {
    // Query builder setup
    when(mockSupabase.from(any)).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.inFilter(any, any)).thenReturn(mockFilterBuilder);
    when(
      mockFilterBuilder.order(any, ascending: anyNamed('ascending')),
    ).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.limit(any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.range(any, any)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);
    when(mockFilterBuilder.single()).thenAnswer((_) async => {});
    when(mockFilterBuilder.then(any)).thenAnswer((_) async => []);

    // Insert/Update/Delete setup
    when(mockQueryBuilder.insert(any)).thenReturn(mockBuilder);
    when(mockBuilder.select(any)).thenReturn(mockFilterBuilder);
    when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
    when(mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);

    // RPC setup
    when(
      mockSupabase.rpc(any, params: anyNamed('params')),
    ).thenAnswer((_) async => []);

    // Stream setup
    when(
      mockQueryBuilder.stream(primaryKey: anyNamed('primaryKey')),
    ).thenReturn(mockFilterBuilder);

    // SharedPreferences setup
    when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);
    when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
    when(mockPrefs.setDouble(any, any)).thenAnswer((_) async => true);
    when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
    when(mockPrefs.remove(any)).thenAnswer((_) async => true);
    when(mockPrefs.clear()).thenAnswer((_) async => true);
    when(mockPrefs.getString(any)).thenReturn(null);
    when(mockPrefs.get(any)).thenReturn(null);
  }

  /// Mock successful findById operation
  void mockFindById(String table, String id, Map<String, dynamic> data) {
    when(mockFilterBuilder.eq('id', id)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => data);
  }

  /// Mock findById returning null (not found)
  void mockFindByIdNotFound(String table, String id) {
    when(mockFilterBuilder.eq('id', id)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);
  }

  /// Mock successful findByUserId operation
  void mockFindByUserId(
    String table,
    String userId,
    List<Map<String, dynamic>> data,
  ) {
    when(mockFilterBuilder.eq('user_id', userId)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.then(any)).thenAnswer((_) async => data);
  }

  /// Mock successful create operation
  void mockCreate(String table, Map<String, dynamic> responseData) {
    when(mockFilterBuilder.single()).thenAnswer((_) async => responseData);
  }

  /// Mock successful update operation
  void mockUpdate(String table, String id, Map<String, dynamic> responseData) {
    when(mockFilterBuilder.eq('id', id)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.single()).thenAnswer((_) async => responseData);
  }

  /// Mock successful delete operation
  void mockDelete(String table, String id) {
    when(mockFilterBuilder.eq('id', id)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.then(any)).thenAnswer((_) async => null);
  }

  /// Mock successful query operation
  void mockQuery(
    String table,
    List<Map<String, dynamic>> data, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) {
    if (filters != null) {
      for (final entry in filters.entries) {
        when(
          mockFilterBuilder.eq(entry.key, entry.value),
        ).thenReturn(mockFilterBuilder);
      }
    }
    if (orderBy != null) {
      when(
        mockFilterBuilder.order(orderBy, ascending: ascending),
      ).thenReturn(mockFilterBuilder);
    }
    if (limit != null) {
      when(mockFilterBuilder.limit(limit)).thenReturn(mockFilterBuilder);
    }
    when(mockFilterBuilder.then(any)).thenAnswer((_) async => data);
  }

  /// Mock successful batch create operation
  void mockCreateBatch(String table, List<Map<String, dynamic>> responseData) {
    when(mockFilterBuilder.then(any)).thenAnswer((_) async => responseData);
  }

  /// Mock successful batch delete operation
  void mockDeleteBatch(String table, List<String> ids) {
    when(mockFilterBuilder.inFilter('id', ids)).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.then(any)).thenAnswer((_) async => null);
  }

  /// Mock RPC call
  void mockRpc(
    String functionName,
    dynamic response, {
    Map<String, dynamic>? params,
  }) {
    when(
      mockSupabase.rpc(functionName, params: params ?? anyNamed('params')),
    ).thenAnswer((_) async => response);
  }

  /// Mock SharedPreferences operations
  void mockSharedPreferences({
    Map<String, String>? stringValues,
    Map<String, int>? intValues,
    Map<String, bool>? boolValues,
    Map<String, double>? doubleValues,
    Map<String, List<String>>? stringListValues,
  }) {
    if (stringValues != null) {
      for (final entry in stringValues.entries) {
        when(mockPrefs.getString(entry.key)).thenReturn(entry.value);
        when(mockPrefs.get(entry.key)).thenReturn(entry.value);
      }
    }
    if (intValues != null) {
      for (final entry in intValues.entries) {
        when(mockPrefs.getInt(entry.key)).thenReturn(entry.value);
        when(mockPrefs.get(entry.key)).thenReturn(entry.value);
      }
    }
    if (boolValues != null) {
      for (final entry in boolValues.entries) {
        when(mockPrefs.getBool(entry.key)).thenReturn(entry.value);
        when(mockPrefs.get(entry.key)).thenReturn(entry.value);
      }
    }
    if (doubleValues != null) {
      for (final entry in doubleValues.entries) {
        when(mockPrefs.getDouble(entry.key)).thenReturn(entry.value);
        when(mockPrefs.get(entry.key)).thenReturn(entry.value);
      }
    }
    if (stringListValues != null) {
      for (final entry in stringListValues.entries) {
        when(mockPrefs.getStringList(entry.key)).thenReturn(entry.value);
        when(mockPrefs.get(entry.key)).thenReturn(entry.value);
      }
    }
  }

  /// Mock database exception
  void mockDatabaseException(DatabaseErrorType errorType, String message) {
    final exception = DatabaseException(errorType, message);
    when(mockFilterBuilder.maybeSingle()).thenThrow(exception);
    when(mockFilterBuilder.single()).thenThrow(exception);
    when(mockFilterBuilder.then(any)).thenThrow(exception);
  }

  /// Mock Supabase PostgrestException
  void mockPostgrestException(String code, String message) {
    final exception = PostgrestException(message: message, code: code);
    when(mockFilterBuilder.maybeSingle()).thenThrow(exception);
    when(mockFilterBuilder.single()).thenThrow(exception);
    when(mockFilterBuilder.then(any)).thenThrow(exception);
  }

  /// Mock network timeout
  void mockNetworkTimeout() {
    final exception = TimeoutException(
      'Network timeout',
      const Duration(seconds: 30),
    );
    when(mockFilterBuilder.maybeSingle()).thenThrow(exception);
    when(mockFilterBuilder.single()).thenThrow(exception);
    when(mockFilterBuilder.then(any)).thenThrow(exception);
  }

  /// Mock real-time subscription stream
  Stream<List<Map<String, dynamic>>> mockRealtimeStream(
    String table,
    List<Map<String, dynamic>> initialData, {
    Duration interval = const Duration(seconds: 1),
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    // Emit initial data
    controller.add(initialData);

    // Set up periodic updates
    Timer.periodic(interval, (timer) {
      if (!controller.isClosed) {
        // Simulate data changes
        final updatedData = initialData.map((item) {
          final updated = Map<String, dynamic>.from(item);
          updated['updated_at'] = DateTime.now().toIso8601String();
          return updated;
        }).toList();
        controller.add(updatedData);
      } else {
        timer.cancel();
      }
    });

    when(
      mockQueryBuilder.stream(primaryKey: anyNamed('primaryKey')),
    ).thenReturn(mockFilterBuilder);
    when(mockFilterBuilder.map(any)).thenReturn(controller.stream);

    return controller.stream;
  }

  /// Create test inventory data
  List<Map<String, dynamic>> createTestInventoryData(
    String userId, {
    int count = 5,
  }) {
    return TestDataFactory.createMockInventoryItems(
      count: count,
      userId: userId,
    );
  }

  /// Create test achievement data
  List<Map<String, dynamic>> createTestAchievementData(
    String userId, {
    int count = 3,
  }) {
    return List.generate(count, (i) {
      final achievement = TestDataFactory.createMockAchievement(
        id: 'test_achievement_$i',
        title: 'Test Achievement $i',
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      return {
        'achievement_id': achievement.id,
        'user_id': userId,
        'title': achievement.title,
        'description': achievement.description,
        'unlocked_at': achievement.unlockedAt?.toIso8601String(),
        'metadata': achievement.metadata,
      };
    });
  }

  /// Create test leaderboard data
  List<Map<String, dynamic>> createTestLeaderboardData({int count = 10}) {
    return TestDataFactory.createMockLeaderboardEntries(count: count)
        .map(
          (entry) => {
            'id': entry.id,
            'username': entry.username,
            'total_points': entry.totalPoints,
            'level': entry.level,
            'rank': entry.rank,
            'avatar_url': entry.avatarUrl,
            'last_active_at': entry.lastActiveAt.toIso8601String(),
          },
        )
        .toList();
  }

  /// Create test bin location data
  List<Map<String, dynamic>> createTestBinLocationData({int count = 5}) {
    return TestDataFactory.createMockBinLocations(
      count: count,
    ).map((bin) => bin.toJson()).toList();
  }

  /// Create test user profile data
  Map<String, dynamic> createTestUserProfileData(String userId) {
    final user = TestDataFactory.createMockUser(id: userId);
    return user.toJson();
  }

  /// Verify cache contains expected data
  void verifyCacheContains(String key, dynamic expectedValue) {
    final cachedValue = dataService.getCache(key);
    expect(cachedValue, expectedValue);
  }

  /// Verify cache is empty for key
  void verifyCacheEmpty(String key) {
    final cachedValue = dataService.getCache(key);
    expect(cachedValue, isNull);
  }

  /// Verify SharedPreferences was called
  void verifySharedPreferencesCall(String method, String key, {dynamic value}) {
    switch (method) {
      case 'getString':
        verify(mockPrefs.getString(key)).called(1);
        break;
      case 'setString':
        verify(mockPrefs.setString(key, value)).called(1);
        break;
      case 'getInt':
        verify(mockPrefs.getInt(key)).called(1);
        break;
      case 'setInt':
        verify(mockPrefs.setInt(key, value)).called(1);
        break;
      case 'getBool':
        verify(mockPrefs.getBool(key)).called(1);
        break;
      case 'setBool':
        verify(mockPrefs.setBool(key, value)).called(1);
        break;
      case 'remove':
        verify(mockPrefs.remove(key)).called(1);
        break;
      case 'clear':
        verify(mockPrefs.clear()).called(1);
        break;
    }
  }

  /// Verify Supabase query was called with expected parameters
  void verifySupabaseQuery(
    String table, {
    String? selectColumns,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool? ascending,
    int? limit,
  }) {
    verify(mockSupabase.from(table)).called(1);

    if (selectColumns != null) {
      verify(mockQueryBuilder.select(selectColumns)).called(1);
    }

    if (filters != null) {
      for (final entry in filters.entries) {
        verify(mockFilterBuilder.eq(entry.key, entry.value)).called(1);
      }
    }

    if (orderBy != null) {
      verify(
        mockFilterBuilder.order(orderBy, ascending: ascending ?? true),
      ).called(1);
    }

    if (limit != null) {
      verify(mockFilterBuilder.limit(limit)).called(1);
    }
  }

  /// Verify RPC was called
  void verifyRpcCall(String functionName, {Map<String, dynamic>? params}) {
    verify(
      mockSupabase.rpc(functionName, params: params ?? anyNamed('params')),
    ).called(1);
  }

  /// Create a test scenario with pre-configured data
  void setupTestScenario({
    required String userId,
    bool includeInventory = true,
    bool includeAchievements = true,
    bool includeProfile = true,
    bool includeLeaderboard = true,
    bool includeBinLocations = true,
  }) {
    if (includeProfile) {
      final profileData = createTestUserProfileData(userId);
      mockFindById('profiles', userId, profileData);
    }

    if (includeInventory) {
      final inventoryData = createTestInventoryData(userId);
      mockFindByUserId('inventory', userId, inventoryData);

      // Mock category stats
      final categoryStats = <String, int>{};
      for (final item in inventoryData) {
        final category = item['category'] as String;
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      }
      when(mockFilterBuilder.then(any)).thenAnswer(
        (_) async => inventoryData
            .map((item) => {'category': item['category']})
            .toList(),
      );
    }

    if (includeAchievements) {
      final achievementData = createTestAchievementData(userId);
      mockFindByUserId('achievements', userId, achievementData);
    }

    if (includeLeaderboard) {
      final leaderboardData = createTestLeaderboardData();
      mockQuery('leaderboard_view', leaderboardData, orderBy: 'total_points');

      // Mock user rank
      final userRank =
          leaderboardData.indexWhere((entry) => entry['id'] == userId) + 1;
      mockFindById('leaderboard_view', userId, {'rank': userRank});
    }

    if (includeBinLocations) {
      final binData = createTestBinLocationData();
      mockQuery('bin_locations', binData, orderBy: 'name');
      mockRpc('get_bins_near_location', binData);
      mockRpc('find_nearest_bin', binData.isNotEmpty ? [binData.first] : []);
    }
  }
}

/// Extension methods for easier testing
extension DataServiceTestExtensions on DataService {
  /// Get cache size for testing
  int get cacheSize => getCacheStats()['size'] as int;

  /// Get max cache size for testing
  int get maxCacheSize => getCacheStats()['maxSize'] as int;

  /// Check if cache contains key
  bool hasCacheKey(String key) => getCache(key) != null;

  /// Get all cache keys (for testing purposes)
  List<String> get cacheKeys {
    // This would require exposing cache internals for testing
    // For now, we'll use the cache stats
    return [];
  }
}
