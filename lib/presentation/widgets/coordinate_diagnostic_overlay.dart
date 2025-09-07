import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import '../../core/services/hand_tracking_service.dart';
import '../../core/models/detected_object.dart';

/// Safe conversion helpers for debug overlays
String safeToInt(num value) {
  if (value.isNaN || value.isInfinite) return 'N/A';
  return value.toInt().toString();
}

String safeRatio(num numerator, num denominator) {
  if (denominator == 0 || numerator.isNaN || denominator.isNaN) return 'N/A';
  final ratio = numerator / denominator;
  if (ratio.isNaN || ratio.isInfinite) return 'N/A';
  return ratio.toStringAsFixed(2);
}

/// Coordinate diagnostic overlay for troubleshooting transformation issues
class CoordinateDiagnosticOverlay extends StatefulWidget {
  final List<HandLandmark> handLandmarks;
  final List<DetectedObject> detectedObjects;
  final Size cameraImageSize;
  final Size widgetSize;
  final CameraController? cameraController;
  final bool isVisible;

  const CoordinateDiagnosticOverlay({
    super.key,
    required this.handLandmarks,
    required this.detectedObjects,
    required this.cameraImageSize,
    required this.widgetSize,
    this.cameraController,
    required this.isVisible,
  });

  @override
  State<CoordinateDiagnosticOverlay> createState() =>
      _CoordinateDiagnosticOverlayState();
}

