# Requirements Document

## Introduction

CleanCity Vibe is a mobile AR gamification app that transforms urban cleanliness into an engaging game. Users point their camera at trash to automatically detect and tag items with colored AR overlays based on disposal bin categories. The app tracks users picking up items, highlights correct disposal bins, and provides immediate rewards when trash is properly disposed of. The MVP focuses on real-time AR tracking, social authentication, competitive leaderboards, urban mapping, mission alerts, and social sharing capabilities.

## Requirements

### Requirement 1

**User Story:** As a user, I want to point my camera at trash and see it automatically tagged with colored AR overlays, so that I can quickly identify the correct disposal category.

#### Acceptance Criteria

1. WHEN the user points their camera at trash THEN the system SHALL detect objects in real-time at ≥15fps on mid-range devices
2. WHEN trash is detected THEN the system SHALL display colored AR overlays within 200ms indicating bin category (EcoGems=green, FuelShards=blue, etc.)
3. WHEN multiple items are visible THEN the system SHALL tag them simultaneously with distinct tracking IDs
4. WHEN object detection confidence is below threshold THEN the system SHALL provide LLM-assisted classification hints

### Requirement 2

**User Story:** As a user, I want the app to remember what trash I've picked up, so that it can guide me to the correct disposal bin.

#### Acceptance Criteria

1. WHEN a tagged object leaves the camera frame THEN the system SHALL detect pick-up and update object state to "carrying"
2. WHEN an item is picked up THEN the system SHALL maintain item details (tracking ID, category, timestamp) in user's current session
3. WHEN pick-up is detected THEN the system SHALL provide visual confirmation within 500ms
4. WHEN user has carrying items THEN the system SHALL sync inventory state to Firestore in real-time

### Requirement 3

**User Story:** As a user, I want bins to be highlighted when I approach them with the correct trash, so that I know where to dispose of items properly.

#### Acceptance Criteria

1. WHEN user enters 10m radius of a bin location THEN the system SHALL detect proximity via GPS
2. WHEN user is carrying items AND approaches matching bin category THEN the system SHALL highlight the correct bin with AR overlay
3. WHEN user approaches wrong bin category THEN the system SHALL keep bin unlit to guide proper disposal
4. WHEN bin highlighting is triggered THEN the system SHALL respond within 1 second

### Requirement 4

**User Story:** As a user, I want to receive immediate rewards when I dispose of trash correctly, so that I feel motivated to continue cleaning.

#### Acceptance Criteria

1. WHEN user drops trash in highlighted bin THEN the system SHALL detect disposal via proximity and inventory state change
2. WHEN correct disposal is detected THEN the system SHALL trigger celebration animation (confetti, sound, badge popup) immediately
3. WHEN disposal is validated THEN the system SHALL award points and update wallet within 3 seconds
4. WHEN points are awarded THEN the system SHALL update real-time leaderboard within 30 seconds

### Requirement 5

**User Story:** As a user, I want to sign in with my social accounts, so that my progress is saved and I can compete with others.

#### Acceptance Criteria

1. WHEN user selects social sign-in THEN the system SHALL support Google and Apple authentication
2. WHEN authentication is successful THEN the system SHALL create/update user profile with display name and avatar
3. WHEN user reopens app THEN the system SHALL restore authenticated session automatically
4. WHEN user signs out THEN the system SHALL clear local session data securely

### Requirement 6

**User Story:** As a user, I want to see leaderboards and my ranking, so that I can compete with other users and stay motivated.

#### Acceptance Criteria

1. WHEN user accesses leaderboard THEN the system SHALL load rankings within 500ms
2. WHEN points are awarded to any user THEN the system SHALL update leaderboard rankings within 30 seconds
3. WHEN user's rank changes THEN the system SHALL display smooth animation transitions
4. WHEN leaderboard is displayed THEN the system SHALL show daily, weekly, monthly, and all-time periods

### Requirement 7

**User Story:** As a user, I want to view nearby bins and trash hotspots on a map, so that I can plan my cleanup activities efficiently.

