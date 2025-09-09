# Design Document

## Overview

This design outlines the migration from demo authentication and local storage (SharedPreferences) to a production-ready Supabase backend. The migration will transform CleanClik from a prototype into a scalable, secure application with real user accounts, persistent cloud storage, and proper data synchronization across devices.

The current architecture uses hardcoded demo users and local storage, which prevents multi-user functionality, data persistence across devices, and secure operations. The new Supabase-based architecture will provide authentication, real-time database operations, and Row-Level Security (RLS) for data protection.

## Architecture

### Current Architecture (Before Migration)
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   UI Layer      │    │   Service Layer  │    │  Storage Layer  │
│                 │    │                  │    │                 │
│ - Auth Screens  │───▶│ - UserService    │───▶│ SharedPrefs     │
│ - Game Screens  │    │ - InventoryServ  │    │ (Local Only)    │
│ - Leaderboard   │    │ - Demo Logic     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### New Architecture (After Migration)
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   UI Layer      │    │   Service Layer  │    │  Backend Layer  │
│                 │    │                  │    │                 │
│ - Auth Screens  │───▶│ - UserService    │───▶│ Supabase Auth   │
│ - Game Screens  │    │ - InventoryServ  │    │ Supabase DB     │
│ - Leaderboard   │    │ - Real-time Sync │    │ Row-Level Sec   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Local Cache     │
                       │ Flutter Secure  │
                       │ Storage         │
                       └─────────────────┘
```

### Authentication Flow
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ App Launch  │───▶│ Check Token │───▶│ Validate    │───▶│ Auto Login  │
│             │    │ in Secure   │    │ with        │    │ or Show     │
│             │    │ Storage     │    │ Supabase    │    │ Auth Screen │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## Components and Interfaces

### 1. Supabase Configuration Service

**Purpose**: Initialize and manage Supabase client with secure configuration.

```dart
class SupabaseConfigService {
  static late Supabase _instance;
  
  static Future<void> initialize() async {
    final supabaseUrl = await _getEnvVariable('SUPABASE_URL');
    final supabaseAnonKey = await _getEnvVariable('SUPABASE_PUBLISHABLE_KEY');
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _instance = Supabase.instance;
  }
  
  static SupabaseClient get client => _instance.client;
}
```

### 2. Enhanced UserService

**Purpose**: Replace demo authentication with real Supabase Auth integration.

**Key Changes**:
- Remove `initializeWithDemoUser()` method
- Replace local storage with Supabase database operations
- Add email/password and social authentication
- Implement secure token management

```dart
class UserService {
  final SupabaseClient _supabase;
  final FlutterSecureStorage _secureStorage;
  
  // Streams for real-time auth state
  Stream<User?> get userStream => _supabase.auth.onAuthStateChange
      .map((state) => state.session?.user)
      .asyncMap(_mapSupabaseUserToAppUser);
  
  // Authentication methods
  Future<AuthResult> signInWithEmail(String email, String password);
  Future<AuthResult> signUpWithEmail(String email, String password);
  Future<AuthResult> signInWithGoogle();
  Future<void> signOut();
  
  // User profile management
  Future<void> updateUserProfile(UserProfile profile);
  Future<void> syncUserData();
}
```

### 3. Database Service Layer

**Purpose**: Abstract database operations with proper error handling and caching.

```dart
abstract class DatabaseService<T> {
  Future<T?> findById(String id);
  Future<List<T>> findByUserId(String userId);
  Future<T> create(T entity);
  Future<T> update(String id, T entity);
  Future<void> delete(String id);
}

class UserDatabaseService extends DatabaseService<UserProfile> {
  // Implements user-specific database operations
}

