import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cleanclik/core/models/database_exceptions.dart';
import 'package:cleanclik/core/services/auth/supabase_config_service.dart';

/// Abstract base class for database services with error handling and retry logic
/// Following patterns from supabase-development-patterns
abstract class DatabaseService<T> {
  /// Supabase client instance
  SupabaseClient get client => SupabaseConfigService.client;

  /// Table name for this service
  String get tableName;

  /// Maximum retry attempts for failed operations
  static const int maxRetryAttempts = 3;

  /// Base delay between retry attempts (in milliseconds)
  static const int baseRetryDelay = 1000;

  /// Maximum delay between retry attempts (in milliseconds)
  static const int maxRetryDelay = 10000;

  // ===== ABSTRACT METHODS =====

  /// Convert database row to model instance
  T fromDatabaseRow(Map<String, dynamic> data);

  /// Convert model instance to database row
  Map<String, dynamic> toDatabaseRow(T entity, String userId);

  // ===== CRUD OPERATIONS =====

  /// Find entity by ID
  Future<DatabaseResult<T?>> findById(String id) async {
    return await executeWithRetry(
      operation: 'findById',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('id', id)
            .maybeSingle();

        if (response == null) {
          return DatabaseResult.success(null);
        }

        final entity = fromDatabaseRow(response);
        return DatabaseResult.success(entity);
      },
    );
  }

  /// Find entities by user ID
  Future<DatabaseResult<List<T>>> findByUserId(String userId) async {
    return await executeWithRetry(
      operation: 'findByUserId',
      action: () async {
        final response = await client
            .from(tableName)
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final entities = response
            .map<T>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(entities);
      },
    );
  }

  /// Find all entities (with optional limit)
  Future<DatabaseResult<List<T>>> findAll({int? limit}) async {
    return await executeWithRetry(
      operation: 'findAll',
      action: () async {
        var query = client
            .from(tableName)
            .select()
            .order('created_at', ascending: false);

        if (limit != null) {
          query = query.limit(limit);
        }

        final response = await query;
        final entities = response
            .map<T>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(entities);
      },
    );
  }

  /// Create new entity
  Future<DatabaseResult<T>> create(T entity, String userId) async {
    return await executeWithRetry(
      operation: 'create',
      action: () async {
        final data = toDatabaseRow(entity, userId);
        final response = await client
            .from(tableName)
            .insert(data)
            .select()
            .single();

        final createdEntity = fromDatabaseRow(response);
        return DatabaseResult.success(createdEntity);
      },
    );
  }

  /// Update existing entity
  Future<DatabaseResult<T>> update(String id, T entity, String userId) async {
    return await executeWithRetry(
      operation: 'update',
      action: () async {
        final data = toDatabaseRow(entity, userId);
        final response = await client
            .from(tableName)
            .update(data)
            .eq('id', id)
            .select()
            .single();

        final updatedEntity = fromDatabaseRow(response);
        return DatabaseResult.success(updatedEntity);
      },
    );
  }

  /// Delete entity by ID
  Future<DatabaseResult<void>> delete(String id) async {
    return await executeWithRetry(
      operation: 'delete',
      action: () async {
        await client.from(tableName).delete().eq('id', id);

        return const DatabaseResult.success(null);
      },
    );
  }

  /// Delete entities by user ID
  Future<DatabaseResult<void>> deleteByUserId(String userId) async {
    return await executeWithRetry(
      operation: 'deleteByUserId',
      action: () async {
        await client.from(tableName).delete().eq('user_id', userId);

        return const DatabaseResult.success(null);
      },
    );
  }

  // ===== BATCH OPERATIONS =====

  /// Create multiple entities in a single transaction
  Future<DatabaseResult<List<T>>> createBatch(
    List<T> entities,
    String userId,
  ) async {
    return await executeWithRetry(
      operation: 'createBatch',
      action: () async {
        final dataList = entities
            .map((entity) => toDatabaseRow(entity, userId))
            .toList();

        final response = await client.from(tableName).insert(dataList).select();

        final createdEntities = response
            .map<T>((row) => fromDatabaseRow(row))
            .toList();

        return DatabaseResult.success(createdEntities);
      },
    );
  }

  /// Update multiple entities in a single transaction
  Future<DatabaseResult<List<T>>> updateBatch(
    Map<String, T> entitiesById,
    String userId,
  ) async {
    return await executeWithRetry(
      operation: 'updateBatch',
      action: () async {
        final updatedEntities = <T>[];

        // Note: Supabase doesn't support batch updates with different data
        // So we'll do individual updates within a transaction-like approach
        for (final entry in entitiesById.entries) {
          final id = entry.key;
          final entity = entry.value;
          final data = toDatabaseRow(entity, userId);

          final response = await client
              .from(tableName)
              .update(data)
              .eq('id', id)
              .select()
              .single();

          updatedEntities.add(fromDatabaseRow(response));
        }

        return DatabaseResult.success(updatedEntities);
      },
    );
  }

  /// Delete multiple entities by IDs
  Future<DatabaseResult<void>> deleteBatch(List<String> ids) async {
    return await executeWithRetry(
      operation: 'deleteBatch',
      action: () async {
        await client.from(tableName).delete().inFilter('id', ids);

        return const DatabaseResult.success(null);
      },
    );
  }

  // ===== QUERY HELPERS =====

  /// Count entities by user ID
  Future<DatabaseResult<int>> countByUserId(String userId) async {
    return await executeWithRetry(
      operation: 'countByUserId',
      action: () async {
        final response = await client
            .from(tableName)
            .select('id')
            .eq('user_id', userId);

        final count = response.length;
        return DatabaseResult.success(count);
      },
    );
  }

  /// Check if entity exists by ID
  Future<DatabaseResult<bool>> existsById(String id) async {
    return await executeWithRetry(
      operation: 'existsById',
      action: () async {
        final response = await client
            .from(tableName)
            .select('id')
            .eq('id', id)
            .limit(1);

        final exists = response.isNotEmpty;
        return DatabaseResult.success(exists);
      },
    );
  }

  // ===== REAL-TIME SUBSCRIPTIONS =====

  /// Subscribe to real-time changes for user's data
  Stream<List<T>> subscribeToUserData(String userId) {
    return client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map<T>((row) => fromDatabaseRow(row)).toList());
  }

  /// Subscribe to real-time changes for specific entity
  Stream<T?> subscribeToEntity(String id) {
    return client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isNotEmpty ? fromDatabaseRow(data.first) : null);
  }

  // ===== ERROR HANDLING AND RETRY LOGIC =====

  /// Execute database operation with retry logic and error handling
  @protected
  Future<DatabaseResult<U>> executeWithRetry<U>({
    required String operation,
    required Future<DatabaseResult<U>> Function() action,
  }) async {
    int attempt = 0;
    Duration delay = const Duration(milliseconds: baseRetryDelay);

    while (attempt < maxRetryAttempts) {
      try {
        return await action();
      } catch (e) {
        attempt++;

        final dbException = _createDatabaseException(e, operation);

        // Don't retry certain types of errors
        if (!_shouldRetry(dbException) || attempt >= maxRetryAttempts) {
          if (kDebugMode) {
            print(
              'DatabaseService[$tableName]: $operation failed after $attempt attempts: $e',
            );
          }
          return DatabaseResult.failure(dbException);
        }

        // Wait before retrying with exponential backoff
        if (kDebugMode) {
          print(
            'DatabaseService[$tableName]: $operation failed (attempt $attempt), retrying in ${delay.inMilliseconds}ms...',
          );
        }

        await Future.delayed(delay);
        delay = Duration(
          milliseconds: min(delay.inMilliseconds * 2, maxRetryDelay),
        );
      }
    }

    // This should never be reached, but just in case
    return DatabaseResult.failure(
      DatabaseException(
        DatabaseErrorType.unknown,
        'Operation failed after $maxRetryAttempts attempts',
        table: tableName,
        operation: operation,
      ),
    );
  }

  /// Create appropriate DatabaseException from error
  DatabaseException _createDatabaseException(dynamic error, String operation) {
    if (error is PostgrestException) {
      return DatabaseException.fromSupabase(
        error,
        table: tableName,
        operation: operation,
      );
    } else if (error is SocketException || error is TimeoutException) {
      return DatabaseException(
        DatabaseErrorType.connectionFailed,
        'Network connection failed: ${error.toString()}',
        table: tableName,
        operation: operation,
        originalError: error,
      );
    } else {
      return DatabaseException(
        DatabaseErrorType.unknown,
        'Unexpected error: ${error.toString()}',
        table: tableName,
        operation: operation,
        originalError: error,
      );
    }
  }

  /// Determine if an error should trigger a retry
  bool _shouldRetry(DatabaseException exception) {
    switch (exception.type) {
      case DatabaseErrorType.connectionFailed:
      case DatabaseErrorType.networkTimeout:
      case DatabaseErrorType.rateLimitExceeded:
        return true;
      case DatabaseErrorType.permissionDenied:
      case DatabaseErrorType.recordNotFound:
      case DatabaseErrorType.duplicateKey:
      case DatabaseErrorType.foreignKeyViolation:
      case DatabaseErrorType.checkConstraintViolation:
      case DatabaseErrorType.notNullViolation:
        return false;
      case DatabaseErrorType.queryFailed:
      case DatabaseErrorType.constraintViolation:
      case DatabaseErrorType.unknown:
        return true; // Retry unknown errors in case they're transient
    }
  }

  // ===== CONNECTION MANAGEMENT =====

  /// Test database connection
  Future<bool> testConnection() async {
    try {
      await client.from(tableName).select('count').limit(1);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DatabaseService[$tableName]: Connection test failed: $e');
      }
      return false;
    }
  }

  /// Get connection health status
  Future<DatabaseResult<Map<String, dynamic>>> getHealthStatus() async {
    final stopwatch = Stopwatch()..start();

    try {
      await client.from(tableName).select('count').limit(1);

      stopwatch.stop();

      return DatabaseResult.success({
        'table': tableName,
        'healthy': true,
        'responseTimeMs': stopwatch.elapsedMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      stopwatch.stop();

      return DatabaseResult.success({
        'table': tableName,
        'healthy': false,
        'responseTimeMs': stopwatch.elapsedMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      });
    }
  }
}
