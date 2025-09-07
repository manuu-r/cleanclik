# Design Document

## Overview

This design implements a two-part solution: (1) filtering out hand detections from ML Kit object detection to prevent false positives, and (2) simplifying the waste categorization system by removing landfill and mapping the five available ML Kit categories directly to four waste types. The solution focuses on improving detection accuracy while simplifying the user experience.

## Architecture

### Current Flow
```
ML Kit Object Detection → All Objects (including hands) → 5 Waste Categories → Complex Categorization
```

### Enhanced Flow
```
ML Kit Object Detection → Hand Filtering → Valid Objects Only → 4 Waste Categories → Simplified Categorization
```

### Key Components

1. **Object Filter Service**: Filters out hand-like objects from ML Kit detections
2. **Waste Category Mapper**: Maps ML Kit categories to simplified waste types
3. **Hand Detection Coordinator**: Coordinates between MediaPipe hand tracking and object filtering
4. **Enhanced AR Detection Service**: Integrates filtering and simplified categorization

## Components and Interfaces

### ObjectFilterService

```dart
class ObjectFilterService {
  /// Filter out hand-like objects from ML Kit detections
  List<DetectedObject> filterHandObjects(
    List<DetectedObject> objects, 
    List<HandLandmarks> handLandmarks,
    Size screenSize
  );
  
  /// Check if an object overlaps with detected hands
  bool isObjectNearHand(DetectedObject object, List<HandLandmarks> hands, Size screenSize);
  
  /// Determine if object characteristics suggest it's a hand
  bool isLikelyHandObject(DetectedObject object);
  
  /// Calculate overlap between object bounding box and hand region
  double calculateHandObjectOverlap(Rect objectBounds, Offset handCenter, double handRadius);
}
```

### WasteCategoryMapper

```dart
class WasteCategoryMapper {
  /// Map ML Kit object categories to simplified waste types
  static const Map<String, WasteCategory> categoryMapping = {
    'FASHION_GOOD': WasteCategory.recycle,
    'FOOD': WasteCategory.organic,
    'HOME_GOOD': WasteCategory.recycle,
    'PLANT': WasteCategory.organic,
    // Note: PLACE items are excluded as they are not waste
  };
  
  /// Get waste category for ML Kit detection
  WasteCategory getWasteCategory(String mlKitCategory);
  
  /// Get all supported ML Kit categories
  List<String> getSupportedCategories();
  
  /// Validate category mapping configuration
  bool validateCategoryMapping();
}
```

### HandDetectionCoordinator

```dart
class HandDetectionCoordinator {
  /// Coordinate hand tracking with object filtering
  FilteringContext createFilteringContext(List<HandLandmarks> hands, Size screenSize);
  
  /// Calculate hand exclusion zones for object filtering
  List<Rect> calculateHandExclusionZones(List<HandLandmarks> hands, Size screenSize);
  
  /// Transform hand landmarks to screen coordinates for filtering
  List<Offset> getHandCenters(List<HandLandmarks> hands, Size screenSize);
}
```

## Data Models

### FilteringContext

```dart
class FilteringContext {
  final List<Offset> handCenters;
  final List<Rect> exclusionZones;
  final Size screenSize;
  final double handRadius;
  
  const FilteringContext({
    required this.handCenters,
    required this.exclusionZones,
    required this.screenSize,
    this.handRadius = 100.0, // Default hand exclusion radius
  });
}
```

### FilteringResult

```dart
class FilteringResult {
  final List<DetectedObject> validObjects;
  final List<DetectedObject> filteredObjects;
  final int handFilterCount;
  final Map<String, dynamic> debugInfo;
  
  const FilteringResult({
    required this.validObjects,
    required this.filteredObjects,
    required this.handFilterCount,
    required this.debugInfo,
  });
}
```

### Simplified WasteCategory Enum

```dart
enum WasteCategory {
  recycle,   // FASHION_GOOD, HOME_GOOD
  organic,   // FOOD, PLANT
  ewaste,    // (future expansion)
  hazardous, // (future expansion)
}

extension WasteCategoryExtension on WasteCategory {
  String get displayName {
    switch (this) {
      case WasteCategory.recycle:
        return 'Recycle';
      case WasteCategory.organic:
        return 'Organic';
      case WasteCategory.ewaste:
        return 'E-Waste';
      case WasteCategory.hazardous:
        return 'Hazardous';
    }
  }
  
  Color get color {
    switch (this) {
      case WasteCategory.recycle:
        return Colors.blue;
      case WasteCategory.organic:
        return Colors.green;
      case WasteCategory.ewaste:
        return Colors.orange;
      case WasteCategory.hazardous:
        return Colors.red;
    }
  }
}
```

## Error Handling

### Hand Filtering Failures

1. **Missing Hand Data**: Continue with object detection without hand filtering
2. **Coordinate Transformation Errors**: Use fallback filtering based on object characteristics
3. **Performance Degradation**: Implement adaptive filtering complexity based on frame rate
4. **False Positive Filtering**: Provide manual override mechanism for incorrectly filtered objects

