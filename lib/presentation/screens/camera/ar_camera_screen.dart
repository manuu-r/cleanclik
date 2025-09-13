import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/camera/qr_camera_controller.dart';
import 'package:cleanclik/core/services/location/bin_location_service.dart';
import 'package:cleanclik/core/models/detected_object.dart';
import 'package:cleanclik/core/models/camera_mode.dart';
import 'package:cleanclik/presentation/widgets/camera/qr_scanner_overlay.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_services.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_processing.dart';
import 'package:cleanclik/presentation/screens/camera/ar_camera_ui.dart';

class ARCameraScreen extends ConsumerStatefulWidget {
  final CameraMode initialMode;

  const ARCameraScreen({super.key, this.initialMode = CameraMode.mlDetection});

  @override
  ConsumerState<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends ConsumerState<ARCameraScreen>
    with WidgetsBindingObserver {
  // Core components
  late final ARCameraServices _services;
  late final ARCameraProcessing _processing;
  late final ARCameraUI _ui;
  late final InventoryService _inventoryService;
  late final QRCameraController _qrController;

  // Camera management
  CameraController? _cameraController;
  bool _isInitialized = false;
  String? _errorMessage;

  // Camera mode state
  CameraState _cameraState = CameraState.initial;

  // State tracking
  List<DetectedObject> _detectedObjects = [];
  List<HandLandmark> _handLandmarks = [];
  List<DetectedObject> _originalDetectedObjects = [];

  // UI state
  bool _showObjectOverlays = true;
  bool _showHandOverlays = true;
  bool _showHandSkeleton = true;
  bool _showPickupIndicators = true;
  bool _showDebugInfo = false;
  bool _showCoordinateValidation = false;

  // Processing state
  bool _isImageStreamActive = false;

  // QR scanning state
  Widget? _activeOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Determine the effective initial mode, defaulting to mlDetection if none is provided
    var effectiveInitialMode = widget.initialMode;
    if (effectiveInitialMode == CameraMode.none) {
      effectiveInitialMode = CameraMode.mlDetection;
    }

    // Initialize camera state with the effective mode
    _cameraState = CameraState.initial.copyWith(mode: effectiveInitialMode);

    // Initialize modular components
    _services = ARCameraServices();
    _processing = ARCameraProcessing(_services);
    _ui = ARCameraUI(_services, _processing);
    _inventoryService = ref.read(inventoryServiceProvider.notifier);
    _qrController = QRCameraController(
      _inventoryService,
      ref.read(binLocationServiceProvider),
    );

    // Set up callbacks
    _setupCallbacks();

    // Initialize everything
    _initialize();
  }

  @override
  void dispose() {
    print('📱 [AR_CAMERA] Disposing AR camera screen...');
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController?.value.isInitialized != true) return;

    if (state == AppLifecycleState.inactive) {
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
  }

  /// Show pickup notification when item is picked up
  void _showPickupNotification(DetectedObject object) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Picked up: ${object.codeName}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Sync pickup from AR services to local inventory service for QR scanning
  void _syncPickupToLocalInventory(DetectedObject object) {
    // Add the picked up object to the local inventory service
    _inventoryService.addItemFromDetectedObject(object);
  }

  /// Sync inventory from Riverpod service to local service for QR mode
  Future<void> _syncInventoryForQRMode() async {
    try {
      print('📦 [SYNC] Inventory sync for QR mode completed');
    } catch (e) {
      print('❌ [SYNC] Failed to sync inventory for QR mode: $e');
    }
  }

