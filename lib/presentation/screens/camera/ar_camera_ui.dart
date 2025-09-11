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

import 'ar_camera_services.dart';
import 'ar_camera_processing.dart';

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
          ..._buildObjectOverlays(constraints, cameraController),

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
      // Top control bar
      _buildTopControlBar(context),

      // Bottom control bar
      _buildBottomControlBar(context),

      // Side control panel
      if (_showDebugInfo) _buildSideControlPanel(context),
    ];
  }

  /// Build top control bar with status indicators
  Widget _buildTopControlBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: GlassmorphismContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Service status indicators
            _buildServiceStatusIndicator(),

            // Processing status
            _buildProcessingStatusIndicator(),

            // Close button
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Build bottom control bar with toggle buttons
  Widget _buildBottomControlBar(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: GlassmorphismContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToggleButton(
              Icons.visibility,
              Icons.visibility_off,
              _showObjectOverlays,
              () => _showObjectOverlays = !_showObjectOverlays,
              'Objects',
            ),
            _buildToggleButton(
              Icons.pan_tool,
              Icons.pan_tool_outlined,
              _showHandSkeleton,
              () => _showHandSkeleton = !_showHandSkeleton,
              'Hands',
            ),
            _buildActionButton(
              Icons.qr_code_scanner,
              () => _onQRScanPressed?.call(),
              'QR Scan',
            ),
            _buildToggleButton(
              Icons.bug_report,
              Icons.bug_report_outlined,
              _showDebugInfo,
              () => _showDebugInfo = !_showDebugInfo,
              'Debug',
            ),
            _buildToggleButton(
              Icons.grid_on,
              Icons.grid_off,
              _showCoordinateValidation,
              () => _showCoordinateValidation = !_showCoordinateValidation,
              'Coords',
            ),
          ],
        ),
      ),
    );
  }

  /// Build side control panel for advanced options
  Widget _buildSideControlPanel(BuildContext context) {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).padding.top + 80,
      child: GlassmorphismContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildControlPanelButton(
              Icons.refresh,
              'Restart Services',
              () => _services.restartServices(),
            ),
            const SizedBox(height: 8),
            _buildControlPanelButton(
              Icons.cleaning_services,
              'Reset Processing',
              () => _processing.reset(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build service status indicator
  Widget _buildServiceStatusIndicator() {
    final serviceCount =
        _services.getServiceStatus()['service_info']['total_services'] as int;
    final color = _services.hasFullARCapabilities
        ? NeonColors.electricGreen
        : _services.hasCoreServices
        ? NeonColors.solarYellow
        : NeonColors.glowRed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.settings, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$serviceCount',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build processing status indicator
  Widget _buildProcessingStatusIndicator() {
    final isProcessing = _processing.isProcessing;
    final color = isProcessing ? NeonColors.oceanBlue : Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isProcessing)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        else
          Icon(Icons.pause, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '${_processing.detectedObjects.length + _processing.handLandmarks.length}',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build toggle button for UI controls
  Widget _buildToggleButton(
    IconData activeIcon,
    IconData inactiveIcon,
    bool isActive,
    VoidCallback onTap,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            isActive ? activeIcon : inactiveIcon,
            color: isActive ? NeonColors.electricGreen : Colors.grey,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive ? NeonColors.electricGreen : Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Build action button for UI controls
  Widget _buildActionButton(IconData icon, VoidCallback? onTap, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: onTap != null ? NeonColors.oceanBlue : Colors.grey,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: onTap != null ? NeonColors.oceanBlue : Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Build control panel button
  Widget _buildControlPanelButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
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
