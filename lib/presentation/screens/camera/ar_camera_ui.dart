import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanclik/core/models/detected_object.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/services/business/object_management_service.dart'
    show ObjectStatus;

import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/presentation/widgets/camera/enhanced_object_overlay.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/camera/hand_skeleton_painter.dart';
import 'package:cleanclik/presentation/widgets/camera/coordinate_debug_widget.dart';
import 'package:cleanclik/presentation/widgets/camera/coordinate_diagnostic_overlay.dart';

import 'package:cleanclik/presentation/screens/camera/ar_camera_services.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_processing.dart';

/// Manages UI building and overlay rendering for AR camera
class ARCameraUI {
  final ARCameraServices _services;
  final ARCameraProcessing _processing;

  // UI state
  bool _showObjectOverlays = true;
  bool _showHandOverlays = true;
  bool _showHandSkeleton = true;
  bool _showPickupIndicators = true;
  bool _showDebugInfo = false;
  bool _showCoordinateValidation = false;

  // UI configuration
  static const double _overlayOpacity = 0.8;
  static const Duration _animationDuration = Duration(milliseconds: 300);

  // Callbacks
  VoidCallback? _onQRScanPressed;

  ARCameraUI(this._services, this._processing);

  // Getters for UI state
  bool get showObjectOverlays => _showObjectOverlays;
  bool get showHandOverlays => _showHandOverlays;
  bool get showHandSkeleton => _showHandSkeleton;
  bool get showPickupIndicators => _showPickupIndicators;
  bool get showDebugInfo => _showDebugInfo;
  bool get showCoordinateValidation => _showCoordinateValidation;

  // Setters for UI state
  void setShowObjectOverlays(bool show) => _showObjectOverlays = show;
  void setShowHandOverlays(bool show) => _showHandOverlays = show;
  void setShowHandSkeleton(bool show) => _showHandSkeleton = show;
  void setShowPickupIndicators(bool show) => _showPickupIndicators = show;
  void setShowDebugInfo(bool show) => _showDebugInfo = show;
  void setShowCoordinateValidation(bool show) =>
      _showCoordinateValidation = show;

  // Callback setters
  void setOnQRScanPressed(VoidCallback? callback) =>
      _onQRScanPressed = callback;

  /// Build main AR camera view with all overlays
  Widget buildCameraView(
    BuildContext context,
    CameraController? cameraController,
    BoxConstraints constraints,
    List<DetectedObject> detectedObjects,
    List<HandLandmark> handLandmarks,
    List<DetectedObject> originalDetectedObjects,
  ) {
    return Stack(
      children: [
        // Camera preview
        _buildCameraPreview(cameraController),

        // Object overlays
        if (_showObjectOverlays)
          ..._buildObjectOverlays(context, constraints, cameraController),

        // Hand overlays
        if (_showHandOverlays) ..._buildHandOverlays(constraints),

        // Hand skeleton overlay with proper coordinate handling
        if (_showHandSkeleton && handLandmarks.isNotEmpty)
          _buildHandSkeletonOverlay(cameraController, constraints),

        // Pickup indicators
        if (_showPickupIndicators) ..._buildPickupIndicators(constraints),

        // Debug overlay
        if (_showDebugInfo)
          _buildDebugOverlay(
            context,
            constraints,
            handLandmarks,
            originalDetectedObjects,
            detectedObjects,
            cameraController,
          ),

        // Coordinate validation overlay
        if (_showCoordinateValidation)
          _buildCoordinateValidationOverlay(
            constraints,
            handLandmarks,
            detectedObjects,
            cameraController,
          ),

        // Control overlays
        ..._buildControlOverlays(context),
      ],
    );
  }

  /// Build camera preview widget
  Widget _buildCameraPreview(CameraController? cameraController) {
    return Positioned.fill(
      child: cameraController != null
          ? CameraPreview(cameraController)
          : Container(color: Colors.black),
    );
  }

  /// Build object detection overlays
  List<Widget> _buildObjectOverlays(
    BuildContext context,
    BoxConstraints constraints,
    CameraController? cameraController,
  ) {
    final objects = _processing.detectedObjects;

    // Building object overlays for ${objects.length} objects

    if (cameraController == null || !cameraController.value.isInitialized) {
      return [];
    }

    return objects.map((obj) {
      final transformedRect = _services.mlService!.transformBoundingBox(
        obj.boundingBox,
        constraints,
        cameraController,
      );
      return EnhancedObjectOverlay(
        object: obj,
        status: ObjectStatus.detected,
        transformedRect: transformedRect,
        showTooltip: true,
        screenSize: MediaQuery.of(context).size,
      );
    }).toList();
  }

