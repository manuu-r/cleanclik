import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';

/// Hand skeleton connections based on MediaPipe hand topology
class HandConnections {
  // Thumb connections
  static const List<List<int>> thumb = [
    [HandLandmarkIndex.wrist, HandLandmarkIndex.thumbCmc],
    [HandLandmarkIndex.thumbCmc, HandLandmarkIndex.thumbMcp],
    [HandLandmarkIndex.thumbMcp, HandLandmarkIndex.thumbIp],
    [HandLandmarkIndex.thumbIp, HandLandmarkIndex.thumbTip],
  ];

  // Index finger connections
  static const List<List<int>> indexFinger = [
    [HandLandmarkIndex.wrist, HandLandmarkIndex.indexFingerMcp],
    [HandLandmarkIndex.indexFingerMcp, HandLandmarkIndex.indexFingerPip],
    [HandLandmarkIndex.indexFingerPip, HandLandmarkIndex.indexFingerDip],
    [HandLandmarkIndex.indexFingerDip, HandLandmarkIndex.indexFingerTip],
  ];

  // Middle finger connections
  static const List<List<int>> middleFinger = [
    [HandLandmarkIndex.wrist, HandLandmarkIndex.middleFingerMcp],
    [HandLandmarkIndex.middleFingerMcp, HandLandmarkIndex.middleFingerPip],
    [HandLandmarkIndex.middleFingerPip, HandLandmarkIndex.middleFingerDip],
    [HandLandmarkIndex.middleFingerDip, HandLandmarkIndex.middleFingerTip],
  ];

  // Ring finger connections
  static const List<List<int>> ringFinger = [
    [HandLandmarkIndex.wrist, HandLandmarkIndex.ringFingerMcp],
    [HandLandmarkIndex.ringFingerMcp, HandLandmarkIndex.ringFingerPip],
    [HandLandmarkIndex.ringFingerPip, HandLandmarkIndex.ringFingerDip],
    [HandLandmarkIndex.ringFingerDip, HandLandmarkIndex.ringFingerTip],
  ];

  // Pinky finger connections
  static const List<List<int>> pinky = [
    [HandLandmarkIndex.wrist, HandLandmarkIndex.pinkyMcp],
    [HandLandmarkIndex.pinkyMcp, HandLandmarkIndex.pinkyPip],
    [HandLandmarkIndex.pinkyPip, HandLandmarkIndex.pinkyDip],
    [HandLandmarkIndex.pinkyDip, HandLandmarkIndex.pinkyTip],
  ];

  // Palm connections (between MCP joints)
  static const List<List<int>> palm = [
    [HandLandmarkIndex.indexFingerMcp, HandLandmarkIndex.middleFingerMcp],
    [HandLandmarkIndex.middleFingerMcp, HandLandmarkIndex.ringFingerMcp],
    [HandLandmarkIndex.ringFingerMcp, HandLandmarkIndex.pinkyMcp],
  ];

  // All connections combined
  static const List<List<int>> all = [
    ...thumb,
    ...indexFinger,
    ...middleFinger,
    ...ringFinger,
    ...pinky,
    ...palm,
  ];
}

/// Custom painter for rendering hand skeleton with MediaPipe landmarks
class HandSkeletonPainter extends CustomPainter {
  final List<HandLandmark> hands;
  final bool showLandmarkNumbers;
  final bool showConfidence;
  final double landmarkRadius;
  final double connectionStrokeWidth;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;
  final ARThemeExtension arTheme;

  HandSkeletonPainter({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
    required this.arTheme,
    this.showLandmarkNumbers = false,
    this.showConfidence = true,
    this.landmarkRadius = 2.0,
    this.connectionStrokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty) return;

    final scale = size.width / previewSize.height;

    canvas.save();

    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sensorOrientation * math.pi / 180);

    if (lensDirection == CameraLensDirection.front) {
      canvas.scale(-1, 1);
      canvas.rotate(math.pi);
    }

    canvas.scale(scale);

    for (int handIndex = 0; handIndex < hands.length; handIndex++) {
      final hand = hands[handIndex];
      _drawHand(canvas, hand, handIndex, scale);
    }

    canvas.restore();

