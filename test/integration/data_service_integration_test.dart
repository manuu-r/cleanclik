import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

import 'package:cleanclik/core/services/data/data_service.dart';
import 'package:cleanclik/core/models/social_models.dart';
import 'package:cleanclik/core/models/user_models.dart';
import 'package:cleanclik/core/models/location_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';

import '../helpers/base_integration_test.dart';
import '../fixtures/test_data_factory.dart';
import '../test_environment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DataService Integration Tests', () {
    late DataService dataService;
    late String testUserId;

    setUpAll(() async {
      await TestEnvironment.initialize();

      // Initialize Supabase with test configuration
      await Supabase.initialize(
        url: TestEnvironment.supabaseUrl,
        anonKey: TestEnvironment.supabaseAnonKey,
      );

      // Create DataService instance
      dataService = await DataService.create();
      testUserId =
          'integration_test_user_${DateTime.now().millisecondsSinceEpoch}';
    });

    tearDownAll(() async {
      // Clean up test data
      await _cleanupTestData(dataService, testUserId);
      dataService.dispose();
    });

    group('End-to-End Data Flow', () {
      testWidgets('should handle complete inventory workflow', (tester) async {
        // 1. Create inventory items
        final inventoryItems = List.generate(
          5,
          (i) => {
            'tracking_id': 'test_item_$i',
            'category':
                WasteCategory.values[i % WasteCategory.values.length].name,
            'label': 'Test Item $i',
            'picked_up_at': DateTime.now().toIso8601String(),
            'points': 10 + (i * 5),
          },
        );

        final createResult = await dataService.createInventoryBatch(
          testUserId,
          inventoryItems,
        );

        expect(createResult.isSuccess, true);
        expect(createResult.data, hasLength(5));

        // 2. Retrieve inventory
        final getResult = await dataService.getInventoryByUserId(testUserId);
        expect(getResult.isSuccess, true);
        expect(getResult.data, hasLength(5));

        // 3. Get category stats
        final statsResult = await dataService.getInventoryCategoryStats(
          testUserId,
        );
        expect(statsResult.isSuccess, true);
        expect(statsResult.data!.values.reduce((a, b) => a + b), 5);

        // 4. Find specific item by tracking ID
        final findResult = await dataService.findInventoryByTrackingId(
          testUserId,
          'test_item_0',
        );
        expect(findResult.isSuccess, true);
        expect(findResult.data, isNotNull);

        // 5. Delete items by tracking IDs
        final deleteResult = await dataService.deleteInventoryByTrackingIds(
          testUserId,
          ['test_item_0', 'test_item_1'],
        );
        expect(deleteResult.isSuccess, true);
        expect(deleteResult.data, 2);

        // 6. Verify deletion
        final finalResult = await dataService.getInventoryByUserId(testUserId);
        expect(finalResult.isSuccess, true);
        expect(finalResult.data, hasLength(3));
      });

      testWidgets('should handle achievement progression', (tester) async {
        // 1. Check initial achievements
        final initialResult = await dataService.getUserAchievements(testUserId);
        expect(initialResult.isSuccess, true);
        final initialCount = initialResult.data!.length;

        // 2. Unlock first achievement
        final unlockResult1 = await dataService.unlockAchievement(
          testUserId,
          'first_scan',
          metadata: {'points_earned': 10},
        );
        expect(unlockResult1.isSuccess, true);

        // 3. Try to unlock same achievement again (should fail)
        final duplicateResult = await dataService.unlockAchievement(
          testUserId,
          'first_scan',
        );
        expect(duplicateResult.isSuccess, false);

        // 4. Unlock another achievement
        final unlockResult2 = await dataService.unlockAchievement(
          testUserId,
          'eco_warrior',
          metadata: {'items_categorized': 100},
        );
        expect(unlockResult2.isSuccess, true);

        // 5. Verify achievements count
        final finalResult = await dataService.getUserAchievements(testUserId);
        expect(finalResult.isSuccess, true);
        expect(finalResult.data!.length, initialCount + 2);

        // 6. Check specific achievement
        final hasResult = await dataService.hasUserAchievement(
          testUserId,
          'eco_warrior',
        );
        expect(hasResult.isSuccess, true);
        expect(hasResult.data, true);
      });

      testWidgets('should handle user profile and points', (tester) async {
        // 1. Create user profile
        final profileData = {
          'username': 'integration_test_user',
          'email': 'test@integration.com',
          'total_points': 0,
          'level': 1,
        };

        final createResult = await dataService.create(
          'profiles',
          profileData,
          (data) => data,
          userId: testUserId,
        );
        expect(createResult.isSuccess, true);

        // 2. Get user profile
        final getResult = await dataService.getUserProfile(testUserId);
        expect(getResult.isSuccess, true);
        expect(getResult.data!['username'], 'integration_test_user');

        // 3. Add points to user
        final addPointsResult = await dataService.addPointsToUser(
          testUserId,
          150,
        );
        expect(addPointsResult.isSuccess, true);

        // 4. Update profile
        final updateResult = await dataService.updateUserProfile(testUserId, {
          'username': 'updated_test_user',
        });
        expect(updateResult.isSuccess, true);
        expect(updateResult.data!['username'], 'updated_test_user');

        // 5. Verify profile changes
        final finalResult = await dataService.getUserProfile(testUserId);
        expect(finalResult.isSuccess, true);
        expect(finalResult.data!['username'], 'updated_test_user');
      });
    });

    group('Caching and Performance', () {
      testWidgets('should demonstrate cache effectiveness', (tester) async {
        const cacheKey = 'performance_test';
        final testData = {
          'test': 'data',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // 1. Store data in cache
        dataService.setCache(
          cacheKey,
          testData,
          ttl: const Duration(minutes: 5),
        );

        // 2. Retrieve from cache (should be fast)
        final stopwatch = Stopwatch()..start();
        final cachedData = dataService.getCache<Map<String, dynamic>>(cacheKey);
        stopwatch.stop();

        expect(cachedData, testData);
        expect(
          stopwatch.elapsedMicroseconds,
          lessThan(1000),
        ); // Should be very fast

        // 3. Test cache statistics
        final stats = dataService.getCacheStats();
        expect(stats['size'], greaterThan(0));
        expect(stats['maxSize'], 200); // Default cache size
      });

      testWidgets('should handle cache TTL correctly', (tester) async {
        const shortTTLKey = 'short_ttl_test';
        const testValue = 'expires_soon';

        // 1. Set cache with short TTL
        dataService.setCache(
          shortTTLKey,
          testValue,
          ttl: const Duration(milliseconds: 500),
        );

        // 2. Verify data is cached
        expect(dataService.getCache<String>(shortTTLKey), testValue);

        // 3. Wait for TTL to expire
        await tester.pump(const Duration(milliseconds: 600));

        // 4. Verify data is no longer cached
        expect(dataService.getCache<String>(shortTTLKey), isNull);
      });

      testWidgets('should preload user data efficiently', (tester) async {
        // Create test user profile first
        await dataService.create(
          'profiles',
          {
            'username': 'preload_test_user',
            'email': 'preload@test.com',
            'total_points': 100,
            'level': 2,
          },
          (data) => data,
          userId: testUserId,
        );

        // Measure preload performance
        final stopwatch = Stopwatch()..start();
        await dataService.preloadUserData(testUserId);
        stopwatch.stop();

        // Verify data is cached
        expect(dataService.getCache('users_$testUserId'), isNotNull);
        expect(dataService.getCache('inventory_user_$testUserId'), isNotNull);
        expect(
          dataService.getCache('achievements_user_$testUserId'),
          isNotNull,
        );
        expect(dataService.getCache('user_rank_$testUserId'), isNotNull);

        // Performance should be reasonable
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
        ); // Less than 5 seconds
      });
    });

    group('Real-time Subscriptions', () {
      testWidgets('should handle inventory subscription', (tester) async {
        final subscription = dataService.subscribeToUserInventory(testUserId);
        final completer = Completer<List<Map<String, dynamic>>>();

        // Listen to subscription
        late StreamSubscription streamSubscription;
        streamSubscription = subscription.listen((data) {
          if (!completer.isCompleted) {
            completer.complete(data);
            streamSubscription.cancel();
          }
        });

        // Create inventory item to trigger subscription
        await dataService.create(
          'inventory',
          {
            'tracking_id': 'subscription_test',
            'category': 'recycle',
            'label': 'Subscription Test Item',
            'picked_up_at': DateTime.now().toIso8601String(),
            'points': 15,
          },
          (data) => data,
          userId: testUserId,
        );

        // Wait for subscription data
        final subscriptionData = await completer.future.timeout(
          const Duration(seconds: 10),
        );

        expect(subscriptionData, isNotEmpty);
      });

      testWidgets('should handle leaderboard subscription', (tester) async {
        final subscription = dataService.subscribeToLeaderboard();
        final completer = Completer<List<Map<String, dynamic>>>();

        // Listen to subscription
        late StreamSubscription streamSubscription;
        streamSubscription = subscription.listen((data) {
          if (!completer.isCompleted) {
            completer.complete(data);
            streamSubscription.cancel();
          }
        });

        // Wait for initial leaderboard data
        final leaderboardData = await completer.future.timeout(
          const Duration(seconds: 10),
        );

        expect(leaderboardData, isList);
      });
    });

    group('Error Handling and Recovery', () {
      testWidgets('should handle network connectivity issues', (tester) async {
        // This test would require network simulation
        // For now, we'll test the error handling structure

        // Try to access non-existent data
        final result = await dataService.findById(
          'non_existent_table',
          'non_existent_id',
          (data) => data,
        );

        expect(result.isSuccess, false);
        expect(result.error, isNotNull);
      });

      testWidgets('should recover from temporary failures', (tester) async {
        // Test retry logic by attempting operations that might fail initially
        // but succeed on retry (this would require more sophisticated mocking
        // in a real integration test environment)

        final result = await dataService.query(
          'profiles',
          (data) => data,
          filters: {'id': testUserId},
        );

        // Should eventually succeed even if there are temporary failures
        expect(result.isSuccess, true);
      });
    });

    group('Local Storage Integration', () {
      testWidgets('should persist and retrieve local data', (tester) async {
        final testData = {
          'user_preferences': {
            'theme': 'dark',
            'notifications': true,
            'language': 'en',
          },
          'cache_timestamp': DateTime.now().toIso8601String(),
        };

        // 1. Store data locally
        await dataService.setLocal('user_settings', testData);

        // 2. Retrieve data
        final retrievedData = await dataService.getLocal('user_settings');
        expect(retrievedData, testData);

        // 3. Store simple values
        await dataService.setLocalValue(
          'last_sync',
          DateTime.now().millisecondsSinceEpoch,
        );
        await dataService.setLocalValue('user_level', 5);
        await dataService.setLocalValue('tutorial_completed', true);

        // 4. Retrieve simple values
        expect(dataService.getLocalValue<int>('last_sync'), isNotNull);
        expect(dataService.getLocalValue<int>('user_level'), 5);
        expect(dataService.getLocalValue<bool>('tutorial_completed'), true);

        // 5. Remove specific data
        await dataService.removeLocal('user_settings');
        final removedData = await dataService.getLocal('user_settings');
        expect(removedData, isNull);
      });
    });

    group('Location-based Operations', () {
      testWidgets('should handle geospatial queries', (tester) async {
        final testLocation = LatLng(37.7749, -122.4194); // San Francisco
        const radiusMeters = 1000.0;

        // 1. Get bins near location
        final binsResult = await dataService.getBinsNearLocation(
          testLocation,
          radiusMeters,
        );
        expect(binsResult.isSuccess, true);

        // 2. Find nearest bin
        final nearestResult = await dataService.findNearestBin(
          testLocation,
          'recycle',
        );
        expect(nearestResult.isSuccess, true);

        // 3. Get all bin locations
        final allBinsResult = await dataService.getAllBinLocations();
        expect(allBinsResult.isSuccess, true);
      });
    });
  });
}

/// Helper function to clean up test data
Future<void> _cleanupTestData(
  DataService dataService,
  String testUserId,
) async {
  try {
    // Clean up inventory
    final inventoryResult = await dataService.getInventoryByUserId(testUserId);
    if (inventoryResult.isSuccess && inventoryResult.data!.isNotEmpty) {
      final trackingIds = inventoryResult.data!
          .map((item) => item['tracking_id'] as String)
          .toList();
      await dataService.deleteInventoryByTrackingIds(testUserId, trackingIds);
    }

    // Clean up profile
    await dataService.delete('users', testUserId);

    // Clean up achievements (if any test-specific ones were created)
    final achievementsResult = await dataService.getUserAchievements(
      testUserId,
    );
    if (achievementsResult.isSuccess && achievementsResult.data!.isNotEmpty) {
      for (final achievement in achievementsResult.data!) {
        await dataService.delete('achievements', achievement.id);
      }
    }

    // Clear local storage
    await dataService.clearLocal();

    // Clear cache
    dataService.clearCache();
  } catch (e) {
    // Log cleanup errors but don't fail the test
    print('Cleanup error: $e');
  }
}
