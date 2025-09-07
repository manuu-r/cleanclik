import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/services/smart_suggestions_service.dart';
import 'package:cleanclik/presentation/widgets/smart_suggestion_card.dart';

/// Overlay for displaying smart suggestions
class SmartSuggestionsOverlay extends ConsumerWidget {
  final Function(String action)? onActionTap;
  final bool isCompact;
  final int maxSuggestions;
  
  const SmartSuggestionsOverlay({
    super.key,
    this.onActionTap,
    this.isCompact = false,
    this.maxSuggestions = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(currentSuggestionsProvider);
    
    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        
        // Filter out expired suggestions
        final activeSuggestions = suggestions
            .where((s) => !s.isExpired)
            .toList();
        
        if (activeSuggestions.isEmpty) return const SizedBox.shrink();
        
        // Sort by priority and take max suggestions
        activeSuggestions.sort((a, b) => 
            b.priority.index.compareTo(a.priority.index));
        
        final displaySuggestions = activeSuggestions
            .take(maxSuggestions)
            .toList();
        
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: Column(
            children: displaySuggestions.map((suggestion) {
              return SmartSuggestionCard(
                suggestion: suggestion,
                isCompact: isCompact,
                onTap: () => _onSuggestionTap(ref, suggestion),
                onDismiss: () => _onSuggestionDismiss(ref, suggestion),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  void _onSuggestionTap(WidgetRef ref, SmartSuggestion suggestion) {
    // Handle suggestion action
    onActionTap?.call(suggestion.action);
    
    // Optionally dismiss after tap
    if (suggestion.type == SuggestionType.action ||
        suggestion.type == SuggestionType.urgent) {
      _onSuggestionDismiss(ref, suggestion);
    }
  }
  
  void _onSuggestionDismiss(WidgetRef ref, SmartSuggestion suggestion) {
    final service = ref.read(smartSuggestionsServiceProvider);
    service.dismissSuggestion(suggestion.id);
  }
}