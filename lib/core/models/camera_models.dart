/// Camera and AR detection models for the CleanClik system
///
/// This file consolidates all camera-related data models including:
/// - DetectedObject: ML detection results with AR overlay functionality
/// - CameraMode: Camera operation modes (QR scanning, ML detection)
/// - CameraStatus: Camera status enumeration
/// - CameraState: Camera state management
/// - CameraConfiguration: Camera settings for different modes
/// - ObjectIndicatorData: AR overlay indicators for detected objects
/// - IndicatorType: Types of object indicators

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/services/camera/ml_config.dart'
    show ProcessingMode;

/// Represents an image label from ML Kit Image Labeling
class ImageLabel {
  final String text;
  final double confidence;
  final int index;

  const ImageLabel({
    required this.text,
    required this.confidence,
    required this.index,
  });

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {'text': text, 'confidence': confidence, 'index': index};
  }

  /// Create from map
  factory ImageLabel.fromMap(Map<String, dynamic> map) {
    return ImageLabel(
      text: map['text'] as String,
      confidence: map['confidence'] as double,
      index: map['index'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageLabel &&
        other.text == text &&
        other.confidence == confidence &&
        other.index == index;
  }

  @override
  int get hashCode => Object.hash(text, confidence, index);

  @override
  String toString() {
    return 'ImageLabel(text: $text, confidence: ${(confidence * 100).toStringAsFixed(1)}%, index: $index)';
  }
}

/// Detection source enumeration for tracking how objects were detected
enum DetectionSource {
  /// Object detected via ML Kit object detection
  mlDetection,

  /// Object detected via ML Kit image labeling
  imageLabeling,

  /// Object detected via combined ML detection and image labeling
  combined,

  /// Object manually categorized by user
  manual;

  /// Convert to string for serialization
  String get value {
    switch (this) {
      case DetectionSource.mlDetection:
        return 'ml_detection';
      case DetectionSource.imageLabeling:
        return 'image_labeling';
      case DetectionSource.combined:
        return 'combined';
      case DetectionSource.manual:
        return 'manual';
    }
  }

  /// Create from string value
  static DetectionSource fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ml_detection':
        return DetectionSource.mlDetection;
      case 'image_labeling':
        return DetectionSource.imageLabeling;
      case 'combined':
        return DetectionSource.combined;
      case 'manual':
        return DetectionSource.manual;
      default:
        return DetectionSource.mlDetection;
    }
  }
}

/// Represents a detected object with AR overlay information
class DetectedObject {
  final String trackingId;
  final String category;
  final String codeName;
  final Rect boundingBox;
  final double confidence;
  final DateTime detectedAt;
  final Color overlayColor;

  // Enhanced fields for disposal fix - unique object identification
  final String objectId;

  // Detection source tracking
  final DetectionSource detectionSource;

  // Categorization reasoning and metadata
  final String? categorizationReasoning;
  final Map<String, dynamic>? detectionMetadata;

  // Additional properties for backward compatibility with tests
  final String? id;
  final String? label;
  final bool isTracked;

  // Enhanced categorization fields
  final List<ImageLabel>? labels;
  final String? reasoning;

  // Image labeling support - primary field for ML Kit Image Labeling results
  final List<ImageLabel> imageLabels;

  // Dual ML waste categorization fields (legacy support)
  final String? wasteCategory;
  final double? categoryConfidence;
  final bool isWasteItem;
  final Map<String, double>? categoryScores;

  DetectedObject({
    required this.trackingId,
    required this.category,
    required this.codeName,
    required this.boundingBox,
    required this.confidence,
    required this.detectedAt,
    required this.overlayColor,
    // Enhanced fields for disposal fix
    String? objectId,
    this.detectionSource = DetectionSource.mlDetection,
    this.categorizationReasoning,
    this.detectionMetadata,
    // Backward compatibility fields
    this.id,
    this.label,
    this.isTracked = false,
    this.labels,
    this.reasoning,
    // Image labeling support with default empty list for backward compatibility
    this.imageLabels = const [],
    // Dual ML fields (legacy support)
    this.wasteCategory,
    this.categoryConfidence,
    this.isWasteItem = false,
    this.categoryScores,
  }) : objectId = objectId ?? const Uuid().v4();

