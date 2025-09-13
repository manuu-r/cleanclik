import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cleanclik/core/models/achievement_card.dart';

enum SocialPlatform { instagram, twitter, facebook, stories, generic, system }

extension SocialPlatformExtension on SocialPlatform {
  String get displayName {
    switch (this) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.twitter:
        return 'Twitter';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.stories:
        return 'Stories';
      case SocialPlatform.system:
        return 'Share';
      case SocialPlatform.generic:
        return 'Other';
    }
  }
}

class SocialSharingService {
  static const String _logTag = 'SOCIAL_SHARING_SERVICE';

  /// Share an achievement card to a specific platform
  Future<bool> shareAchievementCard(
    AchievementCard card,
    SocialPlatform platform,
  ) async {
    print(
      '📱 [$_logTag] shareAchievementCard called for platform: ${platform.name}',
    );
    print(
      '📱 [$_logTag] Card details - ID: ${card.id}, shareText length: ${card.shareText.length}',
    );

    try {
      // Validate input parameters
      if (card.shareText.isEmpty) {
        print('⚠️ [$_logTag] Warning: Share text is empty for card ${card.id}');
        return false;
      }

      // Use share_plus to share the achievement card text
      await Share.share(
        card.shareText, 
        subject: 'My CleanClik Achievement',
      );

      // Share.share() doesn't return a result in older versions, assume success if no exception
      print('✅ [$_logTag] Share completed for ${platform.name}');
      return true;
    } catch (e) {
      print(
        '❌ [$_logTag] Failed to share achievement card to ${platform.name}: $e',
      );
      return false;
    }
  }

  /// Share a social media card with image
  Future<bool> shareSocialCard(
    File cardFile,
    String shareText,
    SocialPlatform platform,
  ) async {
    print(
      '📱 [$_logTag] shareSocialCard called for platform: ${platform.name}',
    );
    print(
      '📱 [$_logTag] Card file path: ${cardFile.path}, exists: ${cardFile.existsSync()}',
    );

    try {
      // Validate file exists
      if (!cardFile.existsSync()) {
        print('❌ [$_logTag] Card file does not exist: ${cardFile.path}');
        return false;
      }

      // Validate file size
      final fileSize = await cardFile.length();
      print('📱 [$_logTag] Card file size: ${fileSize} bytes');

      if (fileSize == 0) {
        print('❌ [$_logTag] Card file is empty: ${cardFile.path}');
        return false;
      }

      // Share file with text using share_plus
      await Share.shareXFiles(
        [XFile(cardFile.path)],
        text: shareText,
        subject: 'My CleanClik Achievement',
      );

      print('✅ [$_logTag] Social card shared successfully for ${platform.name}');
      return true;
    } catch (e) {
      print('❌ [$_logTag] Failed to share social card to ${platform.name}: $e');
      return false;
    }
  }

  /// Share text content
  Future<bool> shareText(String text) async {
    print('📱 [$_logTag] shareText called with text length: ${text.length}');

    try {
      if (text.isEmpty) {
        print('⚠️ [$_logTag] Cannot share empty text');
        return false;
      }

      await Share.share(text);
      
      print('✅ [$_logTag] Text shared successfully');
      return true;
    } catch (e) {
      print('❌ [$_logTag] Failed to share text: $e');
      return false;
    }
  }

  /// Check if a platform is available - simplified since share_plus handles platform detection
  Future<bool> isPlatformAvailable(SocialPlatform platform) async {
    // share_plus automatically handles available platforms
    // For now, we'll assume all platforms are available on Android
    switch (platform) {
      case SocialPlatform.system:
        return true; // System share is always available
      case SocialPlatform.instagram:
      case SocialPlatform.twitter:
      case SocialPlatform.facebook:
      case SocialPlatform.stories:
      case SocialPlatform.generic:
        return true; // Let the system handle availability
    }
  }

  /// Get available platforms - simplified since share_plus handles this automatically
  Future<List<SocialPlatform>> getAvailablePlatforms() async {
    // Return all platforms since share_plus will show only available apps in the share sheet
    return [
      SocialPlatform.system,
      SocialPlatform.instagram,
      SocialPlatform.twitter,
      SocialPlatform.facebook,
      SocialPlatform.stories,
      SocialPlatform.generic,
    ];
  }

  /// Get platform-specific color
  Color getPlatformColor(SocialPlatform platform) {
    print('🎨 [$_logTag] Getting color for platform: ${platform.name}');

    switch (platform) {
      case SocialPlatform.instagram:
        return const Color(0xFFE4405F);
      case SocialPlatform.twitter:
        return const Color(0xFF1DA1F2);
      case SocialPlatform.facebook:
        return const Color(0xFF4267B2);
      case SocialPlatform.stories:
        return const Color(0xFF833AB4);
      case SocialPlatform.system:
        return Colors.grey[600] ?? Colors.grey;
      case SocialPlatform.generic:
        return Colors.blueGrey;
    }
  }

  /// Get platform-specific icon
  IconData getPlatformIcon(SocialPlatform platform) {
    print('🔍 [$_logTag] Getting icon for platform: ${platform.name}');

    switch (platform) {
      case SocialPlatform.instagram:
        return Icons.camera_alt;
      case SocialPlatform.twitter:
        return Icons.alternate_email;
      case SocialPlatform.facebook:
        return Icons.facebook;
      case SocialPlatform.stories:
        return Icons.history;
      case SocialPlatform.system:
        return Icons.share;
      case SocialPlatform.generic:
        return Icons.share;
    }
  }

  /// Share achievement card with custom text
  Future<bool> shareAchievementWithCustomText(
    AchievementCard card,
    String customText,
    SocialPlatform platform,
  ) async {
    print(
      '📱 [$_logTag] shareAchievementWithCustomText called for platform: ${platform.name}',
    );

    try {
      if (customText.isEmpty) {
        print('⚠️ [$_logTag] Custom text is empty, using card default');
        return await shareAchievementCard(card, platform);
      }

      await Share.share(customText, subject: 'My CleanClik Achievement');

      print('✅ [$_logTag] Custom text shared successfully for ${platform.name}');
      return true;
    } catch (e) {
      print('❌ [$_logTag] Failed to share custom text to ${platform.name}: $e');
      return false;
    }
  }
}

/// Provider for SocialSharingService
final socialSharingServiceProvider = Provider<SocialSharingService>((ref) {
  return SocialSharingService();
});
