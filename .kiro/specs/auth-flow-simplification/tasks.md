# Implementation Plan

- [x] 1. Simplify and consolidate entire authentication system
  - Create unified AuthState class with clear status enum (loading, authenticated, unauthenticated, error)
  - Create simplified AuthResult class with categorized error types for better error handling
  - Replace UserService, TokenService, and UserDatabaseService with single AuthService class
  - Implement core authentication methods: signInWithEmail, signInWithGoogle, signUpWithEmail, signOut
  - Add automatic user profile loading/creation integrated directly into authentication flow
  - Implement single authentication state stream that replaces all current complex state management
  - Add internal token management using Supabase client's built-in mechanisms (no external TokenService)
  - Integrate user database operations directly into AuthService (no separate UserDatabaseService)
  - Create new Riverpod providers: authServiceProvider, authStateProvider, currentUserProvider
  - Update AuthWrapper to use simplified state management with clear loading/error/authenticated states
  - Update all authentication screens (LoginScreen, SignUpScreen, EmailVerificationScreen) to use new AuthService
  - Simplify app initialization and routing to use new authentication state
  - Remove all old authentication services and clean up unused code
  - Add comprehensive error handling with clear categorization and recovery paths
  - Write unit tests for all AuthService methods and state transitions
  - _Requirements: 1.1, 1.2, 1.4, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 5.4, 7.1, 7.2, 7.3, 7.4_