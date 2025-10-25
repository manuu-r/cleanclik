import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/business/pickup_service.dart';
import 'package:cleanclik/core/services/business/user_service.dart';
import 'package:cleanclik/core/services/camera/qr_camera_controller.dart';
import 'package:cleanclik/core/services/location/bin_location_service.dart';
import 'package:cleanclik/core/models/camera_models.dart';
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
  QRCameraController? _qrController;
  // Subscription for pickup events - attached after services are initialized
  StreamSubscription<PickupEvent>? _pickupSubscription;

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

    // Set up callbacks for components that are already initialized
    _setupInitialCallbacks();

    // Initialize everything asynchronously
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    try {
      final binLocationService = await ref.read(
        binLocationServiceProvider.future,
      );
      final userService = ref.read(userServiceProvider.notifier);
      _qrController = QRCameraController(
        _inventoryService,
        binLocationService,
        userService,
      );

      // Set up QR controller callbacks now that it's initialized
      _setupQRControllerCallbacks();

      // Now initialize everything
      _initialize();
    } catch (e) {
      print('Error initializing AR camera: $e');
    }
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
  void _showPickupNotification(ItemPickedUpEvent event) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Picked up: ${event.codeName}'),
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
  void _syncPickupToLocalInventory(ItemPickedUpEvent event) {
    // Add the picked up item to the local inventory service
    _inventoryService.addItemFromPickupEvent(event);
  }

  /// Sync inventory from Riverpod service to local service for QR mode
  Future<void> _syncInventoryForQRMode() async {
    try {
      print('📦 [SYNC] Inventory sync for QR mode completed');
    } catch (e) {
      print('❌ [SYNC] Failed to sync inventory for QR mode: $e');
    }
  }

  /// Setup callbacks for components that are already initialized
  void _setupInitialCallbacks() {
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

    // Pickup event listener is attached after services initialize to ensure
    // the pickup service instance exists and eventsStream is available.
    // Set up UI callbacks
    _ui.setOnQRScanPressed(() => _startQRScanning());
  }

  /// Setup callbacks for QR controller after it's initialized
  void _setupQRControllerCallbacks() {
    final qrController = _qrController;
    if (qrController == null) return;

    // Set up QR controller callbacks
    qrController.setOnShowOverlay((overlay) {
      print(
        '🎭 [AR_CAMERA] Received overlay show request: ${overlay.runtimeType}',
      );
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

    qrController.setOnHideOverlay(() {
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

    qrController.setOnShowMessage((message) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    // Set up navigation callback for disposal completion
    qrController.setOnNavigateHome(() {
      if (mounted) {
        // Navigate back to home screen using GoRouter
        context.go('/');
      }
    });
  }

  /// Initialize camera and services
  Future<void> _initialize() async {
    print('📱 [AR_CAMERA] Initializing AR camera screen...');
    print('📱 [AR_CAMERA] Initial mode: ${_cameraState.mode}');

    try {
      // Initialize QR controller first
      await _qrController?.initialize();

      // Initialize AR services and camera for AR mode
      if (_cameraState.mode == CameraMode.mlDetection) {
        // Get inventory service from Riverpod for pickup integration
        final inventoryService = ref.read(inventoryServiceProvider);

        // Initialize AR services and camera for AR mode
        await _services.initializeServices(inventoryService: inventoryService);

        // Attach pickup event listener now that services are initialized.
        // This ensures we don't listen on a null service and allows us to
        // cancel the subscription during cleanup.
        _pickupSubscription = _services.pickupService?.eventsStream.listen((
          event,
        ) {
          if (mounted && event is ItemPickedUpEvent) {
            _showPickupNotification(event);
            // Sync the pickup to local inventory service for QR scanning
            _syncPickupToLocalInventory(event);
          }
        });

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

  /// Initialize camera with enhanced resource management
  Future<void> _initializeCamera() async {
    print('📷 [AR_CAMERA] Initializing camera...');

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      // Ensure any existing controller is properly disposed
      if (_cameraController != null) {
        await _disposeCameraController();
      }

      // Create new camera controller with optimized settings
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      // Initialize with timeout to prevent hanging
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Camera initialization timeout',
            const Duration(seconds: 10),
          );
        },
      );

      print('✅ [AR_CAMERA] Camera controller initialized');

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null; // Clear any previous errors
        });

        // Start image processing stream with delay to ensure controller is ready
        await Future.delayed(const Duration(milliseconds: 100));
        await _startImageStream();
      }
    } catch (e) {
      print('❌ [AR_CAMERA] Camera initialization failed: $e');

      // Clean up failed controller
      if (_cameraController != null) {
        try {
          await _cameraController!.dispose();
        } catch (disposeError) {
          print(
            '⚠️ [AR_CAMERA] Error disposing failed controller: $disposeError',
          );
        }
        _cameraController = null;
      }

      if (mounted) {
        setState(() {
          _isInitialized = false;
          _errorMessage = 'Camera initialization failed: $e';
        });
      }

      rethrow;
    }
  }

  /// Start camera image stream for processing with resource conflict handling
  Future<void> _startImageStream() async {
    if (_cameraController?.value.isInitialized != true ||
        _isImageStreamActive) {
      return;
    }

    print('📸 [AR_CAMERA] Starting image stream...');

    try {
      // Check if camera is still available before starting stream
      if (!_cameraController!.value.isInitialized) {
        throw Exception('Camera controller not initialized');
      }

      await _cameraController!.startImageStream(_processImage);
      _isImageStreamActive = true;
      print('✅ [AR_CAMERA] Image stream started successfully');
    } catch (e) {
      print('❌ [AR_CAMERA] Failed to start image stream: $e');
      _isImageStreamActive = false;

      // Handle specific camera resource conflicts
      if (e.toString().contains('already streaming') ||
          e.toString().contains('resource busy')) {
        print(
          '🔧 [AR_CAMERA] Camera resource conflict detected, attempting recovery...',
        );
        await _handleCameraResourceConflict();
      } else {
        // For other errors, mark camera as having an error
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to start camera stream: $e';
          });
        }
      }
    }
  }

  /// Handle camera resource conflicts
  Future<void> _handleCameraResourceConflict() async {
    print('🔧 [AR_CAMERA] Handling camera resource conflict...');

    try {
      // Stop any existing stream first
      await _stopImageStream();

      // Wait a bit for resources to be released
      await Future.delayed(const Duration(milliseconds: 200));

      // Try to restart the stream
      if (_cameraController?.value.isInitialized == true && mounted) {
        await _cameraController!.startImageStream(_processImage);
        _isImageStreamActive = true;
        print('✅ [AR_CAMERA] Camera resource conflict resolved');
      }
    } catch (e) {
      print('❌ [AR_CAMERA] Failed to resolve camera resource conflict: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera resource conflict: $e';
        });
      }
    }
  }

  /// Stop camera image stream with enhanced buffer management
  Future<void> _stopImageStream() async {
    if (!_isImageStreamActive ||
        _cameraController?.value.isInitialized != true) {
      return;
    }

    print('📸 [AR_CAMERA] Stopping image stream...');

    try {
      // Add timeout to prevent hanging on stream stop
      await _cameraController!.stopImageStream().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('⚠️ [AR_CAMERA] Image stream stop timed out');
          throw TimeoutException(
            'Image stream stop timeout',
            const Duration(seconds: 2),
          );
        },
      );

      _isImageStreamActive = false;
      print('✅ [AR_CAMERA] Image stream stopped successfully');

      // Add small delay to allow buffer cleanup
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      print('❌ [AR_CAMERA] Error stopping image stream: $e');
      _isImageStreamActive = false;

      // Force reset stream state even if stop failed
      if (e is TimeoutException) {
        print('🔧 [AR_CAMERA] Force resetting stream state due to timeout');
      }
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
    } catch (e) {
      print('❌ [AR_CAMERA] Image processing failed: $e');
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

  /// Clean up all resources with proper timeout handling
  Future<void> _cleanup() async {
    print('🧹 [AR_CAMERA] Starting comprehensive cleanup...');

    // Stop image stream first to prevent buffer overflow
    await _stopImageStream();

    // Cancel pickup subscription if attached
    if (_pickupSubscription != null) {
      try {
        await _pickupSubscription!.cancel();
        _pickupSubscription = null;
        print('🧹 [AR_CAMERA] Pickup event subscription cancelled');
      } catch (e) {
        print('⚠️ [AR_CAMERA] Error cancelling pickup subscription: $e');
      }
    }

    // Dispose modules in reverse order with timeout handling
    final List<Future> disposalTasks = [];

    // QR controller disposal with timeout
    if (_qrController != null) {
      disposalTasks.add(
        _qrController!
            .dispose()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                print('⚠️ [AR_CAMERA] QR controller disposal timed out');
              },
            )
            .catchError((e) {
              print('⚠️ [AR_CAMERA] QR controller disposal error: $e');
            }),
      );
    }

    // Processing disposal
    try {
      _processing.dispose();
      print('✅ [AR_CAMERA] Processing module disposed');
    } catch (e) {
      print('⚠️ [AR_CAMERA] Processing disposal error: $e');
    }

    // Services disposal with timeout
    disposalTasks.add(
      _services
          .dispose()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⚠️ [AR_CAMERA] Services disposal timed out');
            },
          )
          .catchError((e) {
            print('⚠️ [AR_CAMERA] Services disposal error: $e');
          }),
    );

    // Camera controller disposal with enhanced error handling
    if (_cameraController != null) {
      disposalTasks.add(
        _disposeCameraController()
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                print('⚠️ [AR_CAMERA] Camera controller disposal timed out');
                _cameraController = null;
              },
            )
            .catchError((e) {
              print('⚠️ [AR_CAMERA] Camera controller disposal error: $e');
              _cameraController = null;
            }),
      );
    }

    // Wait for all disposal tasks to complete
    try {
      await Future.wait(disposalTasks);
      print('✅ [AR_CAMERA] All disposal tasks completed');
    } catch (e) {
      print('⚠️ [AR_CAMERA] Some disposal tasks failed: $e');
    }

    print('✅ [AR_CAMERA] Comprehensive cleanup completed');
  }

  /// Dispose camera controller with proper resource cleanup
  Future<void> _disposeCameraController() async {
    final controller = _cameraController;
    if (controller == null) return;

    print('📷 [AR_CAMERA] Disposing camera controller...');

    try {
      // Ensure image stream is stopped before disposal
      if (_isImageStreamActive) {
        await controller.stopImageStream();
        _isImageStreamActive = false;
        print('📸 [AR_CAMERA] Image stream stopped before disposal');
      }

      // Add small delay to ensure stream is fully stopped
      await Future.delayed(const Duration(milliseconds: 100));

      // Dispose the controller
      await controller.dispose();
      _cameraController = null;

      print('✅ [AR_CAMERA] Camera controller disposed successfully');
    } catch (e) {
      print('❌ [AR_CAMERA] Camera controller disposal failed: $e');
      _cameraController = null;
      rethrow;
    }
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
                      print(
                        '🎭 [AR_CAMERA] Rendering active overlay: ${_activeOverlay.runtimeType}',
                      );
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

  /// Switch camera to QR scanning mode with proper resource management
  Future<void> _switchToQRMode() async {
    if (_cameraState.isTransitioning) return;

    print('🔄 [AR_CAMERA] Switching to QR scanning mode...');

    setState(() {
      _cameraState = _cameraState.copyWith(
        isTransitioning: true,
        mode: CameraMode.qrScanning,
      );
    });

    try {
      // Stop the stream first to prevent buffer issues
      await _stopImageStream();

      // Pause AR services before disposing camera
      _services.pauseServices();

      // Dispose the camera controller with proper cleanup
      if (_cameraController != null) {
        await _disposeCameraController();
      }

      print('✅ [AR_CAMERA] Successfully switched to QR scanning mode');

      if (mounted) {
        setState(() {
          _cameraState = _cameraState.copyWith(isTransitioning: false);
        });
      }
    } catch (e) {
      print('❌ [AR_CAMERA] Failed to switch to QR mode: $e');
      if (mounted) {
        setState(() {
          _cameraState = _cameraState.copyWith(
            isTransitioning: false,
            errorMessage: 'Failed to switch to QR mode: $e',
          );
        });
      }
    }
  }

  /// Switch camera to AR detection mode with proper resource initialization
  Future<void> _switchToARMode() async {
    if (_cameraState.isTransitioning) return;

    print('🔄 [AR_CAMERA] Switching to AR detection mode...');

    setState(() {
      _isInitialized = false; // Show loading indicator
      _cameraState = _cameraState.copyWith(
        isTransitioning: true,
        mode: CameraMode.mlDetection,
      );
    });

    try {
      // Resume AR services first
      _services.resumeServices();

      // Wait a bit for services to be ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Re-initialize the camera for AR mode with retry logic
      await _initializeCameraWithRetry();

      print('✅ [AR_CAMERA] Successfully switched to AR detection mode');

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

  /// Initialize camera with retry logic for resource conflicts
  Future<void> _initializeCameraWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _initializeCamera();
        return; // Success, exit retry loop
      } catch (e) {
        print(
          '❌ [AR_CAMERA] Camera initialization attempt $attempt failed: $e',
        );

        if (attempt < maxRetries) {
          // Wait before retrying, with exponential backoff
          final delay = Duration(milliseconds: 200 * attempt);
          print(
            '⏳ [AR_CAMERA] Retrying camera initialization in ${delay.inMilliseconds}ms...',
          );
          await Future.delayed(delay);
        } else {
          // Final attempt failed, rethrow the error
          throw Exception(
            'Camera initialization failed after $maxRetries attempts: $e',
          );
        }
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
    _qrController?.handleQRScan(qrData);
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
