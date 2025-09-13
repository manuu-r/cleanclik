import 'package:flutter/material.dart';
import 'package:cleanclik/core/models/detected_object.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import 'package:cleanclik/core/models/object_indicator_data.dart';
import 'package:cleanclik/core/services/business/object_management_service.dart';
import '../overlays/indicator_widget.dart';
import '../overlays/tooltip_widget.dart';

/// Enhanced object overlay that uses the new consolidated overlay system
/// This replaces the old bounding box rendering with modern indicator-based overlays
class EnhancedObjectOverlay extends StatelessWidget {
  final DetectedObject object;
  final ObjectStatus status;
  final Rect transformedRect;
  final VoidCallback? onTap;
  final bool showTooltip;
  final Size? screenSize;

  const EnhancedObjectOverlay({
    super.key,
    required this.object,
    required this.status,
    required this.transformedRect,
    this.onTap,
    this.showTooltip = false,
    this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final category = WasteCategory.fromString(object.category) ?? WasteCategory.recycle;
    final indicatorData = _createIndicatorData(category);
    
    return Stack(
      children: [
        // Main indicator using new system
        IndicatorWidget(
          indicatorData: indicatorData,
          opacity: _getOpacityForStatus(),
          enableAnimations: _shouldEnableAnimations(),
          onTap: onTap,
        ),
        
        // Status overlay for carried/targeted objects
        if (status != ObjectStatus.detected)
          _buildStatusOverlay(),
          
        // Optional tooltip
        if (showTooltip && object.confidence >= 0.5)
          _buildTooltip(category),
      ],
    );
  }

  ObjectIndicatorData _createIndicatorData(WasteCategory category) {
    return ObjectIndicatorData(
      category: category,
      centerPosition: transformedRect.center,
      confidence: object.confidence,
      type: _getIndicatorTypeForStatus(),
      categoryColor: _getColorForStatus(),
      objectInfo: object.codeName,
      trackingId: object.trackingId,
      detectedAt: DateTime.now(),
      showTooltip: showTooltip,
      isVisible: true,
      animationDuration: _getAnimationDurationForStatus(),
    );
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

  Color _getColorForStatus() {
    switch (status) {
      case ObjectStatus.carried:
        return Colors.green;
      case ObjectStatus.targeted:
        return Colors.orange;
      case ObjectStatus.detected:
        return object.overlayColor;
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

  Widget _buildTooltip(WasteCategory category) {
    return TooltipWidget(
      category: category,
      objectInfo: object.codeName,
      indicatorPosition: transformedRect.center,
      screenSize: screenSize ?? const Size(400, 800), // Use actual screen size or fallback
      isVisible: true,
      animationDuration: const Duration(milliseconds: 300),
      onTap: onTap,
    );
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
          color: object.overlayColor,
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
