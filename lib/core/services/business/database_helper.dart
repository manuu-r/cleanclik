import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanclik/core/services/data/local_storage_service.dart';

class DatabaseHelper {
  static const String _logTag = 'DATABASE_HELPER';

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalStorageService _storageService = LocalStorageService.instance;

  static const String _localDataPrefix = 'local_data_';

  Future<Map<String, dynamic>?> create(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final query = _supabase.from(table).insert(data);

      final response = table == 'inventory'
          ? await query
                .select(
                  'id, user_id, tracking_id, display_name, code_name, category, confidence, picked_up_at, created_at',
                )
                .single()
          : await query.select().single();

      debugPrint('✅ [$_logTag] Created record in $table');
      return response;
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to create record in $table: $e');

      try {
        await _saveToLocalStorage(table, data);
        await _queuePendingOperation('create', table, data);
        debugPrint('💾 [$_logTag] Saved to local storage as fallback');
        return data;
      } catch (localError) {
        debugPrint('❌ [$_logTag] Local storage fallback failed: $localError');
        return null;
      }
    }
  }

  Future<List<Map<String, dynamic>>> read(
    String table, {
    String? userId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = _supabase.from(table).select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      final response = await query;
      debugPrint('✅ [$_logTag] Read ${response.length} records from $table');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to read from $table: $e');

      try {
        final localData = await _readFromLocalStorage(
          table,
          userId: userId,
          filters: filters,
        );
        debugPrint(
          '💾 [$_logTag] Returned ${localData.length} records from local storage',
        );
        return localData;
      } catch (localError) {
        debugPrint('❌ [$_logTag] Local storage fallback failed: $localError');
        return [];
      }
    }
  }

  Future<Map<String, dynamic>?> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final query = _supabase.from(table).update(data).eq('id', id);

      final response = table == 'inventory'
          ? await query
                .select(
                  'id, user_id, tracking_id, display_name, code_name, category, confidence, picked_up_at, created_at',
                )
                .single()
          : await query.select().single();

      debugPrint('✅ [$_logTag] Updated record in $table: $id');
      return response;
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to update record in $table: $e');

      try {
        final updatedData = {...data, 'id': id};
        await _updateLocalStorage(table, id, updatedData);
        await _queuePendingOperation('update', table, updatedData);
        debugPrint('💾 [$_logTag] Updated in local storage as fallback');
        return updatedData;
      } catch (localError) {
        debugPrint('❌ [$_logTag] Local storage fallback failed: $localError');
        return null;
      }
    }
  }

  Future<bool> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      var query = _supabase.from(table).delete();

      if (where != null && whereArgs != null) {
        if (where.contains('key = ?') && whereArgs.isNotEmpty) {
          query = query.eq('key', whereArgs[0]);
        }
      }

      await query;
      debugPrint('✅ [$_logTag] Deleted records from $table');
      return true;
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to delete from $table: $e');
      return false;
    }
  }

  Future<bool> deleteById(String table, String id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);

      debugPrint('✅ [$_logTag] Deleted record from $table: $id');
      return true;
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to delete record from $table: $e');

      try {
        await _deleteFromLocalStorage(table, id);
        await _queuePendingOperation('delete', table, {'id': id});
        debugPrint('💾 [$_logTag] Deleted from local storage as fallback');
        return true;
      } catch (localError) {
        debugPrint('❌ [$_logTag] Local storage fallback failed: $localError');
        return false;
      }
    }
  }

  String? get currentUserId {
    return _supabase.auth.currentUser?.id;
  }

  bool get isAuthenticated {
    return _supabase.auth.currentUser != null;
  }

  /// Get current user's email from Supabase auth
  String? get currentUserEmail {
    return _supabase.auth.currentUser?.email;
  }

  /// Get current user's username from metadata or email
  String get currentUserUsername {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'User';

    // Try to get username from metadata
    final username = user.userMetadata?['username'] as String?;
    if (username != null && username.isNotEmpty) {
      return username;
    }

    // Fallback to email prefix
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User';
  }

  /// Get current user's metadata
  Map<String, dynamic>? get currentUserMetadata {
    return _supabase.auth.currentUser?.userMetadata;
  }

  Future<bool> testConnection() async {
    try {
      await _supabase.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('❌ [$_logTag] Connection test failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> readAdvanced(
    String table, {
    String? userId,
    Map<String, dynamic>? filters,
    String? orderBy,
    int? limit,
    int? offset,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      dynamic query = _supabase.from(table).select();

      if (userId != null) {
        if (table == 'users') {
          query = query.eq('auth_id', userId);
        } else {
          query = query.eq('user_id', userId);
        }
      }

      if (where != null && whereArgs != null) {
        if (where.contains('auth_id = ?') && whereArgs.isNotEmpty) {
          query = query.eq('auth_id', whereArgs[0]);
        } else if (where.contains('user_id = ?') && whereArgs.isNotEmpty) {
          query = query.eq('user_id', whereArgs[0]);
        } else if (where.contains('id = ?') && whereArgs.isNotEmpty) {
          query = query.eq('id', whereArgs[0]);
        }
      }

      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      if (orderBy != null) {
        final orderClauses = orderBy
            .split(',')
            .map((clause) => clause.trim())
            .toList();

        for (final clause in orderClauses) {
          final parts = clause.split(' ');
          final column = parts[0].trim();
          final ascending =
              parts.length == 1 || parts[1].toUpperCase() != 'DESC';
          query = query.order(column, ascending: ascending);
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;
      debugPrint(
        '✅ [$_logTag] Read ${response.length} records from $table with advanced options',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint(
        '❌ [$_logTag] Failed to read from $table with advanced options: $e',
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> batchCreate(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    try {
      final query = _supabase.from(table).insert(dataList);

      final response = table == 'inventory'
          ? await query.select(
              'id, user_id, tracking_id, display_name, code_name, category, confidence, picked_up_at, created_at',
            )
          : await query.select();

      debugPrint(
        '✅ [$_logTag] Batch created ${response.length} records in $table',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to batch create records in $table: $e');

      try {
        for (final data in dataList) {
          await _saveToLocalStorage(table, data);
          await _queuePendingOperation('create', table, data);
        }
        debugPrint('💾 [$_logTag] Batch saved to local storage as fallback');
        return dataList;
      } catch (localError) {
        debugPrint('❌ [$_logTag] Local storage fallback failed: $localError');
        return [];
      }
    }
  }

  Future<void> syncPendingOperations() async {
    if (!isAuthenticated) {
      debugPrint('⚠️ [$_logTag] Cannot sync - user not authenticated');
      return;
    }

    try {
      final pendingOps = await _storageService.getPendingOperations();

      if (pendingOps.isEmpty) return;
      final List<Map<String, dynamic>> failedOps = [];

      for (final op in pendingOps) {
        final operation = op['operation'] as String;
        final table = op['table'] as String;
        var data = Map<String, dynamic>.from(
          op['data'] as Map<String, dynamic>,
        );

        if (table == 'inventory' && data.containsKey('label')) {
          data['display_name'] = data['label'];
          data.remove('label');
          debugPrint(
            '🔄 [$_logTag] Transformed legacy "label" field to "display_name"',
          );
        }

        try {
          switch (operation) {
            case 'create':
              await _supabase.from(table).insert(data);
              break;
            case 'update':
              final id = data['id'] as String;
              await _supabase.from(table).update(data).eq('id', id);
              break;
            case 'delete':
              final id = data['id'] as String;
              await _supabase.from(table).delete().eq('id', id);
              break;
          }
          debugPrint('✅ [$_logTag] Synced pending $operation on $table');
        } catch (e) {
          debugPrint('❌ [$_logTag] Failed to sync $operation on $table: $e');
          failedOps.add(op);
        }
      }

      if (failedOps.isEmpty) {
        await _storageService.clearPendingOperations();
        debugPrint('✅ [$_logTag] All pending operations synced successfully');
      } else {
        await _storageService.setPendingOperations(failedOps);
        debugPrint(
          '⚠️ [$_logTag] ${failedOps.length} operations still pending',
        );
      }
    } catch (e) {
      debugPrint('❌ [$_logTag] Failed to sync pending operations: $e');
    }
  }

  Future<Map<String, dynamic>?> resolveConflict(
    String table,
    String id,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    try {
      final localTimestamp = localData['updated_at'] ?? localData['created_at'];
      final remoteTimestamp =
          remoteData['updated_at'] ?? remoteData['created_at'];

      if (localTimestamp != null && remoteTimestamp != null) {
        final localTime = DateTime.parse(localTimestamp as String);
        final remoteTime = DateTime.parse(remoteTimestamp as String);

        if (localTime.isAfter(remoteTime)) {
          debugPrint('🔄 [$_logTag] Local data newer, updating remote for $id');
          return await update(table, id, localData);
        } else {
          debugPrint('🔄 [$_logTag] Remote data newer, using remote for $id');
          return remoteData;
        }
      }

      debugPrint(
        '🔄 [$_logTag] No timestamps available, using remote data for $id',
      );
      return remoteData;
    } catch (e) {
      debugPrint('❌ [$_logTag] Conflict resolution failed: $e');
      return remoteData;
    }
  }

  Future<void> _saveToLocalStorage(
    String table,
    Map<String, dynamic> data,
  ) async {
    final key = '$_localDataPrefix${table}_${data['id']}';
    final dataWithTimestamp = {
      ...data,
      'local_updated_at': DateTime.now().toIso8601String(),
    };
    await _storageService.setJsonData(key, dataWithTimestamp);
  }

  Future<List<Map<String, dynamic>>> _readFromLocalStorage(
    String table, {
    String? userId,
    Map<String, dynamic>? filters,
  }) async {
    final allKeys = await _storageService.getAllKeys();
    final keys = allKeys
        .where((key) => key.startsWith('$_localDataPrefix$table'))
        .toList();

    final results = <Map<String, dynamic>>[];

    for (final key in keys) {
      final data = await _storageService.getJsonData(key);
      if (data != null) {
        bool matches = true;

        if (userId != null && data['user_id'] != userId) {
          matches = false;
        }

        if (filters != null) {
          for (final entry in filters.entries) {
            if (data[entry.key] != entry.value) {
              matches = false;
              break;
            }
          }
        }

        if (matches) {
          results.add(data);
        }
      }
    }

    return results;
  }

  Future<void> _updateLocalStorage(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final key = '$_localDataPrefix${table}_$id';
    final dataWithTimestamp = {
      ...data,
      'local_updated_at': DateTime.now().toIso8601String(),
    };
    await _storageService.setJsonData(key, dataWithTimestamp);
  }

  Future<void> _deleteFromLocalStorage(String table, String id) async {
    final key = '$_localDataPrefix${table}_$id';
    await _storageService.remove(key);
  }

  Future<void> _queuePendingOperation(
    String operation,
    String table,
    Map<String, dynamic> data,
  ) async {
    await _storageService.addPendingOperation({
      'operation': operation,
      'table': table,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
