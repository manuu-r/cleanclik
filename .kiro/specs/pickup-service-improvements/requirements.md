# Pickup Service Improvements - Requirements Document

## Introduction

The current pickup service has several critical issues preventing objects from being properly detected, picked up, and added to the user's inventory. This spec addresses the core problems: ML Kit object detection configuration, overly strict pickup thresholds, and missing integration with the inventory service.

## Requirements

### Requirement 1: ML Kit Object Detection Reliability

**User Story:** As a user, I want the app to consistently detect objects in my camera view, so that I can interact with them for pickup.

#### Acceptance Criteria

1. WHEN the camera is active THEN the system SHALL detect common objects (bottles, cans, food items) with >70% confidence
2. WHEN objects are present in the camera view THEN the system SHALL log detection results every frame for debugging
3. WHEN ML Kit fails to detect objects THEN the system SHALL provide fallback detection mechanisms
4. WHEN detection confidence is low THEN the system SHALL still track objects but with lower pickup thresholds

### Requirement 2: Simplified Pickup Detection

**User Story:** As a user, I want to easily pick up detected objects with simple hand gestures, so that I can add them to my inventory without complex interactions.

#### Acceptance Criteria

1. WHEN my hand is near an object (within 100px) THEN the system SHALL consider it for pickup
2. WHEN I make a simple grasp gesture THEN the system SHALL trigger pickup within 500ms
3. WHEN pickup conditions are met for 3 consecutive frames THEN the system SHALL automatically pick up the object
4. WHEN an object is picked up THEN the system SHALL provide immediate visual and audio feedback

### Requirement 3: Inventory Integration

**User Story:** As a user, I want picked up objects to automatically appear in my inventory, so that I can track what I'm carrying and dispose of items properly.

#### Acceptance Criteria

1. WHEN an object is picked up THEN the system SHALL automatically add it to the user's inventory
2. WHEN an item is added to inventory THEN the system SHALL update the inventory count in real-time
3. WHEN inventory is updated THEN the system SHALL persist changes to local storage immediately
4. WHEN the app restarts THEN the system SHALL restore the previous inventory state

### Requirement 4: Debug and Monitoring Capabilities

**User Story:** As a developer, I want comprehensive logging and debug information, so that I can troubleshoot pickup detection issues effectively.

#### Acceptance Criteria

1. WHEN objects are detected THEN the system SHALL log detailed detection information
2. WHEN pickup analysis runs THEN the system SHALL log confidence scores and thresholds
3. WHEN inventory changes occur THEN the system SHALL log the specific changes made
4. WHEN errors occur THEN the system SHALL provide clear error messages and recovery suggestions

### Requirement 5: Performance Optimization

**User Story:** As a user, I want the pickup detection to run smoothly without affecting app performance, so that I have a responsive AR experience.

#### Acceptance Criteria

1. WHEN processing frames THEN the system SHALL complete pickup analysis within 50ms per frame
2. WHEN multiple objects are detected THEN the system SHALL prioritize closest objects for analysis
3. WHEN hands are not detected THEN the system SHALL skip expensive grasp calculations
4. WHEN memory usage is high THEN the system SHALL clean up old object states automatically