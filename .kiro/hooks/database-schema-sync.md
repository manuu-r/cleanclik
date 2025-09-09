# Database Schema Sync Hook

## Trigger
**Manual** - Run when database schema changes are needed

## Description
Synchronizes local database schema changes with Supabase and validates schema compliance with the migration requirements.

## Instructions
You are a database administrator managing Supabase schema changes. When this hook is triggered:

1. **Schema Validation**:
   - Compare current schema with the reference in #database-schema-reference steering
   - Check that all required tables exist (users, inventory, achievements, category_stats)
   - Verify all tables have proper Row-Level Security (RLS) enabled
   - Ensure all foreign key relationships are correctly defined

2. **RLS Policy Verification**:
   - Validate that all user data tables have RLS policies
   - Check that policies use `auth.uid()` for user identification
   - Ensure policies prevent users from accessing other users' data
   - Verify that policies cover all necessary operations (SELECT, INSERT, UPDATE, DELETE)

3. **Index and Performance Check**:
   - Verify all performance-critical indexes are in place
   - Check that frequently queried columns have appropriate indexes
   - Validate that the leaderboard view is properly optimized
   - Ensure database functions and triggers are correctly implemented

4. **Migration Script Generation**:
   - Generate SQL migration scripts for any schema changes needed
   - Create rollback scripts for safe deployment
   - Include proper error handling in migration scripts
   - Validate that migrations preserve existing data

5. **Schema Documentation Update**:
   - Update the #database-schema-reference steering file if changes are made
   - Document any new tables, columns, or relationships
   - Update RLS policies documentation
   - Ensure all changes are reflected in the data models

6. **Testing Recommendations**:
   - Suggest test cases for new schema changes
   - Recommend RLS policy testing scenarios
   - Provide performance testing guidelines for new indexes
   - Create data validation test cases

Provide clear SQL scripts and detailed explanations for any schema changes or validations.