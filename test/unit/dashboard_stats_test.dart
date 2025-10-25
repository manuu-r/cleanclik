import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/services/business/user_service.dart';

void main() {
  group('Dashboard Statistics', () {
    test('DashboardStats.empty() creates empty stats', () {
      final stats = DashboardStats.empty();
      
      expect(stats.totalPoints, equals(0));
      expect(stats.rank, isNull);
      expect(stats.totalItemsDisposed, equals(0));
      expect(stats.recentActivity, isEmpty);
      expect(stats.categoryBreakdown, isEmpty);
      expect(stats.isStale, isFalse);
    });

    test('DashboardStats.copyWithStale() marks data as stale', () {
      final originalStats = DashboardStats(
        totalPoints: 100,
        rank: 5,
        totalItemsDisposed: 10,
        recentActivity: [],
        categoryBreakdown: {'recycle': 5, 'organic': 3},
        lastUpdated: DateTime.now(),
        isStale: false,
      );
      
      final staleStats = originalStats.copyWithStale();
      
      expect(staleStats.totalPoints, equals(100));
      expect(staleStats.rank, equals(5));
      expect(staleStats.totalItemsDisposed, equals(10));
      expect(staleStats.categoryBreakdown, equals({'recycle': 5, 'organic': 3}));
      expect(staleStats.isStale, isTrue);
    });

    test('DashboardStats JSON serialization works correctly', () {
      final originalStats = DashboardStats(
        totalPoints: 150,
        rank: 3,
        totalItemsDisposed: 15,
        recentActivity: [
          RecentActivity(
            id: 'test-1',
            displayName: 'Plastic Bottle',
            category: 'recycle',
            timestamp: DateTime(2024, 1, 1, 12, 0),
            pointsEarned: 10,
          ),
        ],
        categoryBreakdown: {'recycle': 8, 'organic': 7},
        lastUpdated: DateTime(2024, 1, 1, 12, 0),
        isStale: false,
      );
      
      final json = originalStats.toJson();
      final deserializedStats = DashboardStats.fromJson(json);
      
      expect(deserializedStats.totalPoints, equals(150));
      expect(deserializedStats.rank, equals(3));
      expect(deserializedStats.totalItemsDisposed, equals(15));
      expect(deserializedStats.recentActivity.length, equals(1));
      expect(deserializedStats.recentActivity.first.displayName, equals('Plastic Bottle'));
      expect(deserializedStats.categoryBreakdown, equals({'recycle': 8, 'organic': 7}));
      expect(deserializedStats.isStale, isFalse);
    });

    test('RecentActivity.fromInventoryRow() creates activity from database row', () {
      final inventoryRow = {
        'id': 'test-id',
        'display_name': 'Glass Jar',
        'category': 'recycle',
        'picked_up_at': '2024-01-01T12:00:00.000Z',
      };
      
      final activity = RecentActivity.fromInventoryRow(inventoryRow);
      
      expect(activity.id, equals('test-id'));
      expect(activity.displayName, equals('Glass Jar'));
      expect(activity.category, equals('recycle'));
      expect(activity.timestamp, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
      expect(activity.pointsEarned, equals(10)); // recycle category points
    });

    test('RecentActivity calculates correct points for different categories', () {
      final categories = {
        'hazardous': 20,
        'ewaste': 15,
        'recycle': 10,
        'organic': 8,
        'landfill': 5,
        'unknown': 5,
      };
      
      for (final entry in categories.entries) {
        final inventoryRow = {
          'id': 'test-id',
          'display_name': 'Test Item',
          'category': entry.key,
          'picked_up_at': '2024-01-01T12:00:00.000Z',
        };
        
        final activity = RecentActivity.fromInventoryRow(inventoryRow);
        expect(activity.pointsEarned, equals(entry.value), 
               reason: 'Category ${entry.key} should award ${entry.value} points');
      }
    });
  });
}