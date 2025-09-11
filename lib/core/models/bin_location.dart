import 'package:latlong2/latlong.dart';

/// Represents a bin location with geohash, coordinates, category, and metadata
class BinLocation {
  final String id;
  final String geohash;
  final LatLng coordinates;
  final String category;
  final String name;
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

/// Utility class for geohash operations
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

  /// Calculate distance between two coordinates in meters
  static double distanceBetween(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
}
