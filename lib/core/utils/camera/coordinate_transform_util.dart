import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Utility class for coordinate transformations and spatial calculations.
///
/// This class provides static methods to transform bounding boxes from the
/// camera's image coordinate system to the screen's UI coordinate system.
/// It also includes helper methods for spatial calculations like overlap
/// and distance, which are essential for object tracking.
class CoordinateTransformUtil {
  // Private constructor to prevent instantiation.
  CoordinateTransformUtil._();

  /// Transforms a bounding box from image coordinates to screen coordinates.
  ///
  /// This function accounts for differences in resolution, aspect ratio,
  /// and camera sensor orientation between the camera image and the screen preview.
  /// It also applies a size reduction to the bounding box to improve proximity accuracy.
  static Rect transformBoundingBox(
    Rect mlkitRect,
    Size imageSize,
    Size previewSize,
    CameraController cameraController,
  ) {
    final previewWidth = previewSize.width;
    final previewHeight = previewSize.height;

    // Get actual image dimensions accounting for camera rotation.
    final actualImageSize = _getActualImageSize(imageSize, cameraController);
    final imageWidth = actualImageSize.width;
    final imageHeight = actualImageSize.height;

    // Calculate scale factors.
    final scaleX = previewWidth / imageWidth;
    final scaleY = previewHeight / imageHeight;

    // Use uniform scaling to maintain aspect ratio.
    final scale = math.min(scaleX, scaleY);

    // Calculate actual preview area (may have letterboxing).
    final scaledImageWidth = imageWidth * scale;
    final scaledImageHeight = imageHeight * scale;

    // Calculate offsets for centering.
    final offsetX = (previewWidth - scaledImageWidth) / 2;
    final offsetY = (previewHeight - scaledImageHeight) / 2;

    // Apply transformation.
    final transformedLeft = mlkitRect.left * scale + offsetX;
    final transformedTop = mlkitRect.top * scale + offsetY;
    final transformedWidth = mlkitRect.width * scale;
    final transformedHeight = mlkitRect.height * scale;

    // Reduce bounding box size by 30% while maintaining center position
    // to improve proximity accuracy.
    const double sizeReduction = 0.30; // 30% reduction
    final reducedWidth = transformedWidth * (1.0 - sizeReduction);
    final reducedHeight = transformedHeight * (1.0 - sizeReduction);

    // Calculate new position to maintain center.
    final centerX = transformedLeft + transformedWidth / 2;
    final centerY = transformedTop + transformedHeight / 2;
    final newLeft = centerX - reducedWidth / 2;
    final newTop = centerY - reducedHeight / 2;

    return Rect.fromLTWH(
      newLeft.clamp(0, previewWidth),
      newTop.clamp(0, previewHeight),
      reducedWidth.clamp(0, previewWidth - newLeft),
      reducedHeight.clamp(0, previewHeight - newTop),
    );
  }

  /// Adjusts the image size based on the camera's sensor orientation.
  static Size _getActualImageSize(
    Size imageSize,
    CameraController cameraController,
  ) {
    final camera = cameraController.description;
    // Swap width and height for portrait orientations.
    if (camera.sensorOrientation == 90 || camera.sensorOrientation == 270) {
      return Size(imageSize.height, imageSize.width);
    }
    return imageSize;
  }

  /// Calculates the Intersection over Union (IoU) of two rectangles.
  ///
  /// This is used to determine how much two bounding boxes overlap, which is
  /// a key factor in tracking an object from one frame to the next.
  static double calculateBoundingBoxOverlap(Rect rect1, Rect rect2) {
    final intersectionLeft = math.max(rect1.left, rect2.left);
    final intersectionTop = math.max(rect1.top, rect2.top);
    final intersectionRight = math.min(rect1.right, rect2.right);
    final intersectionBottom = math.min(rect1.bottom, rect2.bottom);

    if (intersectionLeft >= intersectionRight ||
        intersectionTop >= intersectionBottom) {
      return 0.0;
    }

    final intersectionArea =
        (intersectionRight - intersectionLeft) *
        (intersectionBottom - intersectionTop);
    final unionArea =
        (rect1.width * rect1.height) +
        (rect2.width * rect2.height) -
        intersectionArea;

    return unionArea > 0 ? intersectionArea / unionArea : 0.0;
  }

  /// Calculates the distance between the centers of two rectangles.
  ///
  /// This is used in object tracking to help associate a detected object
  /// with its corresponding instance in the previous frame.
  static double calculateBoundingBoxDistance(Rect rect1, Rect rect2) {
    final center1 = rect1.center;
    final center2 = rect2.center;
    return (center1 - center2).distance;
  }
}