  DetectedObject copyWith({
    String? trackingId,
    String? category,
    String? codeName,
    Rect? boundingBox,
    double? confidence,
    DateTime? detectedAt,
    Color? overlayColor,
    // Enhanced fields for disposal fix
    String? objectId,
    DetectionSource? detectionSource,
    String? categorizationReasoning,
    Map<String, dynamic>? detectionMetadata,
    // Backward compatibility fields
    String? id,
    String? label,
    bool? isTracked,
    List<ImageLabel>? labels,
    String? reasoning,
    // Image labeling support
    List<ImageLabel>? imageLabels,
    // Dual ML fields (legacy support)
    String? wasteCategory,
    double? categoryConfidence,
    bool? isWasteItem,
    Map<String, double>? categoryScores,
  }) {
    return DetectedObject(
      trackingId: trackingId ?? this.trackingId,
      category: category ?? this.category,
      codeName: codeName ?? this.codeName,
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      detectedAt: detectedAt ?? this.detectedAt,
      overlayColor: overlayColor ?? this.overlayColor,
      // Enhanced fields for disposal fix
      objectId: objectId ?? this.objectId,
      detectionSource: detectionSource ?? this.detectionSource,
      categorizationReasoning:
          categorizationReasoning ?? this.categorizationReasoning,
      detectionMetadata: detectionMetadata ?? this.detectionMetadata,
      // Backward compatibility fields
      id: id ?? this.id,
      label: label ?? this.label,
      isTracked: isTracked ?? this.isTracked,
      labels: labels ?? this.labels,
      reasoning: reasoning ?? this.reasoning,
      // Image labeling support
      imageLabels: imageLabels ?? this.imageLabels,
      // Dual ML fields (legacy support)
      wasteCategory: wasteCategory ?? this.wasteCategory,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      isWasteItem: isWasteItem ?? this.isWasteItem,
      categoryScores: categoryScores ?? this.categoryScores,
    );
  }

  /// Merge method for combining detection and labeling data
  /// Creates a new DetectedObject with the provided image labels
  DetectedObject mergeWithLabels(List<ImageLabel> newImageLabels) {
    return DetectedObject(
      trackingId: trackingId,
      category: category,
      codeName: codeName,
      boundingBox: boundingBox,
      confidence: confidence,
      detectedAt: detectedAt,
      overlayColor: overlayColor,
      // Enhanced fields for disposal fix
      objectId: objectId,
      detectionSource:
          DetectionSource.combined, // Update to combined when merging
      categorizationReasoning: categorizationReasoning,
      detectionMetadata: detectionMetadata,
      // Backward compatibility fields
      id: id,
      label: label,
      isTracked: isTracked,
      labels: labels,
      reasoning: reasoning,
      // Merge the new image labels
      imageLabels: newImageLabels,
      // Preserve existing dual ML fields
      wasteCategory: wasteCategory,
      categoryConfidence: categoryConfidence,
      isWasteItem: isWasteItem,
      categoryScores: categoryScores,
    );
  }

  /// Get the most confident image label for display purposes
  /// Returns null if no image labels are available
  ImageLabel? get mostConfidentImageLabel {
    if (imageLabels.isEmpty) return null;

    return imageLabels.reduce(
      (current, next) => current.confidence > next.confidence ? current : next,
    );
  }

  /// Check if image labeling data is available
  bool get hasImageLabels => imageLabels.isNotEmpty;

  /// Get formatted string of all image labels for debug display
  String get imageLabelsDebugString {
    if (imageLabels.isEmpty) return 'No image labels';

    return imageLabels
        .map(
          (label) =>
              '${label.text} (${(label.confidence * 100).toStringAsFixed(1)}%)',
        )
        .join(', ');
  }

  /// Convert to inventory metadata for database storage
  /// Requirements: 1.1, 1.2, 1.3, 2.1, 2.2
  Map<String, dynamic> toInventoryMetadata() {
    return {
      'detection': {
        'source': detectionSource.value,
        'object_id': objectId,
        'ml_labels': labels?.map((label) => label.toMap()).toList() ?? [],
        'image_labels': imageLabels.map((label) => label.toMap()).toList(),
        'detected_at': detectedAt.toIso8601String(),
        'tracking_id': trackingId,
        'confidence': confidence,
        'bounding_box': {
          'left': boundingBox.left,
          'top': boundingBox.top,
          'right': boundingBox.right,
          'bottom': boundingBox.bottom,
        },
      },
      'categorization': {
        'final_category': category,
        'confidence': categoryConfidence ?? confidence,
        'reasoning':
            categorizationReasoning ??
            reasoning ??
            'Auto-categorized from detection',
        'waste_category': wasteCategory,
        'category_scores': categoryScores,
        'user_corrected': false,
        'is_waste_item': isWasteItem,
      },
      'system': {
        'version': '2.0',
        'created_at': DateTime.now().toIso8601String(),
        'code_name': codeName,
        'overlay_color': overlayColor.value,
        'detection_metadata': detectionMetadata,
      },
    };
  }

