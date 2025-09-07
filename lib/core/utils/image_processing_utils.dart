import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';

/// Utility class for image processing operations
class ImageProcessingUtils {
  /// Convert YUV420 camera image to RGB bytes
  static Uint8List convertYuv420ToRgb(CameraImage cameraImage) {
    final yBuffer = cameraImage.planes[0].bytes;
    final uBuffer = cameraImage.planes[1].bytes;
    final vBuffer = cameraImage.planes[2].bytes;
    
    final width = cameraImage.width;
    final height = cameraImage.height;
    final rgbBytes = Uint8List(width * height * 3);
    
    int rgbIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);
        
        if (yIndex < yBuffer.length && uvIndex < uBuffer.length && uvIndex < vBuffer.length) {
          final yValue = yBuffer[yIndex];
          final uValue = uBuffer[uvIndex] - 128;
          final vValue = vBuffer[uvIndex] - 128;
          
          // YUV to RGB conversion
          int r = (yValue + 1.402 * vValue).round().clamp(0, 255);
          int g = (yValue - 0.344136 * uValue - 0.714136 * vValue).round().clamp(0, 255);
          int b = (yValue + 1.772 * uValue).round().clamp(0, 255);
          
          rgbBytes[rgbIndex++] = r;
          rgbBytes[rgbIndex++] = g;
          rgbBytes[rgbIndex++] = b;
        }
      }
    }
    
    return rgbBytes;
  }

  /// Resize RGB image using nearest neighbor interpolation
  static Uint8List resizeRgbImage(
    Uint8List rgbBytes,
    int srcWidth,
    int srcHeight,
    int targetWidth,
    int targetHeight,
  ) {
    final resizedBytes = Uint8List(targetWidth * targetHeight * 3);
    
    final scaleX = srcWidth / targetWidth;
    final scaleY = srcHeight / targetHeight;
    
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final srcX = (x * scaleX).floor().clamp(0, srcWidth - 1);
        final srcY = (y * scaleY).floor().clamp(0, srcHeight - 1);
        
        final srcIndex = (srcY * srcWidth + srcX) * 3;
        final dstIndex = (y * targetWidth + x) * 3;
        
        if (srcIndex + 2 < rgbBytes.length && dstIndex + 2 < resizedBytes.length) {
          resizedBytes[dstIndex] = rgbBytes[srcIndex];         // R
          resizedBytes[dstIndex + 1] = rgbBytes[srcIndex + 1]; // G
          resizedBytes[dstIndex + 2] = rgbBytes[srcIndex + 2]; // B
        }
      }
    }
    
    return resizedBytes;
  }

  /// Normalize RGB bytes to float32 range
  /// [normalize01] = true: [0, 1] range (typical for MediaPipe)
  /// [normalize01] = false: [-1, 1] range (typical for some TensorFlow models)
  static Float32List normalizeRgbToFloat32(Uint8List rgbBytes, {bool normalize01 = false}) {
    final normalizedBytes = Float32List(rgbBytes.length);
    
    if (normalize01) {
      // Normalize to [0, 1] range
      for (int i = 0; i < rgbBytes.length; i++) {
        normalizedBytes[i] = rgbBytes[i] / 255.0;
      }
    } else {
      // Normalize to [-1, 1] range
      for (int i = 0; i < rgbBytes.length; i++) {
        normalizedBytes[i] = (rgbBytes[i] / 127.5) - 1.0;
      }
    }
    
    return normalizedBytes;
  }

  /// Extract region from RGB image
  static Uint8List extractRgbRegion(
    Uint8List rgbBytes,
    int imageWidth,
    int imageHeight,
    int regionX,
    int regionY,
    int regionWidth,
    int regionHeight,
  ) {
    final extractedBytes = Uint8List(regionWidth * regionHeight * 3);
    
    // Clamp region to image bounds
    final clampedX = regionX.clamp(0, imageWidth - regionWidth);
    final clampedY = regionY.clamp(0, imageHeight - regionHeight);
    final clampedWidth = regionWidth.clamp(1, imageWidth - clampedX);
    final clampedHeight = regionHeight.clamp(1, imageHeight - clampedY);
    
    int extractedIndex = 0;
    for (int y = 0; y < clampedHeight; y++) {
      for (int x = 0; x < clampedWidth; x++) {
        final srcX = clampedX + x;
        final srcY = clampedY + y;
        final srcIndex = (srcY * imageWidth + srcX) * 3;
        
        if (srcIndex + 2 < rgbBytes.length && extractedIndex + 2 < extractedBytes.length) {
          extractedBytes[extractedIndex++] = rgbBytes[srcIndex];     // R
          extractedBytes[extractedIndex++] = rgbBytes[srcIndex + 1]; // G
          extractedBytes[extractedIndex++] = rgbBytes[srcIndex + 2]; // B
        }
      }
    }
    
    return extractedBytes;
  }

  /// Convert RGB bytes to grayscale
  static Uint8List rgbToGrayscale(Uint8List rgbBytes) {
    final grayscaleBytes = Uint8List(rgbBytes.length ~/ 3);
    
    for (int i = 0; i < grayscaleBytes.length; i++) {
      final rgbIndex = i * 3;
      if (rgbIndex + 2 < rgbBytes.length) {
        final r = rgbBytes[rgbIndex];
        final g = rgbBytes[rgbIndex + 1];
        final b = rgbBytes[rgbIndex + 2];
        
        // Standard grayscale conversion
        grayscaleBytes[i] = (0.299 * r + 0.587 * g + 0.114 * b).round();
      }
    }
    
    return grayscaleBytes;
  }

  /// Apply Gaussian blur to RGB image (simplified)
  static Uint8List applyGaussianBlur(
    Uint8List rgbBytes,
    int width,
    int height,
    double sigma,
  ) {
    // Simplified blur implementation
    final blurredBytes = Uint8List.fromList(rgbBytes);
    final kernelSize = (sigma * 3).ceil();
    
    // Horizontal pass
    for (int y = 0; y < height; y++) {
      for (int x = kernelSize; x < width - kernelSize; x++) {
        for (int c = 0; c < 3; c++) {
          double sum = 0;
          double weightSum = 0;
          
          for (int kx = -kernelSize; kx <= kernelSize; kx++) {
            final weight = math.exp(-(kx * kx) / (2 * sigma * sigma));
            final index = (y * width + x + kx) * 3 + c;
            
            if (index >= 0 && index < rgbBytes.length) {
              sum += rgbBytes[index] * weight;
              weightSum += weight;
            }
          }
          
          final resultIndex = (y * width + x) * 3 + c;
          if (resultIndex < blurredBytes.length) {
            blurredBytes[resultIndex] = (sum / weightSum).round().clamp(0, 255);
          }
        }
      }
    }
    
    return blurredBytes;
  }

  /// Calculate image histogram for RGB channels
  static Map<String, List<int>> calculateRgbHistogram(Uint8List rgbBytes) {
    final rHistogram = List.filled(256, 0);
    final gHistogram = List.filled(256, 0);
    final bHistogram = List.filled(256, 0);
    
    for (int i = 0; i < rgbBytes.length; i += 3) {
      if (i + 2 < rgbBytes.length) {
        rHistogram[rgbBytes[i]]++;
        gHistogram[rgbBytes[i + 1]]++;
        bHistogram[rgbBytes[i + 2]]++;
      }
    }
    
    return {
      'r': rHistogram,
      'g': gHistogram,
      'b': bHistogram,
    };
  }

  /// Enhance image contrast using histogram equalization
  static Uint8List enhanceContrast(Uint8List rgbBytes) {
    final enhancedBytes = Uint8List(rgbBytes.length);
    final histogram = calculateRgbHistogram(rgbBytes);
    
    // Calculate cumulative distribution function for each channel
    final rCdf = _calculateCdf(histogram['r']!);
    final gCdf = _calculateCdf(histogram['g']!);
    final bCdf = _calculateCdf(histogram['b']!);
    
    // Apply histogram equalization
    for (int i = 0; i < rgbBytes.length; i += 3) {
      if (i + 2 < rgbBytes.length) {
        enhancedBytes[i] = rCdf[rgbBytes[i]];
        enhancedBytes[i + 1] = gCdf[rgbBytes[i + 1]];
        enhancedBytes[i + 2] = bCdf[rgbBytes[i + 2]];
      }
    }
    
    return enhancedBytes;
  }

  /// Calculate cumulative distribution function
  static List<int> _calculateCdf(List<int> histogram) {
    final cdf = List<int>.filled(256, 0);
    final totalPixels = histogram.reduce((a, b) => a + b);
    
    if (totalPixels == 0) return cdf;
    
    int cumulative = 0;
    for (int i = 0; i < 256; i++) {
      cumulative += histogram[i];
      cdf[i] = ((cumulative * 255) / totalPixels).round();
    }
    
    return cdf;
  }
}