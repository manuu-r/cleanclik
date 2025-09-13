import 'package:cleanclik/core/models/waste_category.dart';
import '../test_data_factory.dart';
import '../../test_config.dart';

/// Mock inventory item data for testing
class MockInventoryItems {
  /// Create a list of mock inventory items
  static List<Map<String, dynamic>> createMockInventoryItems({
    int count = 50,
    String? userId,
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      final labels = TestConfig.wasteCategories[category.name] ?? ['Unknown Item'];
      final label = labels[index % labels.length];
      
      return TestDataFactory.createMockInventoryItem(
        id: 'inventory-$index',
        objectId: 'object-$index',
        category: category,
        label: label,
        pickedUpAt: DateTime.now().subtract(Duration(days: index)),
        disposedAt: index % 3 == 0 ? DateTime.now().subtract(Duration(days: index - 1)) : null,
        binId: index % 3 == 0 ? 'bin-${index % 10}' : null,
        points: TestConfig.categoryPoints[category.name] ?? 5,
        isSynced: index % 4 != 0, // 25% not synced for testing
      );
    });
  }

  /// Create mock inventory items for a specific category
  static List<Map<String, dynamic>> createCategoryInventoryItems({
    required WasteCategory category,
    int count = 10,
    String? userId,
  }) {
    final labels = TestConfig.wasteCategories[category.name] ?? ['Unknown Item'];
    
    return List.generate(count, (index) {
      return TestDataFactory.createMockInventoryItem(
        id: 'inventory-${category.name}-$index',
        objectId: 'object-${category.name}-$index',
        category: category,
        label: labels[index % labels.length],
        pickedUpAt: DateTime.now().subtract(Duration(hours: index)),
        points: TestConfig.categoryPoints[category.name] ?? 5,
        isSynced: true,
      );
    });
  }

  /// Create mock pending inventory items (not yet disposed)
  static List<Map<String, dynamic>> createPendingInventoryItems({
    int count = 15,
    String? userId,
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      final labels = TestConfig.wasteCategories[category.name] ?? ['Unknown Item'];
      
      return TestDataFactory.createMockInventoryItem(
        id: 'pending-$index',
        objectId: 'pending-object-$index',
        category: category,
        label: labels[index % labels.length],
        pickedUpAt: DateTime.now().subtract(Duration(minutes: index * 10)),
        disposedAt: null, // Not disposed yet
        binId: null,
        points: TestConfig.categoryPoints[category.name] ?? 5,
        isSynced: index % 2 == 0, // 50% synced
      );
    });
  }

  /// Create mock disposed inventory items
  static List<Map<String, dynamic>> createDisposedInventoryItems({
    int count = 20,
    String? userId,
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      final labels = TestConfig.wasteCategories[category.name] ?? ['Unknown Item'];
      final pickedUpAt = DateTime.now().subtract(Duration(days: index + 1));
      
      return TestDataFactory.createMockInventoryItem(
        id: 'disposed-$index',
        objectId: 'disposed-object-$index',
        category: category,
        label: labels[index % labels.length],
        pickedUpAt: pickedUpAt,
        disposedAt: pickedUpAt.add(Duration(hours: 2 + index)),
        binId: 'bin-${index % 10}',
        points: TestConfig.categoryPoints[category.name] ?? 5,
        isSynced: true,
      );
    });
  }

  /// Create mock inventory items with sync conflicts
  static List<Map<String, dynamic>> createConflictedInventoryItems({
    int count = 5,
    String? userId,
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      
      return {
        ...TestDataFactory.createMockInventoryItem(
          id: 'conflict-$index',
          category: category,
          isSynced: false,
        ),
        'syncConflict': true,
        'conflictReason': 'version_mismatch',
        'localVersion': 2,
        'remoteVersion': 3,
        'conflictData': {
          'local': {
            'label': 'Local Label $index',
            'points': 10,
          },
          'remote': {
            'label': 'Remote Label $index',
            'points': 15,
          },
        },
      };
    });
  }

  /// Create mock inventory items for performance testing
  static List<Map<String, dynamic>> createPerformanceTestItems({
    int count = 1000,
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      
      return TestDataFactory.createMockInventoryItem(
        id: 'perf-$index',
        objectId: 'perf-object-$index',
        category: category,
        label: 'Performance Test Item $index',
        pickedUpAt: DateTime.now().subtract(Duration(seconds: index)),
        points: 1,
        isSynced: index % 10 == 0, // 10% not synced
      );
    });
  }

  /// Create mock inventory summary data
  static Map<String, dynamic> createInventorySummary({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'totalItems': 125,
      'pendingItems': 15,
      'disposedItems': 110,
      'totalPoints': 1250,
      'categoryBreakdown': {
        'recycle': {
          'items': 50,
          'points': 500,
          'pending': 5,
          'disposed': 45,
        },
        'organic': {
          'items': 40,
          'points': 320,
          'pending': 4,
          'disposed': 36,
        },
        'landfill': {
          'items': 25,
          'points': 125,
          'pending': 3,
          'disposed': 22,
        },
        'ewaste': {
          'items': 8,
          'points': 120,
          'pending': 2,
          'disposed': 6,
        },
        'hazardous': {
          'items': 2,
          'points': 40,
          'pending': 1,
          'disposed': 1,
        },
      },
      'recentActivity': List.generate(7, (day) => {
        'date': DateTime.now().subtract(Duration(days: day)).toIso8601String().split('T')[0],
        'items': 3 + (day % 3),
        'points': 30 + ((day % 3) * 10),
      }),
      'syncStatus': {
        'lastSync': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'pendingSync': 3,
        'syncErrors': 0,
      },
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock inventory batch operations
  static Map<String, dynamic> createBatchOperation({
    String? operationType,
    int itemCount = 10,
  }) {
    return {
      'operationId': 'batch-${DateTime.now().millisecondsSinceEpoch}',
      'type': operationType ?? 'bulk_dispose',
      'itemIds': List.generate(itemCount, (index) => 'item-$index'),
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
      'estimatedCompletion': DateTime.now().add(const Duration(seconds: 30)).toIso8601String(),
      'progress': {
        'total': itemCount,
        'completed': 0,
        'failed': 0,
      },
    };
  }

  /// Create mock inventory export data
  static Map<String, dynamic> createInventoryExport({
    String? userId,
    String? format = 'csv',
  }) {
    return {
      'exportId': 'export-${DateTime.now().millisecondsSinceEpoch}',
      'userId': userId ?? 'test-user-id',
      'format': format,
      'status': 'completed',
      'itemCount': 125,
      'fileSize': 15420, // bytes
      'downloadUrl': 'https://example.com/exports/inventory-export.csv',
      'expiresAt': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'filters': {
        'dateRange': {
          'start': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'end': DateTime.now().toIso8601String(),
        },
        'categories': ['recycle', 'organic'],
        'status': 'all',
      },
    };
  }

  /// Create mock inventory analytics data
  static Map<String, dynamic> createInventoryAnalytics({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'period': 'last_30_days',
      'metrics': {
        'totalItems': 45,
        'totalPoints': 450,
        'averageItemsPerDay': 1.5,
        'streakDays': 7,
        'mostActiveDay': 'Tuesday',
        'mostActiveHour': 14,
        'categoryDistribution': {
          'recycle': 0.4,
          'organic': 0.3,
          'landfill': 0.2,
          'ewaste': 0.07,
          'hazardous': 0.03,
        },
        'disposalEfficiency': 0.85, // percentage of items properly disposed
        'syncReliability': 0.95, // percentage of successful syncs
      },
      'trends': {
        'itemsCollected': [2, 3, 1, 4, 2, 3, 5], // last 7 days
        'pointsEarned': [20, 30, 10, 40, 20, 30, 50],
        'categoryTrends': {
          'recycle': [1, 1, 0, 2, 1, 1, 2],
          'organic': [1, 2, 1, 1, 1, 2, 2],
          'landfill': [0, 0, 0, 1, 0, 0, 1],
        },
      },
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}