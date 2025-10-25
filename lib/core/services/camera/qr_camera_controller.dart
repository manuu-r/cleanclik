import 'package:flutter/material.dart';
import 'package:cleanclik/core/services/camera/qr_bin_service.dart';
import 'package:cleanclik/core/services/business/inventory_service.dart';
import 'package:cleanclik/core/services/location/bin_matching_service.dart';
import 'package:cleanclik/core/services/camera/disposal_handling_service.dart';
import 'package:cleanclik/core/services/location/bin_location_service.dart';
import 'package:cleanclik/core/services/business/user_service.dart' as user_service;

import 'package:cleanclik/presentation/widgets/overlays/bin_feedback_overlay.dart';
import 'package:cleanclik/presentation/widgets/overlays/disposal_celebration_overlay.dart';
import 'package:cleanclik/presentation/widgets/camera/qr_scanner_overlay.dart';

/// Controller for managing QR scanning functionality in the AR camera
class QRCameraController {
  static const String _logTag = 'QR_CAMERA_CONTROLLER';

  final InventoryService _inventoryService;
  final DisposalHandlingService _disposalService;
  final BinLocationService _binLocationService;
  final user_service.UserService _userService;

  // State
  bool _isQRScannerActive = false;
  BinMatchResult? _currentMatchResult;

  // Callbacks
  Function(Widget)? _onShowOverlay;
  VoidCallback? _onHideOverlay;
  Function(String)? _onShowMessage;
  VoidCallback? _onNavigateHome;

  QRCameraController(
    this._inventoryService,
    this._binLocationService,
    this._userService,
  ) : _disposalService = DisposalHandlingService();

  /// Initialize the controller
  Future<void> initialize() async {
    print('🎮 [$_logTag] Initializing QR camera controller...');

    // Ensure inventory service is loaded (but don't force reload if already loaded)
    await _inventoryService.ensureLoaded();

    print('✅ [$_logTag] QR camera controller initialized');
    _inventoryService.logInventoryState('QR_CONTROLLER_INIT');
  }

  /// Set callback for showing overlays
  void setOnShowOverlay(Function(Widget) callback) {
    _onShowOverlay = callback;
  }

  /// Set callback for hiding overlays
  void setOnHideOverlay(VoidCallback callback) {
    _onHideOverlay = callback;
  }

  /// Set callback for showing messages
  void setOnShowMessage(Function(String) callback) {
    _onShowMessage = callback;
  }

  /// Set callback for navigating to home screen
  void setOnNavigateHome(VoidCallback callback) {
    _onNavigateHome = callback;
  }

  /// Get current QR scanner state
  bool get isQRScannerActive => _isQRScannerActive;

  /// Get current match result
  BinMatchResult? get currentMatchResult => _currentMatchResult;

  /// Get current inventory summary
  Map<String, dynamic> get inventorySummary =>
      _inventoryService.getInventorySummary();

  /// Start QR scanning
  Future<void> startQRScanning() async {
    if (_isQRScannerActive) {
      print('⚠️ [$_logTag] QR scanner already active');
      return;
    }

    print('📷 [$_logTag] Starting QR scanner...');
    _isQRScannerActive = true;

    // Show QR scanner overlay
    if (_onShowOverlay != null) {
      _onShowOverlay!(
        QRScannerOverlay(
          onQRScanned: _handleQRDetection,
          onClose: stopQRScanning,
        ),
      );
    }

    print('✅ [$_logTag] QR scanner started');
  }

  /// Stop QR scanning
  Future<void> stopQRScanning() async {
    if (!_isQRScannerActive) return;

    print('📷 [$_logTag] Stopping QR scanner...');
    _isQRScannerActive = false;
    _currentMatchResult = null;

    // Hide overlay
    if (_onHideOverlay != null) {
      _onHideOverlay!();
    }

    print('✅ [$_logTag] QR scanner stopped');
  }

