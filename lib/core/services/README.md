# Core Services

This directory contains the core services for CleanClik, including AR detection, authentication, and data management systems.

## Authentication System

The authentication system provides secure user management with Supabase integration and demo mode fallback.

### Components

#### UserService
- **Purpose**: Main authentication service with user profile management
- **Key Features**:
  - Email/password authentication via Supabase Auth
  - Google OAuth integration
  - Anonymous sign-in for demo users
  - Real-time authentication state management
  - Automatic user profile creation and synchronization
  - Demo mode support when Supabase is not configured

#### TokenService
- **Purpose**: Secure token storage and management
- **Key Features**:
  - Encrypted token storage using Flutter Secure Storage
  - Automatic token refresh 5 minutes before expiry
  - Session validation and restoration
  - Secure token cleanup on sign-out
  - Token status monitoring and health checks

#### SupabaseConfigService
- **Purpose**: Supabase client configuration and initialization
- **Key Features**:
  - Environment-based configuration loading
  - Graceful fallback to demo mode when credentials are missing
  - Connection health monitoring
  - PKCE flow for enhanced security

### Authentication Flow

```dart
// Initialize authentication
final userService = ref.read(userServiceProvider);

// Sign in with email/password
final result = await userService.signInWithEmail(email, password);
if (result.success) {
  // User signed in successfully
  final user = result.user;
} else {
  // Handle error
  print(result.error);
}

// Listen to authentication state
ref.listen(authStateProvider, (previous, next) {
  next.when(
    data: (isAuthenticated) => {
      if (isAuthenticated) {
        // User is signed in
      } else {
        // User is signed out
      }
    },
    loading: () => {/* Show loading */},
    error: (error, stack) => {/* Handle error */},
  );
});
```

### Demo Mode

When Supabase credentials are not configured, the app automatically runs in demo mode:

- ✅ Full UI functionality with sample data
- ✅ Local user profile with achievements and stats  
- ❌ No cloud synchronization
- ❌ No real authentication persistence

### Security Features

- **Encrypted Storage**: All tokens stored using device-specific encryption
- **Automatic Refresh**: Tokens refreshed automatically before expiry
- **Session Validation**: Regular session health checks
- **Secure Cleanup**: Complete token cleanup on sign-out
- **PKCE Flow**: Enhanced OAuth security with Proof Key for Code Exchange

## AR Detection System

This section contains the AR detection system for real-time object detection with colored AR overlays.

## Components

### ARDetectionService
- **Purpose**: Main service for AR-based object detection and overlay rendering
- **Key Features**:
  - Real-time ML Kit object detection
  - Category-based color mapping
  - Performance optimization for <200ms latency
  - Graceful fallback for devices without AR capability

### ObjectTracker
- **Purpose**: Manages object tracking IDs and persistence across frames
- **Key Features**:
  - Unique tracking ID assignment
  - Object overlap detection and ID reuse
  - Automatic cleanup of expired objects
  - Smooth visual transitions

### CameraService
- **Purpose**: Camera initialization and permission handling
- **Key Features**:
  - Permission management
  - Camera selection (back/front)
  - Error handling and fallbacks

## Waste Categories

The system categorizes detected objects into 5 disposal categories:

1. **EcoGems** (Green) - Recyclable items
   - Bottles, cans, plastic containers, paper, cardboard
2. **FuelShards** (Light Green) - Organic waste
   - Food scraps, fruits, vegetables, compostable materials
3. **VoidCrystals** (Gray) - Landfill waste
   - General trash, non-recyclable items
4. **TechRelics** (Blue) - Electronic waste
   - Phones, computers, batteries, cables
5. **ToxicOrbs** (Red) - Hazardous materials
   - Chemicals, paint, oil, pharmaceuticals

## Performance Optimizations

- **Detection Interval**: 100ms between ML Kit processing calls
- **Confidence Threshold**: 0.5 minimum for object classification
- **Frame Processing**: Asynchronous with processing flags to prevent overlap
- **Memory Management**: Automatic cleanup of expired tracking objects
- **Battery Optimization**: Efficient camera preview and detection cycles

## Usage Example

```dart
// Initialize AR detection service
final arService = ARDetectionServiceImpl();

// Start detection with camera controller
await arService.startDetection(cameraController);

// Listen to detection stream
arService.detectionStream.listen((detectedObjects) {
  // Update UI with detected objects
  setState(() {
    _detectedObjects = detectedObjects;
  });
});

// Stop detection when done
await arService.stopDetection();
arService.dispose();
```

## Testing

Run the AR detection tests:
```bash
flutter test test/ar_detection_test.dart
```

Tests cover:
- Waste category classification
- Object tracking ID management
- Overlap detection and ID reuse
- Object lifecycle management

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **1.1**: Real-time object detection at ≥15fps on mid-range devices
- **1.2**: Colored AR overlays within 200ms indicating bin categories
- **1.3**: Simultaneous multi-object tagging with distinct tracking IDs
- **1.4**: LLM-assisted classification hints (framework ready)

## Future Enhancements

### Authentication System
- Biometric authentication support (Face ID, Touch ID, Fingerprint)
- Multi-factor authentication (2FA)
- Social sign-in providers (Apple, Facebook, Twitter)
- Enterprise SSO integration
- Advanced session management with device tracking

### AR Detection System
- Integration with LLM for low-confidence object classification
- ARCore/ARKit depth API integration for realistic occlusion
- Advanced tracking algorithms for improved object persistence
- Performance profiling and optimization for various device tiers

## Environment Setup

The authentication system requires environment variables for full functionality:

```bash
# Required for production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key

# Optional for Google Sign-In
GOOGLE_WEB_CLIENT_ID=your-web-client-id.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your-ios-client-id.googleusercontent.com
```

See `docs/ENVIRONMENT_SETUP.md` for detailed configuration instructions.

## Testing

Run authentication tests:
```bash
flutter test test/auth_test.dart
```

Run AR detection tests:
```bash
flutter test test/ar_detection_test.dart
```