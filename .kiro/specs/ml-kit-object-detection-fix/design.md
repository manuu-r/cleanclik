# Design Document

## Overview

The pickup detection system failure is caused by a complete breakdown in hand coordinate mapping from MediaPipe's 3D coordinate system to Flutter's 2D screen coordinates. All hand positions are incorrectly mapped to (0,0), causing proximity calculations to fail and preventing any pickup interactions. This design addresses the coordinate transformation pipeline and ensures accurate hand-object distance calculations.

## Architecture

### Current Broken Flow
```
MediaPipe Hand Detection → 3D Landmarks → [BROKEN MAPPING] → (0,0) Screen Coords → Wrong Distances → Ignore Zone → No Pickup
```

### Fixed Flow
```
MediaPipe Hand Detection → 3D Landmarks → Coordinate Transformation → Valid Screen Coords → Accurate Distances → Proximity Zones → Pickup Detection
```

### Key Components

1. **Hand Coordinate Transformer**: Converts MediaPipe 3D coordinates to Flutter 2D screen coordinates
2. **Coordinate Validator**: Ensures mapped coordinates are valid and within screen bounds
3. **Proximity Calculator**: Uses correct coordinates to determine hand-object distances
4. **Debug Logger**: Provides detailed coordinate transformation debugging

## Components and Interfaces

### HandCoordinateTransformer

```dart
class HandCoordinateTransformer {
  /// Transform MediaPipe 3D hand landmarks to Flutter 2D screen coordinates
  Offset transformHandCenter(List<Landmark> landmarks, Size screenSize, Size imageSize);
  
  /// Validate that coordinates are within valid screen bounds
  bool validateCoordinates(Offset coordinates, Size screenSize);
  
  /// Calculate hand center from palm landmarks
  Offset calculateHandCenter(List<Landmark> landmarks);
  
  /// Apply camera/screen transformation matrix
  Offset applyTransformation(Offset rawCoords, Size screenSize, Size imageSize);
}
```

### CoordinateDebugger

```dart
class CoordinateDebugger {
  /// Log raw MediaPipe landmark data
  void logRawLandmarks(List<Landmark> landmarks);
  
  /// Log coordinate transformation steps
  void logTransformationSteps(Offset raw, Offset transformed, Size screenSize);
  
  /// Log validation results
  void logValidationResult(Offset coordinates, bool isValid, String reason);
  
  /// Log proximity calculation details
  void logProximityCalculation(Offset handPos, Offset objectPos, double distance);
}
```

### Enhanced PickupService

```dart
class PickupService {
  final HandCoordinateTransformer _transformer;
  final CoordinateDebugger _debugger;
  
  /// Process frame with coordinate validation
  void processFrame(List<DetectedObject> objects, List<HandLandmarks> hands);
  
  /// Analyze proximity with validated coordinates
  ProximityAnalysis analyzeProximity(Offset handPos, DetectedObject object);
  
  /// Skip analysis for invalid coordinates
  void skipInvalidCoordinates(String handId, String reason);
}
```

## Data Models

### CoordinateTransformationResult

```dart
class CoordinateTransformationResult {
  final Offset screenCoordinates;
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic> debugInfo;
  
  const CoordinateTransformationResult({
    required this.screenCoordinates,
    required this.isValid,
    this.errorMessage,
    required this.debugInfo,
  });
}
```

### ProximityZoneConfig

```dart
class ProximityZoneConfig {
  static const double nearThreshold = 80.0;    // Pickup ready zone
  static const double closeThreshold = 120.0;  // Targeting zone  
  static const double farThreshold = 180.0;    // Detection range
  static const double ignoreThreshold = 300.0; // Beyond interaction range
}
```

## Error Handling

### Coordinate Mapping Failures

1. **Invalid Landmark Data**: Skip frame and log detailed landmark information
2. **Transformation Errors**: Use fallback coordinate estimation or skip analysis
3. **Out-of-Bounds Coordinates**: Clamp to screen bounds or mark as invalid
4. **Zero Coordinates (0,0)**: Detect and log as coordinate mapping failure

### Fallback Strategies