  /// Build hand detection overlays
  List<Widget> _buildHandOverlays(BoxConstraints constraints) {
    final hands = _processing.handLandmarks;

    // Building hand overlays for ${hands.length} hands

    return hands.asMap().entries.map((entry) {
      final index = entry.key;
      final hand = entry.value;

      return Positioned.fill(
        child: AnimatedOpacity(
          opacity: _overlayOpacity,
          duration: _animationDuration,
          child: CustomPaint(
            painter: _HandVisualizationPainter(
              hand: hand,
              index: index,
              showNumbers: _showCoordinateValidation,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Build hand skeleton overlay
  Widget _buildHandSkeletonOverlay(
    CameraController? cameraController,
    BoxConstraints constraints,
  ) {
    if (cameraController == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: HandOverlayWidget(
        hands: _processing.handLandmarks,
        previewSize: cameraController.value.previewSize!,
        lensDirection: cameraController.description.lensDirection,
        sensorOrientation: cameraController.description.sensorOrientation,
        showSkeleton: true,
        showLandmarkNumbers: _showCoordinateValidation,
        showConfidence: true,
      ),
    );
  }

  /// Build pickup detection indicators
  List<Widget> _buildPickupIndicators(BoxConstraints constraints) {
    if (!_services.hasObjectManagementService) {
      return [];
    }

    final objectManagement = _services.objectManagementService!;
    final carriedObjects = objectManagement.carriedObjects;

    // Show pickup notifications for recently picked up items
    return [
      if (carriedObjects.isNotEmpty)
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.greenAccent, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Carrying ${carriedObjects.length} item${carriedObjects.length == 1 ? '' : 's'}: ${carriedObjects.map((obj) => obj.codeName).join(', ')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  /// Build debug information overlay with geometric analysis
  Widget _buildDebugOverlay(
    BuildContext context,
    BoxConstraints constraints,
    List<HandLandmark> handLandmarks,
    List<DetectedObject> originalDetectedObjects,
    List<DetectedObject> filteredObjects,
    CameraController? cameraController,
  ) {
    // Fallback to original debug overlay
    return Positioned.fill(
      child: CoordinateDebugWidget(
        handLandmarks: handLandmarks,
        detectedObjects: originalDetectedObjects,
        filteredObjects: filteredObjects,
        cameraImageSize: Size(_processing.imageWidth, _processing.imageHeight),
        widgetSize: Size(constraints.maxWidth, constraints.maxHeight),
        cameraController: cameraController,
        debugInfo: _getDebugInfo(),
      ),
    );
  }

  /// Build coordinate validation overlay
  Widget _buildCoordinateValidationOverlay(
    BoxConstraints constraints,
    List<HandLandmark> handLandmarks,
    List<DetectedObject> detectedObjects,
    CameraController? cameraController,
  ) {
    return Positioned.fill(
      child: CoordinateDiagnosticOverlay(
        handLandmarks: handLandmarks,
        detectedObjects: detectedObjects,
        cameraImageSize: Size(_processing.imageWidth, _processing.imageHeight),
        widgetSize: Size(constraints.maxWidth, constraints.maxHeight),
        cameraController: cameraController,
        isVisible: _showCoordinateValidation,
      ),
    );
  }

  /// Build control overlays (buttons, panels, etc.)
  List<Widget> _buildControlOverlays(BuildContext context) {
    return [
      // Close button in top right
      _buildCloseButton(context),

      // QR scanning button
      _buildQRScanButton(context),
    ];
  }

  /// Build close button with circular background in top right
  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.6),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Build QR scanning button with highlighting when objects are picked up
  Widget _buildQRScanButton(BuildContext context) {
    // Check if there are carried objects to highlight the button
    final hasCarriedObjects = _services.hasObjectManagementService &&
        _services.objectManagementService!.carriedObjects.isNotEmpty;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 32,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR scanning button
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasCarriedObjects 
                    ? NeonColors.electricGreen.withOpacity(0.9)
                    : Colors.black.withOpacity(0.6),
                border: Border.all(
                  color: hasCarriedObjects 
                      ? NeonColors.electricGreen
                      : Colors.white.withOpacity(0.3),
                  width: hasCarriedObjects ? 3 : 1,
                ),
                boxShadow: hasCarriedObjects ? [
                  BoxShadow(
                    color: NeonColors.electricGreen.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: IconButton(
                onPressed: _onQRScanPressed,
                icon: Icon(
                  Icons.qr_code_scanner,
                  color: hasCarriedObjects ? Colors.black : Colors.white,
                  size: 32,
                ),
              ),
            ),
            
            // Label text
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                hasCarriedObjects ? 'Scan Bin to Dispose' : 'Scan Bin',
                style: TextStyle(
                  color: hasCarriedObjects ? NeonColors.electricGreen : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// Get debug information
  Map<String, dynamic> _getDebugInfo() {
    return {
      'services': _services.getServiceStatus(),
      'processing': _processing.getPerformanceMetrics(),
      'ui_state': {
        'show_objects': _showObjectOverlays,
        'show_hands': _showHandOverlays,
        'show_skeleton': _showHandSkeleton,
        'show_debug': _showDebugInfo,
        'show_validation': _showCoordinateValidation,
      },
    };
  }
}

/// Custom painter for hand visualization
class _HandVisualizationPainter extends CustomPainter {
  final HandLandmark hand;
  final int index;
  final bool showNumbers;

  _HandVisualizationPainter({
    required this.hand,
    required this.index,
    this.showNumbers = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Simple hand visualization - just key points
    final paint = Paint()
      ..color = index == 0 ? Colors.blue : Colors.red
      ..style = PaintingStyle.fill;

    // Draw key landmarks
    final keyLandmarks = [0, 4, 8, 12, 16, 20]; // Wrist and fingertips

    for (final landmarkIndex in keyLandmarks) {
      if (landmarkIndex < hand.landmarks.length) {
        final landmark = hand.landmarks[landmarkIndex];
        canvas.drawCircle(landmark, 6, paint);

        if (showNumbers) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: landmarkIndex.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(landmark.dx - 5, landmark.dy - 15));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
