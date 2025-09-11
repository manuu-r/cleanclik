import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cleanclik/core/models/waste_category.dart';

/// Service for parsing and validating QR code data from waste bins
class QRBinService {
  static const String _logTag = 'QR_BIN_SERVICE';

  /// Parse QR code JSON payload and extract bin information
  static BinInfo? parseQRCode(String qrData) {
    print('🔍 [$_logTag] Parsing QR code data...');

    try {
      // Parse JSON
      final Map<String, dynamic> data = jsonDecode(qrData);
      print('🔍 [$_logTag] JSON parsed successfully');

      // Validate required fields
      if (!_validateRequiredFields(data)) {
        print('❌ [$_logTag] Missing required fields');
        return null;
      }

      // Extract and validate category (supports both ID and codeName formats)
      final categoryString = data['category'] as String;
      final category = WasteCategory.fromString(categoryString);

      if (category == null) {
        print('❌ [$_logTag] Invalid category: $categoryString');
        return null;
      }

      // Create BinInfo object
      final binInfo = BinInfo(
        binId: data['bin_id'] as String,
        category: category,
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        geohash: data['geohash'] as String,
        generatedAt: DateTime.parse(data['generated_at'] as String),
        version: data['version'] as String,
        locationName: data['location_name'] as String?,
      );

      print(
        '✅ [$_logTag] Successfully parsed bin: ${binInfo.binId} (${binInfo.category.id})',
      );
      _logBinScan(binInfo);

      return binInfo;
    } catch (e) {
      print('❌ [$_logTag] Failed to parse QR code: $e');
      _logParsingError(qrData, e.toString());
      return null;
    }
  }

  /// Validate that all required fields are present in the QR data
  static bool _validateRequiredFields(Map<String, dynamic> data) {
    final requiredFields = [
      'bin_id',
      'category',
      'latitude',
      'longitude',
      'geohash',
      'generated_at',
      'version',
    ];

    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        print('❌ [$_logTag] Missing required field: $field');
        return false;
      }
    }

    // Validate data types
    try {
      data['latitude'] as num;
      data['longitude'] as num;
      DateTime.parse(data['generated_at'] as String);
    } catch (e) {
      print('❌ [$_logTag] Invalid data type in required fields: $e');
      return false;
    }

    return true;
  }

  /// Log successful bin scan for analytics
  static void _logBinScan(BinInfo binInfo) {
    if (kDebugMode) {
      debugPrint(
        '📊 [$_logTag] Bin scanned: ${binInfo.binId} at ${binInfo.locationName ?? 'Unknown location'}',
      );
    }
  }

  /// Log parsing errors for debugging
  static void _logParsingError(String qrData, String error) {
    if (kDebugMode) {
      debugPrint('📊 [$_logTag] Parse error: $error');
      debugPrint(
        '📊 [$_logTag] QR data: ${qrData.length > 200 ? qrData.substring(0, 200) + '...' : qrData}',
      );
    }
  }

  /// Validate QR code format without full parsing (quick check)
  static bool isValidQRFormat(String qrData) {
    try {
      final data = jsonDecode(qrData);
      return data is Map<String, dynamic> &&
          data.containsKey('bin_id') &&
          data.containsKey('category');
    } catch (e) {
      return false;
    }
  }

  /// Get user-friendly error message for invalid QR codes
  static String getErrorMessage(String qrData) {
    if (qrData.isEmpty) {
      return 'QR code is empty';
    }

    try {
      final data = jsonDecode(qrData);
      if (data is! Map<String, dynamic>) {
        return 'QR code format is invalid';
      }

      if (!data.containsKey('bin_id')) {
        return 'QR code is missing bin ID';
      }

      if (!data.containsKey('category')) {
        return 'QR code is missing category information';
      }

      final categoryString = data['category'] as String?;
      if (categoryString == null ||
          WasteCategory.fromString(categoryString) == null) {
        return 'QR code has invalid waste category';
      }

      return 'QR code data is corrupted';
    } catch (e) {
      return 'QR code is not valid JSON format';
    }
  }
}

/// Information extracted from a waste bin QR code
class BinInfo {
  final String binId;
  final WasteCategory category;
  final double latitude;
  final double longitude;
  final String geohash;
  final DateTime generatedAt;
  final String version;
  final String? locationName;

  const BinInfo({
    required this.binId,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.generatedAt,
    required this.version,
    this.locationName,
  });

  @override
  String toString() {
    return 'BinInfo(binId: $binId, category: ${category.id}, location: $locationName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BinInfo && other.binId == binId;
  }

  @override
  int get hashCode => binId.hashCode;
}
