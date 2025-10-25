import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';

part 'inventory_provider.g.dart';

/// Provider for InventoryService
/// Requirements: 2.1, 3.1
@riverpod
InventoryService inventoryService(InventoryServiceRef ref) {
  return ref.watch(inventoryServiceProvider);
}

/// Provider for current inventory items
/// Requirements: 2.1, 3.1
@riverpod
List<InventoryItem> inventoryItems(InventoryItemsRef ref) {
  final service = ref.watch(inventoryServiceProvider);
  return service.inventory;
}

/// Provider for inventory items by category
/// Requirements: 2.1, 3.1
@riverpod
List<InventoryItem> inventoryItemsByCategory(
  InventoryItemsByCategoryRef ref,
  String category,
) {
  final service = ref.watch(inventoryServiceProvider);
  return service.getItemsByCategory(category);
}

/// Provider for inventory empty state
/// Requirements: 2.1, 3.1
@riverpod
bool isInventoryEmpty(IsInventoryEmptyRef ref) {
  final service = ref.watch(inventoryServiceProvider);
  return service.isEmpty;
}
