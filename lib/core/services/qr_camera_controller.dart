import 'package:flutter/material.dart';
import 'qr_bin_service.dart';
import 'inventory_service.dart';
import 'bin_matching_service.dart';
import 'disposal_detection_service.dart';
import 'hand_tracking_service.dart';
import 'bin_location_service.dart';

import '../../presentation/widgets/bin_feedback_overlay.dart';
import '../../presentation/widgets/disposal_celebration_overlay.dart';
import '../../presentation/widgets/qr_scanner_overlay.dart';

/// Controller for managing QR scanning functionality in the AR camera
class QRCameraController {
  static const String _logTag = 'QR_CAMERA_CONTROLLER';

  final InventoryService _inventoryService;
  final DisposalDetectionService _disposalService;
  final BinLocationService _binLocationService;

  // State
  bool _isQRScannerActive = false;
  BinMatchResult? _currentMatchResult;

  // Callbacks
  Function(Widget)? _onShowOverlay;
  VoidCallback? _onHideOverlay;
  Function(String)? _onShowMessage;
  VoidCallback? _onNavigateHome;

  QRCameraController(this._inventoryService, this._binLocationService)
    : _disposalService = DisposalDetectionService();

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
        print('✅ [$_logTag] Added new bin location: ${binLocation.name} at ${binLocation.coordinates}');
        print('🗺️ [$_logTag] Bin will appear on map automatically via stream updates');
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
    if (_onShowOverlay != null) {
      _onShowOverlay!(
        BinFeedbackOverlay(
          matchResult: matchResult,
          onDispose: (itemsToDispose) => _handleDisposal(matchResult),
          onDismiss: stopQRScanning,
        ),
      );
    }

    print(
      '📊 [$_logTag] Match result: ${matchResult.matchType} (${matchResult.matchingItems.length} matching items)',
    );
  }

  /// Handle hand gesture detection for disposal
  Future<DisposalResult?> processHandGestures(
    List<HandLandmark> handLandmarks,
  ) async {
    if (!_isQRScannerActive || _currentMatchResult == null) {
      return null;
    }

    return _disposalService.processHandLandmarks(
      handLandmarks,
      _inventoryService.carriedItems,
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
      
      // Remove items from inventory
      final trackingIds = itemsToDispose.map((item) => item.trackingId).toList();
      await _inventoryService.removeItems(trackingIds);

      // Award points for disposal after successful disposal confirmation
      await _inventoryService.awardPointsForDisposal(itemsToDispose);

      // Calculate points for celebration display
      const categoryPoints = {
        'recycle': 10,
        'organic': 8,
        'ewaste': 15,
        'hazardous': 20,
      };
      
      int totalPoints = 0;
      for (final item in itemsToDispose) {
        totalPoints += categoryPoints[item.category] ?? 5;
      }

      print(
        '✅ [$_logTag] Disposal successful: ${itemsToDispose.length} items, $totalPoints points',
      );

      // Show celebration overlay
      if (_onShowOverlay != null) {
        // Create a DisposalResult for the celebration overlay
        final celebrationResult = DisposalResult(
          binInfo: matchResult.binInfo,
          itemsDisposed: itemsToDispose
              .map((item) => item.toCarriedItem())
              .toList(),
          pointsEarned: totalPoints,
          streakCount: 1,
          accuracy: 1.0,
          disposalTime: DateTime.now(),
          bonusMultiplier: 1.0,
        );

        _onShowOverlay!(
          DisposalCelebrationOverlay(
            disposalResult: celebrationResult,
            onComplete: () {
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
      print('🏆 [$_logTag] Total points: ${_inventoryService.totalPoints}');
    } catch (e) {
      print('❌ [$_logTag] Disposal error: $e');
      _showMessage('Disposal error: $e');
    }
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
      'total_points': _inventoryService.totalPoints,
      'categories': _inventoryService.carriedCategories,
      'session_stats': _inventoryService.sessionStats.toJson(),
      'has_items': _inventoryService.hasItems,
    };
  }

  /// Add test items for development
  Future<void> addTestItems() async {
    await _inventoryService.addTestItems();
    print('✅ [$_logTag] Added test items to inventory');
  }

  /// Clear inventory for testing
  Future<void> clearInventory() async {
    await _inventoryService.clearInventory();
    print('✅ [$_logTag] Cleared inventory');
  }

  /// Get disposal statistics
  Map<String, dynamic> getDisposalStats() {
    final stats = _inventoryService.sessionStats;
    return {
      'items_picked_up': stats.totalItemsPickedUp,
      'items_disposed': stats.totalItemsDisposed,
      'points_earned': stats.totalPointsEarned,
      'disposal_accuracy': stats.disposalAccuracy,
      'session_duration': stats.sessionDuration.inMinutes,
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

  /// Dispose of the controller
  Future<void> dispose() async {
    print('🎮 [$_logTag] Disposing QR camera controller...');

    // Stop any active scanning
    await stopQRScanning();

    // Dispose services
    await _inventoryService.dispose();

    print('✅ [$_logTag] QR camera controller disposed');
  }
}
