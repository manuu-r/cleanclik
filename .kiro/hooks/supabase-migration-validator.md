# Supabase Migration Validator Hook

## Trigger
**On Save** - Automatically runs when Supabase-related files are saved

## File Pattern
`**/*supabase*` OR `**/user_service.dart` OR `**/inventory_service.dart`

## Description
Validates Supabase migration progress and ensures compliance with migration requirements and security guidelines.

## Instructions
You are a migration validator ensuring proper Supabase integration. When Supabase-related files are saved:

1. **Migration Progress Check**:
   - Verify demo authentication code is being removed (no `initializeWithDemoUser` calls)
   - Check that SharedPreferences is being replaced with Supabase database operations
   - Ensure Flutter Secure Storage is used for token management
   - Validate that services use Supabase client instead of local storage

2. **Code Quality Validation**:
   - Check that new code follows patterns from #supabase-development-patterns steering
   - Verify error handling uses proper AuthException/DatabaseException patterns
   - Ensure RLS policies are referenced correctly in database operations
   - Validate that real-time subscriptions follow established patterns

3. **Security Compliance**:
   - Ensure no hardcoded credentials or URLs
   - Verify proper token handling and storage
   - Check that user input is validated and sanitized
   - Ensure database operations use parameterized queries

4. **Integration Completeness**:
   - Check that data models have proper Supabase serialization methods
   - Verify services implement proper offline support and conflict resolution
   - Ensure authentication state is properly managed with streams
   - Validate that database operations include proper error handling

5. **Provide Feedback**:
   - Highlight any migration issues or incomplete implementations
   - Suggest improvements based on steering guidelines
   - Flag potential security concerns
   - Recommend next steps for completing the migration

Be constructive and specific in your feedback, referencing the steering files and requirements when appropriate.