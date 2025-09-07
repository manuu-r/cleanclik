import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_data.dart';
import '../services/social_sharing_service.dart' show SocialPlatform;

class PlatformOptimizer {
  static final Map<SocialPlatform, CardDimensions> _platformDimensions = {
    SocialPlatform.instagram: const CardDimensions(
      width: 1080,
      height: 1080,
      aspectRatio: 1.0,
    ),
    SocialPlatform.twitter: const CardDimensions(
      width: 1200,
      height: 675,
      aspectRatio: 16 / 9,
    ),
    SocialPlatform.facebook: const CardDimensions(
      width: 1200,
      height: 630,
      aspectRatio: 1.91,
    ),
    SocialPlatform.stories: const CardDimensions(
      width: 1080,
      height: 1920,
      aspectRatio: 9 / 16,
    ),
    SocialPlatform.system: const CardDimensions(
      width: 1080,
      height: 1080,
      aspectRatio: 1.0,
    ),
    SocialPlatform.generic: const CardDimensions(
      width: 1080,
      height: 1080,
      aspectRatio: 1.0,
    ),
  };

  static final Map<SocialPlatform, int> _maxTextLength = {
    SocialPlatform.instagram: 2200,
    SocialPlatform.twitter: 280,
    SocialPlatform.facebook: 63206,
    SocialPlatform.stories: 2200,
    SocialPlatform.system: 2200,
    SocialPlatform.generic: 2200,
  };

  CardDimensions getDimensions(SocialPlatform platform) {
    return _platformDimensions[platform] ??
        _platformDimensions[SocialPlatform.instagram]!;
  }

  Map<String, String> getMetaTags(SocialPlatform platform, CardData data) {
    final baseTags = {
      'og:title': '${data.userName} - Level ${data.userLevel} on VibeSweep',
      'og:description': data.motivationalMessage,
      'og:type': 'website',
      'og:site_name': 'VibeSweep',
    };

    switch (platform) {
      case SocialPlatform.twitter:
        return {
          ...baseTags,
          'twitter:card': 'summary_large_image',
          'twitter:title': '${data.userName} is making an impact! 🌍',
          'twitter:description': _truncateText(data.motivationalMessage, 200),
        };
      case SocialPlatform.facebook:
        return {
          ...baseTags,
          'og:image:width': '1200',
          'og:image:height': '630',
        };
      case SocialPlatform.instagram:
        return {
          ...baseTags,
          'og:image:width': '1080',
          'og:image:height': '1080',
        };
      case SocialPlatform.stories:
        return {
          ...baseTags,
          'og:image:width': '1080',
          'og:image:height': '1920',
        };
      default:
        return baseTags;
    }
  }

  String optimizeText(String text, SocialPlatform platform) {
    final maxLength = _maxTextLength[platform] ?? 2200;
    return _truncateText(text, maxLength);
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;

    // Find the last space before the limit to avoid cutting words
    int cutoff = maxLength - 3; // Reserve space for "..."
    while (cutoff > 0 && text[cutoff] != ' ') {
      cutoff--;
    }

    if (cutoff == 0) cutoff = maxLength - 3;

    return '${text.substring(0, cutoff)}...';
  }

  String generateHashtags(CardData data, SocialPlatform platform) {
    final baseHashtags = [
      '#VibeSweep',
      '#CleanCity',
      '#Environmental',
      '#Sustainability',
      '#EcoFriendly',
    ];

    // Add achievement-specific hashtags
    if (data.currentStreak > 7) {
      baseHashtags.add('#StreakMaster');
    }

    if (data.impact.itemsCategorized > 100) {
      baseHashtags.add('#EcoWarrior');
    }

    if (data.totalPoints > 5000) {
      baseHashtags.add('#PointsChampion');
    }

    final hashtagString = baseHashtags.join(' ');
    return optimizeText(hashtagString, platform);
  }

  String generateShareText(CardData data, SocialPlatform platform) {
    String baseText;

    switch (platform) {
      case SocialPlatform.twitter:
        baseText =
            '🌍 Just hit Level ${data.userLevel} on @VibeSweep! '
            '${data.impact.itemsCategorized} items categorized, '
            '${data.impact.co2Saved.toStringAsFixed(1)}kg CO₂ saved! '
            '${data.motivationalMessage}';
        break;
      case SocialPlatform.instagram:
        baseText =
            '${data.motivationalMessage}\n\n'
            '📊 My VibeSweep Stats:\n'
            '• Level ${data.userLevel}\n'
            '• ${data.totalPoints} points\n'
            '• ${data.currentStreak} day streak\n'
            '• ${data.impact.itemsCategorized} items categorized\n'
            '• ${data.impact.co2Saved.toStringAsFixed(1)}kg CO₂ saved\n\n'
            '${data.callToAction}';
        break;
      case SocialPlatform.facebook:
        baseText =
            '${data.motivationalMessage}\n\n'
            'I\'ve been using VibeSweep to make a positive environmental impact! '
            'So far I\'ve categorized ${data.impact.itemsCategorized} items and '
            'saved ${data.impact.co2Saved.toStringAsFixed(1)}kg of CO₂. '
            'That\'s equivalent to planting ${data.impact.treesEquivalent} trees! 🌳\n\n'
            '${data.callToAction}';
        break;
      case SocialPlatform.stories:
        baseText =
            '${data.motivationalMessage}\n\n'
            'Level ${data.userLevel} • ${data.totalPoints} points\n'
            '${data.currentStreak} day streak 🔥\n\n'
            '${data.callToAction}';
        break;
      default:
        baseText = '${data.motivationalMessage}\n\n${data.callToAction}';
        break;
    }

    final optimizedText = optimizeText(baseText, platform);
    final hashtags = generateHashtags(data, platform);

    // Combine text and hashtags, ensuring we don't exceed limits
    final combined = '$optimizedText\n\n$hashtags';
    return optimizeText(combined, platform);
  }
}

/// Provider for PlatformOptimizer
final platformOptimizerProvider = Provider<PlatformOptimizer>((ref) {
  return PlatformOptimizer();
});
