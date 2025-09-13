import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/models/card_data.dart';
import 'package:cleanclik/core/services/social/social_sharing_service.dart';
import 'package:cleanclik/core/services/social/card_renderer.dart';
import 'package:cleanclik/core/services/platform/platform_optimizer.dart';
import 'package:cleanclik/core/services/business/motivational_message_service.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';


enum CardTemplate { achievement, impact, progress }

extension CardTemplateExtension on CardTemplate {
  String get displayName {
    switch (this) {
      case CardTemplate.achievement:
        return 'Achievement Focus';
      case CardTemplate.impact:
        return 'Environmental Impact';
      case CardTemplate.progress:
        return 'Progress & Stats';
    }
  }

  String get description {
    switch (this) {
      case CardTemplate.achievement:
        return 'Highlights recent achievements and badges';
      case CardTemplate.impact:
        return 'Emphasizes environmental impact metrics';
      case CardTemplate.progress:
        return 'Shows level progression and streaks';
    }
  }
}

class SocialCardGenerationService {
  final CardRenderer _cardRenderer;
  final PlatformOptimizer _platformOptimizer;
  final MotivationalMessageService _messageService;

  SocialCardGenerationService({
    required CardRenderer cardRenderer,
    required PlatformOptimizer platformOptimizer,
    required MotivationalMessageService messageService,
  }) : _cardRenderer = cardRenderer,
       _platformOptimizer = platformOptimizer,
       _messageService = messageService;

  /// Generate a social media card with the specified template and platform
  Future<File> generateCard({
    required CardTemplate template,
    required CardData data,
    required SocialPlatform platform,
  }) async {
    try {
      print(
        '🎨 SocialCardGenerationService: Generating ${template.displayName} card for ${platform.displayName}',
      );

      final dimensions = _platformOptimizer.getDimensions(platform);
      print(
        '📐 SocialCardGenerationService: Card dimensions - ${dimensions.width}x${dimensions.height}',
      );

      // Widget is no longer needed since we use canvas rendering
      final widget = Container(); // Placeholder widget
      print('🔧 SocialCardGenerationService: Using canvas-based rendering');

      final filename =
          'vibesweep_${template.name}_${platform.name}_${DateTime.now().millisecondsSinceEpoch}.png';
      print('📁 SocialCardGenerationService: Rendering to file: $filename');

      final file = await _cardRenderer.renderAndSave(
        widget,
        Size(dimensions.width, dimensions.height),
        filename,
        userData: {
          'userName': data.userName,
          'totalPoints': data.totalPoints,
          'totalItems': data.impact.itemsCategorized,
          'userLevel': data.userLevel,
          'currentStreak': data.currentStreak,
        },
      );

      print(
        '✅ SocialCardGenerationService: Card generated successfully at: ${file.path}',
      );
      return file;
    } catch (e, stackTrace) {
      print('❌ SocialCardGenerationService: Failed to generate card: $e');
      print('📍 SocialCardGenerationService: Stack trace: $stackTrace');
      throw SocialCardGenerationException(
        message:
            'Failed to generate ${template.displayName} card for ${platform.displayName}',
        originalError: e,
      );
    }
  }

  /// Generate card data from current user state
  Future<CardData> aggregateUserData(WidgetRef ref) async {
    try {
      print('🔍 SocialCardGenerationService: Starting user data aggregation');

      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        print('❌ SocialCardGenerationService: No current user found');
        throw SocialCardGenerationException(
          message: 'No current user available for card generation',
        );
      }

      print(
        '👤 SocialCardGenerationService: User found - ${currentUser.username}, Points: ${currentUser.totalPoints}',
      );

      // Create environmental impact data
      final impact = EnvironmentalImpact(
        itemsCategorized: currentUser.totalItemsCollected,
        co2Saved: currentUser.totalItemsCollected * 0.5, // Estimate
        treesEquivalent: (currentUser.totalItemsCollected * 0.1).round(),
        impactMessage: 'Making a difference one item at a time!',
      );

      // Create sample recent activity
      final recentActivity = [
        RecentActivity(
          type: 'recycle',
          description: 'Categorized plastic bottle',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          pointsEarned: 10,
        ),
      ];

      final cardData = CardData(
        userName: currentUser.username,
        userLevel: 'Level ${(currentUser.totalPoints / 1000).floor() + 1}',
        totalPoints: currentUser.totalPoints,
        currentStreak: 7, // This would come from a streak service
        recentBadges: ['Eco Warrior', 'Streak Master'],
        impact: impact,
        profileImageUrl: '', // Would come from user profile
        lastActivity: DateTime.now(),
        locationName: 'Your City',
        recentActivity: recentActivity,
        motivationalMessage: _messageService.generateMotivationalMessage(
          CardData(
            userName: currentUser.username,
            userLevel: 'Level ${(currentUser.totalPoints / 1000).floor() + 1}',
            totalPoints: currentUser.totalPoints,
            currentStreak: 7,
            recentBadges: ['Eco Warrior'],
            impact: impact,
            profileImageUrl: '',
            lastActivity: DateTime.now(),
            locationName: 'Your City',
            recentActivity: recentActivity,
            motivationalMessage: '',
            callToAction: '',
          ),
        ),
        callToAction: _messageService.generateCallToAction(
          CardData(
            userName: currentUser.username,
            userLevel: 'Level ${(currentUser.totalPoints / 1000).floor() + 1}',
            totalPoints: currentUser.totalPoints,
            currentStreak: 7,
            recentBadges: ['Eco Warrior'],
            impact: impact,
            profileImageUrl: '',
            lastActivity: DateTime.now(),
            locationName: 'Your City',
            recentActivity: recentActivity,
            motivationalMessage: '',
            callToAction: '',
          ),
        ),
      );

      print('✅ SocialCardGenerationService: Card data aggregated successfully');
      return cardData;
    } catch (e, stackTrace) {
      print('❌ SocialCardGenerationService: Failed to aggregate user data: $e');
      print('📍 SocialCardGenerationService: Stack trace: $stackTrace');
      throw SocialCardGenerationException(
        message: 'Failed to aggregate user data for card generation',
        originalError: e,
      );
    }
  }

  /// Get available card templates
  List<CardTemplate> getAvailableTemplates() {
    return CardTemplate.values;
  }

  // Widget building methods removed - now using canvas-based rendering

  // All widget building methods removed - now using canvas-based rendering in CardRenderer
}

class SocialCardGenerationException implements Exception {
  final String message;
  final dynamic originalError;

  const SocialCardGenerationException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'SocialCardGenerationException: $message';
}

/// Provider for SocialCardGenerationService
final socialCardGenerationServiceProvider =
    Provider<SocialCardGenerationService>((ref) {
      return SocialCardGenerationService(
        cardRenderer: CardRenderer(),
        platformOptimizer: ref.read(platformOptimizerProvider),
        messageService: ref.read(motivationalMessageServiceProvider),
      );
    });
