import 'dart:ui';

/// Represents a detected object with AR overlay information
class DetectedObject {
  final String trackingId;
  final String category;
  final String codeName;
  final Rect boundingBox;
  final double confidence;
  final DateTime detectedAt;
  final Color overlayColor;

  const DetectedObject({
    required this.trackingId,
    required this.category,
    required this.codeName,
    required this.boundingBox,
    required this.confidence,
    required this.detectedAt,
    required this.overlayColor,
  });

  DetectedObject copyWith({
    String? trackingId,
    String? category,
    String? codeName,
    Rect? boundingBox,
    double? confidence,
    DateTime? detectedAt,
    Color? overlayColor,
  }) {
    return DetectedObject(
      trackingId: trackingId ?? this.trackingId,
      category: category ?? this.category,
      codeName: codeName ?? this.codeName,
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      detectedAt: detectedAt ?? this.detectedAt,
      overlayColor: overlayColor ?? this.overlayColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedObject && other.trackingId == trackingId;
  }

  @override
  int get hashCode => trackingId.hashCode;

  @override
  String toString() {
    return 'DetectedObject(trackingId: $trackingId, category: $category, codeName: $codeName, confidence: $confidence)';
  }
}