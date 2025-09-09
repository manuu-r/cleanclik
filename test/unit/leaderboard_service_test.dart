import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cleanclik/core/services/leaderboard_service.dart';
import 'package:cleanclik/core/services/leaderboard_database_service.dart';
import 'package:cleanclik/core/services/user_service.dart';
import 'package:cleanclik/core/models/leaderboard_entry.dart';
import 'package:cleanclik/core/models/user.dart';
import 'package:cleanclik/core/models/database_exceptions.dart';

// Generate mocks
@GenerateMocks([
  LeaderboardDatabaseService,
  UserService,
  SharedPreferences,
])
import 'leaderboard_service_test.mocks.dart';

void main() {
  group('LeaderboardService', () {
    late LeaderboardService leaderboardService;
    late MockLeaderboardDatabaseService mockDbService;
    late MockUserService mockUserService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockDbService = MockLeaderboardDatabaseService();
      mockUserService = MockUserService();
      mockPrefs = MockSharedPreferences();

      leaderboardService = LeaderboardService(
        mockDbService,
        mockUserService,
        mockPrefs,
      );
    });

    tearDown(() {
      leaderboardService.dispose();
    });

    group('getLeaderboardPage', () {
      test('should return cached data when cache is valid', () async {
        // Arrange
        final mockUser = User.defaultUser();
        final mockEntries = [
          LeaderboardEntry(
            id: 'user1',
            username: 'TestUser1',
            totalPoints: 1000,
            level: 5,
            rank: 1,
            lastActiveAt: DateTime.now(),
          ),
          LeaderboardEntry(
            id: 'user2',
            username: 'TestUser2',
            totalPoints: 800,
            level: 4,
            rank: 2,
            lastActiveAt: DateTime.now(),
          ),
        ];
        final mockPage = LeaderboardPage(
          entries: mockEntries,
          currentPage: 1,
          totalPages: 1,
          totalEntries: 2,
          hasNextPage: false,
          hasPreviousPage: false,
          lastUpdated: DateTime.now(),
        );

        when(mockUserService.currentUser).thenReturn(mockUser);
        when(mockDbService.getLeaderboardPage(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          currentUserId: anyNamed('currentUserId'),
          filter: anyNamed('filter'),
          sort: anyNamed('sort'),
        )).thenAnswer((_) async => DatabaseResult.success(mockPage));

        // Act
        final result = await leaderboardService.getLeaderboardPage();

        // Assert
        expect(result.entries.length, equals(2));
        expect(result.entries.first.username, equals('TestUser1'));
        expect(result.entries.first.rank, equals(1));
      });

      test('should fetch from database when cache is invalid', () async {
        // Arrange
        final mockUser = User.defaultUser();
        final mockEntries = [
          LeaderboardEntry(
            id: 'user1',
            username: 'TestUser1',
            totalPoints: 1000,
            level: 5,
            rank: 1,
            lastActiveAt: DateTime.now(),
          ),
        ];
        final mockPage = LeaderboardPage(
          entries: mockEntries,
          currentPage: 1,
          totalPages: 1,
          totalEntries: 1,
          hasNextPage: false,
          hasPreviousPage: false,
          lastUpdated: DateTime.now(),
        );

        when(mockUserService.currentUser).thenReturn(mockUser);
        when(mockDbService.getLeaderboardPage(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          currentUserId: anyNamed('currentUserId'),
          filter: anyNamed('filter'),
          sort: anyNamed('sort'),
        )).thenAnswer((_) async => DatabaseResult.success(mockPage));

        // Act
        final result = await leaderboardService.getLeaderboardPage(forceRefresh: true);

        // Assert
        expect(result.entries.length, equals(1));
        verify(mockDbService.getLeaderboardPage(
          page: 1,
          pageSize: 20,
          currentUserId: mockUser.id,
          filter: LeaderboardFilter.all,
          sort: LeaderboardSort.points,
        )).called(1);
      });

      test('should return empty page on database error with no cache', () async {
        // Arrange
        final mockUser = User.defaultUser();
        when(mockUserService.currentUser).thenReturn(mockUser);
        when(mockDbService.getLeaderboardPage(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          currentUserId: anyNamed('currentUserId'),
          filter: anyNamed('filter'),
          sort: anyNamed('sort'),
        )).thenAnswer((_) async => DatabaseResult.failure(
          DatabaseException(
            DatabaseErrorType.connectionFailed,
            'Connection failed',
          ),
        ));

        // Act
        final result = await leaderboardService.getLeaderboardPage();

        // Assert
        expect(result.entries.isEmpty, isTrue);
        expect(result.currentPage, equals(1));
        expect(result.totalPages, equals(0));
      });
    });

    group('getUserRank', () {
      test('should return user rank from database', () async {
        // Arrange
        final mockUser = User.defaultUser();
        when(mockUserService.currentUser).thenReturn(mockUser);
        when(mockDbService.getUserRank(
          mockUser.id,
          filter: anyNamed('filter'),
        )).thenAnswer((_) async => DatabaseResult.success(5));

        // Act
        final result = await leaderboardService.getUserRank();

        // Assert
        expect(result, equals(5));
        verify(mockDbService.getUserRank(
          mockUser.id,
          filter: LeaderboardFilter.all,
        )).called(1);
      });

      test('should return null when user is not authenticated', () async {
        // Arrange
        when(mockUserService.currentUser).thenReturn(null);

        // Act
        final result = await leaderboardService.getUserRank();

        // Assert
        expect(result, isNull);
        verifyNever(mockDbService.getUserRank(any, filter: anyNamed('filter')));
      });

      test('should return cached rank when cache is valid', () async {
        // Arrange
        final mockUser = User.defaultUser();
        when(mockUserService.currentUser).thenReturn(mockUser);
        
        // First call to populate cache
        when(mockDbService.getUserRank(
          mockUser.id,
          filter: anyNamed('filter'),
        )).thenAnswer((_) async => DatabaseResult.success(3));
        
        await leaderboardService.getUserRank();
        
        // Act - Second call should use cache
        final result = await leaderboardService.getUserRank();

        // Assert
        expect(result, equals(3));
        // Should only be called once (for cache population)
        verify(mockDbService.getUserRank(
          mockUser.id,
          filter: LeaderboardFilter.all,
        )).called(1);
      });
    });

    group('getUserRankContext', () {
      test('should return user rank context', () async {
        // Arrange
        final mockUser = User.defaultUser();
        final mockEntries = [
          LeaderboardEntry(
            id: 'user1',
            username: 'TestUser1',
            totalPoints: 1200,
            level: 6,
            rank: 4,
            lastActiveAt: DateTime.now(),
          ),
          LeaderboardEntry(
            id: mockUser.id,
            username: mockUser.username,
            totalPoints: 1000,
            level: 5,
            rank: 5,
            lastActiveAt: DateTime.now(),
            isCurrentUser: true,
          ),
          LeaderboardEntry(
            id: 'user3',
            username: 'TestUser3',
            totalPoints: 800,
            level: 4,
            rank: 6,
            lastActiveAt: DateTime.now(),
          ),
        ];
        final mockPage = LeaderboardPage(
          entries: mockEntries,
          currentPage: 1,
          totalPages: 1,
          totalEntries: 3,
          hasNextPage: false,
          hasPreviousPage: false,
          lastUpdated: DateTime.now(),
        );

        when(mockUserService.currentUser).thenReturn(mockUser);
        when(mockDbService.getUserRankContext(
          userId: anyNamed('userId'),
          contextSize: anyNamed('contextSize'),
          filter: anyNamed('filter'),
        )).thenAnswer((_) async => DatabaseResult.success(mockPage));

        // Act
        final result = await leaderboardService.getUserRankContext();

        // Assert
        expect(result.entries.length, equals(3));
        expect(result.entries[1].isCurrentUser, isTrue);
        expect(result.entries[1].rank, equals(5));
        verify(mockDbService.getUserRankContext(
          userId: mockUser.id,
          contextSize: 5,
          filter: LeaderboardFilter.all,
        )).called(1);
      });

      test('should return empty page when user is not authenticated', () async {
        // Arrange
        when(mockUserService.currentUser).thenReturn(null);

        // Act
        final result = await leaderboardService.getUserRankContext();

        // Assert
        expect(result.entries.isEmpty, isTrue);
        verifyNever(mockDbService.getUserRankContext(
          userId: anyNamed('userId'),
          contextSize: anyNamed('contextSize'),
          filter: anyNamed('filter'),
        ));
      });
    });

    group('searchUsers', () {
      test('should return search results', () async {
        // Arrange
        final mockUser = User.defaultUser();
        final mockEntries = [
          LeaderboardEntry(
            id: 'user1',
            username: 'TestUser1',
            totalPoints: 1000,
            level: 5,
            rank: 1,
            lastActiveAt: DateTime.now(),
          ),
        ];

        when(mockUserService.currentUser).thenReturn(mockUser);
        when(mockDbService.searchUsers(
          query: anyNamed('query'),
          limit: anyNamed('limit'),
          currentUserId: anyNamed('currentUserId'),
        )).thenAnswer((_) async => DatabaseResult.success(mockEntries));

        // Act
        final result = await leaderboardService.searchUsers(query: 'Test');

        // Assert
        expect(result.length, equals(1));
        expect(result.first.username, equals('TestUser1'));
        verify(mockDbService.searchUsers(
          query: 'Test',
          limit: 20,
          currentUserId: mockUser.id,
        )).called(1);
      });

      test('should return empty list for empty query', () async {
        // Act
        final result = await leaderboardService.searchUsers(query: '');

        // Assert
        expect(result.isEmpty, isTrue);
        verifyNever(mockDbService.searchUsers(
          query: anyNamed('query'),
          limit: anyNamed('limit'),
          currentUserId: anyNamed('currentUserId'),
        ));
      });

      test('should return empty list on database error', () async {
        // Arrange
        final mockUser = User.defaultUser();
        when(mockUserService.currentUser).thenReturn(mockUser);
        when(mockDbService.searchUsers(
          query: anyNamed('query'),
          limit: anyNamed('limit'),
          currentUserId: anyNamed('currentUserId'),
        )).thenAnswer((_) async => DatabaseResult.failure(
          DatabaseException(
            DatabaseErrorType.queryFailed,
            'Search failed',
          ),
        ));

        // Act
        final result = await leaderboardService.searchUsers(query: 'Test');

        // Assert
        expect(result.isEmpty, isTrue);
      });
    });

    group('handleUserPointsUpdate', () {
      test('should update cached leaderboard optimistically', () async {
        // Arrange
        final mockUser = User.defaultUser();
        final mockEntries = [
          LeaderboardEntry(
            id: 'user1',
            username: 'TestUser1',
            totalPoints: 1000,
            level: 5,
            rank: 1,
            lastActiveAt: DateTime.now(),
          ),
          LeaderboardEntry(
            id: mockUser.id,
            username: mockUser.username,
            totalPoints: 800,
            level: 4,
            rank: 2,
            lastActiveAt: DateTime.now(),
          ),
        ];
        final mockPage = LeaderboardPage(
          entries: mockEntries,
          currentPage: 1,
          totalPages: 1,
          totalEntries: 2,
          hasNextPage: false,
          hasPreviousPage: false,
          lastUpdated: DateTime.now(),
        );

        when(mockUserService.currentUser).thenReturn(mockUser);
        when(mockDbService.getLeaderboardPage(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          currentUserId: anyNamed('currentUserId'),
          filter: anyNamed('filter'),
          sort: anyNamed('sort'),
        )).thenAnswer((_) async => DatabaseResult.success(mockPage));

        // First, populate the cache
        await leaderboardService.getLeaderboardPage();

        // Act - Update user points optimistically
        leaderboardService.handleUserPointsUpdate(mockUser.id, 1200, 6);

        // Assert - The cached leaderboard should be updated
        final cachedLeaderboard = leaderboardService.cachedLeaderboard;
        expect(cachedLeaderboard, isNotNull);
        
        // User should now be rank 1 with updated points
        final updatedUserEntry = cachedLeaderboard!.entries
            .firstWhere((entry) => entry.id == mockUser.id);
        expect(updatedUserEntry.totalPoints, equals(1200));
        expect(updatedUserEntry.level, equals(6));
        expect(updatedUserEntry.rank, equals(1));
      });
    });
  });
}