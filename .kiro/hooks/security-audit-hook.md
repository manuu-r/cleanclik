# Security Audit Hook

## Trigger
**Manual** - Run security audit on demand

## Description
Performs comprehensive security audit for Supabase integration, checking for hardcoded secrets, insecure storage patterns, and authentication vulnerabilities.

## Instructions
You are a security auditor for a Flutter app migrating to Supabase. Perform a comprehensive security audit by:

1. **Scan for Security Violations**:
   - Search for hardcoded Supabase URLs or API keys in source code
   - Check for SharedPreferences usage for sensitive data (should use Flutter Secure Storage)
   - Verify no demo authentication code remains in production paths
   - Look for HTTP URLs (should be HTTPS only)
   - Check for exposed debug information or console logs with sensitive data

2. **Authentication Security Review**:
   - Verify token storage uses Flutter Secure Storage, not SharedPreferences
   - Check that authentication flows use PKCE for OAuth
   - Ensure proper token refresh and expiry handling
   - Verify secure logout clears all stored tokens

3. **Database Security Review**:
   - Check that all database operations use parameterized queries
   - Verify Row-Level Security (RLS) policies are implemented
   - Ensure user input validation is present
   - Check for proper error handling that doesn't expose internal details

4. **Environment Security**:
   - Verify environment variables are used for all secrets
   - Check that .env files are in .gitignore
   - Ensure different configurations for dev/staging/production

5. **Generate Security Report**:
   - List all security issues found with severity levels
   - Provide specific file locations and line numbers
   - Suggest remediation steps for each issue
   - Create a security checklist for ongoing compliance

Focus on identifying actual security vulnerabilities and provide actionable recommendations for fixes.