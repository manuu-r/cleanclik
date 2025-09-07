# Implementation Plan

- [ ] 1. Rename ConsolidatedInventoryService to InventoryService across codebase
  - Rename `lib/core/services/consolidated_inventory_service.dart` to `inventory_service.dart`
  - Update class name from `ConsolidatedInventoryService` to `InventoryService`
  - Update provider name from `consolidatedInventoryServiceProvider` to `inventoryServiceProvider`
  - Find and replace all imports: `consolidated_inventory_service.dart` → `inventory_service.dart`
  - Update all provider references in UI files: `consolidatedInventoryServiceProvider` → `inventoryServiceProvider`
  - Update variable names in files like `ar_camera_screen.dart`, `home_screen.dart`, `qr_camera_controller.dart`
  - Update test file `test/consolidated_inventory_service_test.dart` to use new names
  - Run `dart run build_runner build --delete-conflicting-outputs` to regenerate Riverpod code
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Fix data persistence and loading issues
  - Modify `addItem()` method to call `_saveToStorage()` immediately after adding items to `_inventory`
  - Verify `removeItems()`, `clearInventory()`, and other inventory modification methods call `_saveToStorage()`
  - Fix `_loadFromStorage()` method to handle corrupted data gracefully with try-catch blocks
  - Add `_loadInventoryWithFallback()` method that returns empty list if JSON parsing fails
  - Add `_loadStatsWithFallback()` method that returns default SessionStats if loading fails
  - Add `_initializeDefaults()` method to set empty inventory, default stats, and zero points
  - Ensure stats are saved immediately when updated during gameplay
  - Add proper error logging without throwing exceptions that crash the app
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 3. Fix points allocation timing
  - Remove all points calculation and `_awardPoints()` calls from `addItem()` method
  - Remove points calculation from `addItemFromDetectedObject()` method
  - Create new `awardPointsForDisposal(List<InventoryItem> disposedItems)` method
  - Calculate points based on disposed items' categories using existing point values
  - Modify disposal confirmation flow to call `awardPointsForDisposal()` after successful disposal
  - Update disposal dialog to show "You will earn X points" instead of showing already earned points
  - Ensure points are only added to `_totalPoints` after disposal confirmation, not on pickup
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 4. Fix confirmation dialog button functionality
  - Investigate button responsiveness in `lib/presentation/widgets/disposal_confirmation_dialog.dart`
  - Add proper async/await handling to the "Dispose Items" button onPressed callback
  - Ensure `Navigator.of(context).pop()` is called after successful disposal
  - Add try-catch blocks around disposal actions with user-friendly error messages
  - Test button interactions to ensure they provide immediate visual feedback
  - Verify dialog dismisses properly and doesn't leave the user in a stuck state
  - Add loading state or disable buttons during disposal processing to prevent double-taps
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_