1. **Previous Frame Coordinates**: Use last valid hand position with decay
2. **Estimated Coordinates**: Calculate approximate position from object interaction history
3. **Graceful Degradation**: Continue object detection without pickup analysis
4. **User Feedback**: Provide visual indication when coordinate mapping fails

## Testing Strategy

### Unit Tests

1. **Coordinate Transformation**:
   - Test MediaPipe to Flutter coordinate conversion
   - Verify screen bounds validation
   - Test edge cases (negative coords, out-of-bounds)

2. **Proximity Calculation**:
   - Test distance calculations with valid coordinates
   - Verify proximity zone classification
   - Test multiple object scenarios

3. **Error Handling**:
   - Test invalid coordinate detection
   - Verify fallback mechanisms
   - Test logging and debugging output

### Integration Tests

1. **End-to-End Coordinate Flow**:
   - MediaPipe detection → Coordinate transformation → Proximity analysis
   - Multiple hands and objects scenarios
   - Real device testing with actual camera input

2. **Performance Testing**:
   - Coordinate transformation latency
   - Memory usage during coordinate processing
   - Frame rate impact of enhanced logging

### Debug Testing

1. **Coordinate Validation**:
   - Log coordinate transformation pipeline
   - Verify screen coordinate accuracy
   - Test coordinate stability across frames

2. **Visual Debugging**:
   - Overlay hand coordinates on camera view
   - Show proximity zones and distances
   - Display coordinate transformation debug info

## Implementation Plan

### Phase 1: Coordinate Transformation Fix
1. Implement HandCoordinateTransformer with proper MediaPipe to Flutter mapping
2. Add coordinate validation and bounds checking
3. Integrate transformer into existing PickupService
4. Add comprehensive coordinate debugging

### Phase 2: Proximity System Enhancement
1. Update proximity calculations to use validated coordinates
2. Implement proper proximity zone classification
3. Add targeting mode activation logic
4. Test proximity detection with multiple objects

### Phase 3: Pickup Detection Restoration
1. Enable pickup evaluation logic with working coordinates
2. Implement targeting duration and stability checks
3. Add pickup success detection and feedback
4. Test complete pickup interaction flow

### Phase 4: Performance and Polish
1. Optimize coordinate transformation performance
2. Reduce debug logging overhead in production
3. Add user-facing coordinate mapping status
4. Implement coordinate mapping health monitoring

## Coordinate Transformation Details

### MediaPipe to Flutter Mapping

MediaPipe provides normalized coordinates (0.0-1.0) that need transformation:

```dart
// MediaPipe landmark coordinates are normalized (0.0-1.0)
// Flutter screen coordinates are in pixels
Offset transformCoordinate(Landmark landmark, Size screenSize, Size imageSize) {
  // Account for camera image vs screen size differences
  final scaleX = screenSize.width / imageSize.width;
  final scaleY = screenSize.height / imageSize.height;
  
  // Transform normalized coordinates to screen pixels
  final screenX = landmark.x * imageSize.width * scaleX;
  final screenY = landmark.y * imageSize.height * scaleY;
  
  return Offset(screenX, screenY);
}
```

### Hand Center Calculation

Calculate hand center from palm landmarks for consistent positioning:

```dart
Offset calculateHandCenter(List<Landmark> landmarks) {
  // Use palm landmarks (0, 5, 9, 13, 17) for stable center calculation
  final palmLandmarks = [0, 5, 9, 13, 17];
  double sumX = 0, sumY = 0;
  
  for (int index in palmLandmarks) {
    sumX += landmarks[index].x;
    sumY += landmarks[index].y;
  }
  
  return Offset(sumX / palmLandmarks.length, sumY / palmLandmarks.length);
}
```

### Coordinate Validation

Ensure coordinates are valid and within expected ranges:

```dart
bool validateCoordinates(Offset coords, Size screenSize) {
  return coords.dx >= 0 && 
         coords.dx <= screenSize.width &&
         coords.dy >= 0 && 
         coords.dy <= screenSize.height &&
         coords != Offset.zero;
}
```

This design addresses the root cause of pickup detection failure by fixing the coordinate transformation pipeline and ensuring accurate hand-object distance calculations.