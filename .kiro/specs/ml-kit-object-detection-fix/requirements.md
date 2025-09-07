# Requirements Document

## Introduction

The VibeSweep app's pickup detection system is completely non-functional due to a critical hand coordinate mapping failure. Comprehensive log analysis reveals that hand tracking detects hands correctly (85% confidence, 21 landmarks) but ALL hand coordinates are mapped to (0,0), causing 100% of proximity calculations to fail. This results in zero targeting events and zero pickup evaluations. The core issue is in the coordinate transformation from 3D hand landmarks to 2D screen coordinates.

## Requirements

### Requirement 1

**User Story:** As a VibeSweep user, I want the hand coordinate mapping to work correctly, so that the pickup detection system can function at all.

#### Acceptance Criteria

1. WHEN hands are detected with valid landmarks THEN the system SHALL map hand center coordinates to valid screen positions (not 0,0)
2. WHEN hand landmarks are processed THEN the system SHALL correctly transform 3D MediaPipe coordinates to 2D Flutter screen coordinates
3. WHEN coordinate mapping fails THEN the system SHALL log detailed debugging information about the transformation process
4. WHEN invalid coordinates (0,0) are detected THEN the system SHALL skip pickup analysis and log the coordinate mapping failure

### Requirement 2

**User Story:** As a VibeSweep user, I want proximity detection to work with correct hand coordinates, so that objects can enter targeting mode.

#### Acceptance Criteria

1. WHEN hand coordinates are valid THEN the system SHALL calculate accurate distances to objects
2. WHEN hands are within 180px of objects THEN the system SHALL classify them in appropriate proximity zones (near, close, far)
3. WHEN hands are within 80px of objects THEN the system SHALL enter "near" zone and enable targeting mode
4. WHEN proximity zones are calculated THEN the system SHALL use consistent coordinate systems for hands and objects

### Requirement 3

**User Story:** As a VibeSweep user, I want targeting mode to activate when my hand approaches objects, so that pickup detection can begin.

#### Acceptance Criteria

1. WHEN hands enter the "near" or "close" proximity zone THEN the system SHALL activate targeting mode
2. WHEN targeting mode is active THEN the system SHALL begin pickup evaluation logic
3. WHEN targeting duration exceeds minimum thresholds THEN the system SHALL proceed with pickup analysis
4. WHEN targeting mode activates THEN the system SHALL log the transition and provide visual feedback

### Requirement 4

**User Story:** As a VibeSweep user, I want pickup evaluation to occur when targeting conditions are met, so that successful pickups can be detected.

#### Acceptance Criteria

1. WHEN targeting mode is active AND grasp confidence is high THEN the system SHALL evaluate pickup conditions
2. WHEN pickup evaluation runs THEN the system SHALL check timing, stability, and confidence requirements
3. WHEN all pickup conditions are met THEN the system SHALL trigger successful pickup detection
4. WHEN pickup evaluation occurs THEN the system SHALL log detailed analysis including all decision factors

### Requirement 5

**User Story:** As a developer, I want comprehensive debugging for the coordinate transformation pipeline, so that I can diagnose and fix mapping issues.

#### Acceptance Criteria

1. WHEN hand landmarks are received THEN the system SHALL log raw MediaPipe coordinate data
2. WHEN coordinate transformation occurs THEN the system SHALL log intermediate transformation steps
3. WHEN screen coordinates are calculated THEN the system SHALL validate coordinates are within screen bounds
4. WHEN coordinate mapping fails THEN the system SHALL provide specific error messages about the failure cause

### Requirement 6

**User Story:** As a VibeSweep user, I want the pickup system to handle multiple objects correctly after coordinate mapping is fixed, so that I can interact with the intended object.

#### Acceptance Criteria

1. WHEN multiple objects are present THEN the system SHALL calculate distances to each object using the same valid hand coordinates
2. WHEN multiple objects are in proximity THEN the system SHALL prioritize the closest object for pickup analysis
3. WHEN hand coordinates are valid THEN the system SHALL analyze each object independently without coordinate confusion
4. WHEN objects are at different distances THEN the system SHALL correctly classify each into appropriate proximity zones

### Requirement 7

**User Story:** As a VibeSweep user, I want responsive pickup detection after the coordinate mapping is fixed, so that interactions feel natural and immediate.

#### Acceptance Criteria

1. WHEN coordinate mapping works correctly THEN the system SHALL achieve sub-200ms pickup detection latency
2. WHEN proximity zones are accurate THEN the system SHALL provide immediate visual feedback for targeting
3. WHEN pickup conditions are met THEN the system SHALL trigger pickup without unnecessary delays
4. WHEN the coordinate system is fixed THEN the system SHALL maintain stable performance across all interaction scenarios