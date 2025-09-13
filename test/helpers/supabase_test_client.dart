/// Test client factory for Supabase mocking
class SupabaseTestClient {
  static Map<String, dynamic>? _mockInstance;
  
  /// Get singleton mock Supabase client
  static Map<String, dynamic> get instance {
    _mockInstance ??= <String, dynamic>{};
    return _mockInstance!;
  }
  
  /// Reset the mock client for clean test state
  static void reset() {
    _mockInstance = null;
  }
  
  /// Configure mock client with default responses
  static void configure() {
    final client = instance;
    
    // Configure basic mock responses
    client['configured'] = true;
  }
  
  /// Create mock user data for testing
  static Map<String, dynamic> createMockUser({
    String? id,
    String? email,
    String? username,
  }) {
    return {
      'id': id ?? 'test-user-id',
      'email': email ?? 'test@example.com',
      'username': username ?? 'testuser',
      'full_name': 'Test User',
    };
  }
  
  /// Create mock session data for testing
  static Map<String, dynamic> createMockSession({Map<String, dynamic>? user}) {
    return {
      'user': user ?? createMockUser(),
      'access_token': 'mock-access-token',
      'refresh_token': 'mock-refresh-token',
    };
  }
  
  /// Simulate successful authentication
  static void simulateSignIn({Map<String, dynamic>? user, Map<String, dynamic>? session}) {
    final client = instance;
    
    final mockUser = user ?? createMockUser();
    final mockSession = session ?? createMockSession(user: mockUser);
    
    client['currentUser'] = mockUser;
    client['currentSession'] = mockSession;
  }
  
  /// Simulate sign out
  static void simulateSignOut() {
    final client = instance;
    
    client['currentUser'] = null;
    client['currentSession'] = null;
  }
  
  /// Configure database query response
  static void configureDatabaseResponse(
    String table,
    String operation,
    dynamic response,
  ) {
    final client = instance;
    client['${table}_$operation'] = response;
  }
  
  /// Configure storage operation response
  static void configureStorageResponse(
    String bucket,
    String operation,
    dynamic response,
  ) {
    final client = instance;
    client['${bucket}_$operation'] = response;
  }
}