# Requirements Document

## Introduction

The CleanClik app currently uses demo authentication and local storage (SharedPreferences) which prevents scalability, security, and multi-device synchronization. This feature will migrate the entire backend infrastructure to Supabase, providing real user authentication, persistent cloud storage, and secure data management. The migration will replace hardcoded demo users with proper authentication flows and transform local data storage into cloud-based database operations with Row-Level Security.

## Requirements

### Requirement 1

**User Story:** As a user, I want to create a real account with email/password or social login, so that my progress and data are securely stored and accessible across devices.

#### Acceptance Criteria

1. WHEN a user opens the app for the first time THEN the system SHALL present authentication screens (login/signup)
2. WHEN a user provides valid email/password credentials THEN the system SHALL authenticate them via Supabase Auth
3. WHEN a user chooses social login (Google) THEN the system SHALL authenticate them via the selected provider through Supabase
4. WHEN authentication succeeds THEN the system SHALL store secure tokens using Flutter Secure Storage
5. WHEN authentication fails THEN the system SHALL display appropriate error messages
6. WHEN a user is authenticated THEN the system SHALL maintain their session across app restarts

### Requirement 2

**User Story:** As a user, I want my inventory, achievements, and progress to be permanently stored in the cloud, so that I never lose my data and can access it from any device.

#### Acceptance Criteria

1. WHEN a user adds items to inventory THEN the system SHALL store them in Supabase database tables
2. WHEN a user earns achievements THEN the system SHALL persist them to the achievements table
3. WHEN a user's data is updated THEN the system SHALL synchronize changes to Supabase in real-time
4. WHEN a user logs in from a different device THEN the system SHALL retrieve their complete profile and progress
5. WHEN network connectivity is lost THEN the system SHALL queue operations for later synchronization
6. WHEN data conflicts occur THEN the system SHALL resolve them using server-side timestamps

### Requirement 3

**User Story:** As a developer, I want all user data protected by Row-Level Security policies, so that users can only access their own data and the system meets security compliance standards.

#### Acceptance Criteria

1. WHEN database tables are created THEN the system SHALL enable Row-Level Security (RLS) on all user data tables
2. WHEN a user queries their data THEN the system SHALL only return records they own via RLS policies
3. WHEN a user attempts to access another user's data THEN the system SHALL deny access through RLS enforcement
4. WHEN authentication tokens expire THEN the system SHALL automatically refresh them using secure refresh tokens
5. WHEN sensitive configuration is needed THEN the system SHALL load it from environment variables, not hardcoded values
6. WHEN the app is built for production THEN the system SHALL obfuscate code and exclude development credentials

### Requirement 4

**User Story:** As a user, I want to see leaderboards and compete with other users, so that I can compare my environmental impact with the community.

#### Acceptance Criteria

1. WHEN a user views leaderboards THEN the system SHALL fetch rankings from Supabase with proper aggregation
2. WHEN a user earns points THEN the system SHALL update their leaderboard position in real-time
3. WHEN leaderboard data is displayed THEN the system SHALL show anonymized usernames and scores only
4. WHEN multiple users have the same score THEN the system SHALL rank them by timestamp
5. WHEN leaderboard queries are made THEN the system SHALL implement pagination for performance
6. WHEN a user opts out of leaderboards THEN the system SHALL respect their privacy preference

### Requirement 5

**User Story:** As a system administrator, I want comprehensive database schema with proper relationships and constraints, so that data integrity is maintained and the system can scale efficiently.

#### Acceptance Criteria

1. WHEN the database is initialized THEN the system SHALL create tables for users, inventory, achievements, leaderboard, and bin_locations
2. WHEN foreign key relationships exist THEN the system SHALL enforce referential integrity through database constraints
3. WHEN data is inserted THEN the system SHALL validate it against schema constraints and data types
4. WHEN tables are queried THEN the system SHALL use proper indexes for performance optimization
5. WHEN schema changes are needed THEN the system SHALL support migrations without data loss
6. WHEN backup and recovery is required THEN the system SHALL leverage Supabase's built-in backup capabilities

### Requirement 6

**User Story:** As a developer, I want all existing services refactored to use Supabase instead of local storage, so that the codebase is consistent and maintainable.

#### Acceptance Criteria

1. WHEN UserService is refactored THEN it SHALL remove all demo user logic and use Supabase Auth
2. WHEN InventoryService is updated THEN it SHALL replace SharedPreferences with Supabase database operations
3. WHEN LeaderboardService is modified THEN it SHALL fetch data from Supabase tables with proper queries
4. WHEN services make database calls THEN they SHALL handle errors gracefully with retry logic
5. WHEN authentication state changes THEN all services SHALL react appropriately to login/logout events
6. WHEN services are initialized THEN they SHALL verify Supabase connection and authentication status

### Requirement 7

**User Story:** As a user, I want secure credential management and token handling, so that my account cannot be compromised and my data remains protected.

#### Acceptance Criteria

1. WHEN tokens are stored THEN the system SHALL use Flutter Secure Storage, not SharedPreferences
2. WHEN access tokens expire THEN the system SHALL automatically refresh them using refresh tokens
3. WHEN refresh tokens expire THEN the system SHALL prompt for re-authentication
4. WHEN the app starts THEN the system SHALL validate stored tokens and refresh if necessary
5. WHEN a user logs out THEN the system SHALL clear all stored tokens and session data
6. WHEN network requests are made THEN the system SHALL include valid authentication headers

### Requirement 8

**User Story:** As a developer, I want proper environment configuration and secrets management, so that the application can be deployed securely across different environments.

#### Acceptance Criteria

1. WHEN Supabase client is initialized THEN it SHALL load URL and keys from environment variables
2. WHEN the app is built THEN it SHALL exclude .env files from version control
3. WHEN environment variables are missing THEN the system SHALL provide clear error messages
4. WHEN different environments are used THEN the system SHALL support dev, staging, and production configurations
5. WHEN secrets are needed THEN the system SHALL never hardcode them in source code
6. WHEN configuration changes THEN the system SHALL support hot-reload in development mode