import 'package:flutter/material.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/services/business/pickup_service.dart';
import '../overlays/indicator_widget.dart';
import '../overlays/tooltip_widget.dart';

/// Enhanced object overlay that uses the new consolidated overlay system
/// This replaces the old bounding box rendering with modern indicator-based overlays
class EnhancedObjectOverlay extends StatelessWidget {
  final DetectedObject detectedObject;
  final ObjectStatus status;
  final Rect transformedRect;
  final VoidCallback? onTap;
  final bool showTooltip;
  final Size? screenSize;

  const EnhancedObjectOverlay({
    super.key,
    required this.detectedObject,
    required this.status,
    required this.transformedRect,
    this.onTap,
    this.showTooltip = false,
    this.screenSize,
  });

  /// Constructor for legacy DetectedObject (backward compatibility)
  const EnhancedObjectOverlay.legacy({
    super.key,
    required DetectedObject object,
    required this.status,
    required this.transformedRect,
    this.onTap,
    this.showTooltip = false,
    this.screenSize,
  }) : detectedObject = object;

  /// Get object confidence
  double get _objectConfidence {
    return detectedObject.confidence;
  }

  /// Get object labels
  List<String> get _objectLabels {
    return [detectedObject.category];
  }

  /// Get image label from ML Kit image labeller
  String _getImageLabel() {
    return detectedObject.codeName;
  }

  /// Get image label confidence from ML Kit image labeller
  double? _getImageLabelConfidence() {
    return detectedObject.confidence;
  }

  /// Get object name from ML Kit image labeller (refined labels preferred)
  String get _mlKitObjectName {
    return _getImageLabel();
  }

  /// Get object name/info from either data model
  String get _objectInfo {
    return _mlKitObjectName;
  }

  /// Get waste categorization
  String? get _wasteCategory {
    return detectedObject.wasteCategory;
  }

  /// Get category confidence
  double? get _categoryConfidence {
    return detectedObject.categoryConfidence;
  }

  @override
  Widget build(BuildContext context) {
    // Use waste category from pipeline or legacy data
    final wasteCategory = _getWasteCategory();
    final indicatorData = _createIndicatorData(wasteCategory);

    return Stack(
      children: [
        // Main indicator using new system
        IndicatorWidget(
          indicatorData: indicatorData,
          opacity: _getOpacityForStatus(),
          enableAnimations: _shouldEnableAnimations(),
          onTap: onTap,
        ),

        // Single tooltip with image label next to object indicator
        if (showTooltip && _objectConfidence >= 0.5)
          _buildImageLabelTooltip(wasteCategory),

        // Status overlay for carried/targeted objects
        if (status != ObjectStatus.detected) _buildStatusOverlay(),
      ],
    );
  }

  /// Get waste category from pipeline or legacy data
  WasteCategory _getWasteCategory() {
    // First try to get waste category from pipeline categorization
    if (_wasteCategory != null) {
      final category = WasteCategory.fromString(_wasteCategory!);
      if (category != null) return category;
    }

    // Fall back to category from labels or legacy category
    final firstLabel = _objectLabels.isNotEmpty
        ? _objectLabels.first
        : 'recycle';
    return WasteCategory.fromString(firstLabel) ?? WasteCategory.recycle;
  }

  /// Check if this is a waste item
  bool _isWasteItem() {
    return detectedObject.isWasteItem;
  }

  ObjectIndicatorData _createIndicatorData(WasteCategory category) {
    return ObjectIndicatorData(
      category: category,
      centerPosition: transformedRect.center,
      confidence: _objectConfidence,
      type: _getIndicatorTypeForStatus(),
      categoryColor: _getCategorySpecificColor(category),
      objectInfo: _objectInfo,
      trackingId: _getTrackingId(),
      detectedAt: DateTime.now(),
      showTooltip: showTooltip,
      isVisible: true,
      animationDuration: _getAnimationDurationForStatus(),
    );
  }

  /// Get tracking ID
  String _getTrackingId() {
    return detectedObject.trackingId;
  }

  IndicatorType _getIndicatorTypeForStatus() {
    switch (status) {
      case ObjectStatus.carried:
        return IndicatorType.glowingDot; // Glowing for carried items
      case ObjectStatus.targeted:
        return IndicatorType.targetReticle; // Target for targeted items
      case ObjectStatus.detected:
        return IndicatorType.pulsatingCircle; // Standard for detected items
    }
  }

  /// Get category-specific color with visual distinction
  Color _getCategorySpecificColor(WasteCategory category) {
    switch (status) {
      case ObjectStatus.carried:
        return Colors.green;
      case ObjectStatus.targeted:
        return Colors.orange;
      case ObjectStatus.detected:
        return category.color;
    }
  }

  double _getOpacityForStatus() {
    switch (status) {
      case ObjectStatus.carried:
        return 0.9; // High visibility for carried items
      case ObjectStatus.targeted:
        return 0.8; // Medium visibility for targeted items
      case ObjectStatus.detected:
        return 0.7; // Standard visibility for detected items
    }
  }

  bool _shouldEnableAnimations() {
    // Enable animations for carried and targeted items for better visibility
    return status != ObjectStatus.detected;
  }

  Duration _getAnimationDurationForStatus() {
    switch (status) {
      case ObjectStatus.carried:
        return const Duration(milliseconds: 800); // Faster for carried
      case ObjectStatus.targeted:
        return const Duration(milliseconds: 1000); // Medium for targeted
      case ObjectStatus.detected:
        return const Duration(milliseconds: 1200); // Slower for detected
    }
  }

  Widget _buildStatusOverlay() {
    final statusData = _getStatusData();

    return Positioned(
      left: transformedRect.left,
      top: transformedRect.top - 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: statusData.color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: statusData.color.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusData.emoji.isNotEmpty) ...[
              Text(statusData.emoji, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 2),
            ],
            Text(
              statusData.statusText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build single tooltip with image label information next to object indicator
  Widget _buildImageLabelTooltip(WasteCategory category) {
    final imageLabel = _getImageLabel();
    final labelConfidence = _getImageLabelConfidence();

    return TooltipWidget(
      category: category,
      objectInfo: imageLabel,
      indicatorPosition: transformedRect.center,
      screenSize: screenSize ?? const Size(400, 800),
      isVisible: true,
      animationDuration: const Duration(milliseconds: 300),
      onTap: onTap,
      categoryConfidence: labelConfidence,
    );
  }

  /// Get category-specific icon
  IconData _getCategoryIcon(WasteCategory category) {
    switch (category) {
      case WasteCategory.recycle:
        return Icons.recycling;
      case WasteCategory.organic:
        return Icons.eco;
      case WasteCategory.ewaste:
        return Icons.electrical_services;
      case WasteCategory.hazardous:
        return Icons.warning;
    }
  }

  ObjectStatusData _getStatusData() {
    switch (status) {
      case ObjectStatus.carried:
        return ObjectStatusData(
          color: Colors.green,
          emoji: '🚚',
          statusText: 'CARRYING',
        );
      case ObjectStatus.targeted:
        return ObjectStatusData(
          color: Colors.orange,
          emoji: '🎯',
          statusText: 'TARGETED',
        );
      case ObjectStatus.detected:
        return ObjectStatusData(
          color: _getCategorySpecificColor(_getWasteCategory()),
          emoji: '',
          statusText: '',
        );
    }
  }
}

/// Status data for object overlays
class ObjectStatusData {
  final Color color;
  final String emoji;
  final String statusText;

  ObjectStatusData({
    required this.color,
    required this.emoji,
    required this.statusText,
  });
}