  /// Get display label for UI components
  /// Requirements: 2.1, 2.2
  String getDisplayLabel() {
    // Prioritize most confident image label if available
    if (imageLabels.isNotEmpty) {
      final mostConfident = mostConfidentImageLabel;
      if (mostConfident != null && mostConfident.confidence > 0.7) {
        return mostConfident.text;
      }
    }

    // Fall back to code name or category
    return codeName.isNotEmpty ? codeName : category;
  }

  /// Get comprehensive categorization summary for disposal overlays
  /// Requirements: 2.1, 2.4, 2.5
  String getCategorizationSummary() {
    final buffer = StringBuffer();

    // Detection source information
    buffer.write('Detected via: ${_getDetectionSourceDisplay()}\n');

    // Primary categorization
    buffer.write('Category: $category');
    if (categoryConfidence != null) {
      buffer.write(
        ' (${(categoryConfidence! * 100).toStringAsFixed(1)}% confidence)',
      );
    }
    buffer.write('\n');

    // Image labeling results
    if (imageLabels.isNotEmpty) {
      buffer.write('Image Labels: ');
      buffer.write(
        imageLabels
            .take(3) // Show top 3 labels
            .map(
              (label) =>
                  '${label.text} (${(label.confidence * 100).toStringAsFixed(1)}%)',
            )
            .join(', '),
      );
      if (imageLabels.length > 3) {
        buffer.write(' and ${imageLabels.length - 3} more');
      }
      buffer.write('\n');
    }

    // Categorization reasoning
    if (categorizationReasoning != null &&
        categorizationReasoning!.isNotEmpty) {
      buffer.write('Reasoning: $categorizationReasoning\n');
    }

    // Confidence and detection time
    buffer.write(
      'Detection Confidence: ${(confidence * 100).toStringAsFixed(1)}%\n',
    );
    buffer.write('Detected: ${_formatDetectionTime()}');

    return buffer.toString();
  }

  /// Get detection source display string
  String _getDetectionSourceDisplay() {
    switch (detectionSource) {
      case DetectionSource.mlDetection:
        return 'ML Object Detection';
      case DetectionSource.imageLabeling:
        return 'Image Labeling';
      case DetectionSource.combined:
        return 'ML Detection + Image Labeling';
      case DetectionSource.manual:
        return 'Manual Classification';
    }
  }

  /// Format detection time for display
  String _formatDetectionTime() {
    final now = DateTime.now();
    final difference = now.difference(detectedAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return '${difference.inHours} hours ago';
    }
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'trackingId': trackingId,
      'category': category,
      'codeName': codeName,
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'right': boundingBox.right,
        'bottom': boundingBox.bottom,
      },
      'confidence': confidence,
      'detectedAt': detectedAt.toIso8601String(),
      'overlayColor': overlayColor.value,
      // Enhanced fields for disposal fix
      'objectId': objectId,
      'detectionSource': detectionSource.value,
      'categorizationReasoning': categorizationReasoning,
      'detectionMetadata': detectionMetadata,
      // Backward compatibility fields
      'id': id,
      'label': label,
      'isTracked': isTracked,
      'labels': labels?.map((label) => label.toMap()).toList(),
      'reasoning': reasoning,
      // Image labeling support
      'imageLabels': imageLabels.map((label) => label.toMap()).toList(),
      'wasteCategory': wasteCategory,
      'categoryConfidence': categoryConfidence,
      'isWasteItem': isWasteItem,
      'categoryScores': categoryScores,
    };
  }

  /// Create from JSON
  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    final boundingBoxData = json['boundingBox'] as Map<String, dynamic>;
    final labelsData = json['labels'] as List<dynamic>?;
    final imageLabelsData = json['imageLabels'] as List<dynamic>?;
    final categoryScoresData = json['categoryScores'] as Map<String, dynamic>?;
    final detectionMetadataData =
        json['detectionMetadata'] as Map<String, dynamic>?;

    return DetectedObject(
      trackingId: json['trackingId'] as String,
      category: json['category'] as String,
      codeName: json['codeName'] as String,
      boundingBox: Rect.fromLTRB(
        boundingBoxData['left'] as double,
        boundingBoxData['top'] as double,
        boundingBoxData['right'] as double,
        boundingBoxData['bottom'] as double,
      ),
      confidence: json['confidence'] as double,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      overlayColor: Color(json['overlayColor'] as int),
      // Enhanced fields for disposal fix with fallbacks for backward compatibility
      objectId: json['objectId'] as String? ?? const Uuid().v4(),
      detectionSource: json['detectionSource'] != null
          ? DetectionSource.fromString(json['detectionSource'] as String)
          : DetectionSource.mlDetection,
      categorizationReasoning: json['categorizationReasoning'] as String?,
      detectionMetadata: detectionMetadataData,
      // Backward compatibility fields
      id: json['id'] as String?,
      label: json['label'] as String?,
      isTracked: json['isTracked'] as bool? ?? false,
      labels: labelsData
          ?.map(
            (labelMap) => ImageLabel.fromMap(labelMap as Map<String, dynamic>),
          )
          .toList(),
      reasoning: json['reasoning'] as String?,
      // Image labeling support with fallback to empty list for backward compatibility
      imageLabels:
          imageLabelsData
              ?.map(
                (labelMap) =>
                    ImageLabel.fromMap(labelMap as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      wasteCategory: json['wasteCategory'] as String?,
      categoryConfidence: json['categoryConfidence'] as double?,
      isWasteItem: json['isWasteItem'] as bool? ?? false,
      categoryScores: categoryScoresData?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedObject &&
        other.objectId == objectId &&
        other.trackingId == trackingId;
  }

  @override
  int get hashCode => Object.hash(objectId, trackingId);

  @override
  String toString() {
    return 'DetectedObject(objectId: $objectId, trackingId: $trackingId, category: $category, codeName: $codeName, confidence: $confidence, source: ${detectionSource.value})';
  }
}

/// Camera operation modes for the AR camera screen
enum CameraMode {
  /// No camera mode active
  none,

  /// QR code scanning mode
  qrScanning,

  /// ML object detection mode (formerly arDetection)
  mlDetection,
}

/// Camera status enumeration
enum CameraStatus {
  /// Camera is not initialized
  uninitialized,

  /// Camera is currently initializing
  initializing,

  /// Camera is ready for use
  ready,

  /// Camera is switching between modes
  switching,

  /// Camera encountered an error
  error,

  /// Camera has been disposed
  disposed,
}

/// Extension to provide string values for camera modes
extension CameraModeExtension on CameraMode {
  /// Convert camera mode to string
  String get value {
    switch (this) {
      case CameraMode.none:
        return 'none';
      case CameraMode.mlDetection:
        return 'ml';
      case CameraMode.qrScanning:
        return 'qr';
    }
  }

  /// Create camera mode from string value
  static CameraMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'qr':
      case 'qrscanning':
        return CameraMode.qrScanning;
      case 'ml':
      case 'mldetection':
      case 'ar':
      case 'ardetection':
        return CameraMode.mlDetection;
      case 'none':
      default:
        return CameraMode.none;
    }
  }
}

