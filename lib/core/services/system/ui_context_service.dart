import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/models/ui_context.dart';

/// Service for managing UI context and adaptive interface behavior
class UIContextService {
  final StreamController<UIContextData> _contextController =
      StreamController<UIContextData>.broadcast();

  UIContextData _currentContext = UIContextData(
    context: UIContext.arCamera,
    activityState: ActivityState.idle,
    timestamp: DateTime.now(),
  );

  /// Stream of UI context changes
  Stream<UIContextData> get contextStream => _contextController.stream;

  /// Current UI context
  UIContextData get currentContext => _currentContext;

  /// Update the UI context
  void updateContext(
    UIContext context, {
    ActivityState? activityState,
    Map<String, dynamic>? contextData,
  }) {
    _currentContext = _currentContext.copyWith(
      context: context,
      activityState: activityState,
      contextData: contextData,
      timestamp: DateTime.now(),
    );
    _contextController.add(_currentContext);
  }

  /// Update only the activity state
  void updateActivityState(
    ActivityState activityState, {
    Map<String, dynamic>? contextData,
  }) {
    _currentContext = _currentContext.copyWith(
      activityState: activityState,
      contextData: contextData,
      timestamp: DateTime.now(),
    );
    _contextController.add(_currentContext);
  }

  /// Check if current context matches
  bool isContext(UIContext context) => _currentContext.context == context;

  /// Check if current activity state matches
  bool isActivityState(ActivityState state) =>
      _currentContext.activityState == state;

  /// Get contextual actions for current state
  List<String> getContextualActions() {
    switch (_currentContext.context) {
      case UIContext.arCamera:
        return _getARCameraActions();
      case UIContext.map:
        return _getMapActions();
      case UIContext.inventory:
        return _getInventoryActions();
      case UIContext.social:
        return _getSocialActions();
      case UIContext.profile:
        return _getProfileActions();
      case UIContext.mission:
        return _getMissionActions();
    }
  }

  List<String> _getARCameraActions() {
    switch (_currentContext.activityState) {
      case ActivityState.idle:
      case ActivityState.scanning:
        return ['scan', 'inventory', 'nearby_bins', 'profile_stats'];
      case ActivityState.tracking:
      case ActivityState.carrying:
        return ['inventory', 'find_bin', 'cancel_pickup', 'help'];
      case ActivityState.approaching:
        return ['dispose', 'inventory', 'wrong_bin', 'help'];
      case ActivityState.disposing:
        return ['confirm', 'cancel', 'help'];
      case ActivityState.celebrating:
        return ['share', 'continue', 'leaderboard', 'next_mission'];
    }
  }

  List<String> _getMapActions() {
    return ['bins', 'hotspots', 'missions', 'friends'];
  }

  List<String> _getInventoryActions() {
    return ['dispose', 'categories', 'share', 'clear'];
  }

  List<String> _getSocialActions() {
    return ['leaderboard', 'friends', 'share', 'challenges'];
  }

  List<String> _getProfileActions() {
    return ['stats', 'badges', 'settings', 'help'];
  }

  List<String> _getMissionActions() {
    return ['accept', 'details', 'leaderboard', 'share'];
  }

  void dispose() {
    _contextController.close();
  }
}

/// Provider for UI context service
final uiContextServiceProvider = Provider<UIContextService>((ref) {
  final service = UIContextService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for current UI context
final currentUIContextProvider = StreamProvider<UIContextData>((ref) {
  final service = ref.watch(uiContextServiceProvider);
  return service.contextStream;
});
