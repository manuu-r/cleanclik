# Design Document

## Overview

This design addresses critical issues in the current inventory service implementation by renaming ConsolidatedInventoryService to InventoryService, fixing data persistence bugs, resolving confirmation dialog button functionality, and correcting the points allocation timing. The solution ensures reliable inventory management with proper data persistence and user experience improvements.

## Architecture

### Service Renaming Strategy
The ConsolidatedInventoryService will be renamed to InventoryService throughout the codebase while maintaining all existing functionality. This involves:

- Renaming the main service class file
- Updating all import statements across the codebase
- Modifying Riverpod provider names and references
- Updating test files and documentation

### Data Persistence Architecture
The current persistence implementation has gaps that cause data loss on app restart. The improved architecture will:

- Implement immediate persistence on every inventory change
- Add robust error handling for storage operations
- Ensure data is loaded synchronously during app initialization
- Provide fallback mechanisms for corrupted data

### Points Allocation System
Currently points are awarded on pickup, but they should only be awarded on successful disposal. The new system will:

- Remove points allocation from the pickup/add item flow
- Move points calculation to the disposal confirmation process
- Ensure points are only awarded after successful disposal confirmation
- Maintain proper points persistence

## Components and Interfaces

### 1. InventoryService (Renamed from ConsolidatedInventoryService)

**File**: `lib/core/services/inventory_service.dart`

**Key Methods**:
```dart
class InventoryService extends _$InventoryService {
  // Existing functionality maintained
  Future<bool> addItem(InventoryItem item) async
  Future<void> removeItems(List<String> trackingIds) async
  Future<void> clearInventory() async
  
  // Modified methods
  Future<void> _saveToStorage() async // Enhanced error handling
  Future<void> _loadFromStorage() async // Synchronous loading
  
  // New methods
  Future<void> awardPointsForDisposal(List<InventoryItem> disposedItems) async
}
```

### 2. Enhanced Persistence Layer

**Current Issues**:
- Data not saved immediately on item addition
- Loading happens asynchronously causing race conditions
- No error recovery for corrupted data

**Solution**:
```dart
// Enhanced persistence methods
Future<void> _saveToStorage() async {
  try {
    _prefs ??= await SharedPreferences.getInstance();
    
    // Save inventory data
    final inventoryData = _inventory.map((item) => item.toJson()).toList();
    await _prefs!.setString(_inventoryKey, jsonEncode(inventoryData));
    
    // Save stats data
    await _prefs!.setString(_statsKey, jsonEncode(_sessionStats.toJson()));
    
    // Save points
    await _prefs!.setInt(_pointsKey, _totalPoints);
    
    print('✅ Data persisted successfully');
  } catch (e) {
    print('❌ Failed to save data: $e');
    // Log error but don't throw to prevent app crashes
  }
}

Future<void> _loadFromStorage() async {
  try {
    _prefs ??= await SharedPreferences.getInstance();
    
    // Load with fallbacks for corrupted data
    _inventory = _loadInventoryWithFallback();
    _sessionStats = _loadStatsWithFallback();
    _totalPoints = _prefs!.getInt(_pointsKey) ?? 0;
    
    print('✅ Data loaded successfully');
  } catch (e) {
    print('❌ Failed to load data, using defaults: $e');
    _initializeDefaults();
  }
}
```

### 3. Confirmation Dialog Button Fix

**Current Issue**: Buttons in DisposalConfirmationDialog are not responding properly

**Root Cause Analysis**: The dialog buttons are properly wired, but there may be issues with:
- Event propagation being blocked
- State management not updating properly
- Navigation context issues

**Solution**:
```dart
// Enhanced button handling in DisposalConfirmationDialog
ElevatedButton(
  onPressed: matchResult.matchingItems.isNotEmpty
      ? () async {
          // Ensure proper async handling
          try {
            await onConfirmDisposal(matchResult.matchingItems);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          } catch (e) {
            print('Error during disposal: $e');
            // Show error feedback to user
          }
        }
      : null,
  // ... rest of button configuration
)
```

### 4. Points Allocation Timing Fix

**Current Flow** (Incorrect):
```
User picks up item → Points awarded immediately → Item added to inventory
```

**New Flow** (Correct):
```
User picks up item → Item added to inventory (no points) → User disposes item → Points awarded on confirmation
```

**Implementation**:
```dart
// Remove points from addItem method
Future<bool> addItem(InventoryItem item) async {
  // Add item logic without points
  _inventory.add(item);
  await _saveToStorage();
  // NO POINTS AWARDED HERE
  return true;
}

// Add points only on disposal
Future<void> confirmDisposal(List<InventoryItem> disposedItems) async {
  // Calculate points for disposed items
  int totalPoints = _calculateDisposalPoints(disposedItems);
  
  // Remove items from inventory
  for (final item in disposedItems) {
    _inventory.removeWhere((i) => i.trackingId == item.trackingId);
  }
  
  // Award points ONLY after successful disposal
  _totalPoints += totalPoints;
  
  // Persist changes
  await _saveToStorage();
  
  // Notify UI
  ref.notifyListeners();
}
```

## Data Models

### Enhanced InventoryItem
No changes needed to the existing InventoryItem model - it already supports all required functionality.

### SessionStats Enhancement
```dart
class SessionStats {
  final int totalItemsPickedUp;
  final int totalItemsDisposed; // Track disposed vs picked up
  final int totalPointsEarned;
  final Map<String, int> categoryStats;
  final DateTime sessionStart;
  
  // Add disposal tracking
  SessionStats copyWithDisposal(List<InventoryItem> disposedItems) {
    return copyWith(
      totalItemsDisposed: totalItemsDisposed + disposedItems.length,
      // Update other stats
    );
  }
}
```

## Error Handling

### Storage Error Recovery
```dart
List<InventoryItem> _loadInventoryWithFallback() {
  try {
    final jsonString = _prefs!.getString(_inventoryKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => InventoryItem.fromJson(json)).toList();
    }
  } catch (e) {
    print('Failed to load inventory, using empty list: $e');
  }
  return [];
}

void _initializeDefaults() {
  _inventory = [];
  _sessionStats = SessionStats.initial();
  _totalPoints = 0;
}
```

### Dialog Error Handling
```dart
// Add try-catch blocks around dialog actions
// Provide user feedback for errors
// Ensure proper cleanup on failures
```

## Testing Strategy

### Unit Tests
- Test service renaming doesn't break functionality
- Test persistence works immediately on item addition
- Test data loading works correctly on app start
- Test points are only awarded on disposal
- Test error recovery for corrupted data

### Integration Tests
- Test full pickup → disposal → points flow
- Test app restart with inventory data
- Test dialog button functionality
- Test error scenarios and recovery

### Widget Tests
- Test DisposalConfirmationDialog button interactions
- Test UI updates after disposal confirmation
- Test error state handling in UI

## Migration Strategy

### Phase 1: Service Renaming
1. Rename ConsolidatedInventoryService to InventoryService
2. Update all imports and references
3. Regenerate Riverpod providers
4. Update tests

### Phase 2: Persistence Fixes
1. Enhance _saveToStorage method with immediate persistence
2. Fix _loadFromStorage to be synchronous during app init
3. Add error recovery mechanisms
4. Test data persistence across app restarts

### Phase 3: Points System Fix
1. Remove points allocation from addItem method
2. Move points calculation to disposal confirmation
3. Update UI to show points only after disposal
4. Test complete pickup → disposal → points flow

### Phase 4: Dialog Button Fix
1. Investigate and fix button responsiveness issues
2. Add proper error handling and user feedback
3. Test dialog interactions thoroughly