/// Camera state model to track current mode and status
class CameraState {
  final CameraMode mode;
  final CameraStatus status;
  final String? errorMessage;
  final bool hasPermission;
  final DateTime lastUpdated;
  final bool isTransitioning;

  const CameraState({
    required this.mode,
    required this.status,
    this.errorMessage,
    required this.hasPermission,
    required this.lastUpdated,
    this.isTransitioning = false,
  });

  /// Check if camera is ready for use
  bool get isReady => status == CameraStatus.ready;

  /// Check if camera can switch modes
  bool get canSwitch =>
      status == CameraStatus.ready || status == CameraStatus.error;

  /// Check if camera is initialized (legacy compatibility)
  bool get isInitialized => status == CameraStatus.ready;

  /// Create a copy with updated values
  CameraState copyWith({
    CameraMode? mode,
    CameraStatus? status,
    String? errorMessage,
    bool? hasPermission,
    DateTime? lastUpdated,
    bool? isTransitioning,
  }) {
    return CameraState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      hasPermission: hasPermission ?? this.hasPermission,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isTransitioning: isTransitioning ?? this.isTransitioning,
    );
  }

  /// Create initial state
  static CameraState initial = CameraState(
    mode: CameraMode.none,
    status: CameraStatus.uninitialized,
    hasPermission: false,
    lastUpdated: DateTime.now(),
  );
}

/// Camera configuration for different modes
class CameraConfiguration {
  final ResolutionPreset resolution;
  final bool enableAudio;
  final CameraLensDirection lensDirection;
  final ImageFormatGroup? imageFormatGroup;

  const CameraConfiguration({
    this.resolution = ResolutionPreset.medium,
    this.enableAudio = false,
    this.lensDirection = CameraLensDirection.back,
    this.imageFormatGroup,
  });

  /// Configuration optimized for QR code scanning
  static const CameraConfiguration forQRScanning = CameraConfiguration(
    resolution: ResolutionPreset.medium,
    enableAudio: false,
    lensDirection: CameraLensDirection.back,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );

  /// Configuration optimized for ML object detection
  static const CameraConfiguration forMLDetection = CameraConfiguration(
    resolution: ResolutionPreset.high,
    enableAudio: false,
    lensDirection: CameraLensDirection.back,
    imageFormatGroup: ImageFormatGroup.nv21,
  );

