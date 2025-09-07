import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../models/bin_location.dart';

/// Service for managing bin locations with local storage
class BinLocationService {
  static const String _storageKey = 'bin_locations';
  static const String _lastUpdateKey = 'bin_locations_last_update';
  
  SharedPreferences? _prefs;
  List<BinLocation> _cachedBins = [];
  DateTime? _lastUpdate;
  
  // Stream controller for real-time updates
  final StreamController<List<BinLocation>> _binsController = StreamController<List<BinLocation>>.broadcast();
  
  /// Stream of bin location updates
  Stream<List<BinLocation>> get binsStream => _binsController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadBinsFromStorage();
  }

  /// Get all stored bin locations
  Future<List<BinLocation>> getAllBins() async {
    await _ensureInitialized();
    return List.from(_cachedBins);
  }

  /// Get bins within a radius of a location
  Future<List<BinLocation>> getBinsNearLocation(
    LatLng location, {
    double radiusMeters = 1000,
  }) async {
    await _ensureInitialized();
    
    return _cachedBins.where((bin) {
      final distance = GeohashUtils.distanceBetween(location, bin.coordinates);
      return distance <= radiusMeters;
    }).toList();
  }

  /// Get bins by category
  Future<List<BinLocation>> getBinsByCategory(String category) async {
    await _ensureInitialized();
    return _cachedBins.where((bin) => bin.category == category).toList();
  }

  /// Add a new bin location
  Future<bool> addBin(BinLocation bin) async {
    await _ensureInitialized();
    
    // Check for duplicates within 10 meters
    final existingBin = _cachedBins.where((existing) {
      final distance = GeohashUtils.distanceBetween(
        existing.coordinates,
        bin.coordinates,
      );
      return distance <= 10; // 10 meter threshold for duplicates
    }).firstOrNull;
    
    if (existingBin != null) {
      print('🗑️ [BIN_SERVICE] Duplicate bin detected within 10m of existing bin: ${existingBin.name}');
      return false; // Duplicate found
    }
    
    _cachedBins.add(bin);
    await _saveBinsToStorage();
    
    // Notify listeners of the update
    _binsController.add(List.from(_cachedBins));
    
    print('✅ [BIN_SERVICE] Added new bin: ${bin.name} (${bin.category})');
    return true;
  }

  /// Update an existing bin location
  Future<bool> updateBin(BinLocation updatedBin) async {
    await _ensureInitialized();
    
    final index = _cachedBins.indexWhere((bin) => bin.id == updatedBin.id);
    if (index == -1) {
      return false; // Bin not found
    }
    
    _cachedBins[index] = updatedBin;
    await _saveBinsToStorage();
    
    // Notify listeners of the update
    _binsController.add(List.from(_cachedBins));
    
    print('🔄 [BIN_SERVICE] Updated bin: ${updatedBin.name}');
    return true;
  }

  /// Remove a bin location
  Future<bool> removeBin(String binId) async {
    await _ensureInitialized();
    
    final initialLength = _cachedBins.length;
    _cachedBins.removeWhere((bin) => bin.id == binId);
    
    if (_cachedBins.length < initialLength) {
      await _saveBinsToStorage();
      
      // Notify listeners of the update
      _binsController.add(List.from(_cachedBins));
      
      print('🗑️ [BIN_SERVICE] Removed bin: $binId');
      return true;
    }
    
    return false; // Bin not found
  }

  /// Clear all bin locations
  Future<void> clearAllBins() async {
    await _ensureInitialized();
    _cachedBins.clear();
    await _saveBinsToStorage();
    
    // Notify listeners of the update
    _binsController.add(List.from(_cachedBins));
    
    print('🧹 [BIN_SERVICE] Cleared all bins');
  }

  /// Get bins count by category
  Future<Map<String, int>> getBinCountsByCategory() async {
    await _ensureInitialized();
    
    final counts = <String, int>{};
    for (final bin in _cachedBins) {
      counts[bin.category] = (counts[bin.category] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Find the nearest bin to a location
  Future<BinLocation?> findNearestBin(
    LatLng location, {
    String? category,
    double maxDistanceMeters = 5000,
  }) async {
    await _ensureInitialized();
    
    var candidateBins = _cachedBins;
    
    // Filter by category if specified
    if (category != null) {
      candidateBins = candidateBins.where((bin) => bin.category == category).toList();
    }
    
    if (candidateBins.isEmpty) return null;
    
    BinLocation? nearestBin;
    double nearestDistance = double.infinity;
    
    for (final bin in candidateBins) {
      final distance = GeohashUtils.distanceBetween(location, bin.coordinates);
      if (distance <= maxDistanceMeters && distance < nearestDistance) {
        nearestDistance = distance;
        nearestBin = bin;
      }
    }
    
    return nearestBin;
  }

  /// Create a bin from QR code data
  BinLocation? createBinFromQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      
      // Extract required fields
      final geohash = data['geohash'] as String?;
      final category = data['category'] as String?;
      final name = data['name'] as String?;
      
      if (geohash == null || category == null || name == null) {
        print('❌ [BIN_SERVICE] Invalid QR data: missing required fields');
        return null;
      }
      
      // Decode geohash to coordinates (simplified implementation)
      final coordinates = _decodeGeohash(geohash);
      if (coordinates == null) {
        print('❌ [BIN_SERVICE] Invalid geohash in QR data: $geohash');
        return null;
      }
      
      // Generate unique ID
      final id = 'bin_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      
      return BinLocation(
        id: id,
        geohash: geohash,
        coordinates: coordinates,
        category: category,
        name: name,
        timestamp: DateTime.now(),
        metadata: data['metadata'] as Map<String, dynamic>?,
        fillLevel: (data['fillLevel'] as num?)?.toDouble(),
      );
    } catch (e) {
      print('❌ [BIN_SERVICE] Error parsing QR data: $e');
      return null;
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    await _ensureInitialized();
    
    return {
      'totalBins': _cachedBins.length,
      'lastUpdate': _lastUpdate?.toIso8601String(),
      'categoryCounts': await getBinCountsByCategory(),
      'storageSize': _calculateStorageSize(),
    };
  }

  // Private methods

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  Future<void> _loadBinsFromStorage() async {
    try {
      final binsJson = _prefs?.getString(_storageKey);
      final lastUpdateStr = _prefs?.getString(_lastUpdateKey);
      
      if (binsJson != null) {
        final binsList = jsonDecode(binsJson) as List<dynamic>;
        _cachedBins = binsList
            .map((json) => BinLocation.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('📦 [BIN_SERVICE] Loaded ${_cachedBins.length} bins from storage');
      }
      
      if (lastUpdateStr != null) {
        _lastUpdate = DateTime.parse(lastUpdateStr);
      }
      
      // Notify listeners of initial data
      if (_cachedBins.isNotEmpty) {
        _binsController.add(List.from(_cachedBins));
      }
    } catch (e) {
      print('❌ [BIN_SERVICE] Error loading bins from storage: $e');
      _cachedBins = [];
    }
  }

  Future<void> _saveBinsToStorage() async {
    try {
      final binsJson = jsonEncode(_cachedBins.map((bin) => bin.toJson()).toList());
      await _prefs?.setString(_storageKey, binsJson);
      
      _lastUpdate = DateTime.now();
      await _prefs?.setString(_lastUpdateKey, _lastUpdate!.toIso8601String());
      
      print('💾 [BIN_SERVICE] Saved ${_cachedBins.length} bins to storage');
    } catch (e) {
      print('❌ [BIN_SERVICE] Error saving bins to storage: $e');
    }
  }

  LatLng? _decodeGeohash(String geohash) {
    // Simplified geohash decoding - in production, use a proper geohash library
    // For now, we'll use a basic implementation
    try {
      const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
      
      double latMin = -90.0, latMax = 90.0;
      double lonMin = -180.0, lonMax = 180.0;
      
      bool evenBit = true;
      
      for (int i = 0; i < geohash.length; i++) {
        final char = geohash[i];
        final idx = base32.indexOf(char);
        if (idx == -1) return null;
        
        for (int j = 4; j >= 0; j--) {
          final bit = (idx >> j) & 1;
          
          if (evenBit) {
            // longitude
            final mid = (lonMin + lonMax) / 2;
            if (bit == 1) {
              lonMin = mid;
            } else {
              lonMax = mid;
            }
          } else {
            // latitude
            final mid = (latMin + latMax) / 2;
            if (bit == 1) {
              latMin = mid;
            } else {
              latMax = mid;
            }
          }
          
          evenBit = !evenBit;
        }
      }
      
      final lat = (latMin + latMax) / 2;
      final lon = (lonMin + lonMax) / 2;
      
      return LatLng(lat, lon);
    } catch (e) {
      print('❌ [BIN_SERVICE] Error decoding geohash: $e');
      return null;
    }
  }

  int _calculateStorageSize() {
    try {
      final binsJson = jsonEncode(_cachedBins.map((bin) => bin.toJson()).toList());
      return binsJson.length;
    } catch (e) {
      return 0;
    }
  }

  /// Dispose of the service and clean up resources
  Future<void> dispose() async {
    await _binsController.close();
    print('🧹 [BIN_SERVICE] Service disposed');
  }
}

/// Riverpod provider for BinLocationService
final binLocationServiceProvider = Provider<BinLocationService>((ref) {
  final service = BinLocationService();
  // Initialize the service when first accessed
  service.initialize();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Riverpod provider for bin locations stream
final binLocationsStreamProvider = StreamProvider<List<BinLocation>>((ref) {
  final binService = ref.watch(binLocationServiceProvider);
  return binService.binsStream;
});