class InventoryDatabaseService extends DatabaseService<InventoryItem> {
  // Implements inventory-specific database operations
}
```

### 4. Enhanced InventoryService

**Purpose**: Replace SharedPreferences with Supabase database operations.

**Key Changes**:
- Replace `_loadFromStorage()` with Supabase queries
- Replace `_saveToStorage()` with real-time database updates
- Add offline support with local caching
- Implement conflict resolution for multi-device sync

```dart
class InventoryService extends _$InventoryService {
  final InventoryDatabaseService _dbService;
  final CacheService _cacheService;
  
  @override
  Future<void> build() async {
    await _loadFromDatabase();
    _setupRealtimeSubscription();
  }
  
  Future<void> _loadFromDatabase() async {
    final userId = _getCurrentUserId();
    final items = await _dbService.findByUserId(userId);
    _inventory = items;
  }
  
  void _setupRealtimeSubscription() {
    _supabase
        .from('inventory')
        .stream(primaryKey: ['id'])
        .eq('user_id', _getCurrentUserId())
        .listen(_handleRealtimeUpdate);
  }
}
```

### 5. Authentication UI Components

**Purpose**: Provide user-friendly authentication screens.

**Components**:
- `LoginScreen`: Email/password and social login options
- `SignUpScreen`: User registration with validation
- `AuthWrapper`: Route protection and authentication state management

```dart
class AuthWrapper extends ConsumerWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (isAuthenticated) => isAuthenticated 
          ? child 
          : const LoginScreen(),
      loading: () => const LoadingScreen(),
      error: (error, _) => ErrorScreen(error: error),
    );
  }
}
```

## Data Models

### Database Schema

#### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  avatar_url TEXT,
  total_points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_online BOOLEAN DEFAULT FALSE,
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth_id = auth.uid());

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth_id = auth.uid());
```

#### Inventory Table
```sql
CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(auth_id) ON DELETE CASCADE,
  tracking_id VARCHAR(100) NOT NULL,
  category VARCHAR(20) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  code_name VARCHAR(100) NOT NULL,
  confidence DECIMAL(3,2) NOT NULL,
  picked_up_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, tracking_id)
);

-- Row Level Security
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own inventory" ON inventory
  FOR ALL USING (user_id = auth.uid());
```

#### Achievements Table
```sql
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(auth_id) ON DELETE CASCADE,
  achievement_id VARCHAR(50) NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB,
  UNIQUE(user_id, achievement_id)
);

-- Row Level Security
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own achievements" ON achievements
  FOR SELECT USING (user_id = auth.uid());
```

#### Leaderboard View
```sql
CREATE VIEW leaderboard AS
SELECT 
  u.id,
  u.username,
  u.total_points,
  u.level,
  RANK() OVER (ORDER BY u.total_points DESC) as rank
FROM users u
WHERE u.total_points > 0
ORDER BY u.total_points DESC;
```

#### Category Stats Table
```sql
CREATE TABLE category_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(auth_id) ON DELETE CASCADE,
  category VARCHAR(20) NOT NULL,
  item_count INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, category)
);

-- Row Level Security
ALTER TABLE category_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own stats" ON category_stats
  FOR ALL USING (user_id = auth.uid());
```

### Enhanced Data Models

#### UserProfile Model
```dart
class UserProfile {
  final String id;
  final String authId;
  final String username;
  final String email;
  final String? avatarUrl;
  final int totalPoints;
  final int level;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isOnline;
  
  // Factory methods for Supabase integration
  factory UserProfile.fromSupabase(Map<String, dynamic> data);
  Map<String, dynamic> toSupabase();
}
```

#### InventoryItem Model (Enhanced)
```dart
class InventoryItem {
  final String id;
  final String userId;
  final String trackingId;
  final String category;
  final String displayName;
  final String codeName;
  final double confidence;
  final DateTime pickedUpAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  
  // Supabase integration
  factory InventoryItem.fromSupabase(Map<String, dynamic> data);
  Map<String, dynamic> toSupabase();
}
```

## Error Handling

