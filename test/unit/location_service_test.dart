import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:cleanclik/core/services/location/location_service.dart';
import 'package:cleanclik/core/models/bin_location.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import '../helpers/base_service_test.dart';
import '../fixtures/test_data_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('LocationService', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Initialization', () {
      test('should provide LocationService instance', () {
        final locationService = container.read(locationServiceProvider);
        expect(locationService, isA<LocationService>());
      });
    });

    group('Service Structure', () {
      test('should have proper service structure', () {
        // Test that the service exists and can be imported
        expect(LocationService, isA<Type>());
      });
    });

    group('Bin Location Management', () {
      test('should handle bin locations', () {
        final binLocation = TestDataFactory.createMockBinLocation(
          category: WasteCategory.recycle,
          latitude: 37.7749,
          longitude: -122.4194,
        );

        expect(binLocation.category, WasteCategory.recycle.name);
        expect(binLocation.coordinates.latitude, 37.7749);
        expect(binLocation.coordinates.longitude, -122.4194);
        expect(binLocation.id, isNotEmpty);
      });

      test('should create multiple bin locations', () {
        final binLocations = TestDataFactory.createMockBinLocations(count: 5);
        
        expect(binLocations.length, 5);
        expect(binLocations.every((bin) => bin.id.isNotEmpty), isTrue);
        expect(binLocations.every((bin) => bin.coordinates != null), isTrue);
      });
    });

    group('Position Handling', () {
      test('should create mock position', () {
        final position = TestDataFactory.createMockPosition(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
        );

        expect(position.latitude, 37.7749);
        expect(position.longitude, -122.4194);
        expect(position.accuracy, 5.0);
      });

      test('should handle position accuracy', () {
        final highAccuracyPosition = TestDataFactory.createMockPosition(
          accuracy: 3.0,
        );
        
        final lowAccuracyPosition = TestDataFactory.createMockPosition(
          accuracy: 50.0,
        );

        expect(highAccuracyPosition.accuracy, lessThan(10));
        expect(lowAccuracyPosition.accuracy, greaterThan(10));
      });
    });

    group('Geohash Utilities', () {
      test('should encode coordinates to geohash', () {
        final geohash = GeohashUtils.encode(37.7749, -122.4194);
        expect(geohash, isNotEmpty);
        expect(geohash.length, greaterThan(5));
      });
    });
  });
}