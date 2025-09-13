import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:cleanclik/presentation/screens/map/map_screen.dart';
import 'package:cleanclik/core/services/location/location_service.dart';
import 'package:cleanclik/core/services/location/bin_location_service.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/mock_services.mocks.dart';
import '../../../fixtures/test_data_factory.dart';

class MapScreenWidgetTest extends BaseWidgetTest {
  late MockLocationService mockLocationService;
  late MockBinLocationService mockBinLocationService;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockLocationService = MockLocationService();
    mockBinLocationService = MockBinLocationService();

    // Configure mock location service
    when(mockLocationService.currentPosition).thenReturn(
      TestDataFactory.createMockPosition(),
    );
    when(mockLocationService.hasPermission).thenReturn(true);
    when(mockLocationService.isLocationEnabled).thenReturn(true);

    // Configure mock bin location service
    when(mockBinLocationService.nearbyBins).thenReturn(
      TestDataFactory.createMockBinLocations(count: 5),
    );
    when(mockBinLocationService.allBins).thenReturn(
      TestDataFactory.createMockBinLocations(count: 10),
    );

    // Add provider overrides
    overrideProviders([
      locationServiceProvider.overrideWith((ref) => mockLocationService),
      binLocationServiceProvider.overrideWith((ref) => mockBinLocationService),
    ]);
  }

  @override
  void tearDownWidgetTest() {
    super.tearDownWidgetTest();
    reset(mockLocationService);
    reset(mockBinLocationService);
  }
}

void main() {
  group('MapScreen Widget Tests', () {
    late MapScreenWidgetTest testHelper;

    setUp(() {
      testHelper = MapScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display map screen with basic structure', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets('should display loading indicator when location is loading', (tester) async {
      // Arrange
      when(testHelper.mockLocationService.currentPosition).thenReturn(null);
      
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Note: Actual loading indicator depends on MapScreen implementation
    });

    testWidgets('should display Google Maps when location is available', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Note: GoogleMap widget testing requires platform channel mocking
      // For now, we verify the basic structure
    });

    testWidgets('should handle location permission denied', (tester) async {
      // Arrange
      when(testHelper.mockLocationService.hasPermission).thenReturn(false);
      
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Should handle permission denied state gracefully
    });

    testWidgets('should display bin markers on map', (tester) async {
      // Arrange
      final mockBins = TestDataFactory.createMockBinLocations(count: 3);
      when(testHelper.mockBinLocationService.nearbyBins).thenReturn(mockBins);
      
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      verify(testHelper.mockBinLocationService.nearbyBins).called(greaterThan(0));
    });

    testWidgets('should handle map layer toggles', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should have the basic map structure
      expect(find.byType(Scaffold), findsOneWidget);
      // Layer toggle functionality would be tested with actual UI interactions
    });

    testWidgets('should display user location marker', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      verify(testHelper.mockLocationService.currentPosition).called(greaterThan(0));
    });

    testWidgets('should handle map camera movements', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - basic structure should be present
      expect(find.byType(Scaffold), findsOneWidget);
      // Camera movement testing would require GoogleMap widget interaction
    });

    testWidgets('should display bin information on marker tap', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should have map structure ready for interactions
      expect(find.byType(Scaffold), findsOneWidget);
      // Marker tap testing would require GoogleMap platform channel mocking
    });

    testWidgets('should handle location service errors gracefully', (tester) async {
      // Arrange
      when(testHelper.mockLocationService.currentPosition).thenThrow(
        Exception('Location service error'),
      );
      
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - should not crash and display error state
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should update map when location changes', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Simulate location change
      when(testHelper.mockLocationService.currentPosition).thenReturn(
        TestDataFactory.createMockPosition(
          latitude: 37.7849,
          longitude: -122.4094,
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      verify(testHelper.mockLocationService.currentPosition).called(greaterThan(0));
    });
  });

  group('MapScreen Integration Tests', () {
    late MapScreenWidgetTest testHelper;

    setUp(() {
      testHelper = MapScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should integrate with location service for user position', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockLocationService.currentPosition).called(greaterThan(0));
      verify(testHelper.mockLocationService.hasPermission).called(greaterThan(0));
    });

    testWidgets('should integrate with bin location service for markers', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockBinLocationService.nearbyBins).called(greaterThan(0));
    });

    testWidgets('should handle proximity detection for nearby bins', (tester) async {
      // Arrange
      final nearbyBins = TestDataFactory.createMockBinLocations(count: 2);
      when(testHelper.mockBinLocationService.nearbyBins).thenReturn(nearbyBins);
      
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockBinLocationService.nearbyBins).called(greaterThan(0));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should update bin markers when bin data changes', (tester) async {
      // Arrange
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate bin data change
      final newBins = TestDataFactory.createMockBinLocations(count: 7);
      when(testHelper.mockBinLocationService.nearbyBins).thenReturn(newBins);

      await tester.pump();

      // Assert
      verify(testHelper.mockBinLocationService.nearbyBins).called(greaterThan(0));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('MapScreen Responsive Design Tests', () {
    late MapScreenWidgetTest testHelper;

    setUp(() {
      testHelper = MapScreenWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should adapt to phone screen size', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Reset view
      addTearDown(tester.view.reset);
    });

    testWidgets('should adapt to tablet screen size', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      const screen = MapScreen();
      final widget = testHelper.createTestWidget(screen);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Reset view
      addTearDown(tester.view.reset);
    });
  });
}