# Requirements Document

## Introduction

This specification outlines the requirements for implementing a comprehensive testing strategy for the CleanClik Flutter app. Based on the actual codebase analysis, CleanClik is a Supabase-powered waste management app with AR object detection, QR bin scanning, inventory management, leaderboards, and social features. The testing suite will ensure reliability across authentication, camera/ML detection, inventory management, location services, and social features.

## Requirements

### Requirement 1

**User Story:** As a developer, I want comprehensive unit tests for all core services, so that I can ensure business logic reliability and catch regressions early in the Supabase-integrated app.

#### Acceptance Criteria

1. WHEN AuthService methods are executed THEN the system SHALL have tests for Supabase authentication, Google Sign-In, and demo mode functionality
2. WHEN MLDetectionService processes camera frames THEN the system SHALL have tests for Google ML Kit object detection and tracking
3. WHEN InventoryService manages items THEN the system SHALL have tests for local storage, Supabase sync, and item lifecycle
4. WHEN LocationService handles GPS data THEN the system SHALL have tests for bin proximity detection and geofencing
5. WHEN LeaderboardService processes scores THEN the system SHALL have tests for Supabase database operations and ranking calculations

### Requirement 2

**User Story:** As a developer, I want widget tests for all screen components, so that I can ensure proper rendering and navigation behavior in the GoRouter-based app.

#### Acceptance Criteria

1. WHEN ARCameraScreen is rendered THEN the system SHALL have tests for camera initialization, ML detection UI, and QR scanning modes
2. WHEN MapScreen displays bin locations THEN the system SHALL have tests for Google Maps integration and location markers
3. WHEN ProfileScreen shows user data THEN the system SHALL have tests for Supabase user profile display and editing
4. WHEN LeaderboardScreen displays rankings THEN the system SHALL have tests for real-time leaderboard updates and social features
5. WHEN AuthWrapper protects routes THEN the system SHALL have tests for authentication state management and route protection

### Requirement 3

**User Story:** As a developer, I want integration tests for critical user flows, so that I can ensure end-to-end functionality works correctly with Supabase backend.

#### Acceptance Criteria

1. WHEN users complete authentication flow THEN the system SHALL have tests for Supabase login, Google Sign-In, email verification, and demo mode
2. WHEN users scan objects with camera THEN the system SHALL have tests for ML detection, QR bin scanning, and inventory addition
3. WHEN users manage inventory THEN the system SHALL have tests for local storage, Supabase synchronization, and offline functionality
4. WHEN users interact with map THEN the system SHALL have tests for bin location display, proximity detection, and disposal workflow
5. WHEN users view leaderboards THEN the system SHALL have tests for real-time score updates and social sharing features

### Requirement 4

**User Story:** As a developer, I want performance tests for camera and ML features, so that I can ensure the app meets the specified latency requirements.

#### Acceptance Criteria

1. WHEN ML object detection processes frames THEN the system SHALL verify processing time is under 100ms per frame
2. WHEN camera switches between QR and ML modes THEN the system SHALL verify mode switching latency is under 200ms
3. WHEN multiple objects are detected THEN the system SHALL verify tracking performance with up to 10 simultaneous objects
4. WHEN inventory syncs with Supabase THEN the system SHALL verify sync operations complete within 5 seconds
5. WHEN memory usage is monitored THEN the system SHALL verify no memory leaks during extended camera sessions

### Requirement 5

**User Story:** As a developer, I want mock data and test fixtures, so that I can run tests consistently without Supabase dependencies.

#### Acceptance Criteria

1. WHEN tests require authentication THEN the system SHALL provide mock Supabase auth states and Google Sign-In responses
2. WHEN tests require ML detection THEN the system SHALL provide mock Google ML Kit detection results for various object categories
3. WHEN tests require inventory data THEN the system SHALL provide mock InventoryItem objects with proper Supabase schema
4. WHEN tests require location data THEN the system SHALL provide mock GPS coordinates and bin location data
5. WHEN tests require leaderboard data THEN the system SHALL provide mock user rankings and achievement data

### Requirement 6

**User Story:** As a developer, I want automated test execution in CI/CD, so that I can ensure code quality is maintained across all commits with proper Riverpod provider testing.

#### Acceptance Criteria

1. WHEN code is committed THEN the system SHALL automatically run unit tests for all Riverpod providers and services
2. WHEN pull requests are created THEN the system SHALL run widget tests for all screens and navigation flows
3. WHEN tests fail THEN the system SHALL prevent merging and provide detailed failure information with Supabase connection status
4. WHEN Riverpod code generation changes THEN the system SHALL verify generated files are up to date
5. WHEN integration tests run THEN the system SHALL use mock Supabase instances to avoid external dependencies

### Requirement 7

**User Story:** As a developer, I want test coverage reporting, so that I can identify untested code areas and maintain quality standards for the Flutter/Supabase architecture.

#### Acceptance Criteria

1. WHEN tests are executed THEN the system SHALL generate coverage reports excluding generated Riverpod files (.g.dart)
2. WHEN coverage reports are generated THEN the system SHALL require 85% minimum coverage for service classes
3. WHEN new Riverpod providers are added THEN the system SHALL verify they have corresponding unit tests
4. WHEN Supabase integration code is modified THEN the system SHALL ensure 90%+ test coverage for database operations
5. WHEN camera/ML code is changed THEN the system SHALL ensure 80%+ test coverage for performance-critical paths

### Requirement 8

**User Story:** As a developer, I want golden tests for UI consistency, so that I can detect unintended visual changes across Material 3 theme updates.

#### Acceptance Criteria

1. WHEN key screens are rendered THEN the system SHALL capture golden files for ARCameraScreen, MapScreen, ProfileScreen, and LeaderboardScreen
2. WHEN Material 3 theme changes THEN the system SHALL detect visual differences in light and dark modes
3. WHEN different device sizes are tested THEN the system SHALL verify responsive design for phone and tablet layouts
4. WHEN AR overlay components render THEN the system SHALL verify visual consistency of detection indicators and object labels
5. WHEN navigation shell updates THEN the system SHALL verify bottom navigation and route transitions remain consistent