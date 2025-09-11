import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cleanclik/core/models/card_data.dart';
import 'social_sharing_service.dart';
import 'card_renderer.dart';
import 'package:cleanclik/core/services/platform/platform_optimizer.dart';
import 'package:cleanclik/core/services/business/motivational_message_service.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';

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

      final widget = _buildCardWidget(template, data, platform);
      print('🔧 SocialCardGenerationService: Widget built successfully');

      final filename =
          'vibesweep_${template.name}_${platform.name}_${DateTime.now().millisecondsSinceEpoch}.png';
      print('📁 SocialCardGenerationService: Rendering to file: $filename');

      final file = await _cardRenderer.renderAndSave(
        widget,
        Size(dimensions.width, dimensions.height),
        filename,
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

  /// Build the card widget based on template
  Widget _buildCardWidget(
    CardTemplate template,
    CardData data,
    SocialPlatform platform,
  ) {
    switch (template) {
      case CardTemplate.achievement:
        return _buildAchievementCard(data, platform);
      case CardTemplate.impact:
        return _buildImpactCard(data, platform);
      case CardTemplate.progress:
        return _buildProgressCard(data, platform);
    }
  }

  Widget _buildAchievementCard(CardData data, SocialPlatform platform) {
    final dimensions = _platformOptimizer.getDimensions(platform);

    return Container(
      width: dimensions.width,
      height: dimensions.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NeonColors.electricGreen, NeonColors.cosmicPurple],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎉 Achievement Unlocked!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VibeSweep',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Achievement content
            Text(
              data.motivationalMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'By ${data.userName}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
              ),
            ),

            const Spacer(),

            // Recent badges
            if (data.recentBadges.isNotEmpty) ...[
              const Text(
                'Recent Achievements:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: data.recentBadges
                    .take(3)
                    .map(
                      (badge) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard(CardData data, SocialPlatform platform) {
    final dimensions = _platformOptimizer.getDimensions(platform);

    return Container(
      width: dimensions.width,
      height: dimensions.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🌍 Environmental Impact',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VibeSweep',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            Text(
              '${data.userName} is making a difference!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // Impact metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImpactMetric(
                  '${data.impact.itemsCategorized}',
                  'Items\nCategorized',
                  '♻️',
                ),
                _buildImpactMetric(
                  '${data.impact.co2Saved.toStringAsFixed(1)}kg',
                  'CO₂\nSaved',
                  '🌿',
                ),
                _buildImpactMetric(
                  '${data.impact.treesEquivalent}',
                  'Trees\nEquivalent',
                  '🌳',
                ),
              ],
            ),

            const Spacer(),

            Text(
              data.callToAction,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(CardData data, SocialPlatform platform) {
    final dimensions = _platformOptimizer.getDimensions(platform);

    return Container(
      width: dimensions.width,
      height: dimensions.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📈 Progress Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VibeSweep',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            Text(
              '${data.userName} • ${data.userLevel}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // Progress stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressStat('${data.totalPoints}', 'Total Points', '💎'),
                _buildProgressStat('${data.currentStreak}', 'Day Streak', '🔥'),
              ],
            ),

            const Spacer(),

            Text(
              data.motivationalMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactMetric(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressStat(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
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
