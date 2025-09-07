# Requirements Document

## Introduction

This spec addresses critical issues with the QR scanner functionality in VibeSweep. Currently, there are two major problems: 1) The QR scanner button on the home screen incorrectly navigates to the AR camera in object detection mode instead of QR scanning mode, and 2) The QR scanner overlay crashes the app due to improper widget positioning within the widget tree.

## Requirements

### Requirement 1: Fix Home Screen QR Scanner Navigation

**User Story:** As a user, I want to click the "Scan Bin QR Code" button on the home screen and be taken directly to QR scanning mode, so that I can immediately scan bin QR codes without having to manually switch modes.

#### Acceptance Criteria

1. WHEN the user clicks the "Scan Bin QR Code" button on the home screen THEN the system SHALL navigate to the camera screen with QR scanning mode automatically activated
2. WHEN the camera screen loads from the QR scanner button THEN the system SHALL immediately display the QR scanner overlay without requiring additional user interaction
3. WHEN the QR scanner is activated from the home screen THEN the system SHALL disable object detection and hand tracking to prevent conflicts
4. WHEN the user navigates via the QR scanner button THEN the system SHALL provide visual feedback that QR scanning mode is active

### Requirement 2: Fix QR Scanner Overlay Widget Positioning

**User Story:** As a user, I want the QR scanner overlay to display properly without crashing the app, so that I can successfully scan QR codes.

#### Acceptance Criteria

1. WHEN the QR scanner overlay is displayed THEN the system SHALL render all positioned widgets within proper parent containers
2. WHEN the scan line animation is shown THEN the system SHALL ensure the Positioned widget is within a Stack parent
3. WHEN the QR scanner overlay is mounted THEN the system SHALL not throw "Incorrect use of ParentDataWidget" exceptions
4. WHEN switching between AR mode and QR mode THEN the system SHALL properly dispose of camera resources to prevent conflicts
5. WHEN the QR scanner is closed THEN the system SHALL cleanly return to the previous camera state without errors

### Requirement 3: Improve Camera Resource Management

**User Story:** As a user, I want smooth transitions between AR detection mode and QR scanning mode, so that the app doesn't crash or freeze when switching between modes.

#### Acceptance Criteria

1. WHEN switching from AR mode to QR mode THEN the system SHALL properly pause the AR camera stream before initializing QR scanner
2. WHEN switching from QR mode to AR mode THEN the system SHALL properly dispose of QR scanner resources before resuming AR detection
3. WHEN camera permission conflicts occur THEN the system SHALL handle them gracefully with appropriate error messages
4. WHEN the user rapidly switches between modes THEN the system SHALL prevent race conditions and resource conflicts
5. WHEN camera initialization fails THEN the system SHALL provide clear error messages and recovery options