#### Acceptance Criteria

1. WHEN user opens map view THEN the system SHALL display bin markers and hotspot clusters
2. WHEN user taps a bin marker THEN the system SHALL open AR view focused on that location
3. WHEN map is loaded THEN the system SHALL perform smoothly on mid-range devices (Moto G Power equivalent)
4. WHEN hotspots are clustered THEN the system SHALL show aggregated counts and categories

### Requirement 8

**User Story:** As a user, I want to receive mission alerts for time-limited cleanup opportunities, so that I can earn special rewards.

#### Acceptance Criteria

1. WHEN mission becomes available THEN the system SHALL send push notification in all app states
2. WHEN user enters mission radius THEN the system SHALL auto-enroll user and show mission details
3. WHEN mission is completed within time/location constraints THEN the system SHALL grant special badge within 5 seconds
4. WHEN mission expires THEN the system SHALL update user interface and disable participation

### Requirement 9

**User Story:** As a user, I want to share my achievements on social media, so that I can inspire others to participate in city cleanup.

#### Acceptance Criteria

1. WHEN user achieves milestone THEN the system SHALL generate achievement card (1080×1920 px)
2. WHEN user selects share THEN the system SHALL open native share sheet with generated card
3. WHEN card is generated THEN the system SHALL include user stats, badge, and branded design elements
4. WHEN sharing is completed THEN the system SHALL track social engagement metrics

### Requirement 10

**User Story:** As a VibeSweep user, I want the app to accurately map ML Kit object labels to recyclable waste categories, so that I can learn proper recycling habits and earn appropriate points.

#### Acceptance Criteria

1. WHEN ML Kit detects "bottle" or "plastic bottle" labels THEN the system SHALL map them to "recycle" category with at least 80% accuracy
2. WHEN ML Kit detects "can" or "aluminum can" labels THEN the system SHALL map them to "recycle" category with at least 80% accuracy  
3. WHEN ML Kit detects "cardboard" or "box" labels THEN the system SHALL map them to "recycle" category with at least 80% accuracy
4. WHEN ML Kit detects "glass" or "jar" labels THEN the system SHALL map them to "recycle" category with at least 80% accuracy
5. WHEN ML Kit detects "paper" or "newspaper" labels THEN the system SHALL map them to "recycle" category with at least 75% accuracy

### Requirement 11

**User Story:** As a VibeSweep user, I want the app to correctly map ML Kit food and plant labels to organic waste categories, so that I can learn about composting and earn BioShards points.

#### Acceptance Criteria

1. WHEN ML Kit detects "fruit", "apple", "banana" or similar food labels THEN the system SHALL map them to "organic" category with at least 85% accuracy
2. WHEN ML Kit detects "food", "sandwich", "pizza" or meal labels THEN the system SHALL map them to "organic" category with at least 80% accuracy
3. WHEN ML Kit detects "plant", "leaf", "flower" or vegetation labels THEN the system SHALL map them to "organic" category with at least 75% accuracy
4. WHEN ML Kit detects "bread", "cake", "pastry" or baked good labels THEN the system SHALL map them to "organic" category with at least 80% accuracy

### Requirement 12

**User Story:** As a VibeSweep user, I want the app to properly map ML Kit electronic device labels to e-waste categories, so that I can learn about proper e-waste disposal and earn TechCores points.

#### Acceptance Criteria

1. WHEN ML Kit detects "phone", "smartphone", "mobile phone" labels THEN the system SHALL map them to "ewaste" category with at least 90% accuracy
2. WHEN ML Kit detects "computer", "laptop", "tablet" labels THEN the system SHALL map them to "ewaste" category with at least 90% accuracy
3. WHEN ML Kit detects "cable", "charger", "headphone" labels THEN the system SHALL map them to "ewaste" category with at least 80% accuracy
4. WHEN ML Kit detects "camera", "television", "speaker" labels THEN the system SHALL map them to "ewaste" category with at least 80% accuracy

### Requirement 13

