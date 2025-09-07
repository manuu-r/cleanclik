import 'package:flutter/material.dart';
import '../../core/models/detected_object.dart';
import '../../core/services/object_management_service.dart';

class EnhancedObjectOverlay extends StatelessWidget {
  final DetectedObject object;
  final ObjectStatus status;
  final Rect transformedRect;

  const EnhancedObjectOverlay({
    super.key,
    required this.object,
    required this.status,
    required this.transformedRect,
  });

  @override
  Widget build(BuildContext context) {
    final colorData = _getColorData();

    return Positioned(
      left: transformedRect.left,
      top: transformedRect.top,
      child: Container(
        width: transformedRect.width,
        height: transformedRect.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorData.color,
            width: colorData.borderWidth,
          ),
          borderRadius: BorderRadius.circular(8),
          color: colorData.color.withOpacity(0.2),
          boxShadow: status == ObjectStatus.carried
              ? [
                  BoxShadow(
                    color: colorData.color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(colorData), _buildContent(colorData)],
        ),
      ),
    );
  }

  Widget _buildHeader(ObjectColorData colorData) {
    return Container(
      decoration: BoxDecoration(
        color: colorData.color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (colorData.emoji.isNotEmpty) ...[
            Text(colorData.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Text(
            object.category.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ObjectColorData colorData) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              object.codeName,
              style: TextStyle(
                color: colorData.color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${(object.confidence * 100).toInt()}%',
              style: TextStyle(color: colorData.color, fontSize: 9),
            ),
            if (colorData.statusText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                colorData.statusText,
                style: TextStyle(
                  color: colorData.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ObjectColorData _getColorData() {
    switch (status) {
      case ObjectStatus.carried:
        return ObjectColorData(
          color: Colors.green,
          borderWidth: 4.0,
          emoji: '🚚',
          statusText: 'CARRYING',
        );
      case ObjectStatus.targeted:
        return ObjectColorData(
          color: Colors.orange,
          borderWidth: 3.5,
          emoji: '🎯',
          statusText: 'TARGETED',
        );
      case ObjectStatus.detected:
        return ObjectColorData(
          color: object.overlayColor,
          borderWidth: 3.0,
          emoji: '',
          statusText: '',
        );
    }
  }
}

class ObjectColorData {
  final Color color;
  final double borderWidth;
  final String emoji;
  final String statusText;

  ObjectColorData({
    required this.color,
    required this.borderWidth,
    required this.emoji,
    required this.statusText,
  });
}
