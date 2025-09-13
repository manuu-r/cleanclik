import 'dart:ui';
import 'package:cleanclik/core/models/waste_category.dart';

/// Metadata for test images used in ML detection testing
class TestImageMetadata {
  /// Complete metadata for all test images
  static const Map<String, Map<String, dynamic>> imageMetadata = {
    // Recyclable Objects
    'plastic_bottle_001': {
      'fileName': 'recyclable_objects/plastic_bottle_001.jpg',
      'category': 'recycle',
      'expectedLabels': ['plastic bottle', 'bottle', 'container'],
      'expectedConfidence': 0.92,
      'boundingBox': {'left': 150.0, 'top': 200.0, 'width': 200.0, 'height': 300.0},
      'lighting': 'good',
      'background': 'simple',
      'angle': 'front',
      'difficulty': 'easy',
      'fileSize': 1024000, // 1MB
    },
    'aluminum_can_001': {
      'fileName': 'recyclable_objects/aluminum_can_001.jpg',
      'category': 'recycle',
      'expectedLabels': ['aluminum can', 'can', 'soda can'],
      'expectedConfidence': 0.89,
      'boundingBox': {'left': 180.0, 'top': 150.0, 'width': 120.0, 'height': 250.0},
      'lighting': 'natural',
      'background': 'simple',
      'angle': 'side',
      'difficulty': 'easy',
      'fileSize': 856000,
    },
    'cardboard_box_001': {
      'fileName': 'recyclable_objects/cardboard_box_001.jpg',
      'category': 'recycle',
      'expectedLabels': ['cardboard box', 'box', 'package'],
      'expectedConfidence': 0.85,
      'boundingBox': {'left': 100.0, 'top': 100.0, 'width': 300.0, 'height': 200.0},
      'lighting': 'indoor',
      'background': 'complex',
      'angle': 'angled',
      'difficulty': 'medium',
      'fileSize': 1200000,
    },
    'glass_jar_001': {
      'fileName': 'recyclable_objects/glass_jar_001.jpg',
      'category': 'recycle',
      'expectedLabels': ['glass jar', 'jar', 'container'],
      'expectedConfidence': 0.87,
      'boundingBox': {'left': 200.0, 'top': 180.0, 'width': 150.0, 'height': 200.0},
      'lighting': 'bright',
      'background': 'simple',
      'angle': 'front',
      'difficulty': 'easy',
      'fileSize': 945000,
    },
    'paper_document_001': {
      'fileName': 'recyclable_objects/paper_document_001.jpg',
      'category': 'recycle',
      'expectedLabels': ['paper', 'document', 'papers'],
      'expectedConfidence': 0.78,
      'boundingBox': {'left': 120.0, 'top': 120.0, 'width': 250.0, 'height': 180.0},
      'lighting': 'office',
      'background': 'desk',
      'angle': 'top',
      'difficulty': 'medium',
      'fileSize': 678000,
    },

    // Organic Waste
    'apple_core_001': {
      'fileName': 'organic_waste/apple_core_001.jpg',
      'category': 'organic',
      'expectedLabels': ['apple core', 'apple', 'fruit'],
      'expectedConfidence': 0.88,
      'boundingBox': {'left': 180.0, 'top': 180.0, 'width': 150.0, 'height': 150.0},
      'lighting': 'natural',
      'background': 'complex',
      'angle': 'side',
      'difficulty': 'medium',
      'fileSize': 723000,
    },
    'banana_peel_001': {
      'fileName': 'organic_waste/banana_peel_001.jpg',
      'category': 'organic',
      'expectedLabels': ['banana peel', 'banana', 'peel'],
      'expectedConfidence': 0.91,
      'boundingBox': {'left': 160.0, 'top': 200.0, 'width': 180.0, 'height': 120.0},
      'lighting': 'kitchen',
      'background': 'counter',
      'angle': 'curved',
      'difficulty': 'easy',
      'fileSize': 834000,
    },
    'food_scraps_001': {
      'fileName': 'organic_waste/food_scraps_001.jpg',
      'category': 'organic',
      'expectedLabels': ['food scraps', 'food waste', 'scraps'],
      'expectedConfidence': 0.82,
      'boundingBox': {'left': 100.0, 'top': 150.0, 'width': 300.0, 'height': 200.0},
      'lighting': 'indoor',
      'background': 'plate',
      'angle': 'top',
      'difficulty': 'medium',
      'fileSize': 1100000,
    },
    'leaves_001': {
      'fileName': 'organic_waste/leaves_001.jpg',
      'category': 'organic',
      'expectedLabels': ['leaves', 'leaf', 'foliage'],
      'expectedConfidence': 0.86,
      'boundingBox': {'left': 80.0, 'top': 100.0, 'width': 350.0, 'height': 250.0},
      'lighting': 'outdoor',
      'background': 'ground',
      'angle': 'scattered',
      'difficulty': 'medium',
      'fileSize': 1350000,
    },
    'vegetable_peels_001': {
      'fileName': 'organic_waste/vegetable_peels_001.jpg',
      'category': 'organic',
      'expectedLabels': ['vegetable peels', 'peels', 'potato peels'],
      'expectedConfidence': 0.79,
      'boundingBox': {'left': 140.0, 'top': 160.0, 'width': 220.0, 'height': 180.0},
      'lighting': 'kitchen',
      'background': 'cutting_board',
      'angle': 'pile',
      'difficulty': 'medium',
      'fileSize': 892000,
    },

    // Landfill Waste
    'plastic_bag_001': {
      'fileName': 'landfill_waste/plastic_bag_001.jpg',
      'category': 'landfill',
      'expectedLabels': ['plastic bag', 'bag', 'shopping bag'],
      'expectedConfidence': 0.75,
      'boundingBox': {'left': 120.0, 'top': 140.0, 'width': 260.0, 'height': 220.0},
      'lighting': 'indoor',
      'background': 'floor',
      'angle': 'crumpled',
      'difficulty': 'hard',
      'fileSize': 567000,
    },
    'styrofoam_001': {
      'fileName': 'landfill_waste/styrofoam_001.jpg',
      'category': 'landfill',
      'expectedLabels': ['styrofoam', 'foam container', 'takeout container'],
      'expectedConfidence': 0.83,
      'boundingBox': {'left': 150.0, 'top': 120.0, 'width': 200.0, 'height': 100.0},
      'lighting': 'fluorescent',
      'background': 'table',
      'angle': 'open',
      'difficulty': 'easy',
      'fileSize': 645000,
    },
    'mixed_waste_001': {
      'fileName': 'landfill_waste/mixed_waste_001.jpg',
      'category': 'landfill',
      'expectedLabels': ['mixed waste', 'trash', 'garbage'],
      'expectedConfidence': 0.65,
      'boundingBox': {'left': 50.0, 'top': 80.0, 'width': 400.0, 'height': 300.0},
      'lighting': 'poor',
      'background': 'cluttered',
      'angle': 'various',
      'difficulty': 'hard',
      'fileSize': 1450000,
    },
    'wrapper_001': {
      'fileName': 'landfill_waste/wrapper_001.jpg',
      'category': 'landfill',
      'expectedLabels': ['wrapper', 'candy wrapper', 'packaging'],
      'expectedConfidence': 0.71,
      'boundingBox': {'left': 200.0, 'top': 220.0, 'width': 100.0, 'height': 60.0},
      'lighting': 'bright',
      'background': 'simple',
      'angle': 'flat',
      'difficulty': 'medium',
      'fileSize': 234000,
    },
    'tissue_001': {
      'fileName': 'landfill_waste/tissue_001.jpg',
      'category': 'landfill',
      'expectedLabels': ['tissue', 'paper tissue', 'napkin'],
      'expectedConfidence': 0.68,
      'boundingBox': {'left': 180.0, 'top': 200.0, 'width': 140.0, 'height': 100.0},
      'lighting': 'natural',
      'background': 'surface',
      'angle': 'crumpled',
      'difficulty': 'medium',
      'fileSize': 345000,
    },

    // E-Waste
    'smartphone_001': {
      'fileName': 'ewaste/smartphone_001.jpg',
      'category': 'ewaste',
      'expectedLabels': ['smartphone', 'phone', 'mobile phone'],
      'expectedConfidence': 0.95,
      'boundingBox': {'left': 200.0, 'top': 150.0, 'width': 100.0, 'height': 200.0},
      'lighting': 'clean',
      'background': 'white',
      'angle': 'front',
      'difficulty': 'easy',
      'fileSize': 456000,
    },
    'laptop_001': {
      'fileName': 'ewaste/laptop_001.jpg',
      'category': 'ewaste',
      'expectedLabels': ['laptop', 'computer', 'notebook'],
      'expectedConfidence': 0.93,
      'boundingBox': {'left': 100.0, 'top': 100.0, 'width': 300.0, 'height': 200.0},
      'lighting': 'office',
      'background': 'desk',
      'angle': 'closed',
      'difficulty': 'easy',
      'fileSize': 1100000,
    },
    'battery_001': {
      'fileName': 'ewaste/battery_001.jpg',
      'category': 'ewaste',
      'expectedLabels': ['battery', 'batteries', 'AA battery'],
      'expectedConfidence': 0.89,
      'boundingBox': {'left': 160.0, 'top': 180.0, 'width': 180.0, 'height': 60.0},
      'lighting': 'white_background',
      'background': 'clean',
      'angle': 'group',
      'difficulty': 'easy',
      'fileSize': 278000,
    },
    'cable_001': {
      'fileName': 'ewaste/cable_001.jpg',
      'category': 'ewaste',
      'expectedLabels': ['cable', 'USB cable', 'wire'],
      'expectedConfidence': 0.81,
      'boundingBox': {'left': 120.0, 'top': 160.0, 'width': 260.0, 'height': 180.0},
      'lighting': 'desk',
      'background': 'surface',
      'angle': 'coiled',
      'difficulty': 'medium',
      'fileSize': 523000,
    },
    'circuit_board_001': {
      'fileName': 'ewaste/circuit_board_001.jpg',
      'category': 'ewaste',
      'expectedLabels': ['circuit board', 'PCB', 'electronics'],
      'expectedConfidence': 0.87,
      'boundingBox': {'left': 140.0, 'top': 120.0, 'width': 220.0, 'height': 160.0},
      'lighting': 'technical',
      'background': 'workbench',
      'angle': 'flat',
      'difficulty': 'medium',
      'fileSize': 789000,
    },

    // Hazardous Waste
    'paint_can_001': {
      'fileName': 'hazardous_waste/paint_can_001.jpg',
      'category': 'hazardous',
      'expectedLabels': ['paint can', 'paint', 'hazardous material'],
      'expectedConfidence': 0.91,
      'boundingBox': {'left': 170.0, 'top': 140.0, 'width': 160.0, 'height': 220.0},
      'lighting': 'garage',
      'background': 'shelf',
      'angle': 'front',
      'difficulty': 'easy',
      'fileSize': 867000,
    },
    'chemical_bottle_001': {
      'fileName': 'hazardous_waste/chemical_bottle_001.jpg',
      'category': 'hazardous',
      'expectedLabels': ['chemical bottle', 'hazardous chemical', 'toxic'],
      'expectedConfidence': 0.94,
      'boundingBox': {'left': 190.0, 'top': 160.0, 'width': 120.0, 'height': 180.0},
      'lighting': 'lab',
      'background': 'laboratory',
      'angle': 'upright',
      'difficulty': 'easy',
      'fileSize': 634000,
    },
    'medical_waste_001': {
      'fileName': 'hazardous_waste/medical_waste_001.jpg',
      'category': 'hazardous',
      'expectedLabels': ['medical waste', 'syringe', 'medical'],
      'expectedConfidence': 0.88,
      'boundingBox': {'left': 200.0, 'top': 180.0, 'width': 100.0, 'height': 140.0},
      'lighting': 'clinical',
      'background': 'medical',
      'angle': 'safe',
      'difficulty': 'medium',
      'fileSize': 445000,
    },
    'battery_acid_001': {
      'fileName': 'hazardous_waste/battery_acid_001.jpg',
      'category': 'hazardous',
      'expectedLabels': ['car battery', 'battery', 'lead acid battery'],
      'expectedConfidence': 0.92,
      'boundingBox': {'left': 120.0, 'top': 120.0, 'width': 260.0, 'height': 180.0},
      'lighting': 'automotive',
      'background': 'garage',
      'angle': 'side',
      'difficulty': 'easy',
      'fileSize': 1023000,
    },
    'cleaning_product_001': {
      'fileName': 'hazardous_waste/cleaning_product_001.jpg',
      'category': 'hazardous',
      'expectedLabels': ['cleaning product', 'household cleaner', 'chemical'],
      'expectedConfidence': 0.86,
      'boundingBox': {'left': 180.0, 'top': 150.0, 'width': 140.0, 'height': 200.0},
      'lighting': 'utility',
      'background': 'shelf',
      'angle': 'front',
      'difficulty': 'easy',
      'fileSize': 712000,
    },

    // Edge Cases
    'blurry_object_001': {
      'fileName': 'edge_cases/blurry_object_001.jpg',
      'category': 'recycle',
      'expectedLabels': ['plastic bottle'], // Harder to detect
      'expectedConfidence': 0.45,
      'boundingBox': {'left': 100.0, 'top': 100.0, 'width': 300.0, 'height': 400.0},
      'lighting': 'poor',
      'background': 'complex',
      'angle': 'unclear',
      'difficulty': 'very_hard',
      'isEdgeCase': true,
      'edgeCaseType': 'motion_blur',
      'fileSize': 890000,
    },
    'dark_lighting_001': {
      'fileName': 'edge_cases/dark_lighting_001.jpg',
      'category': 'organic',
      'expectedLabels': ['apple'],
      'expectedConfidence': 0.35,
      'boundingBox': {'left': 150.0, 'top': 200.0, 'width': 200.0, 'height': 200.0},
      'lighting': 'very_poor',
      'background': 'dark',
      'angle': 'front',
      'difficulty': 'very_hard',
      'isEdgeCase': true,
      'edgeCaseType': 'low_light',
      'fileSize': 456000,
    },
    'multiple_objects_001': {
      'fileName': 'edge_cases/multiple_objects_001.jpg',
      'category': 'mixed',
      'expectedObjects': 5,
      'expectedLabels': ['bottle', 'can', 'paper', 'apple', 'bag'],
      'expectedConfidence': 0.72,
      'lighting': 'good',
      'background': 'complex',
      'angle': 'various',
      'difficulty': 'hard',
      'isEdgeCase': true,
      'edgeCaseType': 'multiple_objects',
      'fileSize': 1567000,
    },
    'partial_object_001': {
      'fileName': 'edge_cases/partial_object_001.jpg',
      'category': 'ewaste',
      'expectedLabels': ['smartphone'],
      'expectedConfidence': 0.58,
      'boundingBox': {'left': 0.0, 'top': 100.0, 'width': 150.0, 'height': 200.0},
      'lighting': 'good',
      'background': 'simple',
      'angle': 'partial',
      'difficulty': 'hard',
      'isEdgeCase': true,
      'edgeCaseType': 'partial_frame',
      'fileSize': 345000,
    },
    'reflective_surface_001': {
      'fileName': 'edge_cases/reflective_surface_001.jpg',
      'category': 'recycle',
      'expectedLabels': ['aluminum can'],
      'expectedConfidence': 0.62,
      'boundingBox': {'left': 180.0, 'top': 160.0, 'width': 140.0, 'height': 180.0},
      'lighting': 'bright',
      'background': 'reflective',
      'angle': 'side',
      'difficulty': 'hard',
      'isEdgeCase': true,
      'edgeCaseType': 'glare_reflection',
      'fileSize': 723000,
    },
    'cluttered_background_001': {
      'fileName': 'edge_cases/cluttered_background_001.jpg',
      'category': 'landfill',
      'expectedLabels': ['plastic bag'],
      'expectedConfidence': 0.48,
      'boundingBox': {'left': 200.0, 'top': 180.0, 'width': 100.0, 'height': 120.0},
      'lighting': 'indoor',
      'background': 'very_cluttered',
      'angle': 'front',
      'difficulty': 'very_hard',
      'isEdgeCase': true,
      'edgeCaseType': 'busy_background',
      'fileSize': 1234000,
    },
    'extreme_angle_001': {
      'fileName': 'edge_cases/extreme_angle_001.jpg',
      'category': 'organic',
      'expectedLabels': ['banana'],
      'expectedConfidence': 0.51,
      'boundingBox': {'left': 120.0, 'top': 80.0, 'width': 260.0, 'height': 100.0},
      'lighting': 'natural',
      'background': 'simple',
      'angle': 'extreme',
      'difficulty': 'hard',
      'isEdgeCase': true,
      'edgeCaseType': 'unusual_angle',
      'fileSize': 567000,
    },
    'tiny_object_001': {
      'fileName': 'edge_cases/tiny_object_001.jpg',
      'category': 'ewaste',
      'expectedLabels': ['button battery'],
      'expectedConfidence': 0.42,
      'boundingBox': {'left': 240.0, 'top': 240.0, 'width': 20.0, 'height': 20.0},
      'lighting': 'macro',
      'background': 'clean',
      'angle': 'top',
      'difficulty': 'very_hard',
      'isEdgeCase': true,
      'edgeCaseType': 'very_small',
      'fileSize': 123000,
    },
    'oversized_object_001': {
      'fileName': 'edge_cases/oversized_object_001.jpg',
      'category': 'recycle',
      'expectedLabels': ['cardboard'],
      'expectedConfidence': 0.67,
      'boundingBox': {'left': 0.0, 'top': 0.0, 'width': 500.0, 'height': 400.0},
      'lighting': 'outdoor',
      'background': 'minimal',
      'angle': 'close',
      'difficulty': 'medium',
      'isEdgeCase': true,
      'edgeCaseType': 'oversized',
      'fileSize': 1890000,
    },

    // QR Codes
    'bin_qr_recycle_001': {
      'fileName': 'qr_codes/bin_qr_recycle_001.png',
      'category': 'qr_code',
      'expectedData': 'BIN_RECYCLE_001',
      'qrCodeType': 'bin_identifier',
      'lighting': 'good',
      'background': 'clean',
      'angle': 'straight',
      'difficulty': 'easy',
      'fileSize': 45000,
    },
    'bin_qr_organic_001': {
      'fileName': 'qr_codes/bin_qr_organic_001.png',
      'category': 'qr_code',
      'expectedData': 'BIN_ORGANIC_001',
      'qrCodeType': 'bin_identifier',
      'lighting': 'good',
      'background': 'clean',
      'angle': 'straight',
      'difficulty': 'easy',
      'fileSize': 47000,
    },
    'bin_qr_landfill_001': {
      'fileName': 'qr_codes/bin_qr_landfill_001.png',
      'category': 'qr_code',
      'expectedData': 'BIN_LANDFILL_001',
      'qrCodeType': 'bin_identifier',
      'lighting': 'good',
      'background': 'clean',
      'angle': 'straight',
      'difficulty': 'easy',
      'fileSize': 46000,
    },
    'bin_qr_ewaste_001': {
      'fileName': 'qr_codes/bin_qr_ewaste_001.png',
      'category': 'qr_code',
      'expectedData': 'BIN_EWASTE_001',
      'qrCodeType': 'bin_identifier',
      'lighting': 'good',
      'background': 'clean',
      'angle': 'straight',
      'difficulty': 'easy',
      'fileSize': 44000,
    },
    'bin_qr_hazardous_001': {
      'fileName': 'qr_codes/bin_qr_hazardous_001.png',
      'category': 'qr_code',
      'expectedData': 'BIN_HAZARDOUS_001',
      'qrCodeType': 'bin_identifier',
      'lighting': 'good',
      'background': 'clean',
      'angle': 'straight',
      'difficulty': 'easy',
      'fileSize': 48000,
    },
    'damaged_qr_001': {
      'fileName': 'qr_codes/damaged_qr_001.png',
      'category': 'qr_code',
      'expectedData': null, // Should fail to read
      'qrCodeType': 'bin_identifier',
      'lighting': 'good',
      'background': 'clean',
      'angle': 'straight',
      'difficulty': 'impossible',
      'isEdgeCase': true,
      'edgeCaseType': 'damaged_qr',
      'fileSize': 52000,
    },
    'angled_qr_001': {
      'fileName': 'qr_codes/angled_qr_001.png',
      'category': 'qr_code',
      'expectedData': 'BIN_RECYCLE_002',
      'qrCodeType': 'bin_identifier',
      'lighting': 'good',
      'background': 'clean',
      'angle': 'angled',
      'difficulty': 'medium',
      'isEdgeCase': true,
      'edgeCaseType': 'angled_qr',
      'fileSize': 49000,
    },

    // Calibration Images
    'white_balance_001': {
      'fileName': 'calibration/white_balance_001.jpg',
      'category': 'calibration',
      'purpose': 'white_balance_reference',
      'lighting': 'various',
      'background': 'color_chart',
      'angle': 'front',
      'difficulty': 'reference',
      'fileSize': 234000,
    },
    'color_chart_001': {
      'fileName': 'calibration/color_chart_001.jpg',
      'category': 'calibration',
      'purpose': 'color_accuracy_reference',
      'lighting': 'controlled',
      'background': 'standard',
      'angle': 'front',
      'difficulty': 'reference',
      'fileSize': 345000,
    },
    'resolution_test_001': {
      'fileName': 'calibration/resolution_test_001.jpg',
      'category': 'calibration',
      'purpose': 'resolution_testing',
      'lighting': 'good',
      'background': 'detailed',
      'angle': 'front',
      'difficulty': 'reference',
      'fileSize': 2048000, // 2MB high detail
    },
    'contrast_test_001': {
      'fileName': 'calibration/contrast_test_001.jpg',
      'category': 'calibration',
      'purpose': 'contrast_testing',
      'lighting': 'controlled',
      'background': 'pattern',
      'angle': 'front',
      'difficulty': 'reference',
      'fileSize': 156000,
    },
    'lighting_gradient_001': {
      'fileName': 'calibration/lighting_gradient_001.jpg',
      'category': 'calibration',
      'purpose': 'lighting_testing',
      'lighting': 'gradient',
      'background': 'neutral',
      'angle': 'front',
      'difficulty': 'reference',
      'fileSize': 278000,
    },
  };

