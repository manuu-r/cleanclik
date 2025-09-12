import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;

import 'package:cleanclik/core/models/camera_mode.dart';
import 'package:cleanclik/core/models/detected_object.dart' as app_models;
import 'package:cleanclik/core/providers/camera_provider.dart';
import 'package:cleanclik/core/services/camera/camera_resource_manager.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/neon_icon_button.dart';

/// ML Detection widget that integrates with the camera resource manager
class IntegratedMLDetection extends ConsumerStatefulWidget {
  final Function(List<app_models.DetectedObject>) onObjectsDetected;
  final VoidCallback? onClose;
  final bool showOverlay;

  const IntegratedMLDetection({
    super.key,
    required this.onObjectsDetected,
    this.onClose,
    this.showOverlay = true,
  });

  @override
  ConsumerState<IntegratedMLDetection> createState() =>
      _IntegratedMLDetectionState();
}

class _IntegratedMLDetectionState extends ConsumerState<IntegratedMLDetection> {
  CameraController? _cameraController;
  mlkit.ObjectDetector? _objectDetector;
  bool _isProcessing = false;
  bool _isImageStreamActive = false;
  List<app_models.DetectedObject> _detectedObjects = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMLDetection();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  /// Initialize ML detection through camera resource manager
  Future<void> _initializeMLDetection() async {
    try {
      // Use Future.microtask to avoid modifying provider during build
      await Future.microtask(() async {
        // Request camera for ML detection
        await ref.read(cameraNotifierProvider.notifier).switchToMLMode();

        // Initialize ML Kit object detector
        await _initializeObjectDetector();

        // Get camera controller from resource manager
        _cameraController = CameraResourceManager().activeController;

        if (_cameraController != null &&
            _cameraController!.value.isInitialized) {
          await _startImageStream();
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize ML detection: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Initialize ML Kit object detector
  Future<void> _initializeObjectDetector() async {
    try {
      final options = mlkit.ObjectDetectorOptions(
        mode: mlkit.DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      );

      _objectDetector = mlkit.ObjectDetector(options: options);
      debugPrint('ML Kit object detector initialized');
    } catch (e) {
      debugPrint('Failed to initialize object detector: $e');
      rethrow;
    }
  }

  /// Start camera image stream for ML processing
  Future<void> _startImageStream() async {
    if (_cameraController?.value.isInitialized != true ||
        _isImageStreamActive) {
      return;
    }

    try {
      await _cameraController!.startImageStream(_processImage);
      _isImageStreamActive = true;
      debugPrint('ML detection image stream started');
    } catch (e) {
      debugPrint('Failed to start ML detection image stream: $e');
      setState(() {
        _errorMessage = 'Failed to start image processing: $e';
      });
    }
  }

  /// Stop camera image stream
  Future<void> _stopImageStream() async {
    if (!_isImageStreamActive) return;

    try {
      await _cameraController?.stopImageStream();
      _isImageStreamActive = false;
      debugPrint('ML detection image stream stopped');
    } catch (e) {
      debugPrint('Error stopping ML detection image stream: $e');
    }
  }

  /// Process camera image for object detection
  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || _objectDetector == null) return;

    _isProcessing = true;

    try {
      // Convert camera image to InputImage for ML Kit
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return;

      // Detect objects
      final objects = await _objectDetector!.processImage(inputImage);

      // Convert ML Kit objects to our DetectedObject format
      final detectedObjects = _convertMLKitObjects(objects);

      if (mounted) {
        setState(() {
          _detectedObjects = detectedObjects;
        });

        // Notify callback
        widget.onObjectsDetected(detectedObjects);
      }
    } catch (e) {
      debugPrint('ML detection processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  mlkit.InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final camera = _cameraController!.description;
      final mlkit.InputImageRotation imageRotation =
          mlkit.InputImageRotationValue.fromRawValue(
            camera.sensorOrientation,
          ) ??
          mlkit.InputImageRotation.rotation0deg;

      final mlkit.InputImageFormat inputImageFormat =
          mlkit.InputImageFormatValue.fromRawValue(image.format.raw) ??
          mlkit.InputImageFormat.nv21;

      final metadata = mlkit.InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return mlkit.InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Convert ML Kit detected objects to our DetectedObject format
  List<app_models.DetectedObject> _convertMLKitObjects(
    List<mlkit.DetectedObject> mlkitObjects,
  ) {
    return mlkitObjects.map((obj) {
      // Convert ML Kit object to our app's DetectedObject format
      final label = obj.labels.isNotEmpty ? obj.labels.first.text : 'Unknown';
      final confidence = obj.labels.isNotEmpty
          ? obj.labels.first.confidence
          : 0.0;

      return app_models.DetectedObject(
        trackingId: obj.trackingId?.toString() ?? obj.hashCode.toString(),
        category: label,
        codeName: label.toUpperCase(),
        boundingBox: obj.boundingBox,
        confidence: confidence,
        detectedAt: DateTime.now(),
        overlayColor: Colors.green,
      );
    }).toList();
  }

  /// Clean up resources
  Future<void> _cleanup() async {
    await _stopImageStream();
    await _objectDetector?.close();
    _objectDetector = null;
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraStateProvider);

    // Handle camera errors
    if (cameraState.status == CameraStatus.error || _errorMessage != null) {
      return _buildErrorView(
        cameraState.errorMessage ??
            _errorMessage ??
            'ML detection error occurred',
      );
    }

    // Handle camera loading
    if (cameraState.status == CameraStatus.initializing ||
        cameraState.status == CameraStatus.switching) {
      return _buildLoadingView();
    }

    // Handle camera not ready
    if (!cameraState.isReady || cameraState.mode != CameraMode.mlDetection) {
      return _buildLoadingView();
    }

    return widget.showOverlay ? _buildOverlayView() : _buildDetectionView();
  }

  Widget _buildOverlayView() {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: SafeArea(
        child: Stack(
          children: [
            // Detection view
            _buildDetectionView(),

            // Overlay UI
            _buildOverlayUI(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionView() {
    if (_cameraController?.value.isInitialized != true) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(child: CameraPreview(_cameraController!)),

        // Object detection overlays
        ..._buildObjectOverlays(),
      ],
    );
  }

  List<Widget> _buildObjectOverlays() {
    if (_detectedObjects.isEmpty) return [];

    return _detectedObjects.map<Widget>((obj) {
      return Positioned(
        left: obj.boundingBox.left,
        top: obj.boundingBox.top,
        width: obj.boundingBox.width,
        height: obj.boundingBox.height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: NeonColors.electricGreen, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: NeonColors.electricGreen.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                '${obj.category} (${(obj.confidence * 100).toInt()}%)',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: NeonColors.electricGreen),
            const SizedBox(height: 16),
            Text(
              'Initializing ML Detection...',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Container(
      color: Colors.black,
      child: Center(
        child: GlassmorphismContainer(
          padding: const EdgeInsets.all(UIConstants.spacing6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: NeonColors.glowRed,
                size: 64,
              ),
              const SizedBox(height: UIConstants.spacing4),
              Text(
                'ML Detection Error',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: UIConstants.spacing2),
              Text(
                errorMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UIConstants.spacing4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeonIconButton.primary(
                    label: 'Retry',
                    color: Colors.green,
                    onTap: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _initializeMLDetection();
                    },
                    buttonSize: ButtonSize.medium,
                  ),
                  if (widget.onClose != null) ...[
                    const SizedBox(width: UIConstants.spacing2),
                    NeonIconButton.secondary(
                      label: 'Cancel',
                      color: Colors.grey,
                      onTap: widget.onClose,
                      buttonSize: ButtonSize.medium,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayUI(BuildContext context) {
    return Stack(
      children: [
        // Top bar with close button and title
        if (widget.onClose != null)
          Positioned(
            top: UIConstants.spacing4,
            left: UIConstants.spacing4,
            right: UIConstants.spacing4,
            child: GlassmorphismContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacing4,
                vertical: UIConstants.spacing2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Object Detection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  NeonIconButton(
                    icon: Icons.close,
                    color: Colors.white,
                    onTap: widget.onClose,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
          ),

        // Detection stats
        Positioned(
          bottom: UIConstants.spacing4,
          left: UIConstants.spacing4,
          right: UIConstants.spacing4,
          child: _buildDetectionStats(),
        ),
      ],
    );
  }

  Widget _buildDetectionStats() {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(UIConstants.spacing4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Objects Detected:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              Text(
                '${_detectedObjects.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NeonColors.electricGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_detectedObjects.isNotEmpty) ...[
            const SizedBox(height: UIConstants.spacing2),
            Text(
              'Point camera at objects to detect and classify them',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
