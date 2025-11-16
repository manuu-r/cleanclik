import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/providers/inventory_provider.dart';
import 'package:cleanclik/presentation/widgets/common/category_item.dart';

/// Slide-in panel for the inventory view
///
/// Slides from the bottom and covers 75% of screen height
class InventorySlidePanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const InventorySlidePanel({
    super.key,
    required this.onClose,
  });

  @override
  ConsumerState<InventorySlidePanel> createState() => _InventorySlidePanelState();
}

class _InventorySlidePanelState extends ConsumerState<InventorySlidePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Start from bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return GestureDetector(
      onTap: _handleClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          children: [
            // Top dimmed area (tap to close)
            Expanded(
              flex: 25,
              child: Container(),
            ),
            // Bottom panel (inventory content)
            Expanded(
              flex: 75,
              child: SlideTransition(
                position: _slideAnimation,
                child: GestureDetector(
                  onTap: () {}, // Prevent tap propagation
                  onVerticalDragEnd: (details) {
                    // Swipe down to close
                    if (details.primaryVelocity! > 0) {
                      _handleClose();
                    }
                  },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              'Inventory',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _handleClose,
                            ),
                          ],
                        ),
                      ),
                      // Inventory content
                      Expanded(
                        child: inventoryAsync.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No items yet',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.white70,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Start scanning to collect items!',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white54,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Group items by category
                            final grouped = <WasteCategory, int>{};
                            for (final item in items) {
                              grouped[item.category] = (grouped[item.category] ?? 0) + 1;
                            }

                            return ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                // Category cards
                                ...grouped.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: CategoryItem(
                                      category: entry.key,
                                      count: entry.value,
                                      onTap: () {
                                        // TODO: Show category details
                                      },
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                                // Total items
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Items',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Colors.white,
                                            ),
                                      ),
                                      Text(
                                        '${items.length}',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stack) => Center(
                            child: Text(
                              'Error loading inventory',
                              style: TextStyle(color: Colors.red[300]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
