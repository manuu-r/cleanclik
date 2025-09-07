/// Represents the current UI context for adaptive interface
enum UIContext {
  arCamera,
  map,
  inventory,
  social,
  profile,
  mission,
}

/// Represents the current user activity state
enum ActivityState {
  idle,
  scanning,
  tracking,
  carrying,
  approaching,
  disposing,
  celebrating,
}

/// UI context data for adaptive interface
class UIContextData {
  final UIContext context;
  final ActivityState activityState;
  final Map<String, dynamic> contextData;
  final DateTime timestamp;
  
  const UIContextData({
    required this.context,
    required this.activityState,
    this.contextData = const {},
    required this.timestamp,
  });
  
  UIContextData copyWith({
    UIContext? context,
    ActivityState? activityState,
    Map<String, dynamic>? contextData,
    DateTime? timestamp,
  }) {
    return UIContextData(
      context: context ?? this.context,
      activityState: activityState ?? this.activityState,
      contextData: contextData ?? this.contextData,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UIContextData &&
        other.context == context &&
        other.activityState == activityState;
  }
  
  @override
  int get hashCode => Object.hash(context, activityState);
}