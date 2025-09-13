import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cleanclik/core/theme/app_colors.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

class CardRenderer {
  Future<ui.Image> renderWidget(
    Widget widget,
    Size size, {
    Map<String, dynamic>? userData,
  }) async {
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Theme Colors
      const Color backgroundColor = AppColors.darkSurface;
      const Color primaryColor = NeonColors.electricGreen;
      const Color onSurfaceColor = AppColors.darkOnSurface;

      // Background
      canvas.drawColor(backgroundColor, BlendMode.src);

      // User Data
      final userName = userData?['userName'] ?? 'Eco Warrior';
      final totalPoints = userData?['totalPoints'] ?? 0;
      final totalItems = userData?['totalItems'] ?? 0;

      // Draw abstract shapes
      _drawAbstractShapes(canvas, size, primaryColor, onSurfaceColor);

      // Layout
      final double padding = size.width * 0.1;

      // Header
      final brandPainter = _createTextPainter(
        'CleanClik',
        size.width * 0.12,
        FontWeight.bold,
        primaryColor,
        size.width * 0.8,
        align: TextAlign.left,
      );
      brandPainter.paint(canvas, Offset(padding, padding));

      // Footer (User Info)
      final double footerY = size.height - padding - 100;

      final namePainter = _createTextPainter(
        userName.toUpperCase(),
        size.width * 0.04,
        FontWeight.bold,
        primaryColor,
        size.width * 0.8,
        align: TextAlign.left,
      );
      namePainter.paint(canvas, Offset(padding, footerY));

      final pointsPainter = _createTextPainter(
        '$totalPoints POINTS',
        size.width * 0.045,
        FontWeight.normal,
        onSurfaceColor,
        size.width * 0.8,
        align: TextAlign.left,
      );
      pointsPainter.paint(
        canvas,
        Offset(padding, footerY + namePainter.height),
      );

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(
        size.width.round(),
        size.height.round(),
      );
      picture.dispose();
      return image;
    } catch (e) {
      throw CardRenderingException(
        message: 'Failed to render widget to image: $e',
        originalError: e,
      );
    }
  }

  void _drawAbstractShapes(
    Canvas canvas,
    Size size,
    Color primaryColor,
    Color onSurfaceColor,
  ) {
    // Large circle
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      size.width * 0.2,
      Paint()..color = primaryColor,
    );

    // Small circle
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.5),
      size.width * 0.05,
      Paint()..color = primaryColor,
    );

    // Another small circle
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.8),
      size.width * 0.08,
      Paint()..color = primaryColor,
    );

    // Hand-drawn circle
    final path = Path();
    path.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.3, size.height * 0.7),
        radius: size.width * 0.1,
      ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = onSurfaceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Dashed lines
    final dashPaint = Paint()
      ..color = onSurfaceColor
      ..strokeWidth = 1;
    for (int i = 0; i < 10; i++) {
      final start = Offset(size.width * 0.1, size.height * 0.1 + i * 10);
      final end = Offset(size.width * 0.2, size.height * 0.1 + i * 10);
      canvas.drawLine(start, end, dashPaint);
    }
  }

  TextPainter _createTextPainter(
    String text,
    double fontSize,
    FontWeight fontWeight,
    Color color,
    double maxWidth, {
    TextAlign align = TextAlign.center,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter;
  }

  /// Saves an image to a file
  Future<File> saveAsImage(ui.Image image, String filename) async {
    try {
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw CardRenderingException(
          message: 'Failed to convert image to byte data',
        );
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$filename');

      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw CardRenderingException(
        message: 'Failed to save image to file',
        originalError: e,
      );
    }
  }

  /// Gets image bytes without saving to file
  Future<Uint8List> getImageBytes(ui.Image image) async {
    try {
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw CardRenderingException(
          message: 'Failed to convert image to byte data',
        );
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      throw CardRenderingException(
        message: 'Failed to get image bytes',
        originalError: e,
      );
    }
  }

  /// Renders widget and saves directly to file
  Future<File> renderAndSave(
    Widget widget,
    Size size,
    String filename, {
    Map<String, dynamic>? userData,
  }) async {
    final ui.Image image = await renderWidget(widget, size, userData: userData);
    try {
      final File file = await saveAsImage(image, filename);
      return file;
    } finally {
      image.dispose();
    }
  }

  /// Renders widget and returns bytes
  Future<Uint8List> renderToBytes(Widget widget, Size size) async {
    final ui.Image image = await renderWidget(widget, size);
    try {
      return await getImageBytes(image);
    } finally {
      image.dispose();
    }
  }
}

class CardRenderingException implements Exception {
  final String message;
  final dynamic originalError;

  const CardRenderingException({required this.message, this.originalError});

  @override
  String toString() => 'CardRenderingException: $message';
}
