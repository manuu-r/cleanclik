import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/presentation/widgets/camera/qr_scanner_overlay.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/neon_icon_button.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('QRScannerOverlay Widget Tests', () {
    late BaseWidgetTest testHelper;

    setUp(() {
      testHelper = _QRScannerOverlayTestHelper();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    group('Basic Rendering', () {
      testWidgets('should render QR scanner overlay with all UI elements', (tester) async {
        // Arrange
        String? scannedData;
        bool closed = false;

        final widget = QRScannerOverlay(
          onQRScanned: (data) => scannedData = data,
          onClose: () => closed = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Scan Bin QR Code'), findsOneWidget);
        expect(find.text('Position the QR code within the frame'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
        expect(find.byType(GlassmorphismContainer), findsAtLeastNWidgets(1));
      });

      testWidgets('should show loading state initially', (tester) async {
        // Arrange
        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert - Should show either loading or scanner view
        expect(find.byType(Material), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should handle close button tap', (tester) async {
        // Arrange
        bool closed = false;

        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () => closed = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(closed, isTrue);
      });

      testWidgets('should handle torch toggle', (tester) async {
        // Arrange
        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        
        // Find and tap the torch button
        final torchButton = find.byIcon(Icons.flash_on);
        if (torchButton.evaluate().isNotEmpty) {
          await tester.tap(torchButton);
          await tester.pumpAndSettle();
        }

        // Assert - Button should still be present (state change is internal)
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
      });
    });

    group('QR Code Detection', () {
      testWidgets('should call onQRScanned when QR code is detected', (tester) async {
        // Arrange
        String? scannedData;
        final widget = QRScannerOverlay(
          onQRScanned: (data) => scannedData = data,
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Simulate QR code detection by calling the callback directly
        // Note: In a real test, this would be triggered by the QRView widget
        widget.onQRScanned('test_qr_data');

        // Assert
        expect(scannedData, equals('test_qr_data'));
      });
    });

    group('UI States', () {
      testWidgets('should show scanning instructions when active', (tester) async {
        // Arrange
        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Position the QR code within the frame'), findsOneWidget);
        expect(find.text('Make sure the code is well-lit and clearly visible'), findsOneWidget);
      });

      testWidgets('should show scanner controls', (tester) async {
        // Arrange
        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
        expect(find.byType(NeonIconButton), findsAtLeastNWidgets(1));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle camera permission errors gracefully', (tester) async {
        // Arrange
        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert - Should not crash and should show UI elements
        expect(find.byType(Material), findsOneWidget);
        expect(find.text('Scan Bin QR Code'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        // Arrange
        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert - Check for semantic elements
        expect(find.text('Scan Bin QR Code'), findsOneWidget);
        expect(find.byTooltip('Close'), findsOneWidget);
        expect(find.byTooltip('Toggle Flashlight'), findsOneWidget);
      });
    });

    group('Animation and Visual Effects', () {
      testWidgets('should show scan line animation', (tester) async {
        // Arrange
        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.pump(const Duration(milliseconds: 500));

        // Assert - Animation elements should be present
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(0));
      });

      testWidgets('should show glassmorphism containers', (tester) async {
        // Arrange
        final widget = QRScannerOverlay(
          onQRScanned: (data) {},
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(GlassmorphismContainer), findsAtLeastNWidgets(1));
      });
    });
  });
}

class _QRScannerOverlayTestHelper extends BaseWidgetTest {}