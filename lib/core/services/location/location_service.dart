import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location data with accuracy and heading information
class LocationData {
  final LatLng position;
  final double accuracy;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  const LocationData({
    required this.position,
    required this.accuracy,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  factory LocationData.fromPosition(Position position) {
    return LocationData(
      position: LatLng(position.latitude, position.longitude),
      accuracy: position.accuracy,
      heading: position.heading.isNaN ? null : position.heading,
      speed: position.speed.isNaN ? null : position.speed,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LocationData(position: $position, accuracy: ${accuracy.toStringAsFixed(1)}m, heading: $heading)';
  }
}

/// Service for managing device location with real-time updates
class LocationService {
  static const String _logTag = 'LOCATION_SERVICE';

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();

  LocationData? _lastKnownLocation;
  bool _isTracking = false;

  /// Stream of location updates
  Stream<LocationData> get locationStream => _locationController.stream;

  /// Get the last known location
  LocationData? get lastKnownLocation => _lastKnownLocation;

  /// Check if location tracking is active
  bool get isTracking => _isTracking;

  /// Initialize location service and request permissions
  Future<bool> initialize() async {
    print('📍 [$_logTag] Initializing location service...');

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ [$_logTag] Location services are disabled');
        return false;
      }

      // Request location permission
      final permissionStatus = await _requestLocationPermission();
      if (!permissionStatus) {
        print('❌ [$_logTag] Location permission denied');
        return false;
      }

      // Get initial location
      await _getCurrentLocation();

      print('✅ [$_logTag] Location service initialized successfully');
      return true;
    } catch (e) {
      print('❌ [$_logTag] Failed to initialize location service: $e');
      return false;
    }
  }

  /// Start real-time location tracking
  Future<bool> startTracking({
    int intervalMs = 5000, // 5 seconds
    double distanceFilterMeters = 10, // 10 meters
  }) async {
    if (_isTracking) {
      print('⚠️ [$_logTag] Location tracking already active');
      return true;
    }

    try {
      print('📍 [$_logTag] Starting location tracking...');

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters.toInt(),
        timeLimit: Duration(milliseconds: intervalMs),
      );

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              final locationData = LocationData.fromPosition(position);
              _lastKnownLocation = locationData;
              _locationController.add(locationData);

              print(
                '📍 [$_logTag] Location update: ${locationData.position} (±${locationData.accuracy.toStringAsFixed(1)}m)',
              );
            },
            onError: (error) {
              print('❌ [$_logTag] Location stream error: $error');
            },
          );

      _isTracking = true;
      print('✅ [$_logTag] Location tracking started');
      return true;
    } catch (e) {
      print('❌ [$_logTag] Failed to start location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    print('📍 [$_logTag] Stopping location tracking...');

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;

    print('✅ [$_logTag] Location tracking stopped');
  }

  /// Get current location once
  Future<LocationData?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final locationData = LocationData.fromPosition(position);
      _lastKnownLocation = locationData;

      print(
        '📍 [$_logTag] Current location: ${locationData.position} (±${locationData.accuracy.toStringAsFixed(1)}m)',
      );
      return locationData;
    } catch (e) {
      print('❌ [$_logTag] Failed to get current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in meters
  double distanceBetween(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Calculate bearing from one point to another in degrees
  double bearingBetween(LatLng from, LatLng to) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Check if a point is within a radius of another point
  bool isWithinRadius(LatLng center, LatLng point, double radiusMeters) {
    final distance = distanceBetween(center, point);
    return distance <= radiusMeters;
  }

  /// Get location accuracy status
  LocationAccuracyStatus getAccuracyStatus() {
    if (_lastKnownLocation == null) return LocationAccuracyStatus.unknown;

    final accuracy = _lastKnownLocation!.accuracy;
    if (accuracy <= 5) return LocationAccuracyStatus.excellent;
    if (accuracy <= 10) return LocationAccuracyStatus.good;
    if (accuracy <= 20) return LocationAccuracyStatus.fair;
    return LocationAccuracyStatus.poor;
  }

  /// Request location permission
  Future<bool> _requestLocationPermission() async {
    try {
      // Check current permission status
      var permission = await Permission.location.status;

      if (permission.isDenied) {
        // Request permission
        permission = await Permission.location.request();
      }

      if (permission.isPermanentlyDenied) {
        // Open app settings if permanently denied
        print(
          '⚠️ [$_logTag] Location permission permanently denied, opening settings',
        );
        await openAppSettings();
        return false;
      }

      return permission.isGranted;
    } catch (e) {
      print('❌ [$_logTag] Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current location for initialization
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      _lastKnownLocation = LocationData.fromPosition(position);
      print('📍 [$_logTag] Initial location: ${_lastKnownLocation!.position}');
    } catch (e) {
      print('⚠️ [$_logTag] Could not get initial location: $e');
      // Use default location (Bangalore, India) as fallback
      _lastKnownLocation = LocationData(
        position: const LatLng(12.971599, 77.594566),
        accuracy: 1000, // Large accuracy to indicate it's a fallback
        timestamp: DateTime.now(),
      );
    }
  }

  /// Dispose of the service
  Future<void> dispose() async {
    print('📍 [$_logTag] Disposing location service...');

    await stopTracking();
    await _locationController.close();

    print('✅ [$_logTag] Location service disposed');
  }
}

/// Location accuracy status
enum LocationAccuracyStatus {
  unknown,
  excellent, // ≤ 5m
  good, // ≤ 10m
  fair, // ≤ 20m
  poor, // > 20m
}

/// Riverpod provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();

  // Initialize the service when first accessed
  service.initialize().then((success) {
    if (success) {
      // Start tracking with default settings
      service.startTracking();
    }
  });

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Riverpod provider for location stream
final locationStreamProvider = StreamProvider<LocationData?>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.locationStream;
});
