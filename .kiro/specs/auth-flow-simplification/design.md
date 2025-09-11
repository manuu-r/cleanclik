# Design Document

## Overview

This design simplifies the CleanClik authentication system by consolidating multiple services into a single, cohesive authentication service, eliminating redundant state management, and streamlining the user experience. The new design reduces complexity while maintaining security and functionality.

## Architecture

### Current Problems
- **Multiple Services**: UserService, TokenService, UserDatabaseService, SupabaseConfigService all handle overlapping concerns
- **Complex State Management**: Multiple streams, controllers, and state synchronization issues
- **Redundant Token Handling**: Manual token operations scattered throughout the codebase
- **Convoluted Initialization**: Complex session checking, restoration, and timeout logic
- **Inconsistent Error Handling**: Different error patterns across services

### New Simplified Architecture
```
AuthService (Single Service)
├── Authentication Operations (sign in/out, registration)
├── User Profile Management (load, update, sync)
├── Token Management (automatic, internal)
├── State Management (single source of truth)
└── Error Handling (consistent, categorized)
```

## Components and Interfaces

### 1. Simplified AuthService

**Core Responsibilities:**
- Handle all authentication operations (sign in, sign out, registration)
- Manage user profile data automatically
- Handle token operations internally (no external token service)
- Provide single authentication state stream
- Handle demo mode seamlessly

**Key Methods:**
```dart
class AuthService {
  // Authentication operations
  Future<AuthResult> signInWithEmail(String email, String password);
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signUpWithEmail(String email, String password, String username);
  Future<void> signOut();
  
  // State access
  Stream<AuthState> get authStateStream;
  AuthState get currentState;
  User? get currentUser;
  bool get isAuthenticated;
  
  // Profile operations
  Future<void> updateProfile(User updatedUser);
  Future<void> addPoints(int points);
  
  // Initialization
  Future<void> initialize();
  void dispose();
}
```

### 2. Unified AuthState

**Single State Object:**
```dart
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isDemoMode;
  
  // Status enum
  enum AuthStatus {
    loading,      // Initial load or authentication in progress
    authenticated, // User is signed in
    unauthenticated, // User is not signed in
    error         // Authentication error occurred
  }
}
```

### 3. Simplified AuthResult

**Consistent Result Pattern:**
```dart
class AuthResult {
  final bool success;
  final User? user;
  final AuthError? error;
  
  // Error types for better handling
  enum AuthErrorType {
    networkError,
    invalidCredentials,
    emailNotVerified,
    userNotFound,
    weakPassword,
    emailAlreadyInUse,
    unknownError
  }
}
```

### 4. Internal Token Management

**Automatic Token Handling:**
- Tokens stored and managed internally within AuthService using Supabase client
- Automatic refresh handled by Supabase client's built-in mechanisms
- No external token service or manual token operations
- Token clearing happens automatically on sign out
- Proper error handling when tokens are invalid or expired

### 5. Simplified User Database Operations

**Integrated Database Operations:**
- User database operations handled internally by AuthService
- No separate UserDatabaseService exposed to the rest of the app
- Automatic profile creation and updates during authentication
- Simplified error handling with clear database error categorization

## Data Models

### AuthState Model
```dart
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isDemoMode;
  
  // Convenience getters
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get hasError => status == AuthStatus.error;
}
```

### Simplified User Model
- Keep existing User model but simplify update operations
- Remove complex state synchronization
- Automatic timestamp updates

## Error Handling

### Categorized Error Types
```dart
enum AuthErrorType {
  networkError,           // Network connectivity issues
  invalidCredentials,     // Wrong email/password
  emailNotVerified,      // Email confirmation required
  userNotFound,          // User doesn't exist
  weakPassword,          // Password doesn't meet requirements
  emailAlreadyInUse,     // Email already registered
  configurationError,    // Supabase not configured
  unknownError          // Unexpected errors
}
```

### Error Recovery Strategies
- **Network Errors**: Automatic retry with exponential backoff
- **Configuration Errors**: Clear error messages with setup instructions
- **User Errors**: Clear messages with actionable guidance
- **System Errors**: Graceful error handling with detailed logging

## Testing Strategy

### Unit Tests
- Test all authentication operations with mocked Supabase client
- Test state transitions and error handling
- Test demo mode functionality
- Test automatic token management

### Integration Tests
- Test full authentication flows
- Test state persistence across app restarts
- Test error recovery scenarios
- Test demo mode to production mode transitions

### Widget Tests
- Test AuthWrapper behavior with different auth states
- Test loading states and error displays
- Test navigation based on authentication state

## Implementation Approach

### Phase 1: Create New AuthService
1. Create simplified AuthService class
2. Implement core authentication methods
3. Add internal token management
4. Add unified state management

### Phase 2: Update State Management
1. Create unified AuthState model
2. Implement single state stream
3. Update Riverpod providers
4. Remove redundant state controllers

### Phase 3: Simplify UI Integration
1. Update AuthWrapper to use new AuthService
2. Simplify loading and error states
3. Remove complex timeout and retry logic
4. Update authentication screens

### Phase 4: Remove Old Services
1. Remove TokenService
2. Remove UserDatabaseService (integrate into AuthService)
3. Simplify SupabaseConfigService
4. Clean up unused code

### Phase 5: Testing and Validation
1. Add comprehensive tests
2. Test demo mode functionality
3. Test production mode functionality
4. Validate error handling and recovery

## Migration Strategy

### Backward Compatibility
- Keep existing provider names during transition
- Gradually migrate screens to use new AuthService
- Maintain existing User model structure
- Preserve existing authentication state behavior

### Rollback Plan
- Keep old services in separate files during migration
- Use feature flags to switch between old and new implementations
- Maintain existing database schema
- Preserve existing token storage format

## Performance Considerations

### Reduced Complexity
- Single service reduces memory overhead
- Fewer stream subscriptions and controllers
- Simplified state updates reduce CPU usage
- Automatic token management reduces manual operations

### Improved Startup Time
- Simplified initialization process
- Reduced service dependencies
- Faster authentication state determination
- Eliminated complex session restoration logic

### Better Error Recovery
- Faster error detection and recovery
- Reduced error propagation complexity
- Clearer error boundaries
- Improved user experience during errors