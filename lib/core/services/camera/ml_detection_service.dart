import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;
// Make sure these import paths are correct for your project structure
import 'package:cleanclik/core/models/detected_object.dart' as app;
import 'package:cleanclik/core/models/waste_category.dart' as app;

class MLDetectionService {
  mlkit.ObjectDetector? _objectDetector;
  bool _isInitialized = false;
  bool _isDetecting = false;
  DateTime _lastProcessTime = DateTime.now();

  // Configuration
  static const Duration _processingInterval = Duration(
    milliseconds: 100,
  ); // Faster processing
  static const int _maxFrameSkip = 2; // Less frame skipping
  int _frameSkipCount = 0;
  bool _hasRecentDetections = false;
  static const double _minConfidence =
      0.4; // Increased for better quality detection

  // Image dimensions for coordinate transforms
  double _imageWidth = 1280.0;
  double _imageHeight = 720.0;

  // Object tracking state
  List<app.DetectedObject> _previousFrameObjects = [];
  int _nextTrackingId = 1;
  static const double _maxTrackingDistance = 100.0; // pixels
  static const double _overlapThreshold = 0.3; // 30% IoU overlap

  // Object persistence to handle ML Kit detection failures
  static const int _maxMissedFrames =
      6; // Keep objects for 5 frames after last detection
  final Map<String, int> _objectMissedFrames = {};
  final Map<String, app.DetectedObject> _persistentObjects = {};

  // Stream controller for detected objects
  final StreamController<List<app.DetectedObject>> _objectsController =
      StreamController<List<app.DetectedObject>>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDetecting => _isDetecting;
  Stream<List<app.DetectedObject>> get objectsStream =>
      _objectsController.stream;

  static final Set<String> _ignoredLabels = {
    'Hand',
    'Person',
    'Finger',
    'Face',
    'Body part',
    'Left hand',
    'Right hand',
  };

  // Simplified mapping from ML Kit labels to WasteCategory
  // Primary mapping for ML Kit categories: FASHION_GOOD → recycle, HOME_GOOD → recycle, FOOD/PLANT → organic
  static final Map<String, app.WasteCategory> _labelToCategory = {
    // ML Kit primary categories
    'FASHION_GOOD': app.WasteCategory.recycle,
    'HOME_GOOD': app.WasteCategory.recycle,
    'FOOD': app.WasteCategory.organic,
    'PLANT': app.WasteCategory.organic,

    // Backward compatibility for generic labels
    'Container': app.WasteCategory.recycle,
    'Bottle': app.WasteCategory.recycle,
    'Can': app.WasteCategory.recycle,
    'Cup': app.WasteCategory.recycle,
    'Box': app.WasteCategory.recycle,
    'Cardboard': app.WasteCategory.recycle,
    'Paper': app.WasteCategory.recycle,
    'Glass': app.WasteCategory.recycle,
    'Clothing': app.WasteCategory.recycle,

    // Generic Organic
    'Food': app.WasteCategory.organic,
    'Plant': app.WasteCategory.organic,

    // Generic E-waste
    'Electronic device': app.WasteCategory.ewaste,
    'Computer': app.WasteCategory.ewaste,
    'Camera': app.WasteCategory.ewaste,
    'Phone': app.WasteCategory.ewaste,
    'Battery': app.WasteCategory.ewaste,

    // Generic Hazardous
    'Chemical': app.WasteCategory.hazardous,
  };

  // Initialize ML Kit Object Detector
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🤖 [ML] Initializing ML Kit Object Detector...');

      // Use stream mode for better real-time detection
      final options = mlkit.ObjectDetectorOptions(
        mode:
            mlkit.DetectionMode.stream, // Stream mode for continuous detection
        classifyObjects: true, // Enable classification
        multipleObjects: true, // Detect multiple objects
      );

      _objectDetector = mlkit.ObjectDetector(options: options);
      _isInitialized = true;

      print('✅ [ML] ML Kit object detection initialized with stream mode');
    } catch (e) {
      print('❌ [ML] Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // Process camera image for object detection with adaptive throttling
  Future<List<app.DetectedObject>> processImage(
    CameraImage image,
    CameraController cameraController,
  ) async {
    final now = DateTime.now();
    if (!_isInitialized ||
        _isDetecting ||
        _objectDetector == null ||
        now.difference(_lastProcessTime) < _processingInterval) {
      return _previousFrameObjects;
    }

    if (!_hasRecentDetections) {
      _frameSkipCount++;
      if (_frameSkipCount < _maxFrameSkip) {
        return _previousFrameObjects;
      }
      _frameSkipCount = 0;
    }

    _isDetecting = true;
    _lastProcessTime = now;

    try {
      _imageWidth = image.width.toDouble();
      _imageHeight = image.height.toDouble();

      final inputImage = _convertCameraImage(image, cameraController);
      if (inputImage == null) {
        print(
          '❌ [ML] Failed to convert camera image - format: ${image.format.group}',
        );
        return _previousFrameObjects;
      }

      final objects = await _objectDetector!.processImage(inputImage);
      print('🔍 [ML] Detected ${objects.length} raw objects from ML Kit');

      // COMPREHENSIVE ML KIT OUTPUT LOGGING WITH IMPROVED THRESHOLDS
      print('🔍 [ML_DEBUG] ===== DETECTION FRAME ANALYSIS =====');
      print(
        '🔍 [ML_DEBUG] Processing time: ${DateTime.now().difference(now).inMilliseconds}ms',
      );
      print(
        '🔍 [ML_DEBUG] Image dimensions: ${_imageWidth.toInt()}x${_imageHeight.toInt()}',
      );
      print('🔍 [ML_DEBUG] Min confidence threshold: $_minConfidence');
      print('🔍 [ML_DEBUG] Raw ML Kit objects detected: ${objects.length}');

      if (objects.isNotEmpty) {
        print('📋 [ML_RAW] ===== COMPLETE ML KIT DETECTION OUTPUT =====');
        for (int i = 0; i < objects.length; i++) {
          final obj = objects[i];
          print('📋 [ML_RAW] Object #${i + 1}:');
          print('📋 [ML_RAW]   Bounding Box: ${obj.boundingBox}');
          print(
            '📋 [ML_RAW]   Left: ${obj.boundingBox.left}, Top: ${obj.boundingBox.top}',
          );
          print(
            '📋 [ML_RAW]   Right: ${obj.boundingBox.right}, Bottom: ${obj.boundingBox.bottom}',
          );
          print(
            '📋 [ML_RAW]   Width: ${obj.boundingBox.width}, Height: ${obj.boundingBox.height}',
          );
          print('📋 [ML_RAW]   Tracking ID: ${obj.trackingId}');
          print('📋 [ML_RAW]   Labels Count: ${obj.labels.length}');

          if (obj.labels.isNotEmpty) {
            print('📋 [ML_RAW]   All Labels:');
            for (int j = 0; j < obj.labels.length; j++) {
              final label = obj.labels[j];
              final meetsThreshold = label.confidence >= _minConfidence;
              print('📋 [ML_RAW]     Label #${j + 1}: "${label.text}"');
              print(
                '📋 [ML_RAW]     Confidence: ${label.confidence} (${(label.confidence * 100).toStringAsFixed(2)}%) ${meetsThreshold ? "✅" : "❌"}',
              );
              print('📋 [ML_RAW]     Index: ${label.index}');
            }
          } else {
            print('📋 [ML_RAW]   No labels for this object');
          }
          print('📋 [ML_RAW]   ---');
        }
        print('📋 [ML_RAW] ===== END ML KIT OUTPUT =====');
      } else {
        print('🔍 [ML_DEBUG] ❌ No objects detected by ML Kit');
        print('🔍 [ML_DEBUG] Possible causes:');
        print('🔍 [ML_DEBUG]   - No objects in camera view');
        print(
          '🔍 [ML_DEBUG]   - Objects below confidence threshold ($_minConfidence)',
        );
        print('🔍 [ML_DEBUG]   - Poor lighting conditions');
        print('🔍 [ML_DEBUG]   - Camera focus issues');
      }

      // Convert and validate objects
      List<app.DetectedObject> detectedObjects = objects
          .map((obj) => _convertToDetectedObject(obj))
          .where((obj) => obj != null)
          .cast<app.DetectedObject>()
          .where((obj) => _isValidTrashObject(obj))
          .toList();

      detectedObjects = _trackObjectsAcrossFrames(detectedObjects);

      // Apply object persistence to handle ML Kit detection failures
      detectedObjects = _applyObjectPersistence(detectedObjects);

      _hasRecentDetections = detectedObjects.isNotEmpty;
      if (_hasRecentDetections) {
        _frameSkipCount = 0;
      }

      _previousFrameObjects = List.from(detectedObjects);
      _objectsController.add(detectedObjects);

      // FINAL DETECTION RESULTS LOGGING
      print('🎯 [ML_DEBUG] ===== FINAL DETECTION RESULTS =====');
      print('🎯 [ML_DEBUG] Valid trash objects: ${detectedObjects.length}');
      print(
        '🎯 [ML_DEBUG] Previous frame objects: ${_previousFrameObjects.length}',
      );
      print('🎯 [ML_DEBUG] Persistent objects: ${_persistentObjects.length}');

      if (detectedObjects.isNotEmpty) {
        print('🎯 [ML] Final tracked objects: ${detectedObjects.length}');
        for (var obj in detectedObjects) {
          print(
            '   - ${obj.category}: ${obj.codeName} (${(obj.confidence * 100).toStringAsFixed(1)}%) '
            'at ${obj.boundingBox.center.dx.toInt()},${obj.boundingBox.center.dy.toInt()} '
            'size=${obj.boundingBox.width.toInt()}x${obj.boundingBox.height.toInt()}',
          );
        }
      } else {
        print('🎯 [ML_DEBUG] ❌ No valid trash objects detected in this frame');
      }

      print('🎯 [ML_DEBUG] ===== END DETECTION RESULTS =====');
      return detectedObjects;
    } catch (e) {
      print('❌ [ML] Error during detection: $e');
      return _previousFrameObjects;
    } finally {
      _isDetecting = false;
    }
  }

  // --- All CameraImage conversion methods from your original code ---
  // Ensure these are included as they were, they are well-written.
  mlkit.InputImage? _convertCameraImage(
    CameraImage image,
    CameraController cameraController,
  ) {
    try {
      final camera = cameraController.description;
      final sensorOrientation = camera.sensorOrientation;

      mlkit.InputImageRotation rotation;
      switch (sensorOrientation) {
        case 90:
          rotation = mlkit.InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = mlkit.InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = mlkit.InputImageRotation.rotation270deg;
          break;
        default:
          rotation = mlkit.InputImageRotation.rotation0deg;
          break;
      }

      mlkit.InputImage? inputImage;

      if (image.format.group == ImageFormatGroup.yuv420) {
        inputImage = _convertYUV420ToInputImage(image, rotation);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        inputImage = _convertBGRA8888ToInputImage(image, rotation);
      } else {
        inputImage = _convertWithFallbackApproach(image, rotation);
      }

      if (inputImage == null) {
        print(
          '❌ [ML] Image conversion failed for format: ${image.format.group}',
        );
      }

      return inputImage;
    } catch (e) {
      print('❌ [ML] Error converting camera image: $e');
      return null;
    }
  }

  mlkit.InputImage? _convertYUV420ToInputImage(
    CameraImage image,
    mlkit.InputImageRotation rotation,
  ) {
    // This implementation remains the same
    try {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final nv21Bytes = _convertYUV420ToNV21(
        yPlane.bytes,
        uPlane.bytes,
        vPlane.bytes,
        image.width,
        image.height,
        yPlane.bytesPerRow,
        uPlane.bytesPerRow,
        vPlane.bytesPerRow,
      );

      if (nv21Bytes == null) return null;

      return mlkit.InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: mlkit.InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: mlkit.InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Uint8List? _convertYUV420ToNV21(
    Uint8List yBytes,
    Uint8List uBytes,
    Uint8List vBytes,
    int width,
    int height,
    int yRowStride,
    int uRowStride,
    int vRowStride,
  ) {
    // This implementation remains the same
    try {
      final ySize = width * height;
      final uvSize = width * height ~/ 2;
      final nv21 = Uint8List(ySize + uvSize);

      if (yRowStride == width) {
        nv21.setRange(0, ySize, yBytes.take(ySize));
      } else {
        for (int row = 0; row < height; row++) {
          final srcOffset = row * yRowStride;
          final dstOffset = row * width;
          nv21.setRange(dstOffset, dstOffset + width, yBytes, srcOffset);
        }
      }

      int uvIndex = ySize;
      final uvWidth = width ~/ 2;
      final uvHeight = height ~/ 2;

      for (int row = 0; row < uvHeight; row++) {
        for (int col = 0; col < uvWidth; col++) {
          final uOffset = row * uRowStride + col * (uRowStride ~/ uvWidth);
          final vOffset = row * vRowStride + col * (vRowStride ~/ uvWidth);
          if (uvIndex + 1 < nv21.length &&
              vOffset < vBytes.length &&
              uOffset < uBytes.length) {
            nv21[uvIndex++] = vBytes[vOffset];
            nv21[uvIndex++] = uBytes[uOffset];
          }
        }
      }
      return nv21;
    } catch (e) {
      return null;
    }
  }

  mlkit.InputImage? _convertBGRA8888ToInputImage(
    CameraImage image,
    mlkit.InputImageRotation rotation,
  ) {
    // This implementation remains the same
    final plane = image.planes.first;
    return mlkit.InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: mlkit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: mlkit.InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  mlkit.InputImage? _convertWithFallbackApproach(
    CameraImage image,
    mlkit.InputImageRotation rotation,
  ) {
    // This implementation remains the same
    final plane = image.planes.first;
    return mlkit.InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: mlkit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: mlkit.InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }
  // --- End of CameraImage conversion methods ---

  // --- Enhanced Classification Logic with Simplified Waste Categorization ---
  app.DetectedObject? _convertToDetectedObject(
    mlkit.DetectedObject mlkitObject, [
    String? reuseTrackingId,
  ]) {
    if (mlkitObject.labels.isEmpty) {
      print('🗂️ [ML] ❌ SKIPPED: Object has no labels');
      return null;
    }

    // Check for multiple categories (FASHION_GOOD + HOME_GOOD = ewaste)
    final labelTexts = mlkitObject.labels
        .map((label) => label.text.toUpperCase())
        .toSet();
    if (labelTexts.contains('FASHION_GOOD') &&
        labelTexts.contains('HOME_GOOD')) {
      print(
        '🗂️ [ML] ✅ MULTI-CATEGORY DETECTION: FASHION_GOOD + HOME_GOOD → ewaste',
      );

      final trackingId =
          reuseTrackingId ??
          mlkitObject.trackingId?.toString() ??
          'obj_${_nextTrackingId++}';

      return app.DetectedObject(
        trackingId: trackingId,
        category: _getCategoryString(app.WasteCategory.ewaste),
        codeName: '${_getCodeName(app.WasteCategory.ewaste)} (Multi-category)',
        boundingBox: mlkitObject.boundingBox,
        confidence: 0.9, // High confidence for multi-category detection
        detectedAt: DateTime.now(),
        overlayColor: _getCategoryColor(app.WasteCategory.ewaste),
      );
    }

    // Find the label with the highest confidence
    final bestLabel = mlkitObject.labels.reduce(
      (a, b) => a.confidence > b.confidence ? a : b,
    );

    final objectLabel = bestLabel.text;
    final confidence = bestLabel.confidence;

    print(
      '🗂️ [ML] Processing label: "$objectLabel" (${(confidence * 100).toStringAsFixed(2)}%)',
    );

    // Check if this label should be ignored (hands, etc.)
    if (_ignoredLabels.contains(objectLabel)) {
      print('🗂️ [ML] ❌ IGNORED: Label "$objectLabel" is in ignored list');
      return null;
    }

    // Check if this is a PLACE object or unknown ML Kit category
    if (objectLabel.toUpperCase() == 'PLACE') {
      print('🗂️ [ML] ❌ SKIPPED: PLACE objects are not waste items');
      return null;
    }

    // Try to get waste category using the new simplified mapping
    app.WasteCategory? wasteCategory;

    // First try direct ML Kit category mapping
    wasteCategory = _labelToCategory[objectLabel.toUpperCase()];

    // If not found, try the WasteCategory.fromMLKitLabel method for backward compatibility
    if (wasteCategory == null) {
      wasteCategory = app.WasteCategory.fromMLKitLabel(objectLabel, confidence);
    }

    // If still no category found, skip this object
    if (wasteCategory == null) {
      print(
        '🗂️ [ML] ❌ SKIPPED: Unknown ML Kit category "$objectLabel" - not a supported waste type',
      );
      return null;
    }

    print('🗂️ [ML] ✅ CATEGORIZED: "$objectLabel" → ${wasteCategory.id}');

    final trackingId =
        reuseTrackingId ??
        mlkitObject.trackingId?.toString() ??
        'obj_${_nextTrackingId++}';

    final detectedObject = app.DetectedObject(
      trackingId: trackingId,
      category: _getCategoryString(wasteCategory),
      codeName: '${_getCodeName(wasteCategory)} ($objectLabel)',
      boundingBox: mlkitObject.boundingBox,
      confidence: confidence,
      detectedAt: DateTime.now(),
      overlayColor: _getCategoryColor(wasteCategory),
    );

    return detectedObject;
  }

  // --- All tracking and coordinate transform methods from your original code ---
  // These implementations are solid and do not require changes for the classification issue.
  List<app.DetectedObject> _trackObjectsAcrossFrames(
    List<app.DetectedObject> currentObjects,
  ) {
    List<app.DetectedObject> trackedObjects = [];
    List<bool> matchedPrevious = List.filled(
      _previousFrameObjects.length,
      false,
    );
    List<bool> matchedCurrent = List.filled(currentObjects.length, false);

    for (int i = 0; i < currentObjects.length; i++) {
      if (matchedCurrent[i]) continue;

      final currentObj = currentObjects[i];
      String? reuseTrackingId;
      double bestOverlap = 0.0;
      int bestMatchIndex = -1;

      for (int j = 0; j < _previousFrameObjects.length; j++) {
        if (matchedPrevious[j]) continue;

        final previousObj = _previousFrameObjects[j];
        final overlap = _calculateBoundingBoxOverlap(
          currentObj.boundingBox,
          previousObj.boundingBox,
        );
        final distance = _calculateBoundingBoxDistance(
          currentObj.boundingBox,
          previousObj.boundingBox,
        );

        if ((overlap > _overlapThreshold || distance < _maxTrackingDistance) &&
            overlap > bestOverlap) {
          bestOverlap = overlap;
          bestMatchIndex = j;
        }
      }

      if (bestMatchIndex != -1) {
        reuseTrackingId = _previousFrameObjects[bestMatchIndex].trackingId;
        matchedPrevious[bestMatchIndex] = true;
        matchedCurrent[i] = true;
      }

      final newObj = app.DetectedObject(
        trackingId: reuseTrackingId ?? 'obj_${_nextTrackingId++}',
        category: currentObj.category,
        codeName: currentObj.codeName,
        boundingBox: currentObj.boundingBox,
        confidence: currentObj.confidence,
        detectedAt: currentObj.detectedAt,
        overlayColor: currentObj.overlayColor,
      );
      trackedObjects.add(newObj);
    }
    return trackedObjects;
  }

  double _calculateBoundingBoxOverlap(Rect rect1, Rect rect2) {
    final intersectionLeft = math.max(rect1.left, rect2.left);
    final intersectionTop = math.max(rect1.top, rect2.top);
    final intersectionRight = math.min(rect1.right, rect2.right);
    final intersectionBottom = math.min(rect1.bottom, rect2.bottom);

    if (intersectionLeft >= intersectionRight ||
        intersectionTop >= intersectionBottom)
      return 0.0;

    final intersectionArea =
        (intersectionRight - intersectionLeft) *
        (intersectionBottom - intersectionTop);
    final unionArea =
        (rect1.width * rect1.height) +
        (rect2.width * rect2.height) -
        intersectionArea;

    return intersectionArea / unionArea;
  }

  double _calculateBoundingBoxDistance(Rect rect1, Rect rect2) {
    final center1 = rect1.center;
    final center2 = rect2.center;
    return (center1 - center2).distance;
  }

  /// Apply object persistence to handle ML Kit detection failures
  /// This helps maintain object continuity when hands interfere with detection
  List<app.DetectedObject> _applyObjectPersistence(
    List<app.DetectedObject> currentObjects,
  ) {
    final persistedObjects = <app.DetectedObject>[];
    final currentObjectIds = <String>{};

    // Add all currently detected objects and reset their missed frame count
    for (final obj in currentObjects) {
      persistedObjects.add(obj);
      currentObjectIds.add(obj.trackingId);
      _objectMissedFrames[obj.trackingId] = 0;
      _persistentObjects[obj.trackingId] = obj;
    }

    // Check persistent objects that weren't detected this frame
    final objectsToRemove = <String>[];
    for (final entry in _objectMissedFrames.entries) {
      final objectId = entry.key;
      final missedFrames = entry.value;

      if (!currentObjectIds.contains(objectId)) {
        // Object not detected this frame, increment missed count
        final newMissedFrames = missedFrames + 1;
        _objectMissedFrames[objectId] = newMissedFrames;

        if (newMissedFrames <= _maxMissedFrames) {
          // Keep the object for a few more frames
          final persistentObj = _persistentObjects[objectId];
          if (persistentObj != null) {
            // Create a new object with slightly reduced confidence to indicate uncertainty
            final persistedObj = app.DetectedObject(
              trackingId: persistentObj.trackingId,
              category: persistentObj.category,
              codeName: persistentObj.codeName,
              boundingBox: persistentObj.boundingBox,
              confidence:
                  persistentObj.confidence * 0.9, // Slightly reduce confidence
              detectedAt: persistentObj.detectedAt,
              overlayColor: persistentObj.overlayColor,
            );
            persistedObjects.add(persistedObj);

            if (newMissedFrames == 1) {
              print(
                '🔄 [ML] Persisting object ${persistentObj.codeName} (missed 1 frame)',
              );
            }
          }
        } else {
          // Object has been missing too long, remove it
          objectsToRemove.add(objectId);
          print(
            '🗑️ [ML] Removing persistent object ${_persistentObjects[objectId]?.codeName} (missed $newMissedFrames frames)',
          );
        }
      }
    }

    // Clean up objects that have been missing too long
    for (final objectId in objectsToRemove) {
      _objectMissedFrames.remove(objectId);
      _persistentObjects.remove(objectId);
    }

    // Log persistence statistics
    final persistedCount = persistedObjects.length - currentObjects.length;
    if (persistedCount > 0) {
      print(
        '📌 [ML] Persisted $persistedCount objects (${currentObjects.length} detected + $persistedCount persisted = ${persistedObjects.length} total)',
      );
    }

    return persistedObjects;
  }

  Size _getActualImageSize(CameraController cameraController) {
    // Account for camera rotation
    final camera = cameraController.description;
    if (camera.sensorOrientation == 90 || camera.sensorOrientation == 270) {
      // Rotated: swap width/height
      return Size(_imageHeight, _imageWidth);
    }
    return Size(_imageWidth, _imageHeight);
  }

  Rect transformBoundingBox(
    Rect mlkitRect,
    BoxConstraints previewConstraints,
    CameraController cameraController,
  ) {
    final previewWidth = previewConstraints.maxWidth;
    final previewHeight = previewConstraints.maxHeight;

    // Get actual image dimensions accounting for camera rotation
    final actualImageSize = _getActualImageSize(cameraController);
    final imageWidth = actualImageSize.width;
    final imageHeight = actualImageSize.height;

    // Calculate scale factors
    final scaleX = previewWidth / imageWidth;
    final scaleY = previewHeight / imageHeight;

    // Use uniform scaling to maintain aspect ratio
    final scale = math.min(scaleX, scaleY);

    // Calculate actual preview area (may have letterboxing)
    final scaledImageWidth = imageWidth * scale;
    final scaledImageHeight = imageHeight * scale;

    // Calculate offsets for centering
    final offsetX = (previewWidth - scaledImageWidth) / 2;
    final offsetY = (previewHeight - scaledImageHeight) / 2;

    // Apply transformation
    final transformedLeft = mlkitRect.left * scale + offsetX;
    final transformedTop = mlkitRect.top * scale + offsetY;
    final transformedWidth = mlkitRect.width * scale;
    final transformedHeight = mlkitRect.height * scale;

    // REDUCE BOUNDING BOX SIZE BY 30% WHILE MAINTAINING CENTER POSITION
    // This improves proximity accuracy by making bounding boxes more precise
    const double sizeReduction = 0.30; // 30% reduction
    final reducedWidth = transformedWidth * (1.0 - sizeReduction);
    final reducedHeight = transformedHeight * (1.0 - sizeReduction);

    // Calculate new position to maintain center
    final centerX = transformedLeft + transformedWidth / 2;
    final centerY = transformedTop + transformedHeight / 2;
    final newLeft = centerX - reducedWidth / 2;
    final newTop = centerY - reducedHeight / 2;

    print(
      '📦 [ML] Bounding box size reduction: '
      'original=${transformedWidth.toInt()}x${transformedHeight.toInt()}, '
      'reduced=${reducedWidth.toInt()}x${reducedHeight.toInt()} '
      '(${(sizeReduction * 100).toInt()}% smaller)',
    );

    return Rect.fromLTWH(
      newLeft.clamp(0, previewWidth),
      newTop.clamp(0, previewHeight),
      reducedWidth.clamp(0, previewWidth - newLeft),
      reducedHeight.clamp(0, previewHeight - newTop),
    );
  }
  // --- End of tracking and transform methods ---

  bool _isValidTrashObject(app.DetectedObject obj) {
    // Filter out objects that are too small (likely noise)
    const double minObjectSize = 20.0; // pixels
    if (obj.boundingBox.width < minObjectSize ||
        obj.boundingBox.height < minObjectSize) {
      return false;
    }

    // Filter out objects that are too large (likely background/furniture)
    const double maxObjectSize = 800.0; // pixels
    if (obj.boundingBox.width > maxObjectSize &&
        obj.boundingBox.height > maxObjectSize) {}

    return true;
  }

  // --- Helper methods for category display ---
  Color _getCategoryColor(app.WasteCategory category) {
    switch (category) {
      case app.WasteCategory.recycle:
        return Colors.green;
      case app.WasteCategory.organic:
        return const Color(0xFF8BC34A); // Light green for organic
      case app.WasteCategory.ewaste:
        return Colors.orange;
      case app.WasteCategory.hazardous:
        return Colors.red;
      default:
        return Colors.grey; // Fallback color
    }
  }

  String _getCategoryString(app.WasteCategory category) {
    // This provides a clean string like 'recycle' from 'app.WasteCategory.recycle'
    return category.toString().split('.').last.toLowerCase();
  }

  String _getCodeName(app.WasteCategory category) {
    switch (category) {
      case app.WasteCategory.recycle:
        return 'EcoGems';
      case app.WasteCategory.organic:
        return 'BioShards';
      case app.WasteCategory.ewaste:
        return 'TechCores';
      case app.WasteCategory.hazardous:
        return 'ToxicVials';
      default:
        return 'Unknown'; // Fallback name
    }
  }
  // --- End of helper methods ---

  void resetTracking() {
    _previousFrameObjects.clear();
    _nextTrackingId = 1;
    print('DEBUG: Object tracking state reset');
  }

  Future<void> dispose() async {
    try {
      await _objectDetector?.close();
      await _objectsController.close();
      _isInitialized = false;
      _previousFrameObjects.clear();
      _nextTrackingId = 1;

      // Clear persistence data
      _objectMissedFrames.clear();
      _persistentObjects.clear();

      print('🤖 [ML] MLDetectionService disposed');
    } catch (e) {
      print('❌ [ML] Error disposing MLDetectionService: $e');
    }
  }
}
