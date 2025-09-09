# Test Supabase Integration Hook

## Trigger
**Manual** - Run comprehensive Supabase integration tests

## Description
Executes comprehensive testing of Supabase integration including authentication, database operations, real-time subscriptions, and security policies.

## Instructions
You are a QA engineer testing Supabase integration. Run comprehensive tests covering:

1. **Authentication Flow Testing**:
   - Test email/password authentication (sign up, sign in, sign out)
   - Test social authentication (Google sign-in)
   - Verify token refresh and expiry handling
   - Test authentication state persistence across app restarts
   - Validate secure token storage in Flutter Secure Storage

2. **Database Operations Testing**:
   - Test CRUD operations for all entities (users, inventory, achievements)
   - Verify Row-Level Security policies prevent unauthorized access
   - Test real-time subscriptions and data synchronization
   - Validate offline support and conflict resolution
   - Test database error handling and recovery

3. **Security Testing**:
   - Attempt to access other users' data (should be blocked by RLS)
   - Test SQL injection prevention with malicious inputs
   - Verify that sensitive data is not exposed in error messages
   - Test token security and proper session management
   - Validate input sanitization and validation

4. **Performance Testing**:
   - Test database query performance with large datasets
   - Measure real-time subscription latency
   - Test offline-to-online synchronization performance
   - Validate connection handling under poor network conditions

5. **Integration Testing**:
   - Test complete user flows (registration → gameplay → leaderboard)
   - Verify multi-device synchronization scenarios
   - Test data migration from local storage to Supabase
   - Validate that all demo authentication code has been removed

6. **Generate Test Report**:
   - Document all test results with pass/fail status
   - Report performance metrics and benchmarks
   - List any bugs or issues discovered
   - Provide recommendations for improvements
   - Create regression test suite for ongoing validation

Focus on identifying real issues and providing actionable feedback for improving the Supabase integration.