    if (showConfidence) {
      for (int handIndex = 0; handIndex < hands.length; handIndex++) {
        final hand = hands[handIndex];
        _drawHandInfo(canvas, hand, handIndex, size);
      }
    }
  }

  void _drawHand(
    Canvas canvas,
    HandLandmark hand,
    int handIndex,
    double scale,
  ) {
    final confidenceAlpha = (hand.confidence * 255).clamp(150, 255).toInt();

    final connectionPaint = Paint()
      ..strokeWidth = connectionStrokeWidth / scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = arTheme.neonAccent.withAlpha(confidenceAlpha);
    _drawConnections(canvas, hand, connectionPaint, scale);

    _drawLandmarks(canvas, hand, confidenceAlpha, scale);
  }

  Offset _transformLandmark(Offset landmark) {
    // Follow official hand_landmarker example coordinate transformation
    final logicalWidth = previewSize.width;
    final logicalHeight = previewSize.height;

    final dx = (landmark.dx - 0.5) * logicalWidth;
    final dy = (landmark.dy - 0.5) * logicalHeight;

    return Offset(dx, dy);
  }

  void _drawConnections(
    Canvas canvas,
    HandLandmark hand,
    Paint paint,
    double scale,
  ) {
    const double separation = 1.5;

    for (final connection in HandConnections.all) {
      if (connection.length == 2) {
        final startIndex = connection[0];
        final endIndex = connection[1];

        if (startIndex < hand.landmarks.length &&
            endIndex < hand.landmarks.length) {
          final startLandmark = hand.landmarks[startIndex];
          final endLandmark = hand.landmarks[endIndex];

          final startPoint = _transformLandmark(startLandmark);
          final endPoint = _transformLandmark(endLandmark);

          final dx = endPoint.dx - startPoint.dx;
          final dy = endPoint.dy - startPoint.dy;
          final length = math.sqrt(dx * dx + dy * dy);

          if (length == 0) continue;

          final offsetX = -dy / length * separation / scale;
          final offsetY = dx / length * separation / scale;

          final p1Start = Offset(
            startPoint.dx + offsetX,
            startPoint.dy + offsetY,
          );
          final p1End = Offset(endPoint.dx + offsetX, endPoint.dy + offsetY);

          final p2Start = Offset(
            startPoint.dx - offsetX,
            startPoint.dy - offsetY,
          );
          final p2End = Offset(endPoint.dx - offsetX, endPoint.dy - offsetY);

          canvas.drawLine(p1Start, p1End, paint);
          canvas.drawLine(p2Start, p2End, paint);
        }
      }
    }
  }

  void _drawLandmarks(
    Canvas canvas,
    HandLandmark hand,
    int alpha,
    double scale,
  ) {
    final landmarkPaint = Paint()
      ..color = arTheme.neonAccent.withAlpha(alpha)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < hand.landmarks.length; i++) {
      final landmark = hand.landmarks[i];
      final transformedPoint = _transformLandmark(landmark);

      canvas.drawCircle(
        transformedPoint,
        landmarkRadius / scale,
        landmarkPaint,
      );

      if (showLandmarkNumbers) {
        _drawLandmarkNumber(canvas, transformedPoint, i, alpha, scale);
      }
    }
  }

  void _drawLandmarkNumber(
    Canvas canvas,
    Offset landmark,
    int number,
    int alpha,
    double scale,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: TextStyle(
          color: Colors.white.withAlpha(alpha),
          fontSize: 10 / scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position text slightly offset from landmark
    final textOffset = Offset(
      landmark.dx - textPainter.width / 2,
      landmark.dy - textPainter.height / 2 - (landmarkRadius + 8) / scale,
    );

    textPainter.paint(canvas, textOffset);
  }

  void _drawHandInfo(
    Canvas canvas,
    HandLandmark hand,
    int handIndex,
    Size canvasSize,
  ) {
    final infoText =
        '${hand.handedness} Hand ${handIndex + 1}\n'
        'Confidence: ${(hand.confidence * 100).toStringAsFixed(1)}%\n'
        'Handedness: ${(hand.handednessConfidence * 100).toStringAsFixed(1)}%';

    final textPainter = TextPainter(
      text: TextSpan(
        text: infoText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position info text at top-left corner, offset by hand index
    final infoOffset = Offset(10, 10 + (handIndex * 60));

    // Draw background
    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha(128)
      ..style = PaintingStyle.fill;

    final backgroundRect = Rect.fromLTWH(
      infoOffset.dx - 5,
      infoOffset.dy - 5,
      textPainter.width + 10,
      textPainter.height + 10,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
      backgroundPaint,
    );

    textPainter.paint(canvas, infoOffset);
  }

  @override
  bool shouldRepaint(covariant HandSkeletonPainter oldDelegate) {
    return hands != oldDelegate.hands ||
        showLandmarkNumbers != oldDelegate.showLandmarkNumbers ||
        showConfidence != oldDelegate.showConfidence ||
        landmarkRadius != oldDelegate.landmarkRadius ||
        connectionStrokeWidth != oldDelegate.connectionStrokeWidth ||
        previewSize != oldDelegate.previewSize ||
        lensDirection != oldDelegate.lensDirection ||
        sensorOrientation != oldDelegate.sensorOrientation ||
        arTheme != oldDelegate.arTheme;
  }
}

/// Widget that overlays hand skeleton on camera preview
class HandOverlayWidget extends StatelessWidget {
  final List<HandLandmark> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;
  final bool showSkeleton;
  final bool showLandmarkNumbers;
  final bool showConfidence;

  const HandOverlayWidget({
    super.key,
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
    this.showSkeleton = true,
    this.showLandmarkNumbers = false,
    this.showConfidence = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showSkeleton || hands.isEmpty) {
      return const SizedBox.shrink();
    }

    final arTheme = Theme.of(context).arTheme;

    return CustomPaint(
      size: Size.infinite,
      painter: HandSkeletonPainter(
        hands: hands,
        previewSize: previewSize,
        lensDirection: lensDirection,
        sensorOrientation: sensorOrientation,
        arTheme: arTheme,
        showLandmarkNumbers: showLandmarkNumbers,
        showConfidence: showConfidence,
      ),
    );
  }
}

/// Smooth interpolation helper for reducing jitter
class HandLandmarkInterpolator {
  static const double _smoothingFactor = 0.3; // Reduced for faster response
  List<HandLandmark>? _previousHands;

  List<HandLandmark> interpolate(List<HandLandmark> currentHands) {
    // Early exit for first run or count mismatch
    if (_previousHands == null ||
        _previousHands!.length != currentHands.length) {
      _previousHands = currentHands;
      return currentHands;
    }

    // Early exit if no significant change (performance optimization)
    if (_hasMinimalChange(currentHands, _previousHands!)) {
      return _previousHands!;
    }

    final interpolatedHands = <HandLandmark>[];

    for (int i = 0; i < currentHands.length; i++) {
      final current = currentHands[i];
      final previous = i < _previousHands!.length
          ? _previousHands![i]
          : current;

      final interpolatedLandmarks = <Offset>[];
      final interpolatedNormalizedLandmarks = <Offset>[];

      for (int j = 0; j < current.landmarks.length; j++) {
        final currentLandmark = current.landmarks[j];
        final previousLandmark = j < previous.landmarks.length
            ? previous.landmarks[j]
            : currentLandmark;

        // Smooth interpolation
        final interpolatedLandmark = Offset(
          previousLandmark.dx * _smoothingFactor +
              currentLandmark.dx * (1 - _smoothingFactor),
          previousLandmark.dy * _smoothingFactor +
              currentLandmark.dy * (1 - _smoothingFactor),
        );

        interpolatedLandmarks.add(interpolatedLandmark);

        // Also interpolate normalized landmarks
        if (j < current.normalizedLandmarks.length &&
            j < previous.normalizedLandmarks.length) {
          final currentNormalized = current.normalizedLandmarks[j];
          final previousNormalized = previous.normalizedLandmarks[j];

          final interpolatedNormalized = Offset(
            previousNormalized.dx * _smoothingFactor +
                currentNormalized.dx * (1 - _smoothingFactor),
            previousNormalized.dy * _smoothingFactor +
                currentNormalized.dy * (1 - _smoothingFactor),
          );

          interpolatedNormalizedLandmarks.add(interpolatedNormalized);
        }
      }

      // Optimized bounding box calculation
      final interpolatedBoundingBox = _calculateOptimizedBoundingBox(
        interpolatedLandmarks,
      );

      interpolatedHands.add(
        HandLandmark(
          landmarks: interpolatedLandmarks,
          normalizedLandmarks: interpolatedNormalizedLandmarks,
          confidence: current.confidence,
          boundingBox: interpolatedBoundingBox,
          handedness: current.handedness,
          handednessConfidence: current.handednessConfidence,
        ),
      );
    }

    _previousHands = interpolatedHands;
    return interpolatedHands;
  }

  void reset() {
    _previousHands = null;
  }

  void dispose() {
    reset();
  }

  /// Check if the change between current and previous hands is minimal
  bool _hasMinimalChange(
    List<HandLandmark> current,
    List<HandLandmark> previous,
  ) {
    const double threshold = 0.005; // 0.5% change threshold

    for (int i = 0; i < current.length && i < previous.length; i++) {
      final currentLandmarks = current[i].landmarks;
      final previousLandmarks = previous[i].landmarks;

      for (
        int j = 0;
        j < currentLandmarks.length && j < previousLandmarks.length;
        j++
      ) {
        final currentLandmark = currentLandmarks[j];
        final previousLandmark = previousLandmarks[j];

        final deltaX = (currentLandmark.dx - previousLandmark.dx).abs();
        final deltaY = (currentLandmark.dy - previousLandmark.dy).abs();

        if (deltaX > threshold || deltaY > threshold) {
          return false;
        }
      }
    }
    return true;
  }

  /// Optimized bounding box calculation
  Rect _calculateOptimizedBoundingBox(List<Offset> landmarks) {
    if (landmarks.isEmpty) return Rect.zero;

    double minX = landmarks[0].dx;
    double maxX = landmarks[0].dx;
    double minY = landmarks[0].dy;
    double maxY = landmarks[0].dy;

    // Unroll loop for better performance with known 21 landmarks
    for (int i = 1; i < landmarks.length; i++) {
      final landmark = landmarks[i];
      if (landmark.dx < minX)
        minX = landmark.dx;
      else if (landmark.dx > maxX)
        maxX = landmark.dx;
      if (landmark.dy < minY)
        minY = landmark.dy;
      else if (landmark.dy > maxY)
        maxY = landmark.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
