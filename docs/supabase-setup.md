# Supabase Infrastructure Setup Guide

This guide explains how to set up and use the Supabase infrastructure for the CleanClik app.

## Overview

The CleanClik app uses Supabase for:
- User authentication (email/password and social login)
- Real-time database operations
- Secure data storage with Row-Level Security (RLS)
- Automatic data synchronization across devices

## Prerequisites

1. A Supabase account (sign up at [supabase.com](https://supabase.com))
2. Flutter development environment set up
3. Basic understanding of SQL and database concepts

## Setup Steps

### 1. Create Supabase Project

1. Log in to your Supabase dashboard
2. Click "New Project"
3. Choose your organization
4. Enter project name: "cleanclik" (or your preferred name)
5. Enter a secure database password
6. Select your preferred region
7. Wait for the project to be created (usually 2-3 minutes)

### 2. Configure Database Schema

1. Navigate to the SQL Editor in your Supabase dashboard
2. Copy the contents of `database/schema.sql` and execute it
3. Copy the contents of `database/functions.sql` and execute it
4. Verify that all tables, policies, and functions were created successfully

### 3. Set Up Environment Variables

1. Copy `.env.example` to `.env` in your project root:
   ```bash
   cp .env.example .env
   ```

2. Fill in your Supabase credentials in `.env`:
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_PUBLISHABLE_KEY=your-anon-key-here
   ENVIRONMENT=development
   DEBUG_MODE=true
   ```

3. Find your credentials in Supabase dashboard:
   - Go to Settings → API
   - Copy the "Project URL" and "anon public" key

### 4. Configure Authentication

1. In Supabase dashboard, go to Authentication → Settings
2. Configure your site URL (for development: `http://localhost:3000`)
3. Set up OAuth providers if needed (Google, Apple, etc.)
4. Configure email templates if using email authentication

## Usage

### Initialization

The Supabase client is automatically initialized when the app starts:

```dart
// In main.dart or app initialization
await SupabaseConfigService.initialize();
```

### Using Providers

Access Supabase through Riverpod providers:

```dart
// Check if Supabase is ready
final isReady = ref.watch(isSupabaseReadyProvider);

// Get Supabase client
final client = ref.watch(supabaseClientProvider);

// Check health status
final healthStatus = ref.watch(supabaseHealthStatusProvider);
```

### Database Operations

Use the database service pattern for CRUD operations:

```dart
class UserDatabaseService extends DatabaseService<UserProfile> {
  @override
  Future<UserProfile?> findById(String id) async {
    final response = await SupabaseConfigService.client
        .from('users')
        .select()
        .eq('id', id)
        .single();
    
    return UserProfile.fromSupabase(response);
  }
}
```

### Real-time Subscriptions

Set up real-time data synchronization:

```dart
void _setupRealtimeSubscription() {
  SupabaseConfigService.client
      .from('inventory')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .listen((data) {
        // Handle real-time updates
        _handleInventoryUpdate(data);
      });
}
```

## Security Features

### Row-Level Security (RLS)

All user data tables have RLS policies that ensure:
- Users can only access their own data
- Proper authentication is required for all operations
- Data isolation between users

### Environment Security

- Never commit `.env` files to version control
- Use different Supabase projects for dev/staging/production
- Store sensitive credentials in secure environment variables

### Authentication Security

- PKCE flow for OAuth authentication
- Secure token storage using Flutter Secure Storage
- Automatic token refresh
- Proper session management

## Testing

### Unit Tests

Run unit tests for the configuration services:

```bash
flutter test test/unit/supabase_config_service_test.dart
flutter test test/unit/env_config_test.dart
```

### Integration Tests

Test complete authentication and database flows:

```bash
flutter test test/integration/
```

## Troubleshooting

### Common Issues

1. **"Missing required Supabase configuration" error**
   - Ensure `.env` file exists and contains valid credentials
   - Check that environment variables are properly loaded

2. **RLS policy violations**
   - Verify user is authenticated before database operations
   - Check that RLS policies match your use case

3. **Connection timeouts**
   - Check network connectivity
   - Verify Supabase project is active and not paused

### Health Checks

Use the built-in health check functionality:

```dart
final healthStatus = await SupabaseConfigService.healthCheck();
if (!healthStatus.isHealthy) {
  print('Supabase health issue: ${healthStatus.error}');
}
```

## Production Deployment

### Environment Configuration

1. Set up production environment variables
2. Use different Supabase project for production
3. Configure proper CORS settings
4. Set up SSL certificate pinning

### Security Checklist

- [ ] RLS policies tested and verified
- [ ] Environment variables secured
- [ ] Code obfuscation enabled
- [ ] Debug information removed
- [ ] SSL certificate pinning configured
- [ ] Input validation implemented
- [ ] Error handling properly configured

## Support

For issues related to:
- Supabase platform: [Supabase Documentation](https://supabase.com/docs)
- CleanClik implementation: Check the project's issue tracker
- Database schema: Refer to `database/README.md`