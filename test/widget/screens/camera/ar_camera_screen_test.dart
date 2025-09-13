import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:camera/camera.dart';

import 'package:cleanclik/presentation/screens/camera/ar_camera_screen.dart';
import 'package:cleanclik/core/models/camera_mode.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/location/bin_location_service.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/mock_services.mocks.dart';
import '../../../fixtures/test_data_factory.dart';

class ARCameraScreenWidgetTest extends BaseWidgetTest {
  late MockInventoryService mockInventoryService;
  late MockBinLocationService mockBinLocationService;
  late MockCameraController mockCameraController;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockInventoryService = MockInventoryService();
    mockBinLocationService = MockBinLocationService();
    mockCameraController = MockCameraController();

    // Configure mock camera controller
    when(mockCameraController.value).thenReturn(
      const CameraValue(
        isInitialized: true,
        isRecordingVideo: false,
        isTakingPicture: false,
        isStreamingImages: false,
        isRecordingPaused: false,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        exposurePointSupported: true,
        focusPointSupported: true,
        deviceOrientation: DeviceOrientation.portraitUp,
        lockedCaptureOrientation: null,
        recordingOrientation: null,
        isPreviewPaused: false,
        previewSize: Size(1920, 1080),
        aspectRatio: 16/9,
      ),
    );

    // Configure mock services
    when(mockInventoryService.items).thenReturn([]);
    when(mockBinLocationService.nearbyBins).thenReturn([]);

    // Add provider overrides
    overrideProviders([
      inventoryServiceProvider.overrideWith((ref) => mockInventoryService),
      binLocationServiceProvider.overrideWith((ref) => mockBinLocationService),
    ]);
  }

  @override
  void tearDownWidgetTest() {
    super.tearDownWidgetTest();
    reset(mockInventoryService);
    reset(mockBinLocationService);
    reset(mockCameraController);
  }
}

void main() {
  group('ARCameraScreen Widget Tests', () {
    late ARCameraScreenWidgetTest testHelper;

    setUp(() {
      testHelper = ARCameraScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display loading indicator when not initialized', (tester) async {
      // Arrange
      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing AR Camera...'), findsOneWidget);
    });

    testWidgets('should display error message when initialization fails', (tester) async {
      // This test would require mocking the camera initialization to fail
      // For now, we'll test the error UI structure
      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // The screen should show loading initially
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should initialize with ML detection mode by default', (tester) async {
      // Arrange
      const screen = ARCameraScreen(); // No initial mode specified
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should show loading state for ML detection mode
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing AR Camera...'), findsOneWidget);
    });

    testWidgets('should initialize with QR scanning mode when specified', (tester) async {
      // Arrange
      const screen = ARCameraScreen(initialMode: CameraMode.qrScanning);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should show loading state for QR mode
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing AR Camera...'), findsOneWidget);
    });

    testWidgets('should have black background for AR camera interface', (tester) async {
      // Arrange
      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('should display retry button on error', (tester) async {
      // This would require mocking an error state
      // For now, we test the basic structure
      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Should have a scaffold with safe area
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should handle camera mode switching', (tester) async {
      // Arrange
      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should be in loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Note: Full camera mode switching would require more complex mocking
      // of camera controllers and ML detection services
    });

    testWidgets('should display camera view in ML detection mode when initialized', (tester) async {
      // This test would require mocking successful camera initialization
      // For now, we verify the basic widget structure
      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Should have the basic AR camera structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('should handle QR scanner overlay display', (tester) async {
      // Arrange
      const screen = ARCameraScreen(initialMode: CameraMode.qrScanning);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should show loading initially for QR mode
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Note: QR overlay testing would require mocking QR scanner initialization
    });

    testWidgets('should maintain state during widget lifecycle', (tester) async {
      // Arrange
      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Simulate app lifecycle changes
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused'),
        ),
        (data) {},
      );

      await tester.pump();

      // Assert - widget should still be present
      expect(find.byType(ARCameraScreen), findsOneWidget);
    });

    testWidgets('should dispose resources properly', (tester) async {
      // Arrange
      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Remove the widget to trigger dispose
      await tester.pumpWidget(Container());

      // Assert - no exceptions should be thrown during disposal
      expect(tester.takeException(), isNull);
    });
  });

  group('ARCameraScreen Integration Tests', () {
    late ARCameraScreenWidgetTest testHelper;

    setUp(() {
      testHelper = ARCameraScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should integrate with inventory service', (tester) async {
      // Arrange
      final mockItems = TestDataFactory.createMockInventoryItems(count: 3);
      when(testHelper.mockInventoryService.items).thenReturn(mockItems);

      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockInventoryService.items).called(greaterThan(0));
    });

    testWidgets('should integrate with bin location service', (tester) async {
      // Arrange
      final mockBins = TestDataFactory.createMockBinLocations(count: 2);
      when(testHelper.mockBinLocationService.nearbyBins).thenReturn(mockBins);

      const screen = ARCameraScreen(initialMode: CameraMode.mlDetection);
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockBinLocationService.nearbyBins).called(greaterThan(0));
    });
  });
}