### Authentication Errors
```dart
enum AuthErrorType {
  invalidCredentials,
  userNotFound,
  emailAlreadyExists,
  weakPassword,
  networkError,
  tokenExpired,
}

class AuthException implements Exception {
  final AuthErrorType type;
  final String message;
  final dynamic originalError;
  
  const AuthException(this.type, this.message, [this.originalError]);
}
```

### Database Errors
```dart
enum DatabaseErrorType {
  connectionFailed,
  queryFailed,
  constraintViolation,
  permissionDenied,
  recordNotFound,
}

class DatabaseException implements Exception {
  final DatabaseErrorType type;
  final String message;
  final String? table;
  final dynamic originalError;
  
  const DatabaseException(this.type, this.message, {this.table, this.originalError});
}
```

### Error Recovery Strategies
1. **Network Errors**: Implement exponential backoff retry logic
2. **Token Expiry**: Automatic token refresh with fallback to re-authentication
3. **Constraint Violations**: User-friendly error messages with suggested actions
4. **Permission Errors**: Clear messaging about data access restrictions

## Testing Strategy

### Unit Tests
- **Authentication Service**: Mock Supabase Auth responses
- **Database Services**: Test CRUD operations with test database
- **Data Models**: Validate serialization/deserialization
- **Error Handling**: Test all error scenarios and recovery

### Integration Tests
- **Authentication Flow**: End-to-end login/logout scenarios
- **Data Synchronization**: Multi-device sync scenarios
- **Offline Support**: Test offline-to-online data sync
- **Real-time Updates**: Test live data updates across clients

### Security Tests
- **Row-Level Security**: Verify users can only access their data
- **Token Security**: Test token storage and refresh mechanisms
- **Input Validation**: Test SQL injection and XSS prevention
- **Permission Boundaries**: Test unauthorized access attempts

### Performance Tests
- **Database Queries**: Measure query performance with large datasets
- **Real-time Subscriptions**: Test subscription performance under load
- **Offline Sync**: Measure sync performance with large offline changes
- **Authentication**: Test login/logout performance

## Security Considerations

### Authentication Security
- **PKCE Flow**: Use Proof Key for Code Exchange for OAuth flows
- **Token Storage**: Store tokens in Flutter Secure Storage, never in SharedPreferences
- **Token Rotation**: Implement automatic refresh token rotation
- **Session Management**: Proper session timeout and cleanup

### Database Security
- **Row-Level Security**: All tables must have RLS policies
- **Input Validation**: Server-side validation for all user inputs
- **SQL Injection Prevention**: Use parameterized queries exclusively
- **Audit Logging**: Log all data access and modifications

### Environment Security
- **Secret Management**: All secrets in environment variables
- **Code Obfuscation**: Obfuscate production builds
- **Certificate Pinning**: Pin Supabase SSL certificates
- **Debug Protection**: Remove debug information from production builds

### Data Privacy
- **GDPR Compliance**: Implement data export and deletion
- **Data Minimization**: Collect only necessary user data
- **Anonymization**: Anonymize leaderboard data
- **Consent Management**: Clear consent for data collection and processing

## Migration Strategy

### Phase 1: Infrastructure Setup
1. Set up Supabase project and configure authentication
2. Create database schema with RLS policies
3. Set up environment configuration system
4. Add Supabase dependencies to project

### Phase 2: Authentication Migration
1. Create new authentication UI screens
2. Refactor UserService to use Supabase Auth
3. Implement secure token storage
4. Add social authentication providers

### Phase 3: Data Migration
1. Refactor InventoryService for database operations
2. Implement real-time data synchronization
3. Add offline support with local caching
4. Create data migration utilities for existing users

### Phase 4: Testing and Optimization
1. Comprehensive testing of all authentication flows
2. Performance optimization of database queries
3. Security audit and penetration testing
4. User acceptance testing with beta users

### Rollback Plan
- Maintain current demo authentication as fallback
- Feature flags to switch between old and new systems
- Database backup and restore procedures
- Gradual user migration with monitoring