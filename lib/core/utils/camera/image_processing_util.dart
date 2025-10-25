/// Centralized utility for all image processing operations
///
/// This utility provides static methods for:
/// - Format conversions (YUV420 to NV21, BGRA8888, etc.)
/// - Image cropping with bounding box validation
/// - Batch processing support
/// - Camera image to ML Kit InputImage conversion
///
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;
import 'package:cleanclik/core/services/camera/ml_config.dart';

/// Static utility class for image processing operations
class ImageProcessingUtil {
  // Private constructor to prevent instantiation
  ImageProcessingUtil._();

  // ============================================================================
  // Camera Image Conversion
  // ============================================================================

  /// Convert CameraImage to ML Kit InputImage
  ///
  /// Handles different image formats (YUV420, BGRA8888) and applies
  /// appropriate rotation based on camera sensor orientation.
  ///
  /// Returns null if conversion fails.
  static mlkit.InputImage? convertCameraImageToMLKit(
    CameraImage image,
    CameraController controller,
  ) {
    try {
      final camera = controller.description;
      final sensorOrientation = camera.sensorOrientation;

      final rotation = _getRotationFromOrientation(sensorOrientation);

      mlkit.InputImage? inputImage;

      if (image.format.group == ImageFormatGroup.yuv420) {
        inputImage = _convertYUV420ToInputImage(image, rotation);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        inputImage = _convertBGRA8888ToInputImage(image, rotation);
      } else {
        inputImage = _convertWithFallbackApproach(image, rotation);
      }

      if (inputImage == null && kDebugMode) {
        print(
          '❌ [ImageProcessingUtil] Image conversion failed for format: ${image.format.group}',
        );
      }

      return inputImage;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] Error converting camera image: $e');
      }
      return null;
    }
  }

  /// Get rotation from sensor orientation
  static mlkit.InputImageRotation _getRotationFromOrientation(
    int sensorOrientation,
  ) {
    switch (sensorOrientation) {
      case 90:
        return mlkit.InputImageRotation.rotation90deg;
      case 180:
        return mlkit.InputImageRotation.rotation180deg;
      case 270:
        return mlkit.InputImageRotation.rotation270deg;
      default:
        return mlkit.InputImageRotation.rotation0deg;
    }
  }

  // ============================================================================
  // Format Conversions
  // ============================================================================

  /// Convert YUV420 format to InputImage
  static mlkit.InputImage? _convertYUV420ToInputImage(
    CameraImage image,
    mlkit.InputImageRotation rotation,
  ) {
    try {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final nv21Bytes = convertYUV420ToNV21(
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
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] YUV420 conversion failed: $e');
      }
      return null;
    }
  }

  /// Convert YUV420 to NV21 format
  ///
  /// NV21 is a YUV format with Y plane followed by interleaved VU plane.
  /// This is the format expected by ML Kit on Android.
  static Uint8List? convertYUV420ToNV21(
    Uint8List yBytes,
    Uint8List uBytes,
    Uint8List vBytes,
    int width,
    int height,
    int yRowStride,
    int uRowStride,
    int vRowStride,
  ) {
    try {
      final ySize = width * height;
      final uvSize = width * height ~/ 2;
      final nv21 = Uint8List(ySize + uvSize);

      // Copy Y plane
      if (yRowStride == width) {
        // Contiguous Y plane - direct copy
        nv21.setRange(0, ySize, yBytes.take(ySize));
      } else {
        // Non-contiguous Y plane - copy row by row
        for (int row = 0; row < height; row++) {
          final srcOffset = row * yRowStride;
          final dstOffset = row * width;
          nv21.setRange(dstOffset, dstOffset + width, yBytes, srcOffset);
        }
      }

      // Interleave U and V planes into VU format (NV21)
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
            nv21[uvIndex++] = vBytes[vOffset]; // V first (NV21)
            nv21[uvIndex++] = uBytes[uOffset]; // U second
          }
        }
      }

      return nv21;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] YUV420 to NV21 conversion failed: $e');
      }
      return null;
    }
  }

  /// Convert BGRA8888 format to InputImage
  static mlkit.InputImage? _convertBGRA8888ToInputImage(
    CameraImage image,
    mlkit.InputImageRotation rotation,
  ) {
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] BGRA8888 conversion failed: $e');
      }
      return null;
    }
  }

  /// Fallback conversion approach for other formats
  static mlkit.InputImage? _convertWithFallbackApproach(
    CameraImage image,
    mlkit.InputImageRotation rotation,
  ) {
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] Fallback conversion failed: $e');
      }
      return null;
    }
  }

  // ============================================================================
  // Image Cropping
  // ============================================================================

  /// Crop a single region from an InputImage using a bounding box
  ///
  /// Returns null if cropping fails or bounding box is invalid.
  static Future<mlkit.InputImage?> cropImage(
    mlkit.InputImage originalImage,
    Rect boundingBox,
  ) async {
    try {
      final originalMetadata = originalImage.metadata;
      if (originalMetadata == null) {
        return null;
      }

      final imageSize = originalMetadata.size;

      // Validate and adjust bounding box
      final adjustedBox = validateAndAdjustBoundingBox(
        boundingBox,
        imageSize,
        padding: MLConfig.boundaryPadding,
      );

      if (adjustedBox == null) {
        return null;
      }

      // Create cropped InputImage
      return await _createCroppedInputImage(
        originalImage,
        adjustedBox,
        imageSize,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] Image cropping failed: $e');
      }
      return null;
    }
  }

  /// Crop multiple regions from an InputImage
  ///
  /// Processes all bounding boxes and returns successfully cropped images.
  /// Failed crops are omitted from the result.
  static Future<List<mlkit.InputImage>> cropMultipleRegions(
    mlkit.InputImage originalImage,
    List<Rect> boundingBoxes,
  ) async {
    if (boundingBoxes.isEmpty) {
      return [];
    }

    final croppedImages = <mlkit.InputImage>[];

    for (final boundingBox in boundingBoxes) {
      try {
        final croppedImage = await cropImage(originalImage, boundingBox);
        if (croppedImage != null) {
          croppedImages.add(croppedImage);
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '❌ [ImageProcessingUtil] Failed to crop region $boundingBox: $e',
          );
        }
        // Continue with other regions
      }
    }

    return croppedImages;
  }

  /// Create a new InputImage from a cropped region
  static Future<mlkit.InputImage?> _createCroppedInputImage(
    mlkit.InputImage originalImage,
    Rect cropBox,
    Size originalSize,
  ) async {
    try {
      final originalMetadata = originalImage.metadata;
      if (originalMetadata == null) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Original image has no metadata');
        }
        return null;
      }

      // Calculate crop dimensions
      final cropWidth = cropBox.width.round();
      final cropHeight = cropBox.height.round();

      // Validate crop dimensions
      if (cropWidth <= 0 || cropHeight <= 0) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Invalid crop dimensions: ${cropWidth}x$cropHeight');
        }
        return null;
      }

      // Get original image bytes
      final originalBytes = originalImage.bytes;
      if (originalBytes == null) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Original image has no bytes - cannot crop');
        }
        // Return null instead of trying to crop without bytes
        return null;
      }

      // Validate original bytes length
      final expectedMinSize = (originalSize.width * originalSize.height).round();
      if (originalBytes.length < expectedMinSize) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Original bytes too small: ${originalBytes.length} < $expectedMinSize');
        }
        return null;
      }

      // Crop the image bytes based on the format
      final croppedBytes = cropImageBytes(
        originalBytes,
        cropBox,
        originalSize,
        originalMetadata.format,
        originalMetadata.bytesPerRow,
      );

      if (croppedBytes == null) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Failed to crop image bytes');
        }
        return null;
      }

      // Create new metadata for the cropped region
      final croppedMetadata = mlkit.InputImageMetadata(
        size: Size(cropWidth.toDouble(), cropHeight.toDouble()),
        rotation: originalMetadata.rotation,
        format: originalMetadata.format,
        bytesPerRow: calculateBytesPerRow(cropWidth, originalMetadata.format),
      );

      return mlkit.InputImage.fromBytes(
        bytes: croppedBytes,
        metadata: croppedMetadata,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] Failed to create cropped image: $e');
        print('Stack trace: $stackTrace');
      }
      return null;
    }
  }

  // ============================================================================
  // Bounding Box Validation
  // ============================================================================

  /// Validate and adjust bounding box with padding and size constraints
  ///
  /// Returns null if the bounding box is invalid or results in an invalid crop.
  static Rect? validateAndAdjustBoundingBox(
    Rect boundingBox,
    Size imageSize, {
    double padding = MLConfig.boundaryPadding,
  }) {
    // Validate image size
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      if (kDebugMode) {
        print('⚠️ [ImageProcessingUtil] Invalid image size: $imageSize');
      }
      return null;
    }

    // Validate bounding box dimensions
    if (boundingBox.width <= 0 || boundingBox.height <= 0) {
      if (kDebugMode) {
        print('⚠️ [ImageProcessingUtil] Invalid bounding box dimensions: ${boundingBox.width}x${boundingBox.height}');
      }
      return null;
    }

    // Check if bounding box is within image bounds
    if (boundingBox.left < 0 ||
        boundingBox.top < 0 ||
        boundingBox.right > imageSize.width ||
        boundingBox.bottom > imageSize.height) {
      // Clamp to image bounds
      final clampedBox = Rect.fromLTRB(
        boundingBox.left.clamp(0.0, imageSize.width),
        boundingBox.top.clamp(0.0, imageSize.height),
        boundingBox.right.clamp(0.0, imageSize.width),
        boundingBox.bottom.clamp(0.0, imageSize.height),
      );

      // Check if clamped box is still valid
      if (clampedBox.width <= 0 || clampedBox.height <= 0) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Clamped box has invalid dimensions: ${clampedBox.width}x${clampedBox.height}');
        }
        return null;
      }

      boundingBox = clampedBox;
    }

    // Add padding around the bounding box
    final paddingX = boundingBox.width * padding;
    final paddingY = boundingBox.height * padding;

    final paddedBox = Rect.fromLTRB(
      (boundingBox.left - paddingX).clamp(0.0, imageSize.width),
      (boundingBox.top - paddingY).clamp(0.0, imageSize.height),
      (boundingBox.right + paddingX).clamp(0.0, imageSize.width),
      (boundingBox.bottom + paddingY).clamp(0.0, imageSize.height),
    );

    // Validate final dimensions
    if (paddedBox.width < MLConfig.minCropSize ||
        paddedBox.height < MLConfig.minCropSize) {
      return null;
    }

    // Ensure crop doesn't exceed maximum size (scale down if needed)
    if (paddedBox.width > MLConfig.maxCropSize ||
        paddedBox.height > MLConfig.maxCropSize) {
      final scale = (MLConfig.maxCropSize /
              paddedBox.width.clamp(
                MLConfig.maxCropSize.toDouble(),
                double.infinity,
              ))
          .clamp(
            0.0,
            MLConfig.maxCropSize /
                paddedBox.height.clamp(
                  MLConfig.maxCropSize.toDouble(),
                  double.infinity,
                ),
          );

      if (scale < 1.0) {
        final centerX = paddedBox.center.dx;
        final centerY = paddedBox.center.dy;
        final newWidth = paddedBox.width * scale;
        final newHeight = paddedBox.height * scale;

        return Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: newWidth,
          height: newHeight,
        );
      }
    }

    return paddedBox;
  }

  // ============================================================================
  // Image Bytes Manipulation
  // ============================================================================

  /// Crop image bytes based on the bounding box and image format
  ///
  /// Supports NV21, YUV420, and BGRA8888 formats.
  /// Returns null if cropping fails.
  static Uint8List? cropImageBytes(
    Uint8List originalBytes,
    Rect cropBox,
    Size originalSize,
    mlkit.InputImageFormat format,
    int originalBytesPerRow,
  ) {
    try {
      final originalWidth = originalSize.width.round();
      final originalHeight = originalSize.height.round();
      final cropX = cropBox.left.round();
      final cropY = cropBox.top.round();
      final cropWidth = cropBox.width.round();
      final cropHeight = cropBox.height.round();

      // Validate dimensions
      if (originalWidth <= 0 || originalHeight <= 0) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Invalid original dimensions: ${originalWidth}x$originalHeight');
        }
        return null;
      }

      if (cropWidth <= 0 || cropHeight <= 0) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Invalid crop dimensions: ${cropWidth}x$cropHeight');
        }
        return null;
      }

      // Validate crop bounds
      if (cropX < 0 ||
          cropY < 0 ||
          cropX + cropWidth > originalWidth ||
          cropY + cropHeight > originalHeight) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Crop bounds out of range: '
              'crop=($cropX,$cropY,${cropX + cropWidth},${cropY + cropHeight}) '
              'image=(0,0,$originalWidth,$originalHeight)');
        }
        return null;
      }

      // Validate bytes length
      final minExpectedBytes = originalWidth * originalHeight;
      if (originalBytes.length < minExpectedBytes) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] Insufficient bytes: ${originalBytes.length} < $minExpectedBytes');
        }
        return null;
      }

      switch (format) {
        case mlkit.InputImageFormat.nv21:
          return _cropNV21(
            originalBytes,
            originalWidth,
            originalHeight,
            cropX,
            cropY,
            cropWidth,
            cropHeight,
          );
        case mlkit.InputImageFormat.yuv420:
          return _cropYUV420(
            originalBytes,
            originalWidth,
            originalHeight,
            cropX,
            cropY,
            cropWidth,
            cropHeight,
          );
        case mlkit.InputImageFormat.bgra8888:
          return _cropBGRA8888(
            originalBytes,
            originalWidth,
            originalHeight,
            cropX,
            cropY,
            cropWidth,
            cropHeight,
            originalBytesPerRow,
          );
        default:
          // For unsupported formats, return a minimal valid image
          return _createMinimalImageBytes(cropWidth, cropHeight, format);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] Crop image bytes failed: $e');
      }
      return null;
    }
  }

  /// Crop NV21 format image (Y plane followed by interleaved UV)
  static Uint8List? _cropNV21(
    Uint8List originalBytes,
    int originalWidth,
    int originalHeight,
    int cropX,
    int cropY,
    int cropWidth,
    int cropHeight,
  ) {
    try {
      final yPlaneSize = originalWidth * originalHeight;
      final uvPlaneSize = originalWidth * originalHeight ~/ 2;
      final totalSize = yPlaneSize + uvPlaneSize;

      if (originalBytes.length < totalSize) {
        if (kDebugMode) {
          print('⚠️ [ImageProcessingUtil] NV21 bytes too small: ${originalBytes.length} < $totalSize');
        }
        return null;
      }

      final croppedYSize = cropWidth * cropHeight;
      final croppedUVSize = cropWidth * cropHeight ~/ 2;
      final croppedBytes = Uint8List(croppedYSize + croppedUVSize);

      // Crop Y plane with bounds checking
      for (int y = 0; y < cropHeight; y++) {
        final srcOffset = (cropY + y) * originalWidth + cropX;
        final dstOffset = y * cropWidth;
        
        // Validate source offset
        if (srcOffset + cropWidth > yPlaneSize) {
          if (kDebugMode) {
            print('⚠️ [ImageProcessingUtil] Y plane source offset out of bounds: ${srcOffset + cropWidth} > $yPlaneSize');
          }
          return null;
        }
        
        // Validate destination offset
        if (dstOffset + cropWidth > croppedYSize) {
          if (kDebugMode) {
            print('⚠️ [ImageProcessingUtil] Y plane dest offset out of bounds: ${dstOffset + cropWidth} > $croppedYSize');
          }
          return null;
        }
        
        croppedBytes.setRange(
          dstOffset,
          dstOffset + cropWidth,
          originalBytes,
          srcOffset,
        );
      }

      // Crop UV plane (simplified - assumes even crop dimensions)
      final uvCropX = cropX ~/ 2 * 2;
      final uvCropY = cropY ~/ 2;
      final uvCropWidth = cropWidth ~/ 2 * 2;
      final uvCropHeight = cropHeight ~/ 2;

      for (int y = 0; y < uvCropHeight; y++) {
        final srcOffset = yPlaneSize + (uvCropY + y) * originalWidth + uvCropX;
        final dstOffset = croppedYSize + y * uvCropWidth;
        
        // Validate source offset
        if (srcOffset + uvCropWidth > totalSize) {
          if (kDebugMode) {
            print('⚠️ [ImageProcessingUtil] UV plane source offset out of bounds: ${srcOffset + uvCropWidth} > $totalSize');
          }
          return null;
        }
        
        // Validate destination offset
        if (dstOffset + uvCropWidth > croppedBytes.length) {
          if (kDebugMode) {
            print('⚠️ [ImageProcessingUtil] UV plane dest offset out of bounds: ${dstOffset + uvCropWidth} > ${croppedBytes.length}');
          }
          return null;
        }
        
        croppedBytes.setRange(
          dstOffset,
          dstOffset + uvCropWidth,
          originalBytes,
          srcOffset,
        );
      }

      return croppedBytes;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] NV21 crop failed: $e');
        print('Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Crop YUV420 format image (similar to NV21 but different UV layout)
  static Uint8List? _cropYUV420(
    Uint8List originalBytes,
    int originalWidth,
    int originalHeight,
    int cropX,
    int cropY,
    int cropWidth,
    int cropHeight,
  ) {
    // For simplicity, use the same logic as NV21
    // In a production implementation, this would handle the different UV plane layout
    return _cropNV21(
      originalBytes,
      originalWidth,
      originalHeight,
      cropX,
      cropY,
      cropWidth,
      cropHeight,
    );
  }

  /// Crop BGRA8888 format image (4 bytes per pixel)
  static Uint8List? _cropBGRA8888(
    Uint8List originalBytes,
    int originalWidth,
    int originalHeight,
    int cropX,
    int cropY,
    int cropWidth,
    int cropHeight,
    int bytesPerRow,
  ) {
    try {
      const bytesPerPixel = 4;
      final croppedBytes = Uint8List(cropWidth * cropHeight * bytesPerPixel);

      for (int y = 0; y < cropHeight; y++) {
        final srcRowStart = (cropY + y) * bytesPerRow + cropX * bytesPerPixel;
        final dstRowStart = y * cropWidth * bytesPerPixel;
        final rowBytes = cropWidth * bytesPerPixel;

        croppedBytes.setRange(
          dstRowStart,
          dstRowStart + rowBytes,
          originalBytes,
          srcRowStart,
        );
      }

      return croppedBytes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ImageProcessingUtil] BGRA8888 crop failed: $e');
      }
      return null;
    }
  }

  /// Create minimal valid image bytes for unsupported formats
  static Uint8List _createMinimalImageBytes(
    int width,
    int height,
    mlkit.InputImageFormat format,
  ) {
    int bytesPerPixel;
    switch (format) {
      case mlkit.InputImageFormat.nv21:
      case mlkit.InputImageFormat.yuv420:
        // Y plane + UV plane
        return Uint8List(width * height + width * height ~/ 2);
      case mlkit.InputImageFormat.bgra8888:
        bytesPerPixel = 4;
        break;
      default:
        bytesPerPixel = 3;
    }

    return Uint8List(width * height * bytesPerPixel);
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Calculate bytes per row for the given width and format
  static int calculateBytesPerRow(int width, mlkit.InputImageFormat format) {
    switch (format) {
      case mlkit.InputImageFormat.nv21:
      case mlkit.InputImageFormat.yuv420:
        return width; // Y plane
      case mlkit.InputImageFormat.bgra8888:
        return width * 4; // 4 bytes per pixel
      default:
        return width * 3; // Default to 3 bytes per pixel
    }
  }
}
