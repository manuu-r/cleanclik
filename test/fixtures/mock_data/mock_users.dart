import '../../helpers/test_utils.dart';
import '../test_data_factory.dart';
import '../../test_config.dart';

/// Mock user data for testing
class MockUsers {
  /// Create a list of mock users for testing
  static List<Map<String, dynamic>> createMockUsers({int count = 10}) {
    return List.generate(count, (index) {
      final user = TestDataFactory.createMockUser(
        id: 'user-$index',
        email: 'user$index@example.com',
        username: 'user$index',
        fullName: 'Test User $index',
        avatarUrl: index % 3 == 0 ? 'https://example.com/avatar$index.jpg' : null,
      );
      return user.toJson();
    });
  }

  /// Create a mock authenticated user
  static Map<String, dynamic> createAuthenticatedUser() {
    final user = TestDataFactory.createMockUser(
      id: 'authenticated-user-id',
      email: 'authenticated@example.com',
      username: 'authenticateduser',
      fullName: 'Authenticated User',
    );
    return user.toJson();
  }

  /// Create a mock demo user
  static Map<String, dynamic> createDemoUser() {
    final user = TestDataFactory.createMockUser(
      id: 'demo-user-id',
      email: 'demo@example.com',
      username: 'demouser',
      fullName: 'Demo User',
      metadata: {'isDemoMode': true},
    );
    return user.toJson();
  }

  /// Create mock user profiles with different activity levels
  static List<Map<String, dynamic>> createUserProfiles() {
    return [
      // High activity user
      {
        ...TestDataFactory.createMockUser(
          id: 'high-activity-user',
          username: 'ecowarrior',
          fullName: 'Eco Warrior',
        ).toJson(),
        'totalPoints': 5000,
        'itemsCollected': 500,
        'rank': 1,
        'achievements': ['first_recycler', 'eco_warrior', 'organic_expert'],
        'lastActivity': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      
      // Medium activity user
      {
        ...TestDataFactory.createMockUser(
          id: 'medium-activity-user',
          username: 'greenliving',
          fullName: 'Green Living',
        ).toJson(),
        'totalPoints': 1500,
        'itemsCollected': 150,
        'rank': 5,
        'achievements': ['first_recycler'],
        'lastActivity': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      
      // Low activity user
      {
        ...TestDataFactory.createMockUser(
          id: 'low-activity-user',
          username: 'newbie',
          fullName: 'New User',
        ).toJson(),
        'totalPoints': 50,
        'itemsCollected': 5,
        'rank': 50,
        'achievements': [],
        'lastActivity': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      },
    ];
  }

  /// Create mock user with Google Sign-In data
  static Map<String, dynamic> createGoogleSignInUser() {
    return {
      'id': 'google-user-id',
      'email': 'google.user@gmail.com',
      'username': 'googleuser',
      'fullName': 'Google User',
      'avatarUrl': 'https://lh3.googleusercontent.com/test-avatar',
      'provider': 'google',
      'providerData': {
        'googleId': 'google-oauth-id-123',
        'verifiedEmail': true,
      },
      'createdAt': DateTime.now().toIso8601String(),
      'metadata': {
        'signInMethod': 'google',
        'emailVerified': true,
      },
    };
  }

  /// Create mock user preferences
  static Map<String, dynamic> createUserPreferences({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'preferences': {
        'notifications': {
          'achievements': true,
          'leaderboard': true,
          'reminders': false,
        },
        'privacy': {
          'shareLocation': true,
          'shareStats': true,
          'publicProfile': false,
        },
        'app': {
          'theme': 'system',
          'language': 'en',
          'units': 'metric',
        },
        'camera': {
          'autoFocus': true,
          'flashMode': 'auto',
          'soundEnabled': true,
        },
      },
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock user statistics
  static Map<String, dynamic> createUserStatistics({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'statistics': {
        'totalPoints': 1250,
        'itemsCollected': 125,
        'categoriesUsed': 4,
        'streakDays': 7,
        'longestStreak': 15,
        'averageItemsPerDay': 3.5,
        'favoriteCategory': 'recycle',
        'totalDistance': 15.2, // km
        'co2Saved': 45.6, // kg
      },
      'categoryBreakdown': {
        'recycle': {'items': 50, 'points': 500},
        'organic': {'items': 40, 'points': 320},
        'landfill': {'items': 25, 'points': 125},
        'ewaste': {'items': 8, 'points': 120},
        'hazardous': {'items': 2, 'points': 40},
      },
      'monthlyStats': List.generate(12, (month) => {
        'month': month + 1,
        'items': 10 + (month * 2),
        'points': 100 + (month * 20),
      }),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock user session data
  static Map<String, dynamic> createUserSession({
    String? userId,
    bool isActive = true,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'sessionId': TestUtils.generateRandomString(32),
      'isActive': isActive,
      'startedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
      'deviceInfo': {
        'platform': 'iOS',
        'version': '17.0',
        'model': 'iPhone 14',
        'appVersion': '1.0.0',
      },
      'location': {
        'latitude': TestConfig.testLatitude,
        'longitude': TestConfig.testLongitude,
        'accuracy': TestConfig.locationAccuracy,
      },
    };
  }

  /// Create mock user onboarding data
  static Map<String, dynamic> createUserOnboarding({
    String? userId,
    bool completed = false,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'onboardingCompleted': completed,
      'steps': {
        'welcome': completed,
        'permissions': completed,
        'tutorial': completed,
        'firstScan': completed,
        'profile': completed,
      },
      'startedAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      'completedAt': completed ? DateTime.now().toIso8601String() : null,
      'currentStep': completed ? 'completed' : 'welcome',
    };
  }

  /// Create mock user notification settings
  static Map<String, dynamic> createNotificationSettings({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'pushNotifications': {
        'enabled': true,
        'achievements': true,
        'leaderboard': true,
        'reminders': false,
        'social': true,
        'system': true,
      },
      'emailNotifications': {
        'enabled': false,
        'weekly_summary': false,
        'achievements': false,
        'marketing': false,
      },
      'inAppNotifications': {
        'enabled': true,
        'sound': true,
        'vibration': true,
        'badge': true,
      },
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock user privacy settings
  static Map<String, dynamic> createPrivacySettings({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'profileVisibility': 'public', // public, friends, private
      'shareLocation': true,
      'shareStatistics': true,
      'shareAchievements': true,
      'allowFriendRequests': true,
      'showOnLeaderboard': true,
      'dataCollection': {
        'analytics': true,
        'performance': true,
        'crashReports': true,
        'usage': false,
      },
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock user device information
  static Map<String, dynamic> createDeviceInfo({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'devices': [
        {
          'deviceId': 'device-1',
          'platform': 'iOS',
          'model': 'iPhone 14 Pro',
          'osVersion': '17.0',
          'appVersion': '1.0.0',
          'isActive': true,
          'lastSeen': DateTime.now().toIso8601String(),
          'capabilities': {
            'camera': true,
            'gps': true,
            'arkit': true,
            'mlkit': true,
          },
        },
        {
          'deviceId': 'device-2',
          'platform': 'Android',
          'model': 'Pixel 7',
          'osVersion': '14',
          'appVersion': '1.0.0',
          'isActive': false,
          'lastSeen': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          'capabilities': {
            'camera': true,
            'gps': true,
            'arcore': true,
            'mlkit': true,
          },
        },
      ],
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock user social connections
  static Map<String, dynamic> createSocialConnections({
    String? userId,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'friends': List.generate(10, (index) => {
        'friendId': 'friend-$index',
        'username': 'friend$index',
        'avatarUrl': index % 3 == 0 ? 'https://example.com/avatar$index.jpg' : null,
        'status': 'accepted',
        'connectedAt': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
        'mutualFriends': index > 0 ? index - 1 : 0,
      }),
      'pendingRequests': {
        'sent': List.generate(3, (index) => {
          'userId': 'pending-sent-$index',
          'username': 'pendingsent$index',
          'sentAt': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
        }),
        'received': List.generate(2, (index) => {
          'userId': 'pending-received-$index',
          'username': 'pendingreceived$index',
          'receivedAt': DateTime.now().subtract(Duration(hours: index + 1)).toIso8601String(),
        }),
      },
      'blocked': <Map<String, dynamic>>[],
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create mock user activity history
  static Map<String, dynamic> createActivityHistory({
    String? userId,
    int days = 30,
  }) {
    return {
      'userId': userId ?? 'test-user-id',
      'period': '${days}_days',
      'activities': List.generate(days, (day) => {
        'date': DateTime.now().subtract(Duration(days: day)).toIso8601String().split('T')[0],
        'itemsCollected': day < 7 ? (3 + (day % 4)) : (day % 5), // More active in recent days
        'pointsEarned': day < 7 ? (30 + (day % 4) * 10) : (day % 5) * 10,
        'categoriesUsed': day < 7 ? [
          'recycle',
          if (day % 2 == 0) 'organic',
          if (day % 3 == 0) 'landfill',
        ] : [
          if (day % 3 == 0) 'recycle',
        ],
        'sessionsCount': day < 7 ? (2 + (day % 3)) : (day % 2),
        'totalSessionTime': day < 7 ? (15 + (day % 10)) : (5 + (day % 5)), // minutes
      }),
      'summary': {
        'totalItems': days * 2, // Approximate
        'totalPoints': days * 20, // Approximate
        'averageItemsPerDay': 2.0,
        'mostActiveDay': 'Tuesday',
        'favoriteCategory': 'recycle',
        'longestStreak': 15,
        'currentStreak': 7,
      },
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}