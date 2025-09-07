import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../core/services/hand_tracking_service.dart';
import '../../core/models/detected_object.dart';

/// Debug widget for visualizing coordinate transformations and hand filtering
class CoordinateDebugWidget extends StatefulWidget {
  final List<HandLandmark> handLandmarks;
  final List<DetectedObject> detectedObjects;
  final List<DetectedObject> filteredObjects;
  final Size cameraImageSize;
  final Size widgetSize;
  final CameraController? cameraController;
  final Map<String, dynamic> debugInfo;

  const CoordinateDebugWidget({
    super.key,
    required this.handLandmarks,
    required this.detectedObjects,
    required this.filteredObjects,
    required this.cameraImageSize,
    required this.widgetSize,
    this.cameraController,
    this.debugInfo = const {},
  });

  @override
  State<CoordinateDebugWidget> createState() => _CoordinateDebugWidgetState();
}

class _CoordinateDebugWidgetState extends State<CoordinateDebugWidget> {
  bool _showHandExclusionZones = true;
  bool _showObjectBoundingBoxes = true;
  bool _showCoordinateGrid = false;
  bool _showTransformationInfo = true;
  bool _showPerformanceMetrics = false;
  bool _showHandLandmarks = true;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 10,
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_isExpanded) ...[
              _buildToggleControls(),
              if (_showTransformationInfo) _buildTransformationInfo(),
              if (_showPerformanceMetrics) _buildPerformanceMetrics(),
              _buildObjectInfo(),
              _buildHandInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.bug_report_outlined, color: Colors.cyan, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Coordinate Debug',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'H:${widget.handLandmarks.length} O:${widget.detectedObjects.length}→${widget.filteredObjects.length}',
              style: const TextStyle(color: Colors.cyan, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildToggle('Hand Exclusion', _showHandExclusionZones, (value) {
            setState(() => _showHandExclusionZones = value);
          }),
          _buildToggle('Object Boxes', _showObjectBoundingBoxes, (value) {
            setState(() => _showObjectBoundingBoxes = value);
          }),
          _buildToggle('Grid', _showCoordinateGrid, (value) {
            setState(() => _showCoordinateGrid = value);
          }),
          _buildToggle('Transform Info', _showTransformationInfo, (value) {
            setState(() => _showTransformationInfo = value);
          }),
          _buildToggle('Performance', _showPerformanceMetrics, (value) {
            setState(() => _showPerformanceMetrics = value);
          }),
          _buildToggle('Hand Points', _showHandLandmarks, (value) {
            setState(() => _showHandLandmarks = value);
          }),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? Colors.cyan.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? Colors.cyan : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: value ? Colors.cyan : Colors.grey,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildTransformationInfo() {
    final transformDebug =
        widget.debugInfo['coordinate_transformer_debug']
            as Map<String, dynamic>? ??
        {};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coordinate Transformation',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            'Camera Size',
            '${widget.cameraImageSize.width.toInt()}×${widget.cameraImageSize.height.toInt()}',
          ),
          _buildInfoRow(
            'Widget Size',
            '${widget.widgetSize.width.toInt()}×${widget.widgetSize.height.toInt()}',
          ),
          if (widget.cameraController != null) ...[
            _buildInfoRow(
              'Sensor Orient',
              '${widget.cameraController!.description.sensorOrientation}°',
            ),
            _buildInfoRow(
              'Device Orient',
              widget.cameraController!.value.deviceOrientation
                  .toString()
                  .split('.')
                  .last,
            ),
          ],
          _buildInfoRow(
            'Cache Hit',
            transformDebug['has_cached_matrix']?.toString() ?? 'Unknown',
          ),
          if (transformDebug.isNotEmpty) ...[
            _buildInfoRow(
              'Exclusion Zones',
              '${transformDebug['persistent_exclusion_zones_count'] ?? 0}',
            ),
            _buildInfoRow(
              'Hand History',
              '${transformDebug['hand_detection_history_count'] ?? 0}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final enhancedMLDebug =
        widget.debugInfo['enhanced_ml_debug'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            'Frame Skip Count',
            '${enhancedMLDebug['frame_skip_count'] ?? 0}',
          ),
          _buildInfoRow(
            'Temporal Objects',
            '${enhancedMLDebug['temporal_detections'] ?? 0}',
          ),
          _buildInfoRow(
            'Recent Detections',
            '${enhancedMLDebug['has_recent_detections'] ?? false}',
          ),
          _buildInfoRow(
            'ML Initialized',
            '${enhancedMLDebug['initialized'] ?? false}',
          ),
          _buildInfoRow(
            'Currently Detecting',
            '${enhancedMLDebug['detecting'] ?? false}',
          ),
        ],
      ),
    );
  }

  Widget _buildObjectInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objects (${widget.detectedObjects.length}→${widget.filteredObjects.length})',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Show filtered out objects
          if (widget.detectedObjects.length >
              widget.filteredObjects.length) ...[
            Text(
              'Filtered out: ${widget.detectedObjects.length - widget.filteredObjects.length} objects',
              style: const TextStyle(color: Colors.red, fontSize: 10),
            ),
            const SizedBox(height: 2),
          ],
          // Show remaining objects
          ...widget.filteredObjects
              .take(3)
              .map(
                (obj) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${obj.codeName}: ${(obj.confidence * 100).toInt()}% at (${obj.boundingBox.center.dx.toInt()}, ${obj.boundingBox.center.dy.toInt()})',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          if (widget.filteredObjects.length > 3)
            Text(
              '... and ${widget.filteredObjects.length - 3} more',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildHandInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hands (${widget.handLandmarks.length})',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...widget.handLandmarks.map(
            (hand) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${hand.handedness}: ${(hand.confidence * 100).toInt()}% at (${hand.boundingBox.center.dx.toInt()}, ${hand.boundingBox.center.dy.toInt()})',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay painter for visualizing coordinate transformations and exclusions
class CoordinateDebugPainter extends CustomPainter {
  final List<HandLandmark> handLandmarks;
  final List<DetectedObject> detectedObjects;
  final List<DetectedObject> filteredObjects;
  final bool showHandExclusionZones;
  final bool showObjectBoundingBoxes;
  final bool showCoordinateGrid;
  final bool showHandLandmarks;
  final Size canvasSize;

  CoordinateDebugPainter({
    required this.handLandmarks,
    required this.detectedObjects,
    required this.filteredObjects,
    required this.showHandExclusionZones,
    required this.showObjectBoundingBoxes,
    required this.showCoordinateGrid,
    required this.showHandLandmarks,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw coordinate grid
    if (showCoordinateGrid) {
      _drawCoordinateGrid(canvas, size);
    }

    // Draw hand exclusion zones
    if (showHandExclusionZones) {
      _drawHandExclusionZones(canvas);
    }

    // Draw object bounding boxes
    if (showObjectBoundingBoxes) {
      _drawObjectBoundingBoxes(canvas);
    }

    // Draw hand landmarks
    if (showHandLandmarks) {
      _drawHandLandmarks(canvas);
    }
  }

  void _drawCoordinateGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSpacing = 50.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw center lines
    final centerPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  void _drawHandExclusionZones(Canvas canvas) {
    final exclusionPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final hand in handLandmarks) {
      // Draw expanded exclusion zone
      const exclusionPadding = 60.0;
      final exclusionRect = Rect.fromLTRB(
        hand.boundingBox.left - exclusionPadding,
        hand.boundingBox.top - exclusionPadding,
        hand.boundingBox.right + exclusionPadding,
        hand.boundingBox.bottom + exclusionPadding,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(exclusionRect, const Radius.circular(8)),
        exclusionPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(exclusionRect, const Radius.circular(8)),
        borderPaint,
      );

      // Draw hand bounding box
      final handPaint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(hand.boundingBox, const Radius.circular(4)),
        handPaint,
      );
    }
  }

  void _drawObjectBoundingBoxes(Canvas canvas) {
    // Draw all detected objects (including filtered ones)
    for (final obj in detectedObjects) {
      final isFiltered = !filteredObjects.contains(obj);

      final paint = Paint()
        ..color = isFiltered
            ? Colors.red.withOpacity(0.8) // Filtered objects in red
            : Colors.green.withOpacity(0.8) // Kept objects in green
        ..strokeWidth = isFiltered ? 3 : 2
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(obj.boundingBox, const Radius.circular(4)),
        paint,
      );

      // Draw confidence and category
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${obj.codeName}\n${(obj.confidence * 100).toInt()}%',
          style: TextStyle(
            color: isFiltered ? Colors.red : Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          obj.boundingBox.left,
          obj.boundingBox.top - textPainter.height - 2,
        ),
      );
    }
  }

  void _drawHandLandmarks(Canvas canvas) {
    final landmarkPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final connectionPaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final hand in handLandmarks) {
      // Draw landmark points
      for (final landmark in hand.landmarks) {
        if (landmark != Offset.zero) {
          canvas.drawCircle(landmark, 3, landmarkPaint);
        }
      }

      // Draw hand skeleton connections (simplified)
      if (hand.landmarks.length >= 21) {
        _drawHandSkeleton(canvas, hand.landmarks, connectionPaint);
      }

      // Draw hand center
      final centerPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;

      canvas.drawCircle(hand.boundingBox.center, 5, centerPaint);

      // Draw handedness label
      final textPainter = TextPainter(
        text: TextSpan(
          text: hand.handedness,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          hand.boundingBox.center.dx - textPainter.width / 2,
          hand.boundingBox.bottom + 5,
        ),
      );
    }
  }

  void _drawHandSkeleton(Canvas canvas, List<Offset> landmarks, Paint paint) {
    // MediaPipe hand connections (simplified key connections)
    final connections = [
      [0, 1], [1, 2], [2, 3], [3, 4], // Thumb
      [0, 5], [5, 6], [6, 7], [7, 8], // Index
      [0, 17], [5, 9], [9, 10], [10, 11], [11, 12], // Middle
      [9, 13], [13, 14], [14, 15], [15, 16], // Ring
      [13, 17], [17, 18], [18, 19], [19, 20], // Pinky
    ];

    for (final connection in connections) {
      if (connection[0] < landmarks.length &&
          connection[1] < landmarks.length) {
        final start = landmarks[connection[0]];
        final end = landmarks[connection[1]];

        if (start != Offset.zero && end != Offset.zero) {
          canvas.drawLine(start, end, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for debugging
  }
}

/// Widget that overlays the debug painter on the camera preview
class CoordinateDebugOverlay extends StatelessWidget {
  final List<HandLandmark> handLandmarks;
  final List<DetectedObject> detectedObjects;
  final List<DetectedObject> filteredObjects;
  final bool showHandExclusionZones;
  final bool showObjectBoundingBoxes;
  final bool showCoordinateGrid;
  final bool showHandLandmarks;
  final Size canvasSize;

  const CoordinateDebugOverlay({
    super.key,
    required this.handLandmarks,
    required this.detectedObjects,
    required this.filteredObjects,
    required this.showHandExclusionZones,
    required this.showObjectBoundingBoxes,
    required this.showCoordinateGrid,
    required this.showHandLandmarks,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CoordinateDebugPainter(
        handLandmarks: handLandmarks,
        detectedObjects: detectedObjects,
        filteredObjects: filteredObjects,
        showHandExclusionZones: showHandExclusionZones,
        showObjectBoundingBoxes: showObjectBoundingBoxes,
        showCoordinateGrid: showCoordinateGrid,
        showHandLandmarks: showHandLandmarks,
        canvasSize: canvasSize,
      ),
      child:
          Container(), // Transparent child to make CustomPaint cover entire area
    );
  }
}
