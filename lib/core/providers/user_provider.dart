import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cleanclik/core/services/business/user_service.dart';
import 'package:cleanclik/core/services/auth/auth_service.dart';
import 'package:cleanclik/core/models/user_models.dart';

part 'user_provider.g.dart';

@riverpod
UserProfile? currentUserProfile(CurrentUserProfileRef ref) {
  final service = ref.watch(userServiceProvider);
  return service.currentProfile;
}

@riverpod
Stream<UserProfile> userProfileStream(UserProfileStreamRef ref) {
  final service = ref.watch(userServiceProvider);
  return service.profileStream;
}

@riverpod
Future<DashboardStats> dashboardStats(DashboardStatsRef ref) async {
  final service = ref.watch(userServiceProvider);

  try {
    final stats = await service.getDashboardStats().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        return DashboardStats.empty();
      },
    );
    return stats;
  } catch (_) {
    return DashboardStats.empty();
  }
}

@riverpod
Future<DashboardStats> refreshDashboardStats(
  RefreshDashboardStatsRef ref,
) async {
  final service = ref.watch(userServiceProvider);
  return service.refreshDashboardStats();
}

@riverpod
Future<User?> syncedCurrentUser(SyncedCurrentUserRef ref) async {
  final authState = await ref.watch(authStateProvider.future);

  if (!authState.isAuthenticated || authState.user == null) {
    return null;
  }

  final baseUser = authState.user!;

  try {
    final dashboardStats = await ref.watch(dashboardStatsProvider.future);
    return baseUser.copyWith(
      totalPoints: dashboardStats.totalPoints,
      level: User.calculateLevel(dashboardStats.totalPoints),
    );
  } catch (_) {
    return baseUser;
  }
}
