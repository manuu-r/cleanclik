import 'package:flutter/material.dart';
import 'waste_category.dart';
import 'detected_object.dart';

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
    final category = WasteCategory.fromString(detectedObject.category) ?? 
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
      animationDuration: animationDuration ?? const Duration(milliseconds: 1500),
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
    
    return (baseSize * confidenceMultiplier * categoryMultiplier)
        .clamp(baseSize * 0.7, maxSize);
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

// DetectedObject is imported from the existing detected_object.dart model