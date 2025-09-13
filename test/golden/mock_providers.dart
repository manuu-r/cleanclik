import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock provider definitions for golden tests
// These should match the actual providers in the app

// Auth providers
final authStateProvider = StateProvider<AsyncValue<Map<String, dynamic>>>((ref) {
  return const AsyncValue.loading();
});

final userProfileProvider = StateProvider<AsyncValue<Map<String, dynamic>>>((ref) {
  return const AsyncValue.loading();
});

final emailResendStateProvider = StateProvider<AsyncValue<bool>>((ref) {
  return const AsyncValue.data(false);
});

// Camera providers
final cameraStateProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {'mode': 'ml_detection', 'status': 'active'};
});

final detectedObjectsProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

// Navigation providers
final currentNavigationIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final notificationBadgeProvider = StateProvider<int>((ref) {
  return 0;
});

// Location providers
final binLocationsProvider = StateProvider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return const AsyncValue.loading();
});

final userLocationProvider = StateProvider<AsyncValue<Map<String, dynamic>>>((ref) {
  return const AsyncValue.loading();
});

// Inventory providers
final userInventoryProvider = StateProvider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return const AsyncValue.loading();
});

// User stats providers
final userStatsProvider = StateProvider<AsyncValue<Map<String, dynamic>>>((ref) {
  return const AsyncValue.loading();
});

final userAchievementsProvider = StateProvider<AsyncValue<List<String>>>((ref) {
  return const AsyncValue.loading();
});

// Leaderboard providers
final leaderboardProvider = StateProvider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return const AsyncValue.loading();
});

final userRankProvider = StateProvider<AsyncValue<int>>((ref) {
  return const AsyncValue.loading();
});

final weeklyLeaderboardProvider = StateProvider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return const AsyncValue.loading();
});

final weeklyRankProvider = StateProvider<AsyncValue<int>>((ref) {
  return const AsyncValue.loading();
});

final leaderboardPeriodProvider = StateProvider<String>((ref) {
  return 'all_time';
});

final socialSharingStateProvider = StateProvider<bool>((ref) {
  return false;
});

// Enum definitions for golden tests
enum WasteCategory {
  recycle,
  organic,
  landfill,
  ewaste,
  hazardous,
}

enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  allTime,
}

enum CameraMode {
  mlDetection,
  qrScanning,
}

enum CameraStatus {
  inactive,
  active,
  switching,
  error,
}