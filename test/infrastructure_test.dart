import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'helpers/base_service_test.dart';
import 'helpers/base_widget_test.dart';
import 'helpers/supabase_test_client.dart';
import 'helpers/test_utils.dart';
import 'fixtures/test_data_factory.dart';
import 'test_environment.dart';

/// Test to verify the testing infrastructure is properly set up
void main() {
  group('Testing Infrastructure', () {
    setUpAll(() async {
      await TestEnvironment.initialize();
    });

    tearDownAll(() async {
      await TestEnvironment.cleanup();
    });

    test('TestEnvironment initializes correctly', () {
      expect(TestEnvironment.globalContainer, isNotNull);
      TestEnvironment.verifyTestEnvironment();
    });

    test('SupabaseTestClient can be configured', () {
      SupabaseTestClient.configure();
      final client = SupabaseTestClient.instance;
      expect(client, isNotNull);
    });

    test('TestDataFactory creates mock users', () {
      final user = TestDataFactory.createMockUser(
        username: 'testuser',
        email: 'test@example.com',
      );
      
      expect(user.username, equals('testuser'));
      expect(user.email, equals('test@example.com'));
      expect(user.totalPoints, equals(100));
    });

    test('TestDataFactory creates mock detected objects', () {
      final detectedObject = TestDataFactory.createMockDetectedObject(
        codeName: 'PLASTIC_BOTTLE',
        confidence: 0.9,
      );
      
      expect(detectedObject.codeName, equals('PLASTIC_BOTTLE'));
      expect(detectedObject.confidence, equals(0.9));
    });

    test('TestDataFactory creates mock bin locations', () {
      final binLocation = TestDataFactory.createMockBinLocation(
        name: 'Test Bin',
        latitude: 37.7749,
        longitude: -122.4194,
      );
      
      expect(binLocation.name, equals('Test Bin'));
      expect(binLocation.coordinates.latitude, equals(37.7749));
      expect(binLocation.coordinates.longitude, equals(-122.4194));
    });

    test('TestUtils provides utility functions', () {
      final randomString = TestUtils.generateRandomString(10);
      expect(randomString.length, equals(10));
      
      final randomEmail = TestUtils.generateRandomEmail();
      expect(randomEmail, contains('@example.com'));
    });

    test('BaseServiceTest can be extended', () {
      final testClass = _TestServiceTest();
      testClass.setUpMocks();
      
      expect(testClass.mockRouter, isNotNull);
      
      testClass.tearDownMocks();
    });

    test('BaseWidgetTest can be extended', () {
      final testClass = _TestWidgetTest();
      testClass.setUpWidgetTest();
      
      expect(testClass.mockRouter, isNotNull);
      
      testClass.tearDownWidgetTest();
    });

    test('Performance measurement works', () async {
      final duration = await TestUtils.measureExecutionTime(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      
      expect(duration.inMilliseconds, greaterThanOrEqualTo(100));
    });

    test('Mock data generation works for inventory items', () {
      final items = TestDataFactory.createMockInventoryItems(count: 5);
      expect(items.length, equals(5));
      
      for (final item in items) {
        expect(item['id'], isNotNull);
        expect(item['category'], isNotNull);
        expect(item['points'], isA<int>());
      }
    });

    test('Mock leaderboard entries can be created', () {
      final entries = List.generate(3, (index) => 
        TestDataFactory.createMockLeaderboardEntry(
          username: 'user$index',
          totalPoints: 1000 - (index * 100),
          rank: index + 1,
        )
      );
      
      expect(entries.length, equals(3));
      expect(entries[0].rank, equals(1));
      expect(entries[0].totalPoints, equals(1000));
      expect(entries[2].rank, equals(3));
      expect(entries[2].totalPoints, equals(800));
    });
  });
}

/// Test implementation of BaseServiceTest
class _TestServiceTest extends BaseServiceTest {
  // This class is used to test that BaseServiceTest can be extended
}

/// Test implementation of BaseWidgetTest  
class _TestWidgetTest extends BaseWidgetTest {
  // This class is used to test that BaseWidgetTest can be extended
}