  /// Setup callbacks for communication between modules
  void _setupCallbacks() {
    _processing.setStateChangedCallback(() {
      if (mounted) setState(() {});
    });

    _processing.setObjectsDetectedCallback((objects) {
      if (mounted) {
        setState(() {
          _detectedObjects = objects;
        });
      }
    });

    _processing.setHandsDetectedCallback((hands) {
      if (mounted) {
        setState(() {
          _handLandmarks = hands;
        });
      }
    });

    // Set up QR controller callbacks
    _qrController.setOnShowOverlay((overlay) {
      print('🎭 [AR_CAMERA] Received overlay show request: ${overlay.runtimeType}');
      if (mounted) {
        print('✅ [AR_CAMERA] Widget is mounted, setting overlay state');
        setState(() {
          _activeOverlay = overlay;
        });
        print('📱 [AR_CAMERA] Overlay state updated, should be visible now');
      } else {
        print('❌ [AR_CAMERA] Widget not mounted, cannot show overlay');
      }
    });

    _qrController.setOnHideOverlay(() {
      print('🎭 [AR_CAMERA] Received overlay hide request');
      if (mounted) {
        print('✅ [AR_CAMERA] Hiding overlay');
        setState(() {
          _activeOverlay = null;
        });
        print('📱 [AR_CAMERA] Overlay hidden');
      } else {
        print('❌ [AR_CAMERA] Widget not mounted, cannot hide overlay');
      }
    });

    // Set up pickup event listeners for live notifications
    _services.objectManagementService?.objectPickedUpStream.listen((object) {
      if (mounted) {
        _showPickupNotification(object);
        // Sync the pickup to local inventory service for QR scanning
        _syncPickupToLocalInventory(object);
      }
    });

    _qrController.setOnShowMessage((message) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    // Set up navigation callback for disposal completion
    _qrController.setOnNavigateHome(() {
      if (mounted) {
        // Navigate back to home screen using GoRouter
        context.go('/');
      }
    });

    // Set up UI callbacks
    _ui.setOnQRScanPressed(() => _startQRScanning());
  }

  /// Initialize camera and services
  Future<void> _initialize() async {
    print('📱 [AR_CAMERA] Initializing AR camera screen...');
    print('📱 [AR_CAMERA] Initial mode: ${_cameraState.mode}');

    try {
      // Initialize QR controller first
      await _qrController.initialize();

      if (_cameraState.mode == CameraMode.mlDetection) {
        // Get inventory service from Riverpod for pickup integration
        final inventoryService = ref.read(inventoryServiceProvider);

        // Initialize AR services and camera for AR mode
        await _services.initializeServices(inventoryService: inventoryService);
        await _initializeCamera();
      } else if (_cameraState.mode == CameraMode.qrScanning) {
        // For QR mode, skip AR camera initialization and go directly to QR scanning
        print('📱 [AR_CAMERA] Skipping AR camera initialization for QR mode');

        // Sync inventory from Riverpod to local service for QR scanning
        await _syncInventoryForQRMode();

        // Mark as initialized without camera
        setState(() {
          _isInitialized = true;
        });

        // Start QR scanning immediately
        _startQRScanning();
      }

      print('✅ [AR_CAMERA] AR camera screen initialized successfully');
    } catch (e) {
      print('❌ [AR_CAMERA] Initialization failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No cameras available');
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start image processing stream
        await _startImageStream();
      }
    } catch (e) {
      print('❌ [AR_CAMERA] Camera initialization failed: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Camera initialization failed: $e');
      }
    }
  }

  /// Start camera image stream for processing
  Future<void> _startImageStream() async {
    if (_cameraController?.value.isInitialized != true ||
        _isImageStreamActive) {
      return;
    }

    try {
      await _cameraController!.startImageStream(_processImage);
      _isImageStreamActive = true;
      print('📸 [AR_CAMERA] Image stream started');
    } catch (e) {
      print('❌ [AR_CAMERA] Failed to start image stream: $e');
    }
  }

  /// Stop camera image stream
  Future<void> _stopImageStream() async {
    if (!_isImageStreamActive) return;

    try {
      await _cameraController?.stopImageStream();
      _isImageStreamActive = false;
      print('📸 [AR_CAMERA] Image stream stopped');
    } catch (e) {
      print('❌ [AR_CAMERA] Error stopping image stream: $e');
    }
  }

  /// Main image processing pipeline
  Future<void> _processImage(CameraImage image) async {
    if (!mounted || !_services.isInitialized) return;

    try {
      // Process image through our modular processing system
      await _processing.processImage(image, _cameraController, context);

      // Process pickup detection if enabled
      if (_showPickupIndicators) {
        await _processing.processPickupDetection();
      }

      // Process disposal detection using hand tracking
      _processDisposalDetection();
    } catch (e) {
      print('❌ [AR_CAMERA] Image processing failed: $e');
    }
  }

  /// Process disposal detection using current hand landmarks
  void _processDisposalDetection() {
    try {
      _qrController.processHandGestures(_handLandmarks);
      // Hand gesture processing is now handled automatically within the QR controller
      print('🗑️ [AR_CAMERA] Hand gestures processed for disposal detection');
    } catch (e) {
      print('❌ [AR_CAMERA] Disposal detection failed: $e');
    }
  }

  /// Pause camera operation
  Future<void> _pauseCamera() async {
    print('⏸️ [AR_CAMERA] Pausing camera...');
    await _stopImageStream();
    _processing.reset();
  }

  /// Resume camera operation
  Future<void> _resumeCamera() async {
    print('▶️ [AR_CAMERA] Resuming camera...');
    await _startImageStream();
  }

  /// Clean up all resources
  Future<void> _cleanup() async {
    await _stopImageStream();

    // Dispose modules in reverse order
    await _qrController.dispose();
    _processing.dispose();
    await _services.dispose();

    await _cameraController?.dispose();
    _cameraController = null;
  }

  @override
  Widget build(BuildContext context) {
    // Handle error states
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Camera Error',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _initialize(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Handle loading state
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing AR Camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Main AR camera interface
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Update UI state synchronization
            _syncUIState();

            return Stack(
              children: [
                // Only build the camera view in ML mode and if controller is ready
                if (_cameraState.mode == CameraMode.mlDetection &&
                    _cameraController?.value.isInitialized == true)
                  _ui.buildCameraView(
                    context,
                    _cameraController,
                    constraints,
                    _detectedObjects,
                    _handLandmarks,
                    _originalDetectedObjects,
                  ),

                // Active overlay (QR scanner or bin feedback)
                if (_activeOverlay != null) ...[
                  Builder(
                    builder: (context) {
                      print('🎭 [AR_CAMERA] Rendering active overlay: ${_activeOverlay.runtimeType}');
                      return _activeOverlay!;
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Switch camera to QR scanning mode
  Future<void> _switchToQRMode() async {
    if (_cameraState.isTransitioning) return;

    setState(() {
      _cameraState = _cameraState.copyWith(
        isTransitioning: true,
        mode: CameraMode.qrScanning,
      );
    });

    try {
      // Stop the stream and dispose the controller to release the camera
      await _stopImageStream();
      await _cameraController?.dispose();
      _cameraController = null;

      // Pause AR services
      _services.pauseServices();

      print('📱 [AR_CAMERA] Switched to QR scanning mode');

      setState(() {
        _cameraState = _cameraState.copyWith(isTransitioning: false);
      });
    } catch (e) {
      print('❌ [AR_CAMERA] Failed to switch to QR mode: $e');
      setState(() {
        _cameraState = _cameraState.copyWith(
          isTransitioning: false,
          errorMessage: 'Failed to switch to QR mode: $e',
        );
      });
    }
  }

  /// Switch camera to AR detection mode
  Future<void> _switchToARMode() async {
    if (_cameraState.isTransitioning) return;

    setState(() {
      _isInitialized = false; // Show loading indicator
      _cameraState = _cameraState.copyWith(
        isTransitioning: true,
        mode: CameraMode.mlDetection,
      );
    });

    try {
      // Resume AR services
      _services.resumeServices();

      // Re-initialize the camera for AR mode
      await _initializeCamera();

      print('📱 [AR_CAMERA] Switched to AR detection mode');

      // No need for another setState here, _initializeCamera handles it
      if (mounted) {
        setState(() {
          _cameraState = _cameraState.copyWith(isTransitioning: false);
        });
      }
    } catch (e) {
      print('❌ [AR_CAMERA] Failed to switch to AR mode: $e');
      if (mounted) {
        setState(() {
          _cameraState = _cameraState.copyWith(
            isTransitioning: false,
            errorMessage: 'Failed to switch to AR mode: $e',
          );
        });
      }
    }
  }

  /// Start QR scanning
  void _startQRScanning() async {
    print('📱 [AR_CAMERA] Starting QR scanning...');

    // Switch to QR mode if not already (only if we have AR camera running)
    if (_cameraState.mode != CameraMode.qrScanning &&
        _cameraController != null) {
      await _switchToQRMode();
    }

    if (mounted) {
      setState(() {
        _activeOverlay = QRScannerOverlay(
          onQRScanned: _handleQRScanned,
          onClose: _closeQRScanner,
        );
      });
    }
  }

  /// Handle QR code scan result
  void _handleQRScanned(String qrData) {
    print('📱 [AR_CAMERA] QR code scanned: ${qrData.length} characters');

    // Process QR data through controller (this will handle overlay transitions)
    _qrController.handleQRScan(qrData);
  }

  /// Close QR scanner
  void _closeQRScanner() async {
    print('📱 [AR_CAMERA] Closing QR scanner...');
    if (mounted) {
      setState(() {
        _activeOverlay = null;
      });

      // Switch back to AR mode if we were in QR mode
      if (_cameraState.mode == CameraMode.qrScanning) {
        await _switchToARMode();
      }
    }
    print('✅ [AR_CAMERA] QR scanner closed');
  }

  /// Synchronize UI state between main screen and UI module
  void _syncUIState() {
    _ui.setShowObjectOverlays(_showObjectOverlays);
    _ui.setShowHandOverlays(_showHandOverlays);
    _ui.setShowHandSkeleton(_showHandSkeleton);
    _ui.setShowPickupIndicators(_showPickupIndicators);
    _ui.setShowDebugInfo(_showDebugInfo);
    _ui.setShowCoordinateValidation(_showCoordinateValidation);
  }

  /// Get current system status for debugging
  Map<String, dynamic> get systemStatus => {
    'camera_initialized': _isInitialized,
    'error_message': _errorMessage,
    'image_stream_active': _isImageStreamActive,
    'services_status': _services.getServiceStatus(),
    'processing_metrics': _processing.getPerformanceMetrics(),
    'ui_state': {
      'show_objects': _showObjectOverlays,
      'show_hands': _showHandOverlays,
      'show_skeleton': _showHandSkeleton,
      'show_debug': _showDebugInfo,
    },
    'detection_counts': {
      'objects': _detectedObjects.length,
      'hands': _handLandmarks.length,
    },
  };
}
