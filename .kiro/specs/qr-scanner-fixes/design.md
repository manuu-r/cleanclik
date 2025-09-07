# Design Document

## Overview

This design addresses the QR scanner navigation and widget positioning issues by implementing proper route parameter handling, fixing widget tree structure, and improving camera resource management. The solution ensures seamless transitions between AR detection and QR scanning modes while maintaining app stability.

## Architecture

### Navigation Flow Enhancement
- Extend the camera route to accept optional parameters indicating the initial mode
- Modify home screen navigation to pass QR scanning mode parameter
- Update AR camera screen to handle mode initialization based on route parameters

### Widget Tree Restructuring
- Fix QR scanner overlay positioning by ensuring proper parent-child relationships
- Restructure scan line animation to use proper Stack containers
- Implement proper widget disposal and cleanup mechanisms

### Camera Resource Management
- Implement camera state management to prevent conflicts between AR and QR modes
- Add proper resource disposal when switching between modes
- Implement error handling for camera permission and initialization issues

## Components and Interfaces

### 1. Enhanced Route Configuration
```dart
// Updated route to accept mode parameter
GoRoute(
  path: '/camera',
  name: 'camera',
  builder: (context, state) {
    final mode = state.uri.queryParameters['mode'];
    return ARCameraScreen(initialMode: mode);
  },
)
```

### 2. Camera Mode Enum
```dart
enum CameraMode {
  arDetection,
  qrScanning,
}
```

### 3. Updated AR Camera Screen Interface
```dart
class ARCameraScreen extends StatefulWidget {
  final String? initialMode;
  
  const ARCameraScreen({
    super.key,
    this.initialMode,
  });
}
```

### 4. Fixed QR Scanner Overlay Structure
```dart
// Proper widget tree structure with Stack as parent for Positioned widgets
Widget _buildScanLineOverlay() {
  return Positioned.fill(
    child: Stack(
      children: [
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack( // Proper Stack parent for Positioned
              children: [
                AnimatedBuilder(
                  animation: _scanLineAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanLineAnimation.value * 230,
                      left: 10,
                      right: 10,
                      child: Container(/* scan line */),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
```

### 5. Camera Resource Manager
```dart
class CameraResourceManager {
  static Future<void> switchToQRMode(CameraController? arController) async {
    if (arController != null) {
      await arController.pausePreview();
      await arController.dispose();
    }
  }
  
  static Future<void> switchToARMode(QRViewController? qrController) async {
    if (qrController != null) {
      await qrController.pauseCamera();
      await qrController.dispose();
    }
  }
}
```

## Data Models

### Camera State Model
```dart
class CameraState {
  final CameraMode mode;
  final bool isInitialized;
  final String? errorMessage;
  final bool hasPermission;
  
  const CameraState({
    required this.mode,
    required this.isInitialized,
    this.errorMessage,
    required this.hasPermission,
  });
}
```

## Error Handling

### Navigation Error Handling
- Validate route parameters and default to AR mode if invalid
- Handle cases where camera screen is accessed without proper context
- Provide fallback navigation if mode switching fails

### Widget Positioning Error Prevention
- Ensure all Positioned widgets have Stack parents
- Validate widget tree structure before rendering
- Implement proper error boundaries for overlay widgets

### Camera Resource Error Handling
- Handle camera permission denied scenarios
- Manage camera initialization failures
- Prevent resource conflicts during mode switching
- Implement retry mechanisms for failed camera operations

## Testing Strategy

### Unit Tests
- Test route parameter parsing and validation
- Test camera mode switching logic
- Test widget tree structure validation
- Test error handling scenarios

### Widget Tests
- Test QR scanner overlay rendering without crashes
- Test proper positioning of all overlay elements
- Test animation behavior within proper containers
- Test error state rendering

### Integration Tests
- Test complete navigation flow from home screen to QR scanner
- Test mode switching between AR detection and QR scanning
- Test camera resource management during transitions
- Test error recovery and user feedback

### Manual Testing Scenarios
1. Navigate from home screen QR button → should open QR scanner directly
2. Switch from AR mode to QR mode → should transition smoothly
3. Switch from QR mode to AR mode → should resume AR detection
4. Rapid mode switching → should handle gracefully without crashes
5. Camera permission scenarios → should show appropriate messages
6. Device rotation during QR scanning → should maintain proper layout