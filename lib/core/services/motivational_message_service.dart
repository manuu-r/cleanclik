import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_data.dart';
import '../services/social_sharing_service.dart' show SocialPlatform;

class MotivationalMessageService {
  static final Random _random = Random();

  // Achievement-based messages
  static const List<String> _achievementMessages = [
    "Amazing work! Your dedication to the environment is inspiring! 🌟",
    "You're making a real difference, one item at a time! 🌍",
    "Your environmental impact is growing stronger every day! 💪",
    "Keep up the fantastic work - the planet thanks you! 🌱",
    "You're an eco-warrior in action! Keep pushing forward! ⚡",
    "Your commitment to sustainability is truly remarkable! 🏆",
    "Every action counts, and you're proving it! 🎯",
    "You're building a cleaner future with every scan! 🔮",
  ];

  // Streak-based messages
  static const List<String> _streakMessages = [
    "Your consistency is paying off! Keep the streak alive! 🔥",
    "Day after day, you're making it happen! 📈",
    "Your dedication streak is absolutely incredible! ⭐",
    "Consistency is key, and you've mastered it! 🗝️",
    "Your daily commitment is changing the world! 🌎",
    "Streak power activated! You're unstoppable! ⚡",
    "Your persistence is your superpower! 💫",
    "Building habits that build a better planet! 🏗️",
  ];

  // Impact-based messages
  static const List<String> _impactMessages = [
    "Your environmental footprint is getting greener every day! 👣",
    "The CO₂ you've saved is making a real difference! 🌿",
    "Your impact is equivalent to planting a forest! 🌳",
    "You're turning waste into environmental wins! ♻️",
    "Your categorization skills are saving the planet! 🎯",
    "Every item you sort brings us closer to a cleaner world! 🌍",
    "Your environmental impact is truly measurable! 📊",
    "You're proving that individual actions create collective change! 🤝",
  ];

  // Progress-based messages
  static const List<String> _progressMessages = [
    "Level up! Your environmental journey is accelerating! 🚀",
    "Your progress is proof that small actions lead to big changes! 📈",
    "Climbing the levels while climbing towards sustainability! 🧗",
    "Your point total reflects your positive impact! 💎",
    "Progress isn't just points - it's planetary protection! 🛡️",
    "You're advancing in the game and in environmental stewardship! 🎮",
    "Your growth mindset is growing a greener world! 🌱",
    "Leveling up your impact, one scan at a time! ⬆️",
  ];

  // Call-to-action messages
  static const List<String> _callToActions = [
    "Join the movement! Download VibeSweep and start your eco-journey! 📱",
    "Ready to make an impact? Get VibeSweep and scan your way to sustainability! 🔍",
    "Your friends can make a difference too! Share VibeSweep today! 🤝",
    "Be part of the solution! Download VibeSweep and start categorizing! ♻️",
    "Transform your daily routine into environmental action with VibeSweep! ⚡",
    "Every scan counts! Join thousands making a difference with VibeSweep! 🌍",
    "Turn waste sorting into a game! Get VibeSweep now! 🎮",
    "Make every day Earth Day with VibeSweep! Download now! 🌱",
  ];

  // Milestone-specific messages
  static const Map<String, List<String>> _milestoneMessages = {
    'first_scan': [
      "Welcome to your environmental journey! 🌟",
      "Your first scan is the beginning of something amazing! 🚀",
      "Every expert was once a beginner - great start! 👏",
    ],
    'streak_week': [
      "One week strong! Your consistency is incredible! 📅",
      "Seven days of environmental action - you're on fire! 🔥",
      "A week of impact - imagine what a month will bring! 📈",
    ],
    'streak_month': [
      "30 days of dedication! You're a true eco-champion! 🏆",
      "A full month of environmental action - outstanding! ⭐",
      "Your monthly streak proves that consistency creates change! 💪",
    ],
    'hundred_items': [
      "100 items categorized! You're making a serious impact! 💯",
      "Triple digits! Your environmental contribution is significant! 🎯",
      "100 items closer to a cleaner planet! Amazing work! 🌍",
    ],
    'level_milestone': [
      "New level unlocked! Your environmental expertise is growing! 🔓",
      "Level up! You're mastering the art of sustainability! 🎓",
      "Higher level, higher impact! Keep climbing! 🧗",
    ],
  };

  String generateMotivationalMessage(CardData data) {
    // Determine the most appropriate message type based on user data
    if (_isStreakMilestone(data.currentStreak)) {
      return _getStreakMilestoneMessage(data.currentStreak);
    }

    if (_isImpactMilestone(data.impact.itemsCategorized)) {
      return _getImpactMilestoneMessage(data.impact.itemsCategorized);
    }

    if (data.recentBadges.isNotEmpty) {
      return _getRandomMessage(_achievementMessages);
    }

    if (data.currentStreak > 0) {
      return _getRandomMessage(_streakMessages);
    }

    if (data.impact.itemsCategorized > 0) {
      return _getRandomMessage(_impactMessages);
    }

    return _getRandomMessage(_progressMessages);
  }

  String generateCallToAction(CardData data) {
    return _getRandomMessage(_callToActions);
  }

  String generateQRCodeText(CardData data) {
    // Generate app store link or deep link
    return 'https://vibesweep.app/join?ref=${data.userName.toLowerCase().replaceAll(' ', '_')}';
  }

  String generateShareText(CardData data, SocialPlatform platform) {
    final message = generateMotivationalMessage(data);
    final cta = generateCallToAction(data);

    switch (platform) {
      case SocialPlatform.twitter:
        return '$message $cta #VibeSweep #CleanCity #Environmental';
      case SocialPlatform.instagram:
        return '$message\n\n$cta\n\n#VibeSweep #CleanCity #Environmental #Sustainability #EcoFriendly';
      case SocialPlatform.facebook:
        return '$message\n\n$cta';
      case SocialPlatform.stories:
        return '$message\n\n$cta';
      case SocialPlatform.system:
      case SocialPlatform.generic:
        return '$message\n\n$cta';
    }
  }

  bool _isStreakMilestone(int streak) {
    return streak == 7 || streak == 30 || streak == 100 || streak % 50 == 0;
  }

  bool _isImpactMilestone(int items) {
    return items == 100 || items == 500 || items == 1000 || items % 1000 == 0;
  }

  String _getStreakMilestoneMessage(int streak) {
    if (streak == 7) {
      return _getRandomMessage(_milestoneMessages['streak_week']!);
    } else if (streak == 30) {
      return _getRandomMessage(_milestoneMessages['streak_month']!);
    } else {
      return _getRandomMessage(_streakMessages);
    }
  }

  String _getImpactMilestoneMessage(int items) {
    if (items == 100) {
      return _getRandomMessage(_milestoneMessages['hundred_items']!);
    } else {
      return _getRandomMessage(_impactMessages);
    }
  }

  String _getRandomMessage(List<String> messages) {
    return messages[_random.nextInt(messages.length)];
  }

  // Generate contextual messages based on recent activity
  String generateContextualMessage(CardData data) {
    if (data.recentActivity.isNotEmpty) {
      final recentActivity = data.recentActivity.first;

      switch (recentActivity.type.toLowerCase()) {
        case 'recycle':
          return "Great recycling! Every item you sort helps create a circular economy! ♻️";
        case 'organic':
          return "Composting champion! Your organic sorting helps reduce methane emissions! 🌱";
        case 'ewaste':
          return "E-waste expert! Proper electronics disposal prevents toxic contamination! 📱";
        case 'hazardous':
          return "Safety first! Your hazardous waste sorting protects our communities! ⚠️";
        default:
          return generateMotivationalMessage(data);
      }
    }

    return generateMotivationalMessage(data);
  }

  // Generate seasonal or time-based messages
  String generateTimedMessage(CardData data) {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour < 12) {
      return "Good morning, eco-warrior! Ready to make today count? 🌅";
    } else if (hour < 17) {
      return "Afternoon impact session! Your dedication never stops! ☀️";
    } else {
      return "Evening environmental action! Ending the day with purpose! 🌙";
    }
  }
}

/// Provider for MotivationalMessageService
final motivationalMessageServiceProvider = Provider<MotivationalMessageService>((ref) {
  return MotivationalMessageService();
});
