import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import '../helpers/base_integration_test.dart';
import '../helpers/mock_services.dart';
import '../fixtures/test_data_factory.dart';
import '../../lib/core/models/inventory_item.dart';
import '../../lib/core/models/detected_object.dart';
import '../../lib/core/models/waste_category.dart';
import '../../lib/core/models/sync_status.dart';
import '../../lib/core/providers/inventory_provider.dart';
import '../../lib/core/providers/sync_provider.dart';
import '../../lib/presentation/screens/camera/ar_camera_screen.dart';
import '../../lib/presentation/screens/profile/profile_screen.dart';
import '../../lib/presentation/widgets/inventory/inventory_list.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Inventory Synchronization Integration Tests', () {
    late MockInventoryService mockInventoryService;
    late MockSyncService mockSyncService;
    late MockSupabaseClient mockSupabaseClient;
    late MockLocalStorageService mockLocalStorage;
    late ProviderContainer container;

    setUp(() {
      mockInventoryService = MockInventoryService();
      mockSyncService = MockSyncService();
      mockSupabaseClient = MockSupabaseClient();
      mockLocalStorage = MockLocalStorageService();
      
      container = ProviderContainer(
        overrides: [
          inventoryServiceProvider.overrideWithValue(mockInventoryService),
          syncServiceProvider.overrideWithValue(mockSyncService),
          supabaseClientProvider.overrideWithValue(mockSupabaseClient),
          localStorageServiceProvider.overrideWithValue(mockLocalStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete inventory sync workflow - online mode', (tester) async {
      // Arrange
      final localItems = [
        TestDataFactory.createMockInventoryItem(
          id: 'local1',
          category: WasteCategory.recycle,
          isLocal: true,
          syncStatus: SyncStatus.pending,
        ),
        TestDataFactory.createMockInventoryItem(
          id: 'local2',
          category: WasteCategory.organic,
          isLocal: true,
          syncStatus: SyncStatus.pending,
        ),
      ];

      final remoteItems = [
        TestDataFactory.createMockInventoryItem(
          id: 'remote1',
          category: WasteCategory.ewaste,
          isLocal: false,
          syncStatus: SyncStatus.synced,
        ),
      ];

      final allItems = [...localItems, ...remoteItems];

      when(mockLocalStorage.getInventoryItems())
          .thenAnswer((_) async => localItems);
      when(mockInventoryService.getLocalItems())
          .thenAnswer((_) async => localItems);
      when(mockInventoryService.getRemoteItems())
          .thenAnswer((_) async => remoteItems);
      when(mockInventoryService.getAllItems())
          .thenAnswer((_) async => allItems);
      
      when(mockSyncService.syncInventory())
          .thenAnswer((_) async => SyncResult.success(syncedCount: 2));
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockSyncService.syncStatus)
          .thenReturn(SyncStatus.synced);

      // Act & Assert - Start with profile screen to view inventory
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to inventory section
      await tester.tap(find.byKey(const Key('inventory_section')));
      await tester.pumpAndSettle();

      // Verify local items are displayed with pending sync status
      expect(find.byType(InventoryList), findsOneWidget);
      expect(find.text('Pending Sync'), findsNWidgets(2));
      expect(find.text('Synced'), findsOneWidget);

      // Trigger manual sync
      await tester.tap(find.byKey(const Key('sync_inventory_button')));
      await tester.pumpAndSettle();

      // Verify sync was initiated
      verify(mockSyncService.syncInventory()).called(1);

      // Update mock to return synced items
      final syncedItems = localItems.map((item) => 
        item.copyWith(syncStatus: SyncStatus.synced)).toList();
      when(mockInventoryService.getAllItems())
          .thenAnswer((_) async => [...syncedItems, ...remoteItems]);

      await tester.pump();

      // Verify sync success message
      expect(find.text('Sync completed successfully'), findsOneWidget);
      expect(find.text('2 items synced'), findsOneWidget);

      // Verify all items now show as synced
      expect(find.text('Pending Sync'), findsNothing);
      expect(find.text('Synced'), findsNWidgets(3));
    });

    testWidgets('Offline inventory management with local storage', (tester) async {
      // Arrange
      final detectedObject = TestDataFactory.createMockDetectedObject(
        category: WasteCategory.recycle,
        label: 'Plastic Bottle',
      );

      when(mockSyncService.isOnline).thenReturn(false);
      when(mockSyncService.syncStatus).thenReturn(SyncStatus.offline);
      
      when(mockInventoryService.addDetectedObject(any))
          .thenAnswer((_) async {});
      when(mockLocalStorage.saveInventoryItem(any))
          .thenAnswer((_) async {});
      when(mockLocalStorage.getInventoryItems())
          .thenAnswer((_) async => []);

      // Act & Assert - Add item while offline
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ARCameraScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate adding detected object to inventory
      await tester.tap(find.byKey(Key('detected_object_${detectedObject.id}')));
      await tester.pumpAndSettle();

      // Verify item was saved locally
      verify(mockInventoryService.addDetectedObject(detectedObject)).called(1);
      verify(mockLocalStorage.saveInventoryItem(any)).called(1);

      // Verify offline indicator is shown
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Navigate to inventory to see offline items
      await tester.tap(find.byKey(const Key('profile_tab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory_section')));
      await tester.pumpAndSettle();

      // Verify offline items are marked as pending sync
      expect(find.text('Pending Sync'), findsOneWidget);
      expect(find.text('Will sync when online'), findsOneWidget);
    });

    testWidgets('Sync conflict resolution workflow', (tester) async {
      // Arrange
      final conflictedItem = TestDataFactory.createMockInventoryItem(
        id: 'conflict1',
        category: WasteCategory.recycle,
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
        syncStatus: SyncStatus.conflict,
      );

      when(mockSyncService.syncInventory())
          .thenAnswer((_) async => SyncResult.conflict([conflictedItem]));
      when(mockSyncService.resolveConflict(any, any))
          .thenAnswer((_) async => SyncResult.success(syncedCount: 1));
      when(mockInventoryService.getAllItems())
          .thenAnswer((_) async => [conflictedItem]);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to inventory
      await tester.tap(find.byKey(const Key('inventory_section')));
      await tester.pumpAndSettle();

      // Trigger sync that results in conflict
      await tester.tap(find.byKey(const Key('sync_inventory_button')));
      await tester.pumpAndSettle();

      // Verify conflict dialog is shown
      expect(find.text('Sync Conflict'), findsOneWidget);
      expect(find.text('Choose which version to keep'), findsOneWidget);

      // Choose local version
      await tester.tap(find.byKey(const Key('keep_local_button')));
      await tester.pumpAndSettle();

      // Verify conflict resolution was called
      verify(mockSyncService.resolveConflict(conflictedItem, ConflictResolution.keepLocal)).called(1);

      // Verify success message
      expect(find.text('Conflict resolved'), findsOneWidget);
    });

    testWidgets('Automatic sync on network reconnection', (tester) async {
      // Arrange
      final pendingItems = [
        TestDataFactory.createMockInventoryItem(
          syncStatus: SyncStatus.pending,
        ),
      ];

      when(mockSyncService.isOnline).thenReturn(false);
      when(mockSyncService.syncStatus).thenReturn(SyncStatus.offline);
      when(mockInventoryService.getAllItems())
          .thenAnswer((_) async => pendingItems);

      // Act & Assert - Start offline
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify offline state
      expect(find.text('Offline Mode'), findsOneWidget);

      // Simulate network reconnection
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockSyncService.syncStatus).thenReturn(SyncStatus.syncing);
      when(mockSyncService.syncInventory())
          .thenAnswer((_) async => SyncResult.success(syncedCount: 1));

      // Trigger network state change
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/connectivity',
        null,
        (data) {},
      );
      await tester.pumpAndSettle();

      // Verify automatic sync was triggered
      verify(mockSyncService.syncInventory()).called(1);

      // Update to synced state
      when(mockSyncService.syncStatus).thenReturn(SyncStatus.synced);
      await tester.pump();

      // Verify online state restored
      expect(find.text('Offline Mode'), findsNothing);
      expect(find.text('All items synced'), findsOneWidget);
    });

    testWidgets('Batch sync with progress indication', (tester) async {
      // Arrange
      final batchItems = List.generate(10, (index) => 
        TestDataFactory.createMockInventoryItem(
          id: 'batch$index',
          syncStatus: SyncStatus.pending,
        ),
      );

      when(mockInventoryService.getAllItems())
          .thenAnswer((_) async => batchItems);
      when(mockSyncService.syncInventory())
          .thenAnswer((_) async {
            // Simulate progressive sync
            for (int i = 0; i < batchItems.length; i++) {
              await Future.delayed(const Duration(milliseconds: 100));
              // Update progress would be handled by the service
            }
            return SyncResult.success(syncedCount: batchItems.length);
          });

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to inventory
      await tester.tap(find.byKey(const Key('inventory_section')));
      await tester.pumpAndSettle();

      // Verify pending items count
      expect(find.text('10 items pending sync'), findsOneWidget);

      // Start batch sync
      await tester.tap(find.byKey(const Key('sync_inventory_button')));
      await tester.pump(const Duration(milliseconds: 50));

      // Verify sync progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Syncing...'), findsOneWidget);

      // Wait for sync completion
      await tester.pumpAndSettle();

      // Verify completion
      expect(find.text('10 items synced successfully'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Sync failure handling and retry', (tester) async {
      // Arrange
      when(mockSyncService.syncInventory())
          .thenAnswer((_) async => SyncResult.failure('Network error'));
      when(mockInventoryService.getAllItems())
          .thenAnswer((_) async => [
            TestDataFactory.createMockInventoryItem(syncStatus: SyncStatus.pending),
          ]);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to inventory
      await tester.tap(find.byKey(const Key('inventory_section')));
      await tester.pumpAndSettle();

      // Attempt sync
      await tester.tap(find.byKey(const Key('sync_inventory_button')));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Sync failed: Network error'), findsOneWidget);
      expect(find.byKey(const Key('retry_sync_button')), findsOneWidget);

      // Test retry
      when(mockSyncService.syncInventory())
          .thenAnswer((_) async => SyncResult.success(syncedCount: 1));

      await tester.tap(find.byKey(const Key('retry_sync_button')));
      await tester.pumpAndSettle();

      // Verify retry was successful
      verify(mockSyncService.syncInventory()).called(2);
      expect(find.text('Sync completed successfully'), findsOneWidget);
    });

    testWidgets('Real-time sync status updates', (tester) async {
      // Arrange
      final statusController = StreamController<SyncStatus>();
      
      when(mockSyncService.syncStatusStream)
          .thenAnswer((_) => statusController.stream);
      when(mockInventoryService.getAllItems())
          .thenAnswer((_) async => []);

      // Act & Assert
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to inventory
      await tester.tap(find.byKey(const Key('inventory_section')));
      await tester.pumpAndSettle();

      // Test different sync statuses
      statusController.add(SyncStatus.syncing);
      await tester.pump();
      expect(find.text('Syncing...'), findsOneWidget);

      statusController.add(SyncStatus.synced);
      await tester.pump();
      expect(find.text('All items synced'), findsOneWidget);

      statusController.add(SyncStatus.offline);
      await tester.pump();
      expect(find.text('Offline Mode'), findsOneWidget);

      statusController.add(SyncStatus.error);
      await tester.pump();
      expect(find.text('Sync Error'), findsOneWidget);

      statusController.close();
    });
  });
}