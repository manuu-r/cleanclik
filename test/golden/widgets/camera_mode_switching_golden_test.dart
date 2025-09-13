import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_widgets.dart';

void main() {
  group('Camera Mode Switching Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    group('CameraModeSwitching', () {
      testGoldens('CameraModeSwitching ML detection mode', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: CameraModeSwitching(),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Container),
          matchesGoldenFile('camera_mode_switching_ml.png'),
        );
      });

      testGoldens('CameraModeSwitching dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: CameraModeSwitching(),
            ),
          ),
          theme: ThemeData.dark(),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Container),
          matchesGoldenFile('camera_mode_switching_dark.png'),
        );
      });

      testGoldens('CameraModeSwitching tablet layout', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 1024,
            height: 768,
            color: Colors.black,
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: CameraModeSwitching(),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(1024, 768),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Container),
          matchesGoldenFile('camera_mode_switching_tablet.png'),
        );
      });
    });

    group('QRScannerOverlay', () {
      testGoldens('QRScannerOverlay active scanning', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const QRScannerOverlay(
              isScanning: true,
              screenSize: Size(375, 812),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Container),
          matchesGoldenFile('qr_scanner_overlay_active.png'),
        );
      });

      testGoldens('QRScannerOverlay with detected QR code', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const QRScannerOverlay(
              isScanning: true,
              screenSize: Size(375, 812),
              detectedQRCode: 'BIN_001_RECYCLE',
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Container),
          matchesGoldenFile('qr_scanner_overlay_detected.png'),
        );
      });

      testGoldens('QRScannerOverlay with error state', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const QRScannerOverlay(
              isScanning: false,
              screenSize: Size(375, 812),
              errorMessage: 'Invalid QR code format',
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Container),
          matchesGoldenFile('qr_scanner_overlay_error.png'),
        );
      });

      testGoldens('QRScannerOverlay dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const QRScannerOverlay(
              isScanning: true,
              screenSize: Size(375, 812),
            ),
          ),
          theme: ThemeData.dark(),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Container),
          matchesGoldenFile('qr_scanner_overlay_dark.png'),
        );
      });
    });

    group('Mode Switching Interactions', () {
      testGoldens('Mode switching with accessibility', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: CameraModeSwitching(),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
          wrapper: (child) => MediaQuery(
            data: const MediaQueryData(
              textScaleFactor: 1.5,
              boldText: true,
            ),
            child: child,
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(Container),
          matchesGoldenFile('mode_switching_accessibility.png'),
        );
      });
    });
  });
}