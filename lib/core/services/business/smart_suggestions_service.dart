import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/models/ui_context.dart';

/// AI-powered contextual suggestions service
class SmartSuggestionsService {
  final StreamController<List<SmartSuggestion>> _suggestionsController =
      StreamController<List<SmartSuggestion>>.broadcast();

  final List<SmartSuggestion> _currentSuggestions = [];
  final math.Random _random = math.Random();

  /// Stream of smart suggestions
  Stream<List<SmartSuggestion>> get suggestionsStream =>
      _suggestionsController.stream;

  /// Current suggestions
  List<SmartSuggestion> get currentSuggestions =>
      List.unmodifiable(_currentSuggestions);

  /// Generate suggestions based on context
  void generateSuggestions(
    UIContextData context, {
    Map<String, dynamic>? userData,
    Map<String, dynamic>? environmentData,
  }) {
    _currentSuggestions.clear();

    switch (context.context) {
      case UIContext.arCamera:
        _generateARSuggestions(context, userData, environmentData);
        break;
      case UIContext.map:
        _generateMapSuggestions(context, userData, environmentData);
        break;
      case UIContext.inventory:
        _generateInventorySuggestions(context, userData, environmentData);
        break;
      case UIContext.social:
        _generateSocialSuggestions(context, userData, environmentData);
        break;
      case UIContext.profile:
        _generateProfileSuggestions(context, userData, environmentData);
        break;
      case UIContext.mission:
        _generateMissionSuggestions(context, userData, environmentData);
        break;
    }

    _suggestionsController.add(_currentSuggestions);
  }

  void _generateARSuggestions(
    UIContextData context,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? environmentData,
  ) {
    switch (context.activityState) {
      case ActivityState.idle:
        _addSuggestion(
          SmartSuggestion(
            id: 'scan_tip',
            type: SuggestionType.tip,
            title: 'Start Scanning',
            description:
                'Point your camera at objects to identify waste categories',
            action: 'start_scan',
            priority: SuggestionPriority.high,
            icon: 'camera_alt',
          ),
        );
        break;

      case ActivityState.scanning:
        if (_random.nextBool()) {
          _addSuggestion(
            SmartSuggestion(
              id: 'detection_tip',
              type: SuggestionType.tip,
              title: 'Better Detection',
              description: 'Move closer to objects for better recognition',
              action: 'detection_help',
              priority: SuggestionPriority.medium,
              icon: 'zoom_in',
            ),
          );
        }
        break;

      case ActivityState.carrying:
        _addSuggestion(
          SmartSuggestion(
            id: 'find_bin',
            type: SuggestionType.action,
            title: 'Find Disposal Bin',
            description: 'Look for nearby bins to dispose of your items',
            action: 'find_bin',
            priority: SuggestionPriority.high,
            icon: 'place',
          ),
        );
        break;

      case ActivityState.approaching:
        _addSuggestion(
          SmartSuggestion(
            id: 'disposal_ready',
            type: SuggestionType.celebration,
            title: 'Ready to Dispose!',
            description:
                'You\'re near the correct bin. Drop your items to earn points!',
            action: 'dispose_items',
            priority: SuggestionPriority.urgent,
            icon: 'delete',
          ),
        );
        break;

      case ActivityState.celebrating:
        _addSuggestion(
          SmartSuggestion(
            id: 'share_achievement',
            type: SuggestionType.social,
            title: 'Share Your Success!',
            description: 'Tell your friends about your environmental impact',
            action: 'share_achievement',
            priority: SuggestionPriority.medium,
            icon: 'share',
          ),
        );
        break;

      default:
        break;
    }

    // Add contextual suggestions based on user data
    if (userData != null) {
      _addUserBasedSuggestions(userData);
    }

    // Add environmental suggestions
    if (environmentData != null) {
      _addEnvironmentalSuggestions(environmentData);
    }
  }

  void _generateMapSuggestions(
    UIContextData context,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? environmentData,
  ) {
    _addSuggestion(
      SmartSuggestion(
        id: 'nearby_hotspots',
        type: SuggestionType.exploration,
        title: 'Cleanup Hotspots Nearby',
        description: 'There are high-impact areas within 500m of your location',
        action: 'show_hotspots',
        priority: SuggestionPriority.medium,
        icon: 'whatshot',
      ),
    );

    _addSuggestion(
      SmartSuggestion(
        id: 'route_optimization',
        type: SuggestionType.tip,
        title: 'Optimize Your Route',
        description:
            'Plan an efficient path through multiple cleanup locations',
        action: 'optimize_route',
        priority: SuggestionPriority.low,
        icon: 'route',
      ),
    );
  }

  void _generateInventorySuggestions(
    UIContextData context,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? environmentData,
  ) {
    _addSuggestion(
      SmartSuggestion(
        id: 'disposal_reminder',
        type: SuggestionType.reminder,
        title: 'Items Ready for Disposal',
        description: 'You have 3 items ready to be disposed of properly',
        action: 'find_disposal_bins',
        priority: SuggestionPriority.high,
        icon: 'inventory',
      ),
    );
  }