### Category Mapping Issues

1. **Unknown ML Kit Categories**: Default to recycle category with logging
2. **Invalid Category Data**: Skip object with error logging
3. **Mapping Configuration Errors**: Use hardcoded fallback mapping
4. **Category Update Conflicts**: Maintain backward compatibility for existing inventory

## Testing Strategy

### Unit Tests

1. **Object Filtering**:
   - Test hand-object overlap detection
   - Verify filtering accuracy with various hand positions
   - Test performance with multiple hands and objects

2. **Category Mapping**:
   - Test all ML Kit category mappings
   - Verify unknown category handling
   - Test mapping consistency

3. **Coordinate Transformation**:
   - Test hand landmark to screen coordinate conversion
   - Verify exclusion zone calculations
   - Test edge cases (hands at screen edges)

### Integration Tests

1. **End-to-End Filtering**:
   - ML Kit detection → Hand filtering → Category mapping
   - Real camera input with hands and objects
   - Performance testing with filtering enabled

2. **AR Experience Testing**:
   - Verify filtered objects appear correctly in AR overlay
   - Test simplified categorization display
   - Validate user interaction with filtered objects

### Performance Testing

1. **Filtering Overhead**:
   - Measure frame rate impact of hand filtering
   - Test memory usage during filtering operations
   - Benchmark filtering with varying numbers of objects and hands

2. **Categorization Performance**:
   - Measure category mapping speed
   - Test simplified categorization impact on overall performance
   - Validate reduced complexity benefits

## Implementation Details

### Hand Filtering Algorithm

```dart
bool isObjectNearHand(DetectedObject object, List<HandLandmarks> hands, Size screenSize) {
  final objectCenter = object.boundingBox.center;
  
  for (final hand in hands) {
    final handCenter = transformHandCenter(hand.landmarks, screenSize);
    final distance = (objectCenter - handCenter).distance;
    
    // Filter objects within hand radius
    if (distance < handExclusionRadius) {
      return true;
    }
    
    // Additional filtering based on object size and confidence
    if (distance < handExclusionRadius * 1.5 && 
        object.confidence < handLikeConfidenceThreshold) {
      return true;
    }
  }
  
  return false;
}
```

### Category Mapping Implementation

```dart
WasteCategory? getWasteCategory(String mlKitCategory) {
  // Check if category should be ignored
  if (FilteringConfig.ignoredCategories.contains(mlKitCategory)) {
    return null; // Ignore non-waste items like PLACE
  }
  
  final category = WasteCategoryMapper.categoryMapping[mlKitCategory];
  
  if (category == null) {
    // Log unknown category and default to recycle
    _logger.warning('Unknown ML Kit category: $mlKitCategory, defaulting to recycle');
    return WasteCategory.recycle;
  }
  
  return category;
}
```

### Configuration Parameters

```dart
class FilteringConfig {
  static const double handExclusionRadius = 100.0; // pixels
  static const double handLikeConfidenceThreshold = 0.6;
  static const double overlapThreshold = 0.3; // 30% overlap
  static const int maxHandsToProcess = 4; // Performance limit
  
  // Category mapping validation
  static const List<String> supportedMLKitCategories = [
    'FASHION_GOOD',
    'FOOD', 
    'HOME_GOOD',
    'PLANT',
  ];
  
  // Categories to ignore (not waste)
  static const List<String> ignoredCategories = [
    'PLACE',
  ];
}
```

### Enhanced AR Detection Service Integration

```dart
class ARDetectionService {
  final ObjectFilterService _filterService;
  final WasteCategoryMapper _categoryMapper;
  final HandDetectionCoordinator _coordinator;
  
  Future<List<CategorizedObject>> processFrame(
    CameraImage image,
    List<HandLandmarks> hands,
  ) async {
    // Get ML Kit object detections
    final rawObjects = await _mlKitService.detectObjects(image);
    
    // Create filtering context from hand data
    final filteringContext = _coordinator.createFilteringContext(hands, image.size);
    
    // Filter out hand-like objects
    final filteredObjects = _filterService.filterHandObjects(
      rawObjects, 
      hands, 
      image.size,
    );
    
    // Apply simplified categorization and filter out non-waste items
    final categorizedObjects = filteredObjects
        .map((object) {
          final wasteCategory = _categoryMapper.getWasteCategory(object.category);
          if (wasteCategory == null) {
            return null; // Skip non-waste items like PLACE
          }
          return CategorizedObject(
            detectedObject: object,
            wasteCategory: wasteCategory,
            timestamp: DateTime.now(),
          );
        })
        .where((obj) => obj != null)
        .cast<CategorizedObject>()
        .toList();
    
    return categorizedObjects;
  }
}
```

This design provides a clean separation between hand filtering and category mapping while maintaining performance and accuracy. The simplified categorization system reduces user cognitive load while the hand filtering improves detection quality.