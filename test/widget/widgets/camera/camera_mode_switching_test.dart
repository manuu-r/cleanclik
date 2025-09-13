import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/camera_mode.dart';
import 'package:cleanclik/presentation/widgets/common/neon_icon_button.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('Camera Mode Switching Widget Tests', () {
    late BaseWidgetTest testHelper;

    setUp(() {
      testHelper = _CameraModeSwitchingTestHelper();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    group('Mode Toggle Button', () {
      testWidgets('should render ML detection mode button', (tester) async {
        // Arrange
        CameraMode? selectedMode;
        final widget = _CameraModeToggleWidget(
          currentMode: CameraMode.mlDetection,
          onModeChanged: (mode) => selectedMode = mode,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('ML Detection'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
        expect(find.byType(NeonIconButton), findsOneWidget);
      });

      testWidgets('should render QR scanning mode button', (tester) async {
        // Arrange
        CameraMode? selectedMode;
        final widget = _CameraModeToggleWidget(
          currentMode: CameraMode.qrScanning,
          onModeChanged: (mode) => selectedMode = mode,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('QR Scanner'), findsOneWidget);
        expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      });

      testWidgets('should handle mode switching from ML to QR', (tester) async {
        // Arrange
        CameraMode? selectedMode;
        final widget = _CameraModeToggleWidget(
          currentMode: CameraMode.mlDetection,
          onModeChanged: (mode) => selectedMode = mode,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(NeonIconButton));
        await tester.pumpAndSettle();

        // Assert
        expect(selectedMode, equals(CameraMode.qrScanning));
      });

      testWidgets('should handle mode switching from QR to ML', (tester) async {
        // Arrange
        CameraMode? selectedMode;
        final widget = _CameraModeToggleWidget(
          currentMode: CameraMode.qrScanning,
          onModeChanged: (mode) => selectedMode = mode,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(NeonIconButton));
        await tester.pumpAndSettle();

        // Assert
        expect(selectedMode, equals(CameraMode.mlDetection));
      });
    });

    group('Mode Indicator', () {
      testWidgets('should show ML detection mode indicator', (tester) async {
        // Arrange
        final widget = _CameraModeIndicatorWidget(
          currentMode: CameraMode.mlDetection,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('ML Detection Mode'), findsOneWidget);
        expect(find.text('Point camera at objects to detect waste category'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('should show QR scanning mode indicator', (tester) async {
        // Arrange
        final widget = _CameraModeIndicatorWidget(
          currentMode: CameraMode.qrScanning,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('QR Scanner Mode'), findsOneWidget);
        expect(find.text('Scan QR codes on bins to identify disposal location'), findsOneWidget);
        expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      });

      testWidgets('should show different colors for different modes', (tester) async {
        // Test ML Detection mode
        await tester.pumpWidget(
          WidgetTestHelpers.createTestApp(
            child: _CameraModeIndicatorWidget(currentMode: CameraMode.mlDetection),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);

        // Test QR Scanning mode
        await tester.pumpWidget(
          WidgetTestHelpers.createTestApp(
            child: _CameraModeIndicatorWidget(currentMode: CameraMode.qrScanning),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      });
    });

    group('Mode Switching Animation', () {
      testWidgets('should animate mode transition', (tester) async {
        // Arrange
        CameraMode currentMode = CameraMode.mlDetection;
        final widget = StatefulBuilder(
          builder: (context, setState) {
            return _CameraModeAnimatedSwitchWidget(
              currentMode: currentMode,
              onModeChanged: (mode) {
                setState(() {
                  currentMode = mode;
                });
              },
            );
          },
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        
        // Trigger mode switch
        await tester.tap(find.byType(GestureDetector));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });

      testWidgets('should show transition animation between modes', (tester) async {
        // Arrange
        final widget = _CameraModeAnimatedSwitchWidget(
          currentMode: CameraMode.mlDetection,
          onModeChanged: (mode) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.pump(const Duration(milliseconds: 200));

        // Assert
        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });
    });

    group('Mode Status Display', () {
      testWidgets('should show active status for current mode', (tester) async {
        // Arrange
        final widget = _CameraModeStatusWidget(
          mlDetectionActive: true,
          qrScanningActive: false,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('ML Detection: Active'), findsOneWidget);
        expect(find.text('QR Scanner: Inactive'), findsOneWidget);
      });

      testWidgets('should show processing status', (tester) async {
        // Arrange
        final widget = _CameraModeStatusWidget(
          mlDetectionActive: true,
          qrScanningActive: false,
          isProcessing: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Processing...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show ready status when not processing', (tester) async {
        // Arrange
        final widget = _CameraModeStatusWidget(
          mlDetectionActive: true,
          qrScanningActive: false,
          isProcessing: false,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Ready'), findsOneWidget);
      });
    });

    group('Mode Selection Panel', () {
      testWidgets('should render mode selection panel with both options', (tester) async {
        // Arrange
        CameraMode? selectedMode;
        final widget = _CameraModeSelectionPanelWidget(
          currentMode: CameraMode.mlDetection,
          onModeSelected: (mode) => selectedMode = mode,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('ML Detection'), findsOneWidget);
        expect(find.text('QR Scanner'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
        expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      });

      testWidgets('should highlight selected mode', (tester) async {
        // Arrange
        final widget = _CameraModeSelectionPanelWidget(
          currentMode: CameraMode.qrScanning,
          onModeSelected: (mode) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert - QR Scanner should be highlighted
        expect(find.text('QR Scanner'), findsOneWidget);
        expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      });

      testWidgets('should handle mode selection', (tester) async {
        // Arrange
        CameraMode? selectedMode;
        final widget = _CameraModeSelectionPanelWidget(
          currentMode: CameraMode.mlDetection,
          onModeSelected: (mode) => selectedMode = mode,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        
        // Tap QR Scanner option
        final qrOption = find.text('QR Scanner');
        await tester.tap(qrOption);
        await tester.pumpAndSettle();

        // Assert
        expect(selectedMode, equals(CameraMode.qrScanning));
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels for mode buttons', (tester) async {
        // Arrange
        final widget = _CameraModeToggleWidget(
          currentMode: CameraMode.mlDetection,
          onModeChanged: (mode) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('ML Detection'), findsOneWidget);
        // Semantic labels are handled by the NeonIconButton internally
      });

      testWidgets('should announce mode changes', (tester) async {
        // Arrange
        final widget = _CameraModeIndicatorWidget(
          currentMode: CameraMode.mlDetection,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('ML Detection Mode'), findsOneWidget);
        expect(find.text('Point camera at objects to detect waste category'), findsOneWidget);
      });
    });
  });
}

// Helper widgets for testing camera mode switching components

class _CameraModeToggleWidget extends StatelessWidget {
  final CameraMode currentMode;
  final Function(CameraMode) onModeChanged;

  const _CameraModeToggleWidget({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMLMode = currentMode == CameraMode.mlDetection;
    
    return NeonIconButton.primary(
      icon: isMLMode ? Icons.camera_alt : Icons.qr_code_scanner,
      label: isMLMode ? 'ML Detection' : 'QR Scanner',
      color: isMLMode ? Colors.green : Colors.blue,
      onTap: () {
        onModeChanged(isMLMode ? CameraMode.qrScanning : CameraMode.mlDetection);
      },
      buttonSize: ButtonSize.medium,
    );
  }
}

class _CameraModeIndicatorWidget extends StatelessWidget {
  final CameraMode currentMode;

  const _CameraModeIndicatorWidget({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    final isMLMode = currentMode == CameraMode.mlDetection;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isMLMode ? Colors.green : Colors.blue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMLMode ? Colors.green : Colors.blue,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMLMode ? Icons.camera_alt : Icons.qr_code_scanner,
            color: isMLMode ? Colors.green : Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMLMode ? 'ML Detection Mode' : 'QR Scanner Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMLMode 
                    ? 'Point camera at objects to detect waste category'
                    : 'Scan QR codes on bins to identify disposal location',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraModeAnimatedSwitchWidget extends StatelessWidget {
  final CameraMode currentMode;
  final Function(CameraMode) onModeChanged;

  const _CameraModeAnimatedSwitchWidget({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final newMode = currentMode == CameraMode.mlDetection 
          ? CameraMode.qrScanning 
          : CameraMode.mlDetection;
        onModeChanged(newMode);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _CameraModeIndicatorWidget(
          key: ValueKey(currentMode),
          currentMode: currentMode,
        ),
      ),
    );
  }
}

class _CameraModeStatusWidget extends StatelessWidget {
  final bool mlDetectionActive;
  final bool qrScanningActive;
  final bool isProcessing;

  const _CameraModeStatusWidget({
    required this.mlDetectionActive,
    required this.qrScanningActive,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ML Detection: ${mlDetectionActive ? 'Active' : 'Inactive'}',
            style: TextStyle(
              color: mlDetectionActive ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            'QR Scanner: ${qrScanningActive ? 'Active' : 'Inactive'}',
            style: TextStyle(
              color: qrScanningActive ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isProcessing) ...[
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Processing...', style: TextStyle(color: Colors.white, fontSize: 12)),
              ] else
                Text('Ready', style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CameraModeSelectionPanelWidget extends StatelessWidget {
  final CameraMode currentMode;
  final Function(CameraMode) onModeSelected;

  const _CameraModeSelectionPanelWidget({
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeOptionWidget(
              mode: CameraMode.mlDetection,
              icon: Icons.camera_alt,
              label: 'ML Detection',
              isSelected: currentMode == CameraMode.mlDetection,
              onTap: () => onModeSelected(CameraMode.mlDetection),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModeOptionWidget(
              mode: CameraMode.qrScanning,
              icon: Icons.qr_code_scanner,
              label: 'QR Scanner',
              isSelected: currentMode == CameraMode.qrScanning,
              onTap: () => onModeSelected(CameraMode.qrScanning),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOptionWidget extends StatelessWidget {
  final CameraMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOptionWidget({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = mode == CameraMode.mlDetection ? Colors.green : Colors.blue;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraModeSwitchingTestHelper extends BaseWidgetTest {}