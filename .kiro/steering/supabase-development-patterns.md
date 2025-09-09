---
inclusion: fileMatch
fileMatchPattern: '*supabase*'
---

# Supabase Development Patterns

## Service Architecture Patterns

### Database Service Pattern
```dart
abstract class DatabaseService<T> {
  Future<T?> findById(String id);
  Future<List<T>> findByUserId(String userId);
  Future<T> create(T entity);
  Future<T> update(String id, T entity);
  Future<void> delete(String id);
}
```

### Error Handling Pattern
```dart
try {
  final result = await _supabase.from('table').select();
  return result.map((data) => Model.fromSupabase(data)).toList();
} on PostgrestException catch (e) {
  throw DatabaseException(
    DatabaseErrorType.queryFailed,
    'Failed to fetch data: ${e.message}',
    table: 'table',
    originalError: e,
  );
} catch (e) {
  throw DatabaseException(
    DatabaseErrorType.connectionFailed,
    'Database connection failed',
    originalError: e,
  );
}
```

### Real-time Subscription Pattern
```dart
void _setupRealtimeSubscription() {
  _supabase
      .from('table_name')
      .stream(primaryKey: ['id'])
      .eq('user_id', _getCurrentUserId())
      .listen(_handleRealtimeUpdate);
}
```

## Data Model Patterns

### Supabase Integration Pattern
```dart
class Model {
  // Properties...
  
  factory Model.fromSupabase(Map<String, dynamic> data) {
    return Model(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      // Map other fields...
    );
  }
  
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      // Map other fields...
    };
  }
}
```

## Performance Best Practices

### Query Optimization
- Use `.select()` to specify only needed columns
- Implement pagination for large datasets
- Use proper indexing on frequently queried columns
- Cache frequently accessed data locally

### Connection Management
- Reuse Supabase client instance
- Implement connection pooling where appropriate
- Handle connection timeouts gracefully
- Monitor connection health

## Testing Patterns

### Unit Test Pattern
```dart
group('DatabaseService', () {
  late MockSupabaseClient mockClient;
  late DatabaseService service;
  
  setUp(() {
    mockClient = MockSupabaseClient();
    service = DatabaseService(mockClient);
  });
  
  test('should fetch user data', () async {
    // Arrange
    when(mockClient.from('table')).thenReturn(mockQueryBuilder);
    
    // Act & Assert
    final result = await service.findByUserId('user-id');
    expect(result, isNotEmpty);
  });
});
```

### Integration Test Pattern
- Test complete authentication flows
- Verify real-time synchronization
- Test offline-to-online sync scenarios
- Validate RLS policy enforcement