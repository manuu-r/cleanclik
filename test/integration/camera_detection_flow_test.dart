import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:camera/camera.dart';

import '../helpers/base_integration_test.dart';
import '../helpers/mock_services.dart';
import '../fixtures/test_data_factory.dart';
import '../../lib/core/models/detected_object.dart';
import '../../lib/core/models/waste_category.dart';
import '../../lib/core/models/camera_mode.dart';
import '../../lib/core/models/camera_state.dart';
import '../../lib/core/providers/camera_provider.dart';
import '../../lib/core/providers/ml_detection_provider.dart';
import '../../lib/presentation/screens/camera/ar_camera_screen.dart';
import '../../lib/presentation/widgets/camera/enhanced_object_overlay.dart';
import '../../lib/presentation/widgets/camera/qr_scanner_overlay.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Camera Detection Workflow Integration Tests', () {
    late MockMLDetectionService mockMLService;
    late MockQRBinService mockQRService;
    late MockCameraService mockCameraService;
    late MockInventoryService mockInventoryService;
    late ProviderContainer container;

    setUp(() {
      mockMLService = MockMLDetectionService();
      mockQRService = MockQRBinService();
      mockCameraService = MockCameraService();
      mockInventoryService = MockInventoryService();
      
      container = ProviderContainer(
        overrides: [
          mlDetectionServiceProvider.overrideWithValue(mockMLService),
          qrBinServiceProvider.overrideWithValue(mockQRService),
          cameraServiceProvider.overrideWithValue(mockCameraService),
          inventoryServiceProvider.overrideWithValue(mockInventoryService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete ML object detection workflow', (tester) async {
      // Arrange
      final detectedObject = TestDataFactory.createMockDetectedObject(
        category: WasteCategory.recycle,
        confidence: 0.95,
        label: 'Plastic Bottle',
      );

      when(mockCameraService.initialize()).thenAnswer((_) async {});
      when(mockCameraService.startImageStream(any)).thenAnswer((_) async {});
      when(mockCameraService.cameraState)
          .thenReturn(const CameraState.ready(CameraMode.mlDetection));
      
      when(mockMLService.processImage(any))
          .thenAnswer((_) async => [detectedObject]);
      when(mockMLService.detectedObjectsStream)
          .thenAnswer((_) => Stream.value([detectedObject]));

      when(mockInventoryService.addDetectedObject(any))
          .thenAnswer((_) async {});

      // Act & Assert - Start camera screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ARCameraScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify camera initialization
      verify(mockCameraService.initialize()).called(1);
      verify(mockCameraService.startImageStream(any)).called(1);

      // Verify ML detection mode is active
      expect(find.byType(EnhancedObjectOverlay), findsOneWidget);
      
      // Wait for object detection
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify detected object is displayed
      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget); // Confidence level
      expect(find.text('Recycle'), findsOneWidget);

      // Tap on detected object to add to inventory
      await tester.tap(find.byKey(Key('detected_object_${detectedObject.id}')));
      await tester.pumpAndSettle();

      // Verify object was added to inventory
      verify(mockInventoryService.addDetectedObject(detectedObject)).called(1);

      // Verify success feedback
      expect(find.text('Added to inventory!'), findsOneWidget);
    });

    testWidgets('QR bin scanning workflow', (tester) async {
      // Arrange
      final binData = TestDataFactory.createMockBinLocation(
        binId: 'BIN_001',
        category: WasteCategory.recycle,
      );

      when(mockCameraService.initialize()).thenAnswer((_) async {});
      when(mockCameraService.switchMode(CameraMode.qrScanning))
          .thenAnswer((_) async {});
      when(mockCameraService.cameraState)
          .thenReturn(const CameraState.ready(CameraMode.qrScanning));

      when(mockQRService.scanQRCode(any))
          .thenAnswer((_) async => binData);
      when(mockQRService.qrScanResultStream)
          .thenAnswer((_) => Stream.value(binData));

      // Act & Assert - Start in ML mode, then switch to QR
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ARCameraScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to QR scanning mode
      await tester.tap(find.byKey(const Key('qr_mode_button')));
      await tester.pumpAndSettle();

      // Verify mode switch
      verify(mockCameraService.switchMode(CameraMode.qrScanning)).called(1);
      expect(find.byType(QRScannerOverlay), findsOneWidget);

      // Simulate QR code detection
      await tester.pump(const Duration(milliseconds: 500));

      // Verify QR scan result is displayed
      expect(find.text('Bin Found!'), findsOneWidget);
      expect(find.text('BIN_001'), findsOneWidget);
      expect(find.text('Recycle Bin'), findsOneWidget);

      // Verify scan result was processed
      verify(mockQRService.scanQRCode(any)).called(1);
    });

    testWidgets('Camera mode switching workflow', (tester) async {
      // Arrange
      when(mockCameraService.initialize()).thenAnswer((_) async {});
      when(mockCameraService.switchMode(any)).thenAnswer((_) async {});
      when(mockCameraService.cameraState)
          .thenReturn(const CameraState.ready(CameraMode.mlDetection));

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ARCameraScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial ML detection mode
      expect(find.byType(EnhancedObjectOverlay), findsOneWidget);
      expect(find.byKey(const Key('ml_mode_indicator')), findsOneWidget);

      // Switch to QR scanning mode
      await tester.tap(find.byKey(const Key('qr_mode_button')));
      await tester.pumpAndSettle();

      // Verify mode switch
      verify(mockCameraService.switchMode(CameraMode.qrScanning)).called(1);
      
      // Update mock to return QR mode
      when(mockCameraService.cameraState)
          .thenReturn(const CameraState.ready(CameraMode.qrScanning));
      
      await tester.pump();

      // Verify QR mode UI
      expect(find.byType(QRScannerOverlay), findsOneWidget);
      expect(find.byKey(const Key('qr_mode_indicator')), findsOneWidget);

      // Switch back to ML detection
      await tester.tap(find.byKey(const Key('ml_mode_button')));
      await tester.pumpAndSettle();

      // Verify mode switch back
      verify(mockCameraService.switchMode(CameraMode.mlDetection)).called(1);
    });

    testWidgets('Multiple object detection and tracking', (tester) async {
      // Arrange
      final objects = [
        TestDataFactory.createMockDetectedObject(
          id: 'obj1',
          category: WasteCategory.recycle,
          label: 'Plastic Bottle',
          confidence: 0.95,
        ),
        TestDataFactory.createMockDetectedObject(
          id: 'obj2',
          category: WasteCategory.organic,
          label: 'Apple Core',
          confidence: 0.88,
        ),
        TestDataFactory.createMockDetectedObject(
          id: 'obj3',
          category: WasteCategory.ewaste,
          label: 'Old Phone',
          confidence: 0.92,
        ),
      ];

      when(mockCameraService.initialize()).thenAnswer((_) async {});
      when(mockCameraService.startImageStream(any)).thenAnswer((_) async {});
      when(mockCameraService.cameraState)
          .thenReturn(const CameraState.ready(CameraMode.mlDetection));

      when(mockMLService.processImage(any))
          .thenAnswer((_) async => objects);
      when(mockMLService.detectedObjectsStream)
          .thenAnswer((_) => Stream.value(objects));

      when(mockInventoryService.addDetectedObject(any))
          .thenAnswer((_) async {});

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ARCameraScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Wait for object detection
      await tester.pump(const Duration(milliseconds: 500));

      // Verify all objects are displayed
      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('Apple Core'), findsOneWidget);
      expect(find.text('Old Phone'), findsOneWidget);

      // Verify confidence levels
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);

      // Add each object to inventory
      for (final obj in objects) {
        await tester.tap(find.byKey(Key('detected_object_${obj.id}')));
        await tester.pumpAndSettle();
        
        verify(mockInventoryService.addDetectedObject(obj)).called(1);
      }

      // Verify success messages
      expect(find.text('Added to inventory!'), findsWidgets);
    });

    testWidgets('Camera error handling and recovery', (tester) async {
      // Arrange
      when(mockCameraService.initialize())
          .thenThrow(CameraException('camera_error', 'Camera not available'));
      when(mockCameraService.cameraState)
          .thenReturn(const CameraState.error('Camera not available'));

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ARCameraScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify error state is displayed
      expect(find.text('Camera Error'), findsOneWidget);
      expect(find.text('Camera not available'), findsOneWidget);
      expect(find.byKey(const Key('retry_camera_button')), findsOneWidget);

      // Test retry functionality
      when(mockCameraService.initialize()).thenAnswer((_) async {});
      when(mockCameraService.cameraState)
          .thenReturn(const CameraState.ready(CameraMode.mlDetection));

      await tester.tap(find.byKey(const Key('retry_camera_button')));
      await tester.pumpAndSettle();

      // Verify camera recovery
      verify(mockCameraService.initialize()).called(2); // Initial + retry
      expect(find.byType(EnhancedObjectOverlay), findsOneWidget);
    });

    testWidgets('Low confidence object filtering', (tester) async {
      // Arrange
      final lowConfidenceObject = TestDataFactory.createMockDetectedObject(
        category: WasteCategory.recycle,
        confidence: 0.45, // Below threshold
        label: 'Unclear Object',
      );
      final highConfidenceObject = TestDataFactory.createMockDetectedObject(
        category: WasteCategory.organic,
        confidence: 0.85, // Above threshold
        label: 'Clear Object',
      );

      when(mockCameraService.initialize()).thenAnswer((_) async {});
      when(mockCameraService.startImageStream(any)).thenAnswer((_) async {});
      when(mockCameraService.cameraState)
          .thenReturn(const CameraState.ready(CameraMode.mlDetection));

      when(mockMLService.processImage(any))
          .thenAnswer((_) async => [lowConfidenceObject, highConfidenceObject]);
      when(mockMLService.detectedObjectsStream)
          .thenAnswer((_) => Stream.value([highConfidenceObject])); // Filtered

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ARCameraScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Wait for object detection
      await tester.pump(const Duration(milliseconds: 500));

      // Verify only high confidence object is displayed
      expect(find.text('Clear Object'), findsOneWidget);
      expect(find.text('Unclear Object'), findsNothing);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('45%'), findsNothing);
    });
  });
}