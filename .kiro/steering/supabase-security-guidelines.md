---
inclusion: fileMatch
fileMatchPattern: '*supabase*'
---

# Supabase Security Guidelines

## Authentication Security Requirements

### Token Management
- **NEVER** store tokens in SharedPreferences or local files
- **ALWAYS** use Flutter Secure Storage for token storage
- Implement automatic token refresh with exponential backoff
- Use PKCE (Proof Key for Code Exchange) flow for OAuth
- Implement proper session timeout and cleanup

### Row-Level Security (RLS)
- **ALL** user data tables MUST have RLS enabled
- **EVERY** table MUST have policies ensuring users only access their own data
- Test RLS policies thoroughly - users should never see other users' data
- Use `auth.uid()` in all RLS policies for user identification

### Environment Security
- **NEVER** hardcode Supabase URL or keys in source code
- **ALWAYS** load credentials from environment variables
- Exclude `.env` files from version control
- Use different Supabase projects for dev/staging/production

## Database Security Patterns

### Required RLS Policy Pattern
```sql
-- Enable RLS on table
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Policy for user's own data
CREATE POLICY "Users can manage own data" ON table_name
  FOR ALL USING (user_id = auth.uid());
```

### Input Validation
- Validate ALL user inputs on both client and server side
- Use parameterized queries exclusively
- Sanitize data before database operations
- Implement proper constraint checking

## Code Security Standards

### Production Build Security
- Enable code obfuscation for production builds
- Remove all debug information from production
- Implement certificate pinning for Supabase connections
- Use secure build configurations

### Error Handling Security
- Never expose internal error details to users
- Log security events for audit purposes
- Implement proper error boundaries
- Use generic error messages for authentication failures