  CameraConfiguration copyWith({
    ResolutionPreset? resolution,
    bool? enableAudio,
    CameraLensDirection? lensDirection,
    ImageFormatGroup? imageFormatGroup,
  }) {
    return CameraConfiguration(
      resolution: resolution ?? this.resolution,
      enableAudio: enableAudio ?? this.enableAudio,
      lensDirection: lensDirection ?? this.lensDirection,
      imageFormatGroup: imageFormatGroup ?? this.imageFormatGroup,
    );
  }
}

/// Data model for object indicator rendering
class ObjectIndicatorData {
  final WasteCategory category;
  final Offset centerPosition;
  final double confidence;
  final IndicatorType type;
  final Color categoryColor;
  final String objectInfo;
  final bool showTooltip;
  final String trackingId;
  final DateTime detectedAt;
  final Size boundingBoxSize;
  final bool isVisible;
  final Duration animationDuration;

  const ObjectIndicatorData({
    required this.category,
    required this.centerPosition,
    required this.confidence,
    required this.type,
    required this.categoryColor,
    required this.objectInfo,
    required this.trackingId,
    required this.detectedAt,
    this.showTooltip = true,
    this.boundingBoxSize = const Size(20, 20),
    this.isVisible = true,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  ObjectIndicatorData copyWith({
    WasteCategory? category,
    Offset? centerPosition,
    double? confidence,
    IndicatorType? type,
    Color? categoryColor,
    String? objectInfo,
    bool? showTooltip,
    String? trackingId,
    DateTime? detectedAt,
    Size? boundingBoxSize,
    bool? isVisible,
    Duration? animationDuration,
  }) {
    return ObjectIndicatorData(
      category: category ?? this.category,
      centerPosition: centerPosition ?? this.centerPosition,
      confidence: confidence ?? this.confidence,
      type: type ?? this.type,
      categoryColor: categoryColor ?? this.categoryColor,
      objectInfo: objectInfo ?? this.objectInfo,
      showTooltip: showTooltip ?? this.showTooltip,
      trackingId: trackingId ?? this.trackingId,
      detectedAt: detectedAt ?? this.detectedAt,
      boundingBoxSize: boundingBoxSize ?? this.boundingBoxSize,
      isVisible: isVisible ?? this.isVisible,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  /// Create indicator data from detected object
  factory ObjectIndicatorData.fromDetectedObject(
    DetectedObject detectedObject,
    IndicatorType indicatorType, {
    Duration? animationDuration,
  }) {
    final category =
        WasteCategory.fromString(detectedObject.category) ??
        WasteCategory.recycle;

    return ObjectIndicatorData(
      category: category,
      centerPosition: detectedObject.boundingBox.center,
      confidence: detectedObject.confidence,
      type: indicatorType,
      categoryColor: detectedObject.overlayColor,
      objectInfo: detectedObject.codeName,
      trackingId: detectedObject.trackingId,
      detectedAt: detectedObject.detectedAt,
      boundingBoxSize: detectedObject.boundingBox.size,
      isVisible: detectedObject.confidence >= 0.3,
      animationDuration:
          animationDuration ?? const Duration(milliseconds: 1500),
    );
  }

  /// Get indicator type based on waste category
  static IndicatorType getIndicatorTypeForCategory(WasteCategory category) {
    switch (category) {
      case WasteCategory.recycle:
        return IndicatorType.pulsatingCircle;
      case WasteCategory.organic:
        return IndicatorType.glowingDot;
      case WasteCategory.ewaste:
        return IndicatorType.targetReticle;
      case WasteCategory.hazardous:
        return IndicatorType.pulsatingCircle;
    }
  }

  /// Get animation duration based on category
  Duration getAnimationDuration() {
    switch (category) {
      case WasteCategory.recycle:
        return const Duration(milliseconds: 1500);
      case WasteCategory.organic:
        return const Duration(milliseconds: 2000);
      case WasteCategory.ewaste:
        return const Duration(milliseconds: 1200);
      case WasteCategory.hazardous:
        return const Duration(milliseconds: 1000);
    }
  }

  /// Get indicator size based on confidence and category
  double getIndicatorSize() {
    const baseSize = 16.0;
    const maxSize = 20.0;

    // Size varies with confidence
    final confidenceMultiplier = 0.7 + (confidence * 0.3);

    // Category-specific size adjustments
    final categoryMultiplier = switch (category) {
      WasteCategory.hazardous => 1.1, // Slightly larger for hazardous
      WasteCategory.ewaste => 1.05,
      WasteCategory.recycle => 1.0,
      WasteCategory.organic => 0.95,
    };

    return (baseSize * confidenceMultiplier * categoryMultiplier).clamp(
      baseSize * 0.7,
      maxSize,
    );
  }

  /// Check if indicator should be visible (uses stored value)
  bool get shouldBeVisible => confidence >= 0.3;

  /// Get tooltip priority (higher for more confident detections)
  int get tooltipPriority => (confidence * 100).round();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ObjectIndicatorData &&
        other.trackingId == trackingId &&
        other.category == category &&
        other.centerPosition == centerPosition;
  }

  @override
  int get hashCode => Object.hash(trackingId, category, centerPosition);

  @override
  String toString() {
    return 'ObjectIndicatorData('
        'category: $category, '
        'position: $centerPosition, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'type: $type'
        ')';
  }
}

/// Types of object indicators
enum IndicatorType {
  /// Pulsating circle with breathing animation
  pulsatingCircle,

  /// Glowing dot with gentle color transitions
  glowingDot,

  /// Target reticle with minimal animation
  targetReticle,
}

/// Service initialization state enumeration
enum ServiceInitializationState {
  /// Service has not started initializing
  notStarted,

  /// Service is currently initializing
  initializing,

  /// Service initialization completed successfully
  completed,

  /// Service initialization failed
  failed,

  /// Service initialization was skipped (not supported or not needed)
  skipped,
}

/// Service initialization progress data
class ServiceInitializationProgress {
  final String message;
  final double progress; // 0.0 to 1.0
  final Map<String, ServiceInitializationState> serviceStates;
  final bool isComplete;
  final bool hasError;
  final DateTime timestamp;

  ServiceInitializationProgress({
    required this.message,
    required this.progress,
    required this.serviceStates,
    this.isComplete = false,
    this.hasError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Get count of services in each state
  Map<ServiceInitializationState, int> get stateCounts {
    final counts = <ServiceInitializationState, int>{};
    for (final state in ServiceInitializationState.values) {
      counts[state] = 0;
    }

    for (final state in serviceStates.values) {
      counts[state] = (counts[state] ?? 0) + 1;
    }

    return counts;
  }

  /// Get list of failed services
  List<String> get failedServices {
    return serviceStates.entries
        .where((entry) => entry.value == ServiceInitializationState.failed)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get list of completed services
  List<String> get completedServices {
    return serviceStates.entries
        .where((entry) => entry.value == ServiceInitializationState.completed)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get overall initialization success rate
  double get successRate {
    if (serviceStates.isEmpty) return 0.0;

    final completedCount = completedServices.length;
    final skippedCount = serviceStates.values
        .where((state) => state == ServiceInitializationState.skipped)
        .length;

    // Consider both completed and skipped as successful
    return (completedCount + skippedCount) / serviceStates.length;
  }

  @override
  String toString() {
    return 'ServiceInitializationProgress('
        'message: $message, '
        'progress: ${(progress * 100).toStringAsFixed(1)}%, '
        'completed: ${completedServices.length}/${serviceStates.length}, '
        'isComplete: $isComplete'
        ')';
  }
}

/// Detection data model for structured metadata storage
/// Requirements: 4.1, 4.2, 4.4
class DetectionData {
  final DetectionSource source;
  final List<ImageLabel> imageLabels;
  final String originalMLLabel;
  final double mlConfidence;
  final DateTime detectedAt;
  final String trackingId;
  final String objectId;
  final Map<String, double> boundingBox;

  const DetectionData({
    required this.source,
    required this.imageLabels,
    required this.originalMLLabel,
    required this.mlConfidence,
    required this.detectedAt,
    required this.trackingId,
    required this.objectId,
    required this.boundingBox,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'source': source.value,
      'image_labels': imageLabels.map((label) => label.toMap()).toList(),
      'original_ml_label': originalMLLabel,
      'ml_confidence': mlConfidence,
      'detected_at': detectedAt.toIso8601String(),
      'tracking_id': trackingId,
      'object_id': objectId,
      'bounding_box': boundingBox,
    };
  }

  /// Create from JSON
  factory DetectionData.fromJson(Map<String, dynamic> json) {
    final imageLabelsData = json['image_labels'] as List<dynamic>? ?? [];
    final boundingBoxData = json['bounding_box'] as Map<String, dynamic>? ?? {};

    return DetectionData(
      source: DetectionSource.fromString(
        json['source'] as String? ?? 'ml_detection',
      ),
      imageLabels: imageLabelsData
          .map(
            (labelMap) => ImageLabel.fromMap(labelMap as Map<String, dynamic>),
          )
          .toList(),
      originalMLLabel: json['original_ml_label'] as String? ?? '',
      mlConfidence: (json['ml_confidence'] as num?)?.toDouble() ?? 0.0,
      detectedAt: DateTime.parse(
        json['detected_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      trackingId: json['tracking_id'] as String? ?? '',
      objectId: json['object_id'] as String? ?? '',
      boundingBox: boundingBoxData.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  @override
  String toString() {
    return 'DetectionData(source: $source, objectId: $objectId, mlLabel: $originalMLLabel, confidence: $mlConfidence)';
  }
}

/// Categorization data model for structured metadata storage
/// Requirements: 4.1, 4.2, 4.4
class CategorizationData {
  final String finalCategory;
  final double categoryConfidence;
  final String reasoning;
  final String? matchedKeyword;
  final List<String> alternativeCategories;
  final bool wasUserCorrected;
  final DateTime categorizedAt;

  const CategorizationData({
    required this.finalCategory,
    required this.categoryConfidence,
    required this.reasoning,
    this.matchedKeyword,
    required this.alternativeCategories,
    required this.wasUserCorrected,
    required this.categorizedAt,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'final_category': finalCategory,
      'confidence': categoryConfidence,
      'reasoning': reasoning,
      'matched_keyword': matchedKeyword,
      'alternatives': alternativeCategories,
      'user_corrected': wasUserCorrected,
      'categorized_at': categorizedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CategorizationData.fromJson(Map<String, dynamic> json) {
    final alternativesData = json['alternatives'] as List<dynamic>? ?? [];

    return CategorizationData(
      finalCategory: json['final_category'] as String? ?? '',
      categoryConfidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String? ?? '',
      matchedKeyword: json['matched_keyword'] as String?,
      alternativeCategories: alternativesData
          .map((alt) => alt.toString())
          .toList(),
      wasUserCorrected: json['user_corrected'] as bool? ?? false,
      categorizedAt: DateTime.parse(
        json['categorized_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  String toString() {
    return 'CategorizationData(category: $finalCategory, confidence: $categoryConfidence, reasoning: $reasoning)';
  }
}

/// Disposal data model for structured metadata storage
/// Requirements: 4.1, 4.2, 4.4
class DisposalData {
  final DateTime disposedAt;
  final String binId;
  final String binCategory;
  final int pointsAwarded;
  final bool wasCorrectDisposal;
  final String? disposalNotes;
  final double? accuracyScore;

  const DisposalData({
    required this.disposedAt,
    required this.binId,
    required this.binCategory,
    required this.pointsAwarded,
    required this.wasCorrectDisposal,
    this.disposalNotes,
    this.accuracyScore,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'disposed_at': disposedAt.toIso8601String(),
      'bin_id': binId,
      'bin_category': binCategory,
      'points_awarded': pointsAwarded,
      'correct_disposal': wasCorrectDisposal,
      'disposal_notes': disposalNotes,
      'accuracy_score': accuracyScore,
    };
  }

  /// Create from JSON
  factory DisposalData.fromJson(Map<String, dynamic> json) {
    return DisposalData(
      disposedAt: DateTime.parse(
        json['disposed_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      binId: json['bin_id'] as String? ?? '',
      binCategory: json['bin_category'] as String? ?? '',
      pointsAwarded: json['points_awarded'] as int? ?? 0,
      wasCorrectDisposal: json['correct_disposal'] as bool? ?? false,
      disposalNotes: json['disposal_notes'] as String?,
      accuracyScore: (json['accuracy_score'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'DisposalData(binId: $binId, category: $binCategory, points: $pointsAwarded, correct: $wasCorrectDisposal)';
  }
}

/// Enhanced metadata wrapper class with JSON serialization
/// Requirements: 4.1, 4.2, 4.4
class EnhancedMetadata {
  final DetectionData detection;
  final CategorizationData categorization;
  final DisposalData? disposal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String version;

  const EnhancedMetadata({
    required this.detection,
    required this.categorization,
    this.disposal,
    required this.createdAt,
    required this.updatedAt,
    this.version = '2.0',
  });

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'detection': detection.toJson(),
      'categorization': categorization.toJson(),
      'disposal': disposal?.toJson(),
      'system': {
        'version': version,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      },
    };
  }

  /// Create from JSON
  factory EnhancedMetadata.fromJson(Map<String, dynamic> json) {
    final systemData = json['system'] as Map<String, dynamic>? ?? {};
    final disposalData = json['disposal'] as Map<String, dynamic>?;

    return EnhancedMetadata(
      detection: DetectionData.fromJson(
        json['detection'] as Map<String, dynamic>? ?? {},
      ),
      categorization: CategorizationData.fromJson(
        json['categorization'] as Map<String, dynamic>? ?? {},
      ),
      disposal: disposalData != null
          ? DisposalData.fromJson(disposalData)
          : null,
      createdAt: DateTime.parse(
        systemData['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        systemData['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      version: systemData['version'] as String? ?? '2.0',
    );
  }

  /// Create a copy with updated disposal data
  EnhancedMetadata copyWithDisposal(DisposalData disposalData) {
    return EnhancedMetadata(
      detection: detection,
      categorization: categorization,
      disposal: disposalData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      version: version,
    );
  }

  /// Check if metadata has disposal information
  bool get hasDisposalData => disposal != null;

  /// Get summary string for debugging
  String getSummary() {
    final buffer = StringBuffer();
    buffer.write('Enhanced Metadata v$version\n');
    buffer.write(
      'Detection: ${detection.source.value} (${detection.originalMLLabel})\n',
    );
    buffer.write(
      'Category: ${categorization.finalCategory} (${(categorization.categoryConfidence * 100).toStringAsFixed(1)}%)\n',
    );
    if (hasDisposalData) {
      buffer.write(
        'Disposed: ${disposal!.binCategory} bin (${disposal!.pointsAwarded} points)',
      );
    } else {
      buffer.write('Status: Not disposed');
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return 'EnhancedMetadata(version: $version, objectId: ${detection.objectId}, category: ${categorization.finalCategory}, disposed: $hasDisposalData)';
  }
}

/// Service execution context for intelligent pickup service decisions
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
class ServiceExecutionContext {
  final List<DetectedObject> detectedObjects;
  final List<HandLandmark> handLandmarks;
  final ProcessingMode currentMode;
  final bool isMemoryPressure;
  final DateTime timestamp;
  final bool isBatteryLow;
  final int consecutiveEmptyFrames;

  const ServiceExecutionContext({
    required this.detectedObjects,
    required this.handLandmarks,
    required this.currentMode,
    required this.isMemoryPressure,
    required this.timestamp,
    this.isBatteryLow = false,
    this.consecutiveEmptyFrames = 0,
  });

  /// Smart execution decision for pickup service
  /// Requirements: 3.1, 3.2, 3.3
  bool shouldExecutePickupService() {
    // Requirement 3.1: WHEN no objects are detected THEN the pickup service SHALL NOT execute
    if (detectedObjects.isEmpty) {
      return false;
    }

    // Requirement 3.2: WHEN no hands are detected in the scene THEN the pickup service SHALL NOT execute
    if (handLandmarks.isEmpty) {
      return false;
    }

    // Requirement 3.4: WHEN the system is in cached mode THEN pickup service execution SHALL be minimized
    if (currentMode == ProcessingMode.cached) {
      return false;
    }

    // Additional performance considerations
    if (isMemoryPressure || isBatteryLow) {
      return false;
    }

    // Requirement 3.3: WHEN both objects and hands are present THEN the pickup service SHALL execute normally
    return true;
  }

  /// Check if image labeling should be executed
  bool shouldExecuteImageLabeling() {
    return detectedObjects.isNotEmpty &&
        currentMode == ProcessingMode.full &&
        !isMemoryPressure;
  }

  /// Check if full ML processing should be executed
  bool shouldExecuteFullMLProcessing() {
    return currentMode == ProcessingMode.full && !isMemoryPressure;
  }

  /// Get execution reason for logging purposes
  String getExecutionReason() {
    if (!shouldExecutePickupService()) {
      if (detectedObjects.isEmpty) {
        return 'no_objects_detected';
      }
      if (handLandmarks.isEmpty) {
        return 'no_hands_detected';
      }
      if (currentMode == ProcessingMode.cached) {
        return 'cached_mode_active';
      }
      if (isMemoryPressure) {
        return 'memory_pressure';
      }
      if (isBatteryLow) {
        return 'battery_low';
      }
    }
    return 'conditions_met';
  }

  /// Create a copy with updated values
  ServiceExecutionContext copyWith({
    List<DetectedObject>? detectedObjects,
    List<HandLandmark>? handLandmarks,
    ProcessingMode? currentMode,
    bool? isMemoryPressure,
    DateTime? timestamp,
    bool? isBatteryLow,
    int? consecutiveEmptyFrames,
  }) {
    return ServiceExecutionContext(
      detectedObjects: detectedObjects ?? this.detectedObjects,
      handLandmarks: handLandmarks ?? this.handLandmarks,
      currentMode: currentMode ?? this.currentMode,
      isMemoryPressure: isMemoryPressure ?? this.isMemoryPressure,
      timestamp: timestamp ?? this.timestamp,
      isBatteryLow: isBatteryLow ?? this.isBatteryLow,
      consecutiveEmptyFrames:
          consecutiveEmptyFrames ?? this.consecutiveEmptyFrames,
    );
  }

  @override
  String toString() {
    return 'ServiceExecutionContext('
        'objects: ${detectedObjects.length}, '
        'hands: ${handLandmarks.length}, '
        'mode: $currentMode, '
        'memoryPressure: $isMemoryPressure, '
        'batteryLow: $isBatteryLow, '
        'shouldExecutePickup: ${shouldExecutePickupService()}'
        ')';
  }
}