  void _generateSocialSuggestions(
    UIContextData context,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? environmentData,
  ) {
    _addSuggestion(
      SmartSuggestion(
        id: 'challenge_friends',
        type: SuggestionType.social,
        title: 'Challenge Your Friends',
        description: 'Start a weekly cleanup challenge with your network',
        action: 'create_challenge',
        priority: SuggestionPriority.medium,
        icon: 'emoji_events',
      ),
    );
  }

  void _generateProfileSuggestions(
    UIContextData context,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? environmentData,
  ) {
    _addSuggestion(
      SmartSuggestion(
        id: 'streak_milestone',
        type: SuggestionType.achievement,
        title: 'Streak Milestone Coming Up!',
        description: 'Clean up 2 more items to reach your 10-day streak',
        action: 'continue_streak',
        priority: SuggestionPriority.medium,
        icon: 'local_fire_department',
      ),
    );
  }

  void _generateMissionSuggestions(
    UIContextData context,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? environmentData,
  ) {
    _addSuggestion(
      SmartSuggestion(
        id: 'time_sensitive_mission',
        type: SuggestionType.urgent,
        title: 'Time-Limited Mission',
        description:
            'Complete the "Park Cleanup" mission in the next 2 hours for bonus points',
        action: 'accept_mission',
        priority: SuggestionPriority.urgent,
        icon: 'timer',
      ),
    );
  }

  void _addUserBasedSuggestions(Map<String, dynamic> userData) {
    final streak = userData['streak'] as int? ?? 0;
    final totalPoints = userData['totalPoints'] as int? ?? 0;

    if (streak > 0 && streak % 5 == 4) {
      _addSuggestion(
        SmartSuggestion(
          id: 'streak_bonus',
          type: SuggestionType.achievement,
          title: 'Streak Bonus Available!',
          description:
              'One more cleanup today for a ${streak + 1}-day streak bonus',
          action: 'maintain_streak',
          priority: SuggestionPriority.high,
          icon: 'local_fire_department',
        ),
      );
    }

    if (totalPoints > 0 && totalPoints % 1000 < 100) {
      _addSuggestion(
        SmartSuggestion(
          id: 'milestone_approaching',
          type: SuggestionType.achievement,
          title: 'Milestone Approaching',
          description:
              'You\'re ${1000 - (totalPoints % 1000)} points away from the next milestone',
          action: 'view_milestones',
          priority: SuggestionPriority.low,
          icon: 'emoji_events',
        ),
      );
    }
  }

  void _addEnvironmentalSuggestions(Map<String, dynamic> environmentData) {
    final weather = environmentData['weather'] as String?;
    final timeOfDay = environmentData['timeOfDay'] as String?;

    if (weather == 'sunny' && timeOfDay == 'morning') {
      _addSuggestion(
        SmartSuggestion(
          id: 'perfect_weather',
          type: SuggestionType.motivation,
          title: 'Perfect Weather for Cleanup!',
          description:
              'Beautiful morning - ideal conditions for outdoor cleanup activities',
          action: 'start_outdoor_mission',
          priority: SuggestionPriority.medium,
          icon: 'wb_sunny',
        ),
      );
    }
  }

  void _addSuggestion(SmartSuggestion suggestion) {
    // Avoid duplicates
    if (!_currentSuggestions.any((s) => s.id == suggestion.id)) {
      _currentSuggestions.add(suggestion);
    }
  }

  /// Dismiss a suggestion
  void dismissSuggestion(String suggestionId) {
    _currentSuggestions.removeWhere((s) => s.id == suggestionId);
    _suggestionsController.add(_currentSuggestions);
  }

  /// Clear all suggestions
  void clearSuggestions() {
    _currentSuggestions.clear();
    _suggestionsController.add(_currentSuggestions);
  }

  void dispose() {
    _suggestionsController.close();
  }
}

/// Smart suggestion data model
class SmartSuggestion {
  final String id;
  final SuggestionType type;
  final String title;
  final String description;
  final String action;
  final SuggestionPriority priority;
  final String icon;
  final DateTime timestamp;
  final Duration? expiresIn;

  SmartSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
    required this.icon,
    DateTime? timestamp,
    this.expiresIn,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isExpired {
    if (expiresIn == null) return false;
    return DateTime.now().difference(timestamp) > expiresIn!;
  }
}

/// Types of suggestions
enum SuggestionType {
  tip,
  action,
  reminder,
  social,
  achievement,
  exploration,
  motivation,
  urgent,
  celebration,
}

/// Priority levels for suggestions
enum SuggestionPriority { low, medium, high, urgent }

/// Provider for smart suggestions service
final smartSuggestionsServiceProvider = Provider<SmartSuggestionsService>((
  ref,
) {
  final service = SmartSuggestionsService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for current suggestions
final currentSuggestionsProvider = StreamProvider<List<SmartSuggestion>>((ref) {
  final service = ref.watch(smartSuggestionsServiceProvider);
  return service.suggestionsStream;
});
