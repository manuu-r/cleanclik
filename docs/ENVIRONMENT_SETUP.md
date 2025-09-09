# Environment Setup Guide

This guide explains how to set up environment variables for the CleanClik authentication system and other services.

## Overview

CleanClik uses environment variables to securely store API keys and configuration values. The app supports both full functionality with proper configuration and a demo mode when credentials are missing.

## Required Environment Variables

### Supabase Configuration
```bash
# Your Supabase project URL
SUPABASE_URL=https://your-project.supabase.co

# Your Supabase publishable (anon) key
SUPABASE_PUBLISHABLE_KEY=your-publishable-key-here
```

### Google Sign-In (Optional)
```bash
# Google OAuth Web Client ID
GOOGLE_WEB_CLIENT_ID=your-web-client-id.googleusercontent.com

# Google OAuth iOS Client ID  
GOOGLE_IOS_CLIENT_ID=your-ios-client-id.googleusercontent.com
```

## Setup Instructions

### 1. Create Environment File

Create a `.env` file in the root directory of your project:

```bash
# Copy the example file
cp .env.example .env

# Edit with your actual values
nano .env
```

### 2. Development Setup

For development, place your environment variables in the `.env` file:

```bash
# .env file
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
GOOGLE_WEB_CLIENT_ID=123456789-abcdefgh.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=123456789-ijklmnop.googleusercontent.com
```

### 3. Production Setup

For production deployments, set environment variables through your hosting platform:

#### Flutter Web (Firebase Hosting)
```bash
firebase functions:config:set supabase.url="https://your-project.supabase.co"
firebase functions:config:set supabase.key="your-publishable-key"
```

#### Mobile (App Store/Play Store)
Set environment variables during the build process:

```bash
# iOS
flutter build ios --dart-define=SUPABASE_URL="https://your-project.supabase.co"

# Android  
flutter build appbundle --dart-define=SUPABASE_URL="https://your-project.supabase.co"
```

## Getting Your Supabase Credentials

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Sign up/login to your account
3. Click "New Project"
4. Fill in your project details
5. Wait for the project to initialize

### 2. Get Project URL
1. Go to your project dashboard
2. Click "Settings" → "API"
3. Copy the "Project URL"

### 3. Get Publishable Key
1. In the same API settings page
2. Copy the "anon/public" key (this is your publishable key)

## Setting Up Google Sign-In

### 1. Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable the Google Sign-In API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"

### 2. Configure OAuth Clients
Create separate OAuth clients for each platform:

#### Web Application
- Application type: Web application
- Authorized redirect URIs: `https://your-project.supabase.co/auth/v1/callback`

#### iOS Application  
- Application type: iOS
- Bundle ID: Your app's bundle identifier

#### Android Application
- Application type: Android
- Package name: Your app's package name
- SHA-1 certificate fingerprint

## Demo Mode

If environment variables are not configured, the app automatically runs in demo mode:

### Demo Mode Features
- ✅ Full UI functionality
- ✅ Demo user with sample data
- ✅ All app features work locally
- ❌ No real authentication
- ❌ No data persistence
- ❌ No cloud synchronization

### Demo Mode Indicators
The app will show debug messages indicating demo mode:
```
Warning: Missing Supabase configuration. App will run in demo mode.
```

## Security Best Practices

### Environment File Security
- ✅ Add `.env` to `.gitignore`
- ✅ Never commit `.env` files to version control
- ✅ Use different credentials for development/production
- ✅ Regularly rotate API keys

### Key Management
- ✅ Store production keys in secure CI/CD variables
- ✅ Use least-privilege principle for API keys
- ✅ Monitor key usage in respective dashboards
- ✅ Implement key rotation policies

## Troubleshooting

### Common Issues

#### "Supabase not initialized" Error
```bash
# Solution: Check your environment variables
echo $SUPABASE_URL
echo $SUPABASE_PUBLISHABLE_KEY
```

#### Google Sign-In Fails
```bash
# Check OAuth client configuration
# Ensure redirect URIs are correctly set
# Verify SHA-1 fingerprints for Android
```

#### Demo Mode When Expecting Full Functionality
```bash
# Check if .env file exists and has correct format
cat .env

# Verify environment variables are loaded
flutter run --verbose
```

### Debug Commands

Check environment status:
```bash
# View loaded environment variables (development only)
flutter run --dart-define=DEBUG_ENV=true
```

Test Supabase connection:
```bash
# The app will log connection status on startup
flutter run | grep -i supabase
```

## Platform-Specific Configuration

### iOS Configuration
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>your.bundle.identifier</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-ios-client-id</string>
        </array>
    </dict>
</array>
```

### Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<activity
    android:name="com.google.android.gms.auth.api.signin.internal.SignInHubActivity"
    android:exported="true" />
```

## Next Steps

After setting up your environment:

1. **Test Authentication**: Try signing up with email/password
2. **Test Google Sign-In**: Verify OAuth flow works
3. **Check Database**: Confirm user profiles are created
4. **Monitor Logs**: Watch for any authentication errors
5. **Set Up Production**: Deploy with production credentials

## Support

If you encounter issues:

1. Check the debug console for error messages
2. Verify all environment variables are set correctly
3. Test your Supabase project directly in the dashboard
4. Ensure OAuth clients are properly configured

For more help, refer to:
- [Supabase Documentation](https://supabase.com/docs)
- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in)
- [Flutter Environment Variables Guide](https://docs.flutter.dev/deployment/flavors)