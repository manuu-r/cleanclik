import 'dart:math';
import 'package:cleanclik/core/models/waste_category.dart';
import '../test_data_factory.dart';
import '../../test_config.dart';

/// Mock bin location data for testing
class MockBinLocations {
  /// Create a list of mock bin locations
  static List<Map<String, dynamic>> createMockBinLocations({
    int count = 20,
    double? centerLat,
    double? centerLng,
    double radius = 0.01, // ~1km radius
  }) {
    final baseLat = centerLat ?? TestConfig.testLatitude;
    final baseLng = centerLng ?? TestConfig.testLongitude;
    
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      final angle = (index / count) * 2 * pi;
      final distance = Random().nextDouble() * radius;
      
      final lat = baseLat + (distance * cos(angle));
      final lng = baseLng + (distance * sin(angle));
      
      final binLocation = TestDataFactory.createMockBinLocation(
        id: 'bin-$index',
        name: '${category.name.toUpperCase()} Bin $index',
        latitude: lat,
        longitude: lng,
        category: category,
        description: 'Test ${category.name} disposal bin for unit testing',
        isActive: index % 10 != 0, // 10% inactive for testing
      );
      
      return {
        ...binLocation.toJson(),
        'address': 'Test Street ${index + 1}, Test City',
        'capacity': {
          'current': Random().nextInt(80) + 10, // 10-90%
          'maximum': 100,
          'unit': 'percentage',
        },
        'accessibility': {
          'wheelchairAccessible': index % 3 == 0,
          'publicAccess': index % 5 != 0,
          'operatingHours': {
            'open': '06:00',
            'close': '22:00',
            'allDay': index % 7 == 0,
          },
        },
        'maintenance': {
          'lastEmptied': DateTime.now().subtract(Duration(days: Random().nextInt(7))).toIso8601String(),
          'nextScheduledMaintenance': DateTime.now().add(Duration(days: Random().nextInt(14) + 1)).toIso8601String(),
          'condition': ['excellent', 'good', 'fair', 'poor'][Random().nextInt(4)],
        },
      };
    });
  }

  /// Create mock bin locations near a specific point
  static List<Map<String, dynamic>> createNearbyBinLocations({
    required double latitude,
    required double longitude,
    int count = 5,
    double maxDistance = 0.001, // ~100m
  }) {
    return List.generate(count, (index) {
      final category = WasteCategory.values[index % WasteCategory.values.length];
      final angle = Random().nextDouble() * 2 * pi;
      final distance = Random().nextDouble() * maxDistance;
      
      final lat = latitude + (distance * cos(angle));
      final lng = longitude + (distance * sin(angle));
      
      return {
        ...TestDataFactory.createMockBinLocation(
          id: 'nearby-bin-$index',
          name: 'Nearby ${category.name.toUpperCase()} Bin',
          latitude: lat,
          longitude: lng,
          category: category,
        ).toJson(),
        'distance': distance * 111000, // Convert to meters (approximate)
        'isInProximity': distance * 111000 <= TestConfig.binProximityRadius,
      };
    });
  }

  /// Create mock bin locations for specific categories
  static List<Map<String, dynamic>> createCategoryBinLocations({
    required WasteCategory category,
    int count = 5,
    double? centerLat,
    double? centerLng,
  }) {
    final baseLat = centerLat ?? TestConfig.testLatitude;
    final baseLng = centerLng ?? TestConfig.testLongitude;
    
    return List.generate(count, (index) {
      return {
        ...TestDataFactory.createMockBinLocation(
          id: '${category.name}-bin-$index',
          name: '${category.name.toUpperCase()} Collection Point $index',
          latitude: baseLat + (index * 0.001),
          longitude: baseLng + (index * 0.001),
          category: category,
        ).toJson(),
        'specialFeatures': _getCategorySpecialFeatures(category),
        'usage': {
          'dailyAverage': Random().nextInt(50) + 10,
          'peakHours': ['08:00-10:00', '17:00-19:00'],
          'popularityScore': Random().nextDouble(),
        },
      };
    });
  }

  /// Create mock bin locations with different statuses
  static List<Map<String, dynamic>> createStatusVariedBinLocations() {
    return [
      // Active bin
      {
        ...TestDataFactory.createMockBinLocation(
          id: 'active-bin',
          name: 'Active Recycle Bin',
          category: WasteCategory.recycle,
          isActive: true,
        ).toJson(),
        'status': 'active',
        'capacity': {'current': 45, 'maximum': 100},
        'lastUpdate': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      
      // Full bin
      {
        ...TestDataFactory.createMockBinLocation(
          id: 'full-bin',
          name: 'Full Organic Bin',
          category: WasteCategory.organic,
          isActive: true,
        ).toJson(),
        'status': 'full',
        'capacity': {'current': 98, 'maximum': 100},
        'alerts': ['capacity_warning', 'needs_emptying'],
        'lastUpdate': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      
      // Maintenance bin
      {
        ...TestDataFactory.createMockBinLocation(
          id: 'maintenance-bin',
          name: 'Maintenance E-Waste Bin',
          category: WasteCategory.ewaste,
          isActive: false,
        ).toJson(),
        'status': 'maintenance',
        'maintenanceReason': 'Damaged lid mechanism',
        'estimatedRepairTime': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'lastUpdate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      
      // Offline bin
      {
        ...TestDataFactory.createMockBinLocation(
          id: 'offline-bin',
          name: 'Offline Hazardous Bin',
          category: WasteCategory.hazardous,
          isActive: false,
        ).toJson(),
        'status': 'offline',
        'offlineReason': 'Sensor malfunction',
        'lastOnline': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        'lastUpdate': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
    ];
  }

  /// Create mock bin location clusters for map testing
  static List<Map<String, dynamic>> createBinLocationClusters() {
    final clusters = <Map<String, dynamic>>[];
    
    // Downtown cluster
    clusters.addAll(createMockBinLocations(
      count: 8,
      centerLat: TestConfig.testLatitude,
      centerLng: TestConfig.testLongitude,
      radius: 0.002,
    ).map((bin) => {
      ...bin,
      'cluster': 'downtown',
      'clusterName': 'Downtown District',
    }));
    
    // Residential cluster
    clusters.addAll(createMockBinLocations(
      count: 6,
      centerLat: TestConfig.testLatitude + 0.01,
      centerLng: TestConfig.testLongitude + 0.01,
      radius: 0.003,
    ).map((bin) => {
      ...bin,
      'cluster': 'residential',
      'clusterName': 'Residential Area',
    }));
    
    // Industrial cluster
    clusters.addAll(createMockBinLocations(
      count: 4,
      centerLat: TestConfig.testLatitude - 0.005,
      centerLng: TestConfig.testLongitude + 0.015,
      radius: 0.001,
    ).map((bin) => {
      ...bin,
      'cluster': 'industrial',
      'clusterName': 'Industrial Zone',
    }));
    
    return clusters;
  }

  /// Create mock bin location analytics
  static Map<String, dynamic> createBinLocationAnalytics({
    String? binId,
  }) {
    return {
      'binId': binId ?? 'test-bin-id',
      'period': 'last_30_days',
      'usage': {
        'totalDeposits': 245,
        'averageDepositsPerDay': 8.2,
        'peakUsageHour': 18,
        'peakUsageDay': 'Tuesday',
        'utilizationRate': 0.73,
      },
      'capacity': {
        'averageCapacity': 0.65,
        'maxCapacityReached': 0.95,
        'emptyingFrequency': 3.2, // times per week
        'overflowIncidents': 2,
      },
      'maintenance': {
        'scheduledMaintenances': 4,
        'emergencyRepairs': 1,
        'averageDowntime': 2.5, // hours
        'reliabilityScore': 0.92,
      },
      'environmental': {
        'co2Saved': 125.6, // kg
        'wasteProcessed': 890.3, // kg
        'recyclingRate': 0.78,
        'contaminationRate': 0.05,
      },
      'userInteraction': {
        'uniqueUsers': 89,
        'repeatUsers': 67,
        'averageSessionTime': 45, // seconds
        'userSatisfactionScore': 4.2, // out of 5
      },
      'trends': {
        'daily': List.generate(30, (day) => {
          'date': DateTime.now().subtract(Duration(days: day)).toIso8601String().split('T')[0],
          'deposits': 5 + Random().nextInt(15),
          'capacity': Random().nextDouble(),
        }),
        'hourly': List.generate(24, (hour) => {
          'hour': hour,
          'deposits': Random().nextInt(10),
          'capacity': Random().nextDouble(),
        }),
      },
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock bin route optimization data
  static Map<String, dynamic> createBinRouteOptimization({
    List<String>? binIds,
    double? startLat,
    double? startLng,
  }) {
    final bins = binIds ?? ['bin-1', 'bin-2', 'bin-3', 'bin-4', 'bin-5'];
    
    return {
      'routeId': 'route-${DateTime.now().millisecondsSinceEpoch}',
      'startLocation': {
        'latitude': startLat ?? TestConfig.testLatitude,
        'longitude': startLng ?? TestConfig.testLongitude,
      },
      'bins': bins,
      'optimizedOrder': bins.reversed.toList(), // Simple reversal for testing
      'totalDistance': 2.8, // km
      'estimatedTime': 25, // minutes
      'estimatedFuelSaving': 0.3, // liters
      'co2Reduction': 0.7, // kg
      'routeEfficiency': 0.85,
      'waypoints': bins.map((binId) => {
        'binId': binId,
        'latitude': TestConfig.testLatitude + (Random().nextDouble() * 0.01),
        'longitude': TestConfig.testLongitude + (Random().nextDouble() * 0.01),
        'estimatedArrival': DateTime.now().add(Duration(minutes: bins.indexOf(binId) * 5)).toIso8601String(),
        'priority': Random().nextInt(5) + 1,
      }).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Get category-specific special features
  static List<String> _getCategorySpecialFeatures(WasteCategory category) {
    switch (category) {
      case WasteCategory.recycle:
        return ['sorting_compartments', 'compaction', 'material_scanner'];
      case WasteCategory.organic:
        return ['odor_control', 'temperature_monitoring', 'composting_info'];
      case WasteCategory.landfill:
        return ['general_waste', 'volume_sensor', 'basic_compaction'];
      case WasteCategory.ewaste:
        return ['secure_storage', 'data_destruction', 'battery_separation'];
      case WasteCategory.hazardous:
        return ['sealed_container', 'safety_protocols', 'special_handling'];
    }
  }

  /// Create mock bin location search results
  static Map<String, dynamic> createBinLocationSearchResults({
    String? query,
    double? latitude,
    double? longitude,
    WasteCategory? category,
  }) {
    final results = createMockBinLocations(count: 10);
    
    return {
      'query': query ?? 'recycle bin',
      'location': {
        'latitude': latitude ?? TestConfig.testLatitude,
        'longitude': longitude ?? TestConfig.testLongitude,
      },
      'category': category?.name,
      'results': results,
      'totalResults': results.length,
      'searchRadius': 5.0, // km
      'executionTime': 150, // milliseconds
      'suggestions': [
        'Try searching for "organic bin"',
        'Expand search radius to 10km',
        'Filter by accessibility features',
      ],
      'searchedAt': DateTime.now().toIso8601String(),
    };
  }
}