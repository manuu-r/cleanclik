import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class CardRenderer {
  static const double _pixelRatio = 2.0;
  
  /// Renders a Flutter widget to an image
  Future<ui.Image> renderWidget(Widget widget, Size size) async {
    try {
      final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
      
      final RenderView renderView = RenderView(
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          logicalConstraints: BoxConstraints.tight(size),
          devicePixelRatio: _pixelRatio,
        ),
        view: WidgetsBinding.instance.platformDispatcher.views.first,
      );
      
      final PipelineOwner pipelineOwner = PipelineOwner();
      final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
      
      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();
      
      final RenderObjectToWidgetElement<RenderBox> rootElement =
          RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              devicePixelRatio: _pixelRatio,
              textScaler: TextScaler.linear(1.0),
            ),
            child: widget,
          ),
        ),
      ).attachToRenderTree(buildOwner);
      
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();
      
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();
      
      final ui.Image image = await repaintBoundary.toImage(pixelRatio: _pixelRatio);
      
      // Cleanup
      rootElement.unmount();
      
      return image;
    } catch (e) {
      throw CardRenderingException(
        message: 'Failed to render widget to image',
        originalError: e,
      );
    }
  }
  
  /// Saves an image to a file
  Future<File> saveAsImage(ui.Image image, String filename) async {
    try {
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
  Future<File> renderAndSave(Widget widget, Size size, String filename) async {
    final ui.Image image = await renderWidget(widget, size);
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
  
  const CardRenderingException({
    required this.message,
    this.originalError,
  });
  
  @override
  String toString() => 'CardRenderingException: $message';
}