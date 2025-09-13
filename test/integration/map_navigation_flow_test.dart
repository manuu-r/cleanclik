import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../helpers/base_integration_test.dart';
import '../helpers/mock_services.dart';
import '../fixtures/test_data_factory.dart';
import '../../lib/core/models/bin_location.dart';
import '../../lib/core/models/waste_category.dart';
import '../../lib/core/models/inventory_item.dart';
import '../../lib/core/models/disposal_result.dart';
import '../../lib/core/providers/location_provider.dart';
import '../../lib/core/providers/bin_location_provider.dart';
import '../../lib/presentation/screens/map/map_screen.dart';
import '../../lib/presentation/widgets/map/bin_marker.dart';
import '../../lib/presentation/widgets/overlays/disposal_celebration_overlay.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Map Navigation and Disposal Workflow Integration Tests', () {
    late MockLocationService mockLocationService;
    late MockBinLocationService mockBinLocationService;
    late MockInventoryService mockInventoryService;
    late MockProximityService mockProximityService;
    late MockLeaderboardService mockLeaderboardService;
    late ProviderContainer container;

    setUp(() {
      mockLocationService = MockLocationService();
      mockBinLocationService = MockBinLocationService();
      mockInventoryService = MockInventoryService();
      mockProximityService = MockProximityService();
      mockLeaderboardService = MockLeaderboardService();
      
      container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocationService),
          binLocationServiceProvider.overrideWithValue(mockBinLocationService),
          inventoryServiceProvider.overrideWithValue(mockInventoryService),
          proximityServiceProvider.overrideWithValue(mockProximityService),
          leaderboardServiceProvider.overrideWithValue(mockLeaderboardService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete map navigation and bin discovery workflow', (tester) async {
      // Arrange
      final userLocation = const LatLng(37.7749, -122.4194); // San Francisco
      final nearbyBins = [
        TestDataFactory.createMockBinLocation(
          binId: 'BIN_001',
          coordinates: const LatLng(37.7750, -122.4195), // ~10m away
          category: WasteCategory.recycle,
          isActive: true,
        ),
        TestDataFactory.createMockBinLocation(
          binId: 'BIN_002',
          coordinates: const LatLng(37.7748, -122.4193), // ~15m away
          category: WasteCategory.organic,
          isActive: true,
        ),
        TestDataFactory.createMockBinLocation(
          binId: 'BIN_003',
          coordinates: const LatLng(37.7760, -122.4200), // ~100m away
          category: WasteCategory.ewaste,
          isActive: true,
        ),
      ];

      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => userLocation);
      when(mockLocationService.locationStream)
          .thenAnswer((_) => Stream.value(userLocation));
      when(mockLocationService.hasLocationPermission())
          .thenAnswer((_) async => true);

      when(mockBinLocationService.getNearbyBins(userLocation, any))
          .thenAnswer((_) async => nearbyBins);
      when(mockBinLocationService.binLocationsStream)
          .thenAnswer((_) => Stream.value(nearbyBins));

      when(mockProximityService.getProximityToBin(userLocation, any))
          .thenAnswer((invocation) {
            final binLocation = invocation.positionalArguments[1] as BinLocation;
            final distance = _calculateDistance(userLocation, binLocation.coordinates);
            return distance;
          });

      // Act & Assert - Start map screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify location permission and initialization
      verify(mockLocationService.hasLocationPermission()).called(1);
      verify(mockLocationService.getCurrentLocation()).called(1);

      // Verify map is displayed with user location
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Your Location'), findsOneWidget);

      // Verify nearby bins are loaded and displayed
      verify(mockBinLocationService.getNearbyBins(userLocation, any)).called(1);
      
      // Verify bin markers are displayed
      expect(find.byType(BinMarker), findsNWidgets(3));
      expect(find.text('BIN_001'), findsOneWidget);
      expect(find.text('BIN_002'), findsOneWidget);
      expect(find.text('BIN_003'), findsOneWidget);

      // Verify proximity indicators for nearby bins
      expect(find.text('10m'), findsOneWidget); // BIN_001
      expect(find.text('15m'), findsOneWidget); // BIN_002
      expect(find.text('100m'), findsOneWidget); // BIN_003
    });

    testWidgets('Bin proximity detection and highlighting workflow', (tester) async {
      // Arrange
      final userLocation = const LatLng(37.7749, -122.4194);
      final nearBin = TestDataFactory.createMockBinLocation(
        binId: 'BIN_CLOSE',
        coordinates: const LatLng(37.7749, -122.4195), // ~5m away
        category: WasteCategory.recycle,
        isActive: true,
      );

      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => userLocation);
      when(mockLocationService.locationStream)
          .thenAnswer((_) => Stream.value(userLocation));

      when(mockBinLocationService.getNearbyBins(any, any))
          .thenAnswer((_) async => [nearBin]);

      when(mockProximityService.getProximityToBin(any, any))
          .thenReturn(5.0); // 5 meters
      when(mockProximityService.isWithinDisposalRange(any, any))
          .thenReturn(true); // Within 10m threshold
      when(mockProximityService.proximityUpdatesStream)
          .thenAnswer((_) => Stream.value(ProximityUpdate(nearBin, 5.0)));

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Wait for proximity detection
      await tester.pump(const Duration(milliseconds: 500));

      // Verify bin is highlighted as nearby
      expect(find.byKey(Key('highlighted_bin_${nearBin.binId}')), findsOneWidget);
      expect(find.text('Nearby Bin!'), findsOneWidget);
      expect(find.text('5m away'), findsOneWidget);

      // Verify disposal action is available
      expect(find.byKey(const Key('dispose_here_button')), findsOneWidget);
      expect(find.text('Dispose Here'), findsOneWidget);
    });

    testWidgets('Complete disposal workflow with inventory items', (tester) async {
      // Arrange
      final userLocation = const LatLng(37.7749, -122.4194);
      final recycleBin = TestDataFactory.createMockBinLocation(
        binId: 'RECYCLE_BIN',
        coordinates: userLocation, // At user location
        category: WasteCategory.recycle,
        isActive: true,
      );

      final inventoryItems = [
        TestDataFactory.createMockInventoryItem(
          id: 'item1',
          category: WasteCategory.recycle,
          label: 'Plastic Bottle',
        ),
        TestDataFactory.createMockInventoryItem(
          id: 'item2',
          category: WasteCategory.recycle,
          label: 'Aluminum Can',
        ),
        TestDataFactory.createMockInventoryItem(
          id: 'item3',
          category: WasteCategory.organic,
          label: 'Apple Core',
        ),
      ];

      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => userLocation);
      when(mockBinLocationService.getNearbyBins(any, any))
          .thenAnswer((_) async => [recycleBin]);
      when(mockProximityService.isWithinDisposalRange(any, any))
          .thenReturn(true);

      when(mockInventoryService.getItemsForCategory(WasteCategory.recycle))
          .thenAnswer((_) async => inventoryItems.where((item) => 
              item.category == WasteCategory.recycle).toList());
      when(mockInventoryService.disposeItems(any, any))
          .thenAnswer((_) async => DisposalResult.success(
            itemsDisposed: 2,
            pointsEarned: 150,
            achievements: ['Recycling Champion'],
          ));

      when(mockLeaderboardService.updateScore(any))
          .thenAnswer((_) async {});

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on recycle bin to start disposal
      await tester.tap(find.byKey(Key('bin_marker_${recycleBin.binId}')));
      await tester.pumpAndSettle();

      // Verify disposal dialog opens
      expect(find.text('Dispose Items'), findsOneWidget);
      expect(find.text('Recycle Bin'), findsOneWidget);

      // Verify matching items are shown
      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('Aluminum Can'), findsOneWidget);
      expect(find.text('Apple Core'), findsNothing); // Wrong category

      // Select items to dispose
      await tester.tap(find.byKey(const Key('select_item_item1')));
      await tester.tap(find.byKey(const Key('select_item_item2')));
      await tester.pumpAndSettle();

      // Confirm disposal
      await tester.tap(find.byKey(const Key('confirm_disposal_button')));
      await tester.pumpAndSettle();

      // Verify disposal was processed
      verify(mockInventoryService.disposeItems(
        argThat(hasLength(2)),
        recycleBin,
      )).called(1);

      // Verify celebration overlay
      expect(find.byType(DisposalCelebrationOverlay), findsOneWidget);
      expect(find.text('Great Job!'), findsOneWidget);
      expect(find.text('2 items disposed'), findsOneWidget);
      expect(find.text('+150 points'), findsOneWidget);
      expect(find.text('Recycling Champion'), findsOneWidget);

      // Verify leaderboard update
      verify(mockLeaderboardService.updateScore(150)).called(1);
    });

    testWidgets('Wrong bin category disposal prevention', (tester) async {
      // Arrange
      final userLocation = const LatLng(37.7749, -122.4194);
      final organicBin = TestDataFactory.createMockBinLocation(
        binId: 'ORGANIC_BIN',
        coordinates: userLocation,
        category: WasteCategory.organic,
        isActive: true,
      );

      final recycleItem = TestDataFactory.createMockInventoryItem(
        category: WasteCategory.recycle,
        label: 'Plastic Bottle',
      );

      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => userLocation);
      when(mockBinLocationService.getNearbyBins(any, any))
          .thenAnswer((_) async => [organicBin]);
      when(mockProximityService.isWithinDisposalRange(any, any))
          .thenReturn(true);

      when(mockInventoryService.getItemsForCategory(WasteCategory.organic))
          .thenAnswer((_) async => []); // No matching items

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on organic bin
      await tester.tap(find.byKey(Key('bin_marker_${organicBin.binId}')));
      await tester.pumpAndSettle();

      // Verify no matching items message
      expect(find.text('No matching items'), findsOneWidget);
      expect(find.text('You don\'t have any organic waste to dispose'), findsOneWidget);
      expect(find.byKey(const Key('confirm_disposal_button')), findsNothing);
    });

    testWidgets('Map filter and search functionality', (tester) async {
      // Arrange
      final userLocation = const LatLng(37.7749, -122.4194);
      final allBins = [
        TestDataFactory.createMockBinLocation(
          binId: 'RECYCLE_1',
          category: WasteCategory.recycle,
          coordinates: const LatLng(37.7750, -122.4195),
        ),
        TestDataFactory.createMockBinLocation(
          binId: 'ORGANIC_1',
          category: WasteCategory.organic,
          coordinates: const LatLng(37.7748, -122.4193),
        ),
        TestDataFactory.createMockBinLocation(
          binId: 'EWASTE_1',
          category: WasteCategory.ewaste,
          coordinates: const LatLng(37.7751, -122.4196),
        ),
      ];

      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => userLocation);
      when(mockBinLocationService.getNearbyBins(any, any))
          .thenAnswer((_) async => allBins);
      when(mockBinLocationService.filterBinsByCategory(any))
          .thenAnswer((invocation) {
            final category = invocation.positionalArguments[0] as WasteCategory;
            return allBins.where((bin) => bin.category == category).toList();
          });

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all bins are initially shown
      expect(find.byType(BinMarker), findsNWidgets(3));

      // Apply recycle filter
      await tester.tap(find.byKey(const Key('filter_recycle')));
      await tester.pumpAndSettle();

      // Verify only recycle bins are shown
      verify(mockBinLocationService.filterBinsByCategory(WasteCategory.recycle)).called(1);
      expect(find.text('RECYCLE_1'), findsOneWidget);
      expect(find.text('ORGANIC_1'), findsNothing);
      expect(find.text('EWASTE_1'), findsNothing);

      // Clear filter
      await tester.tap(find.byKey(const Key('clear_filter')));
      await tester.pumpAndSettle();

      // Verify all bins are shown again
      expect(find.byType(BinMarker), findsNWidgets(3));
    });

    testWidgets('Location permission handling workflow', (tester) async {
      // Arrange
      when(mockLocationService.hasLocationPermission())
          .thenAnswer((_) async => false);
      when(mockLocationService.requestLocationPermission())
          .thenAnswer((_) async => true);
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => const LatLng(37.7749, -122.4194));

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify permission request dialog
      expect(find.text('Location Permission Required'), findsOneWidget);
      expect(find.text('Allow location access to find nearby bins'), findsOneWidget);

      // Grant permission
      await tester.tap(find.byKey(const Key('grant_permission_button')));
      await tester.pumpAndSettle();

      // Verify permission was requested
      verify(mockLocationService.requestLocationPermission()).called(1);
      verify(mockLocationService.getCurrentLocation()).called(1);

      // Verify map is now accessible
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('Offline map functionality with cached data', (tester) async {
      // Arrange
      final cachedBins = [
        TestDataFactory.createMockBinLocation(
          binId: 'CACHED_BIN',
          category: WasteCategory.recycle,
        ),
      ];

      when(mockLocationService.getCurrentLocation())
          .thenThrow(Exception('No internet connection'));
      when(mockLocationService.getLastKnownLocation())
          .thenAnswer((_) async => const LatLng(37.7749, -122.4194));
      
      when(mockBinLocationService.getCachedBins())
          .thenAnswer((_) async => cachedBins);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify offline mode indicator
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Using cached data'), findsOneWidget);

      // Verify cached bins are displayed
      expect(find.text('CACHED_BIN'), findsOneWidget);
      
      // Verify limited functionality message
      expect(find.text('Some features may be limited'), findsOneWidget);
    });
  });

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple distance calculation for testing
    final lat1 = point1.latitude;
    final lon1 = point1.longitude;
    final lat2 = point2.latitude;
    final lon2 = point2.longitude;
    
    final dLat = (lat2 - lat1) * 111000; // Rough conversion to meters
    final dLon = (lon2 - lon1) * 111000;
    
    return (dLat * dLat + dLon * dLon).abs().sqrt();
  }
}