  /// Reset scanning state to allow new scans
  void _resetScanningState() {
    print('🔄 [$_logTag] Resetting scanning state...');
    _currentMatchResult = null;

    // Reset disposal detection service
    _disposalService.reset();

    // Clear any existing overlays
    if (_onHideOverlay != null) {
      _onHideOverlay!();
    }

    print('✅ [$_logTag] Scanning state reset');
  }

  /// Handle overlay dismissal (when user cancels or closes overlay)
  void _handleOverlayDismiss() {
    print('🎭 [$_logTag] Overlay dismissed by user');

    // Reset the scanning state to allow new scans
    _resetScanningState();

    // Restart QR scanning to allow immediate rescanning
    if (_isQRScannerActive) {
      print('🔄 [$_logTag] Restarting QR scanner for new scan...');
      // Add a small delay to ensure the previous overlay is fully dismissed
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isQRScannerActive && _onShowOverlay != null) {
          _onShowOverlay!(
            QRScannerOverlay(
              onQRScanned: _handleQRDetection,
              onClose: stopQRScanning,
            ),
          );
        }
      });
    }
  }

  /// Handle QR code detection
  Future<void> _handleQRDetection(String qrData) async {
    print(
      '🔍 [$_logTag] QR code detected: ${qrData.substring(0, qrData.length.clamp(0, 50))}...',
    );

    // First, try to create a bin location from QR data
    final binLocation = _binLocationService.createBinFromQRData(qrData);
    if (binLocation != null) {
      // Add the new bin location to local storage
      final added = await _binLocationService.addBin(binLocation);
      if (added) {
        _showMessage('✅ New bin location added: ${binLocation.name}');
        print(
          '✅ [$_logTag] Added new bin location: ${binLocation.name} at ${binLocation.coordinates}',
        );
        print(
          '🗺️ [$_logTag] Bin will appear on map automatically via stream updates',
        );
      } else {
        _showMessage('⚠️ Bin location already exists nearby');
        print('⚠️ [$_logTag] Bin location already exists within 10m radius');
      }
    }

    // Parse QR code for disposal matching
    final binInfo = QRBinService.parseQRCode(qrData);
    if (binInfo == null) {
      print('❌ [$_logTag] Failed to parse QR code for disposal');
      _showMessage('Invalid QR Code: ${QRBinService.getErrorMessage(qrData)}');
      // Reset scanning state to allow retry
      _resetScanningState();
      return;
    }

    print(
      '✅ [$_logTag] Successfully parsed bin: ${binInfo.binId} (${binInfo.category.id})',
    );

    // Debug: Check inventory state before matching
    _inventoryService.logInventoryState('QR_SCAN_BEFORE_MATCH');

    // Analyze match with current inventory
    final matchResult = BinMatchingService.analyzeMatch(
      binInfo,
      _inventoryService.inventory,
    );

    _currentMatchResult = matchResult;

    // Log match analysis
    BinMatchingService.logMatchResult(matchResult);

    // Show bin feedback overlay
    print('🎭 [$_logTag] Attempting to show bin feedback overlay...');
    if (_onShowOverlay != null) {
      print('✅ [$_logTag] Overlay callback is available, showing overlay');
      _onShowOverlay!(
        BinFeedbackOverlay(
          matchResult: matchResult,
          onDispose: (itemsToDispose) => _handleDisposal(matchResult),
          onDismiss: _handleOverlayDismiss,
        ),
      );
      print('📱 [$_logTag] Overlay widget created and callback invoked');
    } else {
      print('❌ [$_logTag] No overlay callback available!');
    }

    print(
      '📊 [$_logTag] Match result: ${matchResult.matchType} (${matchResult.matchingItems.length} matching items)',
    );
  }

  /// Handle disposal action
  Future<void> _handleDisposal(BinMatchResult matchResult) async {
    if (matchResult.matchingItems.isEmpty) {
      print('⚠️ [$_logTag] No items to dispose');
      _showMessage('No matching items to dispose');
      return;
    }

    print(
      '🗑️ [$_logTag] Processing disposal for ${matchResult.matchingItems.length} items...',
    );

    try {
      // Get the items to dispose
      final itemsToDispose = matchResult.matchingItems;

      // Use DisposalHandlingService to validate and calculate disposal
      final disposalResult = _disposalService.validateDisposal(
        itemsToDispose,
        matchResult.binInfo,
      );

      if (disposalResult == null) {
        print('⚠️ [$_logTag] Disposal validation failed');
        _showMessage('Unable to dispose items in this bin');
        return;
      }

      // Confirm disposal with the service
      final confirmed = await _disposalService.confirmDisposal(
        itemsToDispose,
        matchResult.binInfo,
      );

      if (!confirmed) {
        print('⚠️ [$_logTag] Disposal confirmation failed');
        _showMessage('Disposal confirmation failed');
        return;
      }

      // Remove items from inventory
      final trackingIds = itemsToDispose
          .map((item) => item.trackingId)
          .toList();
      await _inventoryService.removeItems(trackingIds);

      // Award points through UserService after successful disposal
      try {
        final points = _calculatePoints(itemsToDispose);
        await _userService.addPoints(points);
        print('🏆 [$_logTag] Awarded $points points through UserService');
      } catch (e) {
        print('❌ [$_logTag] Error awarding points: $e');
        // Don't fail disposal if points fail
      }

      print(
        '✅ [$_logTag] Disposal successful: ${disposalResult.itemsDisposed.length} items, ${disposalResult.pointsEarned} points',
      );

      // Show celebration overlay
      if (_onShowOverlay != null) {
        // Create a DisposalResult for the celebration overlay using InventoryItem directly
        final celebrationResult = DisposalResult(
          binInfo: disposalResult.binInfo,
          itemsDisposed: disposalResult.itemsDisposed,
          pointsEarned: disposalResult.pointsEarned,
          streakCount: disposalResult.streakCount,
          accuracy: disposalResult.accuracy,
          disposalTime: disposalResult.disposalTime,
          bonusMultiplier: disposalResult.bonusMultiplier,

        );

        _onShowOverlay!(
          DisposalCelebrationOverlay(
            disposalResult: celebrationResult,
            onDismiss: () {
              stopQRScanning();
              // Navigate to home screen after disposal
              if (_onNavigateHome != null) {
                _onNavigateHome!();
              }
            },
          ),
        );
      }

      // Update current match result to reflect the disposal
      _currentMatchResult = null;

      print(
        '📊 [$_logTag] Updated inventory: ${_inventoryService.inventory.length} items remaining',
      );
    } catch (e) {
      print('❌ [$_logTag] Disposal error: $e');
      _showMessage('Disposal error: $e');
    }
  }

  /// Calculate points based on item categories
  /// Requirements: 8.2
  int _calculatePoints(List<InventoryItem> items) {
    int total = 0;
    for (final item in items) {
      switch (item.category.toLowerCase()) {
        case 'hazardous':
          total += 20;
          break;
        case 'ewaste':
          total += 15;
          break;
        case 'recycle':
          total += 10;
          break;
        case 'organic':
          total += 8;
          break;
        case 'landfill':
          total += 5;
          break;
        default:
          total += 5;
      }
    }
    return total;
  }

  /// Show message to user
  void _showMessage(String message) {
    print('💬 [$_logTag] Message: $message');
    if (_onShowMessage != null) {
      _onShowMessage!(message);
    }
  }

  /// Handle QR scan result (public interface)
  Future<void> handleQRScan(String qrData) async {
    await _handleQRDetection(qrData);
  }

  /// Get current inventory state for UI
  Map<String, dynamic> getInventoryState() {
    return {
      'total_items': _inventoryService.inventory.length,
      'categories': _inventoryService.inventoryCategories,
      'has_items': _inventoryService.hasItems,
    };
  }

  /// Clear inventory for testing
  Future<void> clearInventory() async {
    await _inventoryService.clearInventory();
    print('✅ [$_logTag] Cleared inventory');
  }

  /// Get disposal statistics
  Map<String, dynamic> getDisposalStats() {
    // Simplified stats without session tracking
    return {
      'total_items': _inventoryService.inventory.length,
      'categories': _inventoryService.inventoryCategories,
      'has_items': _inventoryService.hasItems,
    };
  }

  /// Validate current inventory for disposal
  bool canDispose() {
    return _inventoryService.hasItems &&
        _isQRScannerActive &&
        _currentMatchResult != null;
  }

  /// Get suggestions for disposal
  List<String> getDisposalSuggestions() {
    if (_inventoryService.isEmpty) {
      return [
        'Scan objects with camera first',
        'Pick up items to fill inventory',
      ];
    }

    if (!_isQRScannerActive) {
      return ['Tap QR scan button', 'Point camera at bin QR code'];
    }

    if (_currentMatchResult == null) {
      return ['Scan a bin QR code', 'Find a waste disposal bin'];
    }

    final result = _currentMatchResult!;
    if (result.matchType == BinMatchType.noMatch) {
      return ['Find correct bin type', 'Look for: ${result.additionalInfo}'];
    }

    if (result.matchType == BinMatchType.partialMatch) {
      return ['Dispose matching items', 'Find additional bins for other items'];
    }

    return ['Ready to dispose!', 'Confirm disposal action'];
  }

  /// Force refresh inventory from storage
  Future<void> refreshInventory() async {
    // Just ensure loaded instead of forcing a reload
    await _inventoryService.ensureLoaded();
    print(
      '🔄 [$_logTag] Inventory refreshed: ${_inventoryService.inventory.length} items',
    );
  }

  /// Get current controller state for debugging
  Map<String, dynamic> getControllerState() {
    return {
      'is_qr_scanner_active': _isQRScannerActive,
      'has_current_match_result': _currentMatchResult != null,
      'current_match_type': _currentMatchResult?.matchType.toString(),
      'inventory_summary': _inventoryService.getInventorySummary(),
      'disposal_service_status': _disposalService.getDebugInfo(),
    };
  }

  /// Force reset all state (for debugging/recovery)
  Future<void> forceReset() async {
    print('🔧 [$_logTag] Force resetting all controller state...');

    // Stop scanning
    _isQRScannerActive = false;

    // Clear match result
    _currentMatchResult = null;

    // Reset disposal service
    _disposalService.reset();

    // Hide any overlays
    if (_onHideOverlay != null) {
      _onHideOverlay!();
    }

    print('✅ [$_logTag] Force reset complete');
  }

  /// Dispose of the controller with proper resource cleanup
  Future<void> dispose() async {
    print('🎮 [$_logTag] Disposing QR camera controller...');

    try {
      // Stop any active scanning with timeout
      await stopQRScanning().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('⚠️ [$_logTag] QR scanning stop timed out during disposal');
        },
      );

      // Dispose services with timeout
      await Future(() {
        _disposalService.dispose();
      }).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          print('⚠️ [$_logTag] Disposal service cleanup timed out');
        },
      );

      // Clear state
      _isQRScannerActive = false;
      _currentMatchResult = null;

      // Clear callbacks to prevent memory leaks
      _onShowOverlay = null;
      _onHideOverlay = null;
      _onShowMessage = null;
      _onNavigateHome = null;

      print('✅ [$_logTag] QR camera controller disposed successfully');
    } catch (e) {
      print('⚠️ [$_logTag] Error during QR controller disposal: $e');
      // Force clear state even if disposal failed
      _isQRScannerActive = false;
      _currentMatchResult = null;
      _onShowOverlay = null;
      _onHideOverlay = null;
      _onShowMessage = null;
      _onNavigateHome = null;
    }
  }
}
