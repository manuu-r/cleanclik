import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/models/database_exceptions.dart';
import '../../lib/core/services/user_database_service.dart';
import '../../lib/core/services/inventory_database_service.dart';
import '../../lib/core/services/achievement_database_service.dart';
import '../../lib/core/services/category_stats_database_service.dart';

void main() {
  group('Database Service Tests', () {
    test('DatabaseException should create proper user messages', () {
      final exception = DatabaseException(
        DatabaseErrorType.connectionFailed,
        'Connection failed',
        table: 'users',
        operation: 'findById',
      );

      expect(exception.userMessage, 'Unable to connect to the server. Please check your internet connection.');
      expect(exception.type, DatabaseErrorType.connectionFailed);
      expect(exception.table, 'users');
      expect(exception.operation, 'findById');
    });

    test('AuthException should create proper user messages', () {
      final exception = AuthException(
        AuthErrorType.invalidCredentials,
        'Invalid credentials',
      );

      expect(exception.userMessage, 'Invalid email or password. Please check your credentials and try again.');
      expect(exception.type, AuthErrorType.invalidCredentials);
    });

    test('DatabaseResult should handle success case', () {
      final result = DatabaseResult.success('test data');
      
      expect(result.isSuccess, true);
      expect(result.data, 'test data');
      expect(result.error, null);
      expect(result.dataOrThrow, 'test data');
    });

    test('DatabaseResult should handle failure case', () {
      final exception = DatabaseException(
        DatabaseErrorType.recordNotFound,
        'Record not found',
      );
      final result = DatabaseResult<String>.failure(exception);
      
      expect(result.isSuccess, false);
      expect(result.data, null);
      expect(result.error, exception);
      expect(() => result.dataOrThrow, throwsA(isA<DatabaseException>()));
    });

    test('DatabaseResult should transform data correctly', () {
      final result = DatabaseResult.success(5);
      final transformed = result.map((data) => data.toString());
      
      expect(transformed.isSuccess, true);
      expect(transformed.data, '5');
    });

    test('DatabaseResult should handle transformation errors', () {
      final result = DatabaseResult.success(5);
      final transformed = result.map<String>((data) => throw Exception('Transform error'));
      
      expect(transformed.isSuccess, false);
      expect(transformed.error, isA<DatabaseException>());
    });

    test('AuthResult should work similarly to DatabaseResult', () {
      final result = AuthResult.success('auth data');
      
      expect(result.isSuccess, true);
      expect(result.data, 'auth data');
      expect(result.error, null);
    });

    test('Database services should have correct table names', () {
      final userService = UserDatabaseService();
      final inventoryService = InventoryDatabaseService();
      final achievementService = AchievementDatabaseService();
      final categoryStatsService = CategoryStatsDatabaseService();

      expect(userService.tableName, 'users');
      expect(inventoryService.tableName, 'inventory');
      expect(achievementService.tableName, 'achievements');
      expect(categoryStatsService.tableName, 'category_stats');
    });
  });
}