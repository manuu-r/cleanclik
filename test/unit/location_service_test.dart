import 'dart:async';

import 'package:cleanclik/core/services/location/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_environment.dart';

void main() {
  group('LocationService Unit Tests', () {
    late ProviderContainer container;
    late LocationService locationService;

    setUpAll(() async {
      await TestEnvironment.initialize();
    });

    setUp(() {
      container = TestEnvironment.createTestContainer();
      locationService = container.read(locationServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize successfully and check permissions', () async {
      final initialized = await locationService.initialize();
      expect(initialized, isTrue);
    });

    test('should get current location from mocked platform channel', () async {
      final locationData = await locationService.getCurrentLocation();
      expect(locationData, isNotNull);
      expect(locationData, isA<LocationData>());
      expect(locationData!.position.latitude, isA<double>());
      expect(locationData.position.longitude, isA<double>());
    });

    test('should start and stop location tracking stream', () async {
      final completer = Completer<LocationData>();
      final subscription = locationService.locationStream.listen((
        locationData,
      ) {
        if (!completer.isCompleted) {
          completer.complete(locationData);
        }
      });

      await locationService.startTracking();
      expect(locationService.isTracking, isTrue);

      final locationData = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      expect(locationData, isNotNull);
      expect(locationData.position.latitude, isA<double>());

      await locationService.stopTracking();
      expect(locationService.isTracking, isFalse);

      await subscription.cancel();
    });

    test('should calculate distance between two points correctly', () {
      final point1 = LatLng(37.7749, -122.4194); // San Francisco
      final point2 = LatLng(34.0522, -118.2437); // Los Angeles

      final distance = locationService.distanceBetween(point1, point2);
      expect(distance, greaterThan(500000)); // Approx 559km
      expect(distance, lessThan(600000));
    });

    test('should correctly check if a point is within a radius', () {
      final center = LatLng(37.7749, -122.4194);
      final insidePoint = LatLng(37.7750, -122.4195);
      final outsidePoint = LatLng(37.8750, -122.5195);

      expect(locationService.isWithinRadius(center, insidePoint, 100), isTrue);
      expect(
        locationService.isWithinRadius(center, outsidePoint, 100),
        isFalse,
      );
    });

    test('should return accuracy status', () async {
      await locationService.getCurrentLocation();
      final accuracy = locationService.getAccuracyStatus();
      expect(accuracy, isA<LocationAccuracyStatus>());
      // The mock gives high accuracy
      expect(accuracy, LocationAccuracyStatus.good);
    });

    test('should dispose service and stream controllers', () async {
      await locationService.startTracking();
      expect(locationService.isTracking, isTrue);

      await locationService.dispose();

      // After disposal, the service should be stopped
      expect(locationService.isTracking, isFalse);
      // Stream should be closed
      expect(locationService.locationStream.isBroadcast, isTrue);
    });
  });
}
