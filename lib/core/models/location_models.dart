/// Location and geospatial models for the CleanClik system
///
/// This file consolidates all location-related data models including:
/// - BinLocation: Bin location with geohash, coordinates, and metadata
/// - GeohashUtils: Utility class for geohash operations and distance calculations

import 'package:latlong2/latlong.dart';

/// Represents a bin location with geohash, coordinates, category, and metadata
class BinLocation {
  final String id;
  final String geohash;
  final LatLng coordinates;
  final String category;
  final String name;
  final String? description; // For backward compatibility with tests
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final double? fillLevel;
  final bool isActive;

  const BinLocation({
    required this.id,
    required this.geohash,
    required this.coordinates,
    required this.category,
    required this.name,
    required this.timestamp,
    this.description,
    this.metadata,
    this.fillLevel,
    this.isActive = true,
  });

  /// Create BinLocation from JSON
  factory BinLocation.fromJson(Map<String, dynamic> json) {
    return BinLocation(
      id: json['id'] as String,
      geohash: json['geohash'] as String,
      coordinates: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      category: json['category'] as String,
      name: json['name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      fillLevel: json['fillLevel'] as double?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert BinLocation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'geohash': geohash,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'category': category,
      'name': name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'fillLevel': fillLevel,
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  BinLocation copyWith({
    String? id,
    String? geohash,
    LatLng? coordinates,
    String? category,
    String? name,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    double? fillLevel,
    bool? isActive,
  }) {
    return BinLocation(
      id: id ?? this.id,
      geohash: geohash ?? this.geohash,
      coordinates: coordinates ?? this.coordinates,
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      fillLevel: fillLevel ?? this.fillLevel,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BinLocation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BinLocation(id: $id, category: $category, name: $name, coordinates: $coordinates)';
  }
}

/// Utility class for geohash operations and geospatial calculations
class GeohashUtils {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Generate geohash from coordinates with specified precision
  static String encode(double latitude, double longitude, {int precision = 8}) {
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;

    String geohash = '';
    int bits = 0;
    int bit = 0;
    bool evenBit = true;

    while (geohash.length < precision) {
      if (evenBit) {
        // longitude
        double mid = (lonMin + lonMax) / 2;
        if (longitude >= mid) {
          bit = (bit << 1) + 1;
          lonMin = mid;
        } else {
          bit = bit << 1;
          lonMax = mid;
        }
      } else {
        // latitude
        double mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          bit = (bit << 1) + 1;
          latMin = mid;
        } else {
          bit = bit << 1;
          latMax = mid;
        }
      }

      evenBit = !evenBit;

      if (++bits == 5) {
        geohash += _base32[bit];
        bits = 0;
        bit = 0;
      }
    }

    return geohash;
  }

  /// Decode geohash to approximate coordinates
  static LatLng decode(String geohash) {
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;

    bool evenBit = true;

    for (int i = 0; i < geohash.length; i++) {
      int cd = _base32.indexOf(geohash[i]);

      for (int j = 4; j >= 0; j--) {
        int bit = (cd >> j) & 1;

        if (evenBit) {
          // longitude
          double mid = (lonMin + lonMax) / 2;
          if (bit == 1) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          // latitude
          double mid = (latMin + latMax) / 2;
          if (bit == 1) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }

        evenBit = !evenBit;
      }
    }

    return LatLng((latMin + latMax) / 2, (lonMin + lonMax) / 2);
  }

  /// Calculate distance between two coordinates in meters
  static double distanceBetween(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Calculate distance between two geohashes in meters
  static double distanceBetweenGeohashes(String geohash1, String geohash2) {
    final point1 = decode(geohash1);
    final point2 = decode(geohash2);
    return distanceBetween(point1, point2);
  }

  /// Get geohash neighbors (8 surrounding geohashes)
  static List<String> getNeighbors(String geohash) {
    // This is a simplified implementation
    // In a production system, you'd want a more robust neighbor calculation
    final neighbors = <String>[];
    final baseCoords = decode(geohash);

    // Calculate approximate precision step
    final precision = geohash.length;
    final latStep = 180.0 / (1 << (precision * 5 ~/ 2));
    final lonStep = 360.0 / (1 << ((precision * 5 + 1) ~/ 2));

    // Generate 8 neighbors
    for (int latOffset = -1; latOffset <= 1; latOffset++) {
      for (int lonOffset = -1; lonOffset <= 1; lonOffset++) {
        if (latOffset == 0 && lonOffset == 0) continue; // Skip center

        final neighborLat = baseCoords.latitude + (latOffset * latStep);
        final neighborLon = baseCoords.longitude + (lonOffset * lonStep);

        // Ensure coordinates are within valid bounds
        if (neighborLat >= -90 &&
            neighborLat <= 90 &&
            neighborLon >= -180 &&
            neighborLon <= 180) {
          neighbors.add(encode(neighborLat, neighborLon, precision: precision));
        }
      }
    }

    return neighbors;
  }

  /// Check if a point is within a certain radius of a geohash
  static bool isWithinRadius(
    LatLng point,
    String geohash,
    double radiusMeters,
  ) {
    final geohashCenter = decode(geohash);
    final distance = distanceBetween(point, geohashCenter);
    return distance <= radiusMeters;
  }

  /// Get geohash precision needed for a given accuracy in meters
  static int getPrecisionForAccuracy(double accuracyMeters) {
    // Approximate geohash precision to accuracy mapping
    if (accuracyMeters >= 2500) return 4; // ±2.5km
    if (accuracyMeters >= 630) return 5; // ±630m
    if (accuracyMeters >= 78) return 6; // ±78m
    if (accuracyMeters >= 20) return 7; // ±20m
    if (accuracyMeters >= 2.4) return 8; // ±2.4m
    if (accuracyMeters >= 0.6) return 9; // ±60cm
    return 10; // ±7.4cm
  }

  /// Create a BinLocation with automatic geohash generation
  static BinLocation createBinLocation({
    required String id,
    required LatLng coordinates,
    required String category,
    required String name,
    String? description,
    Map<String, dynamic>? metadata,
    double? fillLevel,
    bool isActive = true,
    int geohashPrecision = 8,
  }) {
    final geohash = encode(
      coordinates.latitude,
      coordinates.longitude,
      precision: geohashPrecision,
    );

    return BinLocation(
      id: id,
      geohash: geohash,
      coordinates: coordinates,
      category: category,
      name: name,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata,
      fillLevel: fillLevel,
      isActive: isActive,
    );
  }
}