  /// Get metadata for a specific image
  static Map<String, dynamic>? getImageMetadata(String imageKey) {
    return imageMetadata[imageKey];
  }

  /// Get all images for a specific category
  static List<String> getImagesByCategory(String category) {
    return imageMetadata.entries
        .where((entry) => entry.value['category'] == category)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get all edge case images
  static List<String> getEdgeCaseImages() {
    return imageMetadata.entries
        .where((entry) => entry.value['isEdgeCase'] == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get images by difficulty level
  static List<String> getImagesByDifficulty(String difficulty) {
    return imageMetadata.entries
        .where((entry) => entry.value['difficulty'] == difficulty)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get QR code images
  static List<String> getQRCodeImages() {
    return imageMetadata.entries
        .where((entry) => entry.value['category'] == 'qr_code')
        .map((entry) => entry.key)
        .toList();
  }

  /// Get calibration images
  static List<String> getCalibrationImages() {
    return imageMetadata.entries
        .where((entry) => entry.value['category'] == 'calibration')
        .map((entry) => entry.key)
        .toList();
  }

  /// Get expected bounding box as Rect
  static Rect? getExpectedBoundingBox(String imageKey) {
    final metadata = getImageMetadata(imageKey);
    if (metadata == null || metadata['boundingBox'] == null) return null;
    
    final bbox = metadata['boundingBox'] as Map<String, dynamic>;
    return Rect.fromLTWH(
      bbox['left']?.toDouble() ?? 0.0,
      bbox['top']?.toDouble() ?? 0.0,
      bbox['width']?.toDouble() ?? 0.0,
      bbox['height']?.toDouble() ?? 0.0,
    );
  }

  /// Get expected confidence threshold
  static double getExpectedConfidence(String imageKey) {
    final metadata = getImageMetadata(imageKey);
    return metadata?['expectedConfidence']?.toDouble() ?? 0.5;
  }

  /// Get expected labels
  static List<String> getExpectedLabels(String imageKey) {
    final metadata = getImageMetadata(imageKey);
    final labels = metadata?['expectedLabels'];
    if (labels is List) {
      return labels.cast<String>();
    }
    return [];
  }

  /// Check if image is an edge case
  static bool isEdgeCase(String imageKey) {
    final metadata = getImageMetadata(imageKey);
    return metadata?['isEdgeCase'] == true;
  }

  /// Get edge case type
  static String? getEdgeCaseType(String imageKey) {
    final metadata = getImageMetadata(imageKey);
    return metadata?['edgeCaseType'] as String?;
  }

  /// Get file path for image
  static String getImagePath(String imageKey) {
    final metadata = getImageMetadata(imageKey);
    return metadata?['fileName'] as String? ?? '';
  }

  /// Get all available image keys
  static List<String> getAllImageKeys() {
    return imageMetadata.keys.toList();
  }

  /// Get images suitable for performance testing (smaller files)
  static List<String> getPerformanceTestImages() {
    return imageMetadata.entries
        .where((entry) => 
            (entry.value['fileSize'] as int? ?? 0) < 500000 && // < 500KB
            entry.value['difficulty'] == 'easy')
        .map((entry) => entry.key)
        .toList();
  }

  /// Get comprehensive test suite (covers all categories and difficulties)
  static List<String> getComprehensiveTestSuite() {
    final categories = ['recycle', 'organic', 'landfill', 'ewaste', 'hazardous'];
    final difficulties = ['easy', 'medium', 'hard'];
    final testSuite = <String>[];

    for (final category in categories) {
      for (final difficulty in difficulties) {
        final images = imageMetadata.entries
            .where((entry) => 
                entry.value['category'] == category &&
                entry.value['difficulty'] == difficulty)
            .map((entry) => entry.key)
            .take(2) // Max 2 per category/difficulty combination
            .toList();
        testSuite.addAll(images);
      }
    }

    // Add some edge cases
    testSuite.addAll(getEdgeCaseImages().take(5));
    
    // Add QR codes
    testSuite.addAll(getQRCodeImages().take(3));

    return testSuite;
  }
}