class _CoordinateDiagnosticOverlayState
    extends State<CoordinateDiagnosticOverlay> {
  bool _showGrid = true;
  bool _showCoordinateInfo = true;
  bool _showTransformationInfo = true;
  bool _showLandmarkCoords = true;
  bool _showBounds = true;
  int _selectedHandIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Stack(
      children: [
        // Grid and coordinate visualization
        if (_showGrid) _buildCoordinateGrid(),

        // Transformation info panel
        if (_showTransformationInfo) _buildTransformationInfoPanel(),

        // Coordinate info panel
        if (_showCoordinateInfo) _buildCoordinateInfoPanel(),

        // Landmark coordinate display
        if (_showLandmarkCoords) _buildLandmarkCoordinateDisplay(),

        // Bounds visualization
        if (_showBounds) _buildBoundsVisualization(),

        // Controls
        _buildControls(),
      ],
    );
  }

  Widget _buildCoordinateGrid() {
    return CustomPaint(
      size: widget.widgetSize,
      painter: CoordinateGridPainter(
        widgetSize: widget.widgetSize,
        cameraImageSize: widget.cameraImageSize,
        cameraController: widget.cameraController,
      ),
    );
  }

  Widget _buildTransformationInfoPanel() {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyan, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'COORDINATE TRANSFORMATION',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildTransformationDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransformationDetails() {
    if (widget.cameraController == null) {
      return const Text(
        'Camera controller not available',
        style: TextStyle(color: Colors.red, fontSize: 10),
      );
    }

    // Calculate transformation parameters
    final aspectRatioCamera = widget.cameraImageSize.height == 0
        ? double.nan
        : widget.cameraImageSize.width / widget.cameraImageSize.height;
    final aspectRatioWidget = widget.widgetSize.height == 0
        ? double.nan
        : widget.widgetSize.width / widget.widgetSize.height;
    final scaleX = widget.cameraImageSize.width == 0
        ? double.nan
        : widget.widgetSize.width / widget.cameraImageSize.width;
    final scaleY = widget.cameraImageSize.height == 0
        ? double.nan
        : widget.widgetSize.height / widget.cameraImageSize.height;
    final uniformScale = (scaleX.isNaN || scaleY.isNaN)
        ? double.nan
        : math.min(scaleX, scaleY);

    final scaledImageWidth = uniformScale.isNaN
        ? double.nan
        : widget.cameraImageSize.width * uniformScale;
    final scaledImageHeight = uniformScale.isNaN
        ? double.nan
        : widget.cameraImageSize.height * uniformScale;
    final offsetX = (scaledImageWidth.isNaN || widget.widgetSize.width.isNaN)
        ? double.nan
        : (widget.widgetSize.width - scaledImageWidth) / 2;
    final offsetY = (scaledImageHeight.isNaN || widget.widgetSize.height.isNaN)
        ? double.nan
        : (widget.widgetSize.height - scaledImageHeight) / 2;

    final sensorOrientation =
        widget.cameraController!.description.sensorOrientation;
    final deviceOrientation = widget.cameraController!.value.deviceOrientation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          'Camera Size',
          '${safeToInt(widget.cameraImageSize.width)}×${safeToInt(widget.cameraImageSize.height)}',
        ),
        _buildInfoRow(
          'Widget Size',
          '${safeToInt(widget.widgetSize.width)}×${safeToInt(widget.widgetSize.height)}',
        ),
        _buildInfoRow(
          'Aspect Ratio Camera',
          safeRatio(
            widget.cameraImageSize.width,
            widget.cameraImageSize.height,
          ),
        ),
        _buildInfoRow(
          'Aspect Ratio Widget',
          safeRatio(widget.widgetSize.width, widget.widgetSize.height),
        ),
        _buildInfoRow(
          'Scale X',
          scaleX.isNaN ? 'N/A' : scaleX.toStringAsFixed(3),
        ),
        _buildInfoRow(
          'Scale Y',
          scaleY.isNaN ? 'N/A' : scaleY.toStringAsFixed(3),
        ),
        _buildInfoRow(
          'Uniform Scale',
          uniformScale.isNaN ? 'N/A' : uniformScale.toStringAsFixed(3),
        ),
        _buildInfoRow(
          'Offset X',
          offsetX.isNaN ? 'N/A' : offsetX.toStringAsFixed(1),
        ),
        _buildInfoRow(
          'Offset Y',
          offsetY.isNaN ? 'N/A' : offsetY.toStringAsFixed(1),
        ),
        _buildInfoRow('Sensor Orient', '${sensorOrientation}°'),
        _buildInfoRow(
          'Device Orient',
          deviceOrientation.toString().split('.').last,
        ),
        _buildInfoRow(
          'Preview Area',
          '${safeToInt(scaledImageWidth)}×${safeToInt(scaledImageHeight)}',
        ),
      ],
    );
  }

  Widget _buildCoordinateInfoPanel() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'COORDINATE SPACES',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildCoordinateSpaceInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinateSpaceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Camera Image Space:',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Origin: (0,0) top-left\nRange: (0,0) to (${safeToInt(widget.cameraImageSize.width)},${safeToInt(widget.cameraImageSize.height)})',
          style: const TextStyle(color: Colors.white, fontSize: 9),
        ),
        const SizedBox(height: 6),
        const Text(
          'Normalized Space:',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Origin: (0,0) top-left\nRange: (0.0,0.0) to (1.0,1.0)',
          style: TextStyle(color: Colors.white, fontSize: 9),
        ),
        const SizedBox(height: 6),
        const Text(
          'Widget Space:',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Origin: (0,0) top-left\nRange: (0,0) to (${safeToInt(widget.widgetSize.width)},${safeToInt(widget.widgetSize.height)})',
          style: const TextStyle(color: Colors.white, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildLandmarkCoordinateDisplay() {
    if (widget.handLandmarks.isEmpty) return const SizedBox.shrink();

    final selectedHand = _selectedHandIndex < widget.handLandmarks.length
        ? widget.handLandmarks[_selectedHandIndex]
        : null;

    if (selectedHand == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 120,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 1),
        ),
        constraints: const BoxConstraints(maxHeight: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HAND ${_selectedHandIndex + 1} COORDINATES (${selectedHand.handedness})',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: _buildLandmarkList(selectedHand),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandmarkList(HandLandmark hand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show key landmarks only to save space
        _buildLandmarkRow('Wrist', 0, hand),
        _buildLandmarkRow('Thumb Tip', 4, hand),
        _buildLandmarkRow('Index Tip', 8, hand),
        _buildLandmarkRow('Middle Tip', 12, hand),
        _buildLandmarkRow('Ring Tip', 16, hand),
        _buildLandmarkRow('Pinky Tip', 20, hand),
        const SizedBox(height: 4),
        Text(
          'Bounding Box: ${hand.boundingBox.left.toInt()},${hand.boundingBox.top.toInt()} → ${hand.boundingBox.right.toInt()},${hand.boundingBox.bottom.toInt()}',
          style: const TextStyle(color: Colors.cyan, fontSize: 9),
        ),
        Text(
          'Size: ${hand.boundingBox.width.toInt()}×${hand.boundingBox.height.toInt()}',
          style: const TextStyle(color: Colors.cyan, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildLandmarkRow(String name, int index, HandLandmark hand) {
    if (index >= hand.landmarks.length ||
        index >= hand.normalizedLandmarks.length) {
      return Text(
        '$name: Invalid index $index',
        style: const TextStyle(color: Colors.red, fontSize: 8),
      );
    }

    final landmark = hand.landmarks[index];
    final normalized = hand.normalizedLandmarks[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$name: (${landmark.dx.toInt()},${landmark.dy.toInt()}) | N:(${normalized.dx.toStringAsFixed(3)},${normalized.dy.toStringAsFixed(3)})',
        style: const TextStyle(color: Colors.white, fontSize: 8),
      ),
    );
  }

  Widget _buildBoundsVisualization() {
    return CustomPaint(
      size: widget.widgetSize,
      painter: BoundsVisualizationPainter(
        handLandmarks: widget.handLandmarks,
        detectedObjects: widget.detectedObjects,
        widgetSize: widget.widgetSize,
        cameraImageSize: widget.cameraImageSize,
        cameraController: widget.cameraController,
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DIAGNOSTIC CONTROLS',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            _buildToggleRow(
              'Grid',
              _showGrid,
              (v) => setState(() => _showGrid = v),
            ),
            _buildToggleRow(
              'Coord Info',
              _showCoordinateInfo,
              (v) => setState(() => _showCoordinateInfo = v),
            ),
            _buildToggleRow(
              'Transform',
              _showTransformationInfo,
              (v) => setState(() => _showTransformationInfo = v),
            ),
            _buildToggleRow(
              'Landmarks',
              _showLandmarkCoords,
              (v) => setState(() => _showLandmarkCoords = v),
            ),
            _buildToggleRow(
              'Bounds',
              _showBounds,
              (v) => setState(() => _showBounds = v),
            ),
            if (widget.handLandmarks.length > 1) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Hand: ',
                    style: TextStyle(color: Colors.white, fontSize: 9),
                  ),
                  ...List.generate(
                    widget.handLandmarks.length,
                    (index) => GestureDetector(
                      onTap: () => setState(() => _selectedHandIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedHandIndex == index
                              ? Colors.purple
                              : Colors.transparent,
                          border: Border.all(color: Colors.purple, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: value ? Colors.purple : Colors.transparent,
                border: Border.all(color: Colors.purple, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: value
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 9),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 9)),
        ],
      ),
    );
  }
}

/// Custom painter for coordinate grid visualization
class CoordinateGridPainter extends CustomPainter {
  final Size widgetSize;
  final Size cameraImageSize;
  final CameraController? cameraController;

  CoordinateGridPainter({
    required this.widgetSize,
    required this.cameraImageSize,
    this.cameraController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawPreviewBounds(canvas, size);
    _drawOriginMarkers(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5;

    const gridSpacing = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center lines
    final centerPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.5)
      ..strokeWidth = 1;

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

  void _drawPreviewBounds(Canvas canvas, Size size) {
    if (cameraController == null) return;

    // Calculate actual preview bounds
    final scaleX = size.width / cameraImageSize.width;
    final scaleY = size.height / cameraImageSize.height;
    final uniformScale = math.min(scaleX, scaleY);

    final previewWidth = cameraImageSize.width * uniformScale;
    final previewHeight = cameraImageSize.height * uniformScale;
    final offsetX = (size.width - previewWidth) / 2;
    final offsetY = (size.height - previewHeight) / 2;

    final previewRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      previewWidth,
      previewHeight,
    );

    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(previewRect, paint);

    // Label the preview area
    final textPainter = TextPainter(
      text: TextSpan(
        text:
            'CAMERA PREVIEW AREA\n${previewWidth.toInt()}×${previewHeight.toInt()}',
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(offsetX + 5, offsetY + 5));
  }

  void _drawOriginMarkers(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Widget origin (0,0)
    canvas.drawCircle(const Offset(0, 0), 5, paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ORIGIN (0,0)',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for bounds visualization
class BoundsVisualizationPainter extends CustomPainter {
  final List<HandLandmark> handLandmarks;
  final List<DetectedObject> detectedObjects;
  final Size widgetSize;
  final Size cameraImageSize;
  final CameraController? cameraController;

  BoundsVisualizationPainter({
    required this.handLandmarks,
    required this.detectedObjects,
    required this.widgetSize,
    required this.cameraImageSize,
    this.cameraController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawHandBounds(canvas, size);
    _drawObjectBounds(canvas, size);
    _drawCoordinateProblems(canvas, size);
  }

  void _drawHandBounds(Canvas canvas, Size size) {
    for (int i = 0; i < handLandmarks.length; i++) {
      final hand = handLandmarks[i];

      // Draw bounding box
      final paint = Paint()
        ..color = (hand.handedness == 'Left' ? Colors.blue : Colors.red)
            .withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(hand.boundingBox, const Radius.circular(4)),
        paint,
      );

      // Draw landmark spread
      if (hand.landmarks.isNotEmpty) {
        double minX = hand.landmarks.first.dx;
        double maxX = hand.landmarks.first.dx;
        double minY = hand.landmarks.first.dy;
        double maxY = hand.landmarks.first.dy;

        for (final landmark in hand.landmarks) {
          minX = math.min(minX, landmark.dx);
          maxX = math.max(maxX, landmark.dx);
          minY = math.min(minY, landmark.dy);
          maxY = math.max(maxY, landmark.dy);
        }

        final landmarkBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
        final landmarkPaint = Paint()
          ..color = Colors.green.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawRect(landmarkBounds, landmarkPaint);
      }
    }
  }

  void _drawObjectBounds(Canvas canvas, Size size) {
    for (final object in detectedObjects) {
      final paint = Paint()
        ..color = Colors.orange.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRRect(
        RRect.fromRectAndRadius(object.boundingBox, const Radius.circular(2)),
        paint,
      );
    }
  }

  void _drawCoordinateProblems(Canvas canvas, Size size) {
    final problems = <String>[];

    for (final hand in handLandmarks) {
      // Check if landmarks are constrained to small area
      final boundingBox = hand.boundingBox;
      final area = boundingBox.width * boundingBox.height;
      final widgetArea = size.width * size.height;

      if (area < widgetArea * 0.01) {
        // Less than 1% of widget area
        problems.add(
          'Hand ${hand.handedness} constrained to ${(area / widgetArea * 100).toStringAsFixed(1)}% of widget area',
        );
      }

      // Check if coordinates are out of bounds
      int outOfBounds = 0;
      for (final landmark in hand.landmarks) {
        if (landmark.dx < 0 ||
            landmark.dx > size.width ||
            landmark.dy < 0 ||
            landmark.dy > size.height) {
          outOfBounds++;
        }
      }

      if (outOfBounds > 0) {
        problems.add(
          'Hand ${hand.handedness} has $outOfBounds landmarks out of bounds',
        );
      }
    }

    if (problems.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'COORDINATE PROBLEMS:\n${problems.join('\n')}',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Draw background
      final backgroundPaint = Paint()
        ..color = Colors.black.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width / 2 - textPainter.width / 2 - 10,
            size.height / 2 - textPainter.height / 2 - 10,
            textPainter.width + 20,
            textPainter.height + 20,
          ),
          const Radius.circular(8),
        ),
        backgroundPaint,
      );

      textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