**User Story:** As a VibeSweep user, I want the app to map ML Kit hazardous material labels to hazardous waste categories, so that I can learn about safe disposal methods and avoid environmental contamination.

#### Acceptance Criteria

1. WHEN ML Kit detects "battery", "car battery", "lithium battery" labels THEN the system SHALL map them to "hazardous" category with at least 85% accuracy
2. WHEN ML Kit detects "paint", "chemical", "solvent" labels THEN the system SHALL map them to "hazardous" category with at least 80% accuracy
3. WHEN ML Kit detects "cleaner", "bleach", "detergent" labels THEN the system SHALL map them to "hazardous" category with at least 75% accuracy
4. WHEN the camera detects medical waste or pharmaceuticals THEN the system SHALL categorize them as "hazardous" with at least 80% accuracy

### Requirement 14

**User Story:** As a VibeSweep user, I want the app to have intelligent fallback categorization, so that unknown items are properly classified and I don't lose engagement due to poor detection.

#### Acceptance Criteria

1. WHEN the ML Kit confidence is below 30% THEN the system SHALL return null instead of guessing a category
2. WHEN an object cannot be matched to recycle, organic, ewaste, or hazardous categories THEN the system SHALL categorize it as "landfill"
3. WHEN multiple labels are detected for a single object THEN the system SHALL use the highest confidence recyclable category first
4. WHEN processing object labels THEN the system SHALL use fuzzy matching to handle variations in ML Kit label text
5. WHEN categorizing objects THEN the system SHALL log detection details for debugging and improvement

### Requirement 15

**User Story:** As a VibeSweep developer, I want comprehensive keyword mapping and smart label processing, so that the system can handle the variety of labels that ML Kit produces.

#### Acceptance Criteria

1. WHEN processing ML Kit labels THEN the system SHALL use both exact matches and substring matching
2. WHEN multiple keywords match different categories THEN the system SHALL prioritize based on category hierarchy (hazardous > ewaste > recycle > organic > landfill)
3. WHEN processing compound labels like "plastic bottle" THEN the system SHALL extract relevant keywords for accurate categorization
4. WHEN ML Kit provides multiple labels for an object THEN the system SHALL evaluate all labels and choose the most appropriate category
5. WHEN updating keyword mappings THEN the system SHALL maintain backward compatibility with existing detection logic

## Non-functional Requirements

### Performance Requirements

1. WHEN AR camera is active THEN the system SHALL maintain ≥30fps on high-end devices and ≥15fps on mid-range devices
2. WHEN object detection occurs THEN the system SHALL display AR overlays within 200ms of detection
3. WHEN user picks up item THEN the system SHALL recognize action within 500ms
4. WHEN user approaches bin THEN the system SHALL highlight correct bin within 1 second
5. WHEN disposal occurs THEN the system SHALL award points within 3 seconds

### Technical Requirements

1. WHEN app launches THEN the system SHALL require active network connection (no offline support)
2. WHEN data changes occur THEN the system SHALL sync via Firebase real-time listeners
3. WHEN ML processing is needed THEN the system SHALL use ML Kit on-device processing for low latency
4. WHEN AR depth is available THEN the system SHALL use ARCore Depth API for realistic occlusion

### Security Requirements

1. WHEN user authenticates THEN the system SHALL implement OAuth best practices with PKCE
2. WHEN data is accessed THEN the system SHALL enforce Firestore security rules preventing cross-user access
3. WHEN user actions occur THEN the system SHALL implement rate limiting to prevent gaming/abuse
4. WHEN photos are uploaded THEN the system SHALL validate size limits and content

### Compliance Requirements

1. WHEN user data is collected THEN the system SHALL provide GDPR/CCPA-ready data export/delete endpoints
2. WHEN app targets users THEN the system SHALL implement age gating if needed for COPPA compliance
3. WHEN app is published THEN the system SHALL meet App Store policies including Apple Sign-In requirements
4. WHEN content is reported THEN the system SHALL implement moderation and content retention policies