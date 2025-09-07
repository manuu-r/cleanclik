import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user.dart';
import 'local_storage_service.dart';

part 'user_service.g.dart';

/// Service for managing user authentication and profile data
class UserService {
  final LocalStorageService _storageService;
  
  // State management
  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  
  User? _currentUser;
  String? _authToken;
  
  // Storage keys for future use
  // static const String _userKey = 'current_user';
  // static const String _tokenKey = 'auth_token';

  UserService(this._storageService) {
    _loadUserFromStorage();
  }

  /// Stream of user changes
  Stream<User?> get userStream => _userController.stream;
  
  /// Stream of authentication state changes
  Stream<bool> get authStateStream => _authStateController.stream;
  
  /// Get current user
  User? get currentUser => _currentUser;
  
  /// Get current auth token
  String? get authToken => _authToken;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  /// Initialize with demo user (for development/testing)
  Future<void> initializeWithDemoUser() async {
    try {
      final demoUser = User.defaultUser();
      final demoToken = 'demo_token_${demoUser.id}';
      
      await _setCurrentUser(demoUser, demoToken);
      
      debugPrint('Initialized with demo user: ${demoUser.username}');
    } catch (e) {
      debugPrint('Failed to initialize demo user: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUser(User updatedUser) async {
    if (_currentUser?.id != updatedUser.id) {
      throw Exception('Cannot update user: ID mismatch');
    }

    try {
      await _setCurrentUser(updatedUser, _authToken);
      debugPrint('User profile updated: ${updatedUser.username}');
    } catch (e) {
      debugPrint('Failed to update user: $e');
      rethrow;
    }
  }

  /// Update user points and level
  Future<void> updateUserPoints(int pointsToAdd) async {
    if (_currentUser == null) return;

    final newTotalPoints = _currentUser!.totalPoints + pointsToAdd;
    final newLevel = User.calculateLevel(newTotalPoints);
    
    final updatedUser = _currentUser!.copyWith(
      totalPoints: newTotalPoints,
      level: newLevel,
      lastActiveAt: DateTime.now(),
    );

    await updateUser(updatedUser);
  }

  /// Update category statistics
  Future<void> updateCategoryStats(String categoryId, int itemsToAdd) async {
    if (_currentUser == null) return;

    final currentStats = Map<String, int>.from(_currentUser!.categoryStats);
    currentStats[categoryId] = (currentStats[categoryId] ?? 0) + itemsToAdd;

    final updatedUser = _currentUser!.copyWith(
      categoryStats: currentStats,
      lastActiveAt: DateTime.now(),
    );

    await updateUser(updatedUser);
  }

  /// Add achievement to user
  Future<void> addAchievement(String achievementId) async {
    if (_currentUser == null) return;
    
    if (_currentUser!.achievements.contains(achievementId)) {
      return; // Already has this achievement
    }

    final updatedAchievements = [..._currentUser!.achievements, achievementId];
    
    final updatedUser = _currentUser!.copyWith(
      achievements: updatedAchievements,
      lastActiveAt: DateTime.now(),
    );

    await updateUser(updatedUser);
    debugPrint('Achievement unlocked: $achievementId');
  }

  /// Update user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      isOnline: isOnline,
      lastActiveAt: DateTime.now(),
    );

    await updateUser(updatedUser);
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      // Clear user data
      _currentUser = null;
      _authToken = null;
      
      // Clear from storage
      await _storageService.clearSession();
      
      // Emit state changes
      _userController.add(null);
      _authStateController.add(false);
      
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Failed to sign out: $e');
      rethrow;
    }
  }

  /// Get user statistics summary
  Map<String, dynamic> getUserStats() {
    if (_currentUser == null) return {};

    return {
      'totalPoints': _currentUser!.totalPoints,
      'level': _currentUser!.level,
      'levelProgress': _currentUser!.levelProgress,
      'pointsToNextLevel': _currentUser!.pointsToNextLevel,
      'totalItemsCollected': _currentUser!.totalItemsCollected,
      'categoryStats': _currentUser!.categoryStats,
      'achievements': _currentUser!.achievements,
      'rank': _currentUser!.rank,
      'accountAge': DateTime.now().difference(_currentUser!.createdAt).inDays,
    };
  }

  /// Set current user and save to storage
  Future<void> _setCurrentUser(User user, String? token) async {
    _currentUser = user;
    _authToken = token;
    
    // Save to storage
    await _saveUserToStorage();
    
    // Emit state changes
    _userController.add(user);
    _authStateController.add(isAuthenticated);
  }

  /// Load user from local storage
  Future<void> _loadUserFromStorage() async {
    try {
      final sessionData = await _storageService.getSession();
      if (sessionData == null) {
        debugPrint('No user session found in storage');
        return;
      }

      final userData = sessionData['user'] as Map<String, dynamic>?;
      final token = sessionData['token'] as String?;

      if (userData != null && token != null) {
        _currentUser = User.fromJson(userData);
        _authToken = token;
        
        // Emit initial state
        _userController.add(_currentUser);
        _authStateController.add(isAuthenticated);
        
        debugPrint('User loaded from storage: ${_currentUser!.username}');
      }
    } catch (e) {
      debugPrint('Failed to load user from storage: $e');
    }
  }

  /// Save user to local storage
  Future<void> _saveUserToStorage() async {
    try {
      if (_currentUser != null && _authToken != null) {
        final sessionData = {
          'user': _currentUser!.toJson(),
          'token': _authToken,
          'lastSaved': DateTime.now().toIso8601String(),
        };
        
        await _storageService.saveSession(sessionData);
      }
    } catch (e) {
      debugPrint('Failed to save user to storage: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _userController.close();
    _authStateController.close();
  }
}

/// Provider for UserService
@riverpod
UserService userService(UserServiceRef ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  final service = UserService(storageService);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
}

/// Provider for current user
@riverpod
Stream<User?> currentUser(CurrentUserRef ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.userStream;
}

/// Provider for authentication state
@riverpod
Stream<bool> authState(AuthStateRef ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.authStateStream;
}

/// Provider for user statistics
@riverpod
Map<String, dynamic> userStats(UserStatsRef ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserStats();
}