library;

import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart'
    as mlkit;

import 'package:cleanclik/core/services/camera/ml_config.dart';
import 'package:cleanclik/core/utils/camera/image_processing_util.dart';
import 'package:cleanclik/core/utils/camera/coordinate_transform_util.dart';
import 'package:cleanclik/core/services/camera/waste_categorizer.dart';
import 'package:cleanclik/core/services/camera/ml_background_processor.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/models/waste_models.dart';

// ML Kit predefined categories we want to filter out at the object detection stage.
const Set<String> _unwantedCategories = {
  'person',
  'face',
  'human',
  'building',
  'house',
  'place',
  'room',
  'land vehicle',
  'car',
  'vehicle',
  'furniture',
  'plant',
  'flower',
  'tree',
  'animal',
  'bird',
  'cat',
  'dog',
};

class WasteDetectionService {
  mlkit.ObjectDetector? _objectDetector;
  mlkit.ImageLabeler? _imageLabeler;

  final WasteCategorizer _categorizer = WasteCategorizer.instance;
  final MLBackgroundProcessor _backgroundProcessor = MLBackgroundProcessor();

  bool _isInitialized = false;
  bool _isProcessing = false;
  int _frameCounter = 0;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;

  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('⚠️ [WasteDetectionService] Already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🚀 [WasteDetectionService] Initializing...');
      }

      final objectDetectorOptions = mlkit.ObjectDetectorOptions(
        mode: MLConfig.objectDetectionMode,
        classifyObjects: MLConfig.classifyObjects,
        multipleObjects: MLConfig.multipleObjects,
      );
      _objectDetector = mlkit.ObjectDetector(options: objectDetectorOptions);

      if (kDebugMode) {
        print('✅ [WasteDetectionService] Object detector initialized');
      }

      final imageLabelOptions = mlkit.ImageLabelerOptions(
        confidenceThreshold: MLConfig.imageLabelingConfidence,
      );
      _imageLabeler = mlkit.ImageLabeler(options: imageLabelOptions);

      if (kDebugMode) {
        print('✅ [WasteDetectionService] Image labeler initialized');
      }

      await _backgroundProcessor.initialize();

      if (kDebugMode) {
        print('✅ [WasteDetectionService] Background processor initialized');
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ [WasteDetectionService] Initialization complete');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [WasteDetectionService] Initialization failed: $e');
        print('Stack trace: $stackTrace');
      }
      await dispose();
      rethrow;
    }
  }

  Future<List<DetectedObject>> detectWaste(
    CameraImage cameraImage,
    CameraController controller,
    Size screenSize,
  ) async {
    if (!_isInitialized) {
      throw StateError('WasteDetectionService not initialized');
    }

    if (_isProcessing) {
      if (kDebugMode) {
        print('⚠️ [WasteDetectionService] Already processing, skipping frame');
      }
      return [];
    }

    _isProcessing = true;
    _frameCounter++;

    try {
      final inputImage = ImageProcessingUtil.convertCameraImageToMLKit(
        cameraImage,
        controller,
      );

      if (inputImage == null) {
        if (kDebugMode) {
          print('❌ [WasteDetectionService] Image conversion failed');
        }
        return [];
      }

      final mlDetectedObjects = await _detectObjects(inputImage);

      if (mlDetectedObjects.isEmpty) {
        return [];
      }

      final results = <DetectedObject>[];
      final imageSize = Size(
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      );

      for (final mlObject in mlDetectedObjects) {
        try {
          final result = await _processDetectedObject(
            mlObject,
            inputImage,
            imageSize,
            screenSize,
            controller,
          );

          if (result != null) {
            results.add(result);
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ [WasteDetectionService] Failed to process object: $e');
          }
        }
      }

      if (kDebugMode && results.isNotEmpty) {
        print(
          '✅ [WasteDetectionService] Detected ${results.length} waste items',
        );
      }

      return results;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [WasteDetectionService] Detection failed: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<DetectedObject>> detectWasteInBackground(
    CameraImage cameraImage,
    CameraController controller,
    Size screenSize,
  ) async {
    if (!_isInitialized) {
      throw StateError('WasteDetectionService not initialized');
    }

    try {
      final imageData = _serializeCameraImage(cameraImage);
      final controllerData = _serializeController(controller);

      final result = await _backgroundProcessor
          .processInIsolate<Map<String, dynamic>>('detectWaste', {
            'cameraImage': imageData,
            'controller': controllerData,
            'screenSize': {
              'width': screenSize.width,
              'height': screenSize.height,
            },
          });

      return _deserializeDetectedObjects(result);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WasteDetectionService] Background detection failed: $e');
      }
      return detectWaste(cameraImage, controller, screenSize);
    }
  }

  Future<List<mlkit.DetectedObject>> _detectObjects(
    mlkit.InputImage inputImage,
  ) async {
    try {
      final objects = await _objectDetector!
          .processImage(inputImage)
          .timeout(MLConfig.processingTimeout);

      return objects.where((obj) {
        if (_getObjectConfidence(obj) < MLConfig.objectDetectionConfidence) {
          return false;
        }

        final box = obj.boundingBox;
        if (box.width <= 0 || box.height <= 0) {
          return false;
        }

        if (box.width < 10 || box.height < 10) {
          return false;
        }

        // Check if any of the object's labels match the unwanted categories.
        final isUnwanted = obj.labels.any((label) {
          final category = label.text.toLowerCase();
          if (_unwantedCategories.contains(category)) {
            if (kDebugMode) {
              print(
                '🚫 [WasteDetectionService] Filtered out object with category: $category',
              );
            }
            return true; // This label is unwanted, so the object is unwanted.
          }
          return false; // This label is fine.
        });

        // If `isUnwanted` is true, it means we found an unwanted label, so we filter out the object.
        return !isUnwanted;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WasteDetectionService] Object detection failed: $e');
      }
      return [];
    }
  }

  Future<DetectedObject?> _processDetectedObject(
    mlkit.DetectedObject mlObject,
    mlkit.InputImage inputImage,
    Size imageSize,
    Size screenSize,
    CameraController controller,
  ) async {
    final croppedImage = await ImageProcessingUtil.cropImage(
      inputImage,
      mlObject.boundingBox,
    );

    if (croppedImage == null) {
      if (kDebugMode) {
        print('⚠️ [WasteDetectionService] Failed to crop object region');
      }
      return null;
    }

    final labels = await _labelImage(croppedImage);

    if (labels.isEmpty) {
      if (kDebugMode) {
        print('⚠️ [WasteDetectionService] No labels found for object');
      }
      return null;
    }

    final category = _categorizer.categorize(labels);

    if (category == null) {
      return null;
    }

    final screenBoundingBox = CoordinateTransformUtil.transformBoundingBox(
      mlObject.boundingBox,
      imageSize,
      screenSize,
      controller,
    );

    final confidence = _calculateCombinedConfidence(mlObject, labels);

    return DetectedObject(
      trackingId: mlObject.trackingId?.toString() ?? _generateTrackingId(),
      category: category.id,
      codeName: category.codeName,
      boundingBox: screenBoundingBox,
      confidence: confidence,
      detectedAt: DateTime.now(),
      overlayColor: category.color,
      imageLabels: labels,
      detectionSource: DetectionSource.combined,
      categorizationReasoning: _buildCategorizationReasoning(labels, category),
    );
  }

  Future<List<ImageLabel>> _labelImage(mlkit.InputImage inputImage) async {
    try {
      final mlLabels = await _imageLabeler!
          .processImage(inputImage)
          .timeout(MLConfig.imageLabelingTimeout);

      return mlLabels
          .where(
            (label) => label.confidence >= MLConfig.minCategorizationConfidence,
          )
          .map(
            (label) => ImageLabel(
              text: label.label,
              confidence: label.confidence,
              index: label.index ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WasteDetectionService] Image labeling failed: $e');
      }
      return [];
    }
  }

  double _getObjectConfidence(mlkit.DetectedObject obj) {
    if (obj.labels.isNotEmpty) {
      return obj.labels.first.confidence;
    }
    return 0.5;
  }

  double _calculateCombinedConfidence(
    mlkit.DetectedObject mlObject,
    List<ImageLabel> labels,
  ) {
    final objectConfidence = _getObjectConfidence(mlObject);
    final labelConfidence = labels.isNotEmpty ? labels.first.confidence : 0.0;
    return (objectConfidence * 0.6) + (labelConfidence * 0.4);
  }

  String _buildCategorizationReasoning(
    List<ImageLabel> labels,
    WasteCategory category,
  ) {
    if (labels.isEmpty) {
      return 'Categorized as ${category.id}';
    }

    final topLabel = labels.first;
    return 'Categorized as ${category.id} based on label "${topLabel.text}" '
        '(${(topLabel.confidence * 100).toStringAsFixed(1)}% confidence)';
  }

  String _generateTrackingId() {
    return 'obj_${DateTime.now().millisecondsSinceEpoch}_$_frameCounter';
  }

  Map<String, dynamic> _serializeCameraImage(CameraImage image) {
    return {
      'width': image.width,
      'height': image.height,
      'format': image.format.group.toString(),
      'planes': image.planes
          .map(
            (plane) => {
              'bytes': plane.bytes,
              'bytesPerRow': plane.bytesPerRow,
              'bytesPerPixel': plane.bytesPerPixel,
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _serializeController(CameraController controller) {
    return {
      'sensorOrientation': controller.description.sensorOrientation,
      'lensDirection': controller.description.lensDirection.toString(),
    };
  }

  List<DetectedObject> _deserializeDetectedObjects(
    Map<String, dynamic> result,
  ) {
    final objectsData = result['objects'] as List<dynamic>?;
    if (objectsData == null) return [];

    return objectsData
        .map((data) => DetectedObject.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  Future<void> dispose() async {
    if (kDebugMode) {
      print('🧹 [WasteDetectionService] Disposing...');
    }

    _isInitialized = false;
    _isProcessing = false;

    try {
      if (_objectDetector != null) {
        await _objectDetector!.close();
        _objectDetector = null;
        if (kDebugMode) {
          print('✅ [WasteDetectionService] Object detector closed');
        }
      }

      if (_imageLabeler != null) {
        await _imageLabeler!.close();
        _imageLabeler = null;
        if (kDebugMode) {
          print('✅ [WasteDetectionService] Image labeler closed');
        }
      }

      await _backgroundProcessor.dispose();
      if (kDebugMode) {
        print('✅ [WasteDetectionService] Background processor disposed');
      }

      if (kDebugMode) {
        print('✅ [WasteDetectionService] Disposal complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WasteDetectionService] Error during disposal: $e');
      }
    }
  }
}
