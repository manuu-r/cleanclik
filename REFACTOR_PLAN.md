# Camera-First UX Refactor Plan
## CleanClik → Single-View Gamified Experience

> **Goal**: Transform CleanClik from a multi-screen app into a unified camera-driven experience with XP/Levels, micro-loops, and overlay-based interactions.

**Created**: 2025-11-15
**Estimated Timeline**: 3-4 weeks (full implementation)
**Complexity**: HIGH - Major architectural refactor

---

## 📋 Executive Summary

### Current State
- **Navigation**: 3-tab bottom navigation (Home, Map, Profile)
- **Progression**: Points-based system with calculated levels
- **Interactions**: Full-screen transitions for most actions
- **Camera**: One screen among many

### Target State
- **Navigation**: Single camera view with slide-in panels
- **Progression**: XP-based leveling with visible progress bars
- **Interactions**: Bottom sheets and floating overlays for all actions
- **Camera**: Primary persistent view, always visible

---

## 🎯 Core Objectives

1. ✅ **Single Persistent Camera View** - Camera never disappears
2. ✅ **XP & Level System** - Replace points with XP, add level progression
3. ✅ **Micro-Loop Interactions** - Quick, rewarding action loops
4. ✅ **Overlay-Based UI** - Bottom sheets instead of full screens
5. ✅ **Visual Feedback** - Progress bars, badges, streaks, haptics
6. ✅ **Reduced Friction** - 2-3 taps max for any action

---

## 📐 Architecture Overview

### New UI Hierarchy

```
CameraView (Persistent, Always Visible)
├── AR Detection Overlay (on camera feed)
├── Top HUD
│   ├── XP Progress Bar (always visible)
│   ├── Level Badge
│   └── Streak Counter
├── Floating Action Buttons (context-aware)
│   ├── Scan Mode Toggle (QR/ML)
│   ├── Quick Actions
│   └── Settings
└── Dynamic Bottom Sheets (slide up on demand)
    ├── Pickup Confirmation Sheet
    ├── Bin Scan Result Sheet
    ├── XP Reward Animation Sheet
    ├── Map Panel (slide from right)
    ├── Profile Panel (slide from left)
    └── Inventory Panel (slide from bottom)
```

### Camera States & Overlays

| State | Visual Cue | Bottom Sheet | Actions |
|-------|-----------|--------------|---------|
| **Idle** | Scanning prompt | None | Detect trash, switch mode |
| **Object Detected** | Bounding box + glow | None | Tap to confirm pickup |
| **Pickup Confirmed** | Pulse animation | XP Reward Sheet | Add to inventory |
| **QR Mode** | QR frame overlay | None | Scan bin QR code |
| **Bin Detected** | Bin info card | Disposal Options Sheet | Dispose items |
| **XP Gained** | +XP animation | Level Up Sheet (if leveled) | Continue |
| **Map View** | Dimmed camera | Map Slide Panel | View bins, close |
| **Profile View** | Dimmed camera | Profile Slide Panel | View stats, close |

---

## 🎮 XP & Level System Design

### Data Model Changes

#### New: `XPSystem` Model

```dart
class XPSystem {
  final int currentXP;
  final int level;
  final int xpForNextLevel;
  final double progressToNextLevel; // 0.0 to 1.0
  final int totalXPEarned;
  final int currentStreak; // Days active
  final DateTime lastActiveDate;

  // XP sources
  final Map<XPSource, int> xpBreakdown;
}

enum XPSource {
  trashDetected,    // +10 XP
  trashPickedUp,    // +25 XP
  binScanned,       // +15 XP
  properDisposal,   // +50 XP
  dailyStreak,      // +20 XP/day
  missionComplete,  // +100 XP
  categoryMaster,   // +75 XP (10 items in one category)
}
```

#### Updated: `User` Model

```dart
class User {
  // Existing fields...
  final int totalPoints;  // DEPRECATED - keep for migration
  final int level;        // DEPRECATED - keep for migration

  // New XP system
  final XPSystem xpSystem;
  final List<Badge> unlockedBadges;
  final List<Streak> activeStreaks;
  final int longestStreak;

  // New fields
  final DateTime? lastXPGain;
  final Map<String, dynamic> gamificationMetadata;
}
```

#### New: `Badge` Model

```dart
class Badge {
  final String id;
  final String title;
  final String description;
  final BadgeRarity rarity;
  final String iconPath;
  final DateTime unlockedAt;
  final BadgeCategory category;
}

enum BadgeRarity { bronze, silver, gold, platinum, diamond }
enum BadgeCategory { pickup, disposal, streak, mission, special }
```

### XP Calculation Formula

```dart
// Level progression: Exponential curve
int xpForLevel(int level) {
  return (100 * pow(1.5, level - 1)).round();
}

// Level 1→2: 100 XP
// Level 2→3: 150 XP
// Level 3→4: 225 XP
// Level 4→5: 338 XP
// Level 5→6: 507 XP
// Level 10: ~3,800 XP
// Level 20: ~330,000 XP
```

### XP Rewards Table

| Action | Base XP | Multipliers | Max XP |
|--------|---------|-------------|--------|
| Detect trash | 10 XP | Streak: 1.5x | 15 XP |
| Pick up trash | 25 XP | Streak: 1.5x, First of day: 2x | 75 XP |
| Scan bin QR | 15 XP | - | 15 XP |
| Dispose correctly | 50 XP | Category match: 1.2x, Streak: 1.5x | 90 XP |
| Daily login | 20 XP | Streak: Day × 5 XP | 100 XP |
| Complete mission | 100 XP | - | 100 XP |

---

## 🔄 Micro-Loop Design

### Primary Loop: Trash Pickup (2-3 taps)

```
1. CAMERA IDLE
   ↓ (ML Detection auto-triggers)
2. OBJECT DETECTED
   └→ Visual: Glowing outline + "Tap to pick up" prompt
   ↓ (User taps object)
3. PICKUP CONFIRMATION SHEET (slides up 30% screen)
   └→ Shows: Item preview, Category, XP reward preview
   └→ Actions: "Pick Up" (primary) | "Skip" (secondary)
   ↓ (User taps "Pick Up")
4. XP REWARD ANIMATION (2s)
   └→ Visual: +25 XP flies to top bar
   └→ Haptic: Light impact
   └→ Audio: Satisfying "ding" (optional)
   └→ Progress bar fills smoothly
   ↓ (Auto-dismiss or user swipes down)
5. BACK TO IDLE
   └→ Item added to inventory (background)
   └→ Camera resumes scanning
```

**Total time**: 3-5 seconds
**Total taps**: 2 (tap object + tap confirm)

### Secondary Loop: Bin Disposal (3-4 taps)

```
1. CAMERA IN QR MODE
   ↓ (User scans bin QR)
2. BIN DETECTED SHEET (slides up 40% screen)
   └→ Shows: Bin type, Compatible items count, Disposal options
   └→ Actions: "View Items" | "Dispose All" | "Cancel"
   ↓ (User taps "Dispose All")
3. DISPOSAL CONFIRMATION SHEET (replaces previous)
   └→ Shows: Items list, XP calculation (+50 XP × items)
   └→ Actions: "Confirm Disposal" (primary) | "Back"
   ↓ (User confirms)
4. XP CELEBRATION ANIMATION (3s)
   └→ Visual: Larger +XP animation, particle effects
   └→ Haptic: Medium impact
   └→ Shows: Total XP gained, items disposed
   └→ Level up modal (if applicable)
   ↓ (Auto-dismiss after 3s or swipe down)
5. BACK TO CAMERA
```

**Total time**: 5-8 seconds
**Total taps**: 3 (scan + dispose + confirm)

---

## 🎨 UI Components Breakdown

### Phase 1: Core Camera HUD

#### 1.1 Top HUD Bar
**File**: `lib/presentation/widgets/camera/camera_hud.dart`

```dart
class CameraHUD extends StatelessWidget {
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            LevelBadge(level: user.xpSystem.level),
            SizedBox(width: 12),
            Expanded(
              child: XPProgressBar(
                currentXP: user.xpSystem.currentXP,
                maxXP: user.xpSystem.xpForNextLevel,
                progress: user.xpSystem.progressToNextLevel,
              ),
            ),
            SizedBox(width: 12),
            StreakCounter(streak: user.xpSystem.currentStreak),
          ],
        ),
      ),
    );
  }
}
```

**Components**:
- `LevelBadge` - Circular badge with level number, gradient border
- `XPProgressBar` - Animated horizontal bar with fill animation
- `StreakCounter` - Fire icon + number (7-day streak)

#### 1.2 XP Progress Bar Widget
**File**: `lib/presentation/widgets/animations/xp_progress_bar.dart`

**Features**:
- Smooth fill animation (300ms ease-out)
- Glow effect when near completion
- Pulse animation on XP gain
- Color gradient based on level tier

#### 1.3 Floating Context Actions
**File**: `lib/presentation/widgets/camera/context_actions.dart`

**Dynamic Actions** (based on camera state):
- Idle: [Switch to QR Mode] [Open Inventory]
- Object Detected: [Confirm Pickup] [Skip]
- QR Mode: [Switch to ML Mode] [Help]

### Phase 2: Bottom Sheet Library

#### 2.1 Base Bottom Sheet Component
**File**: `lib/presentation/widgets/overlays/base_bottom_sheet.dart`

```dart
class BaseBottomSheet extends StatelessWidget {
  final Widget content;
  final double heightPercentage; // 0.3, 0.5, 0.7, 0.9
  final bool isDismissible;
  final VoidCallback? onDismiss;

  // Drag handle, glassmorphism, rounded corners
}
```

**Variants**:
- `QuickActionSheet` - 30% height, quick confirm/cancel
- `DetailSheet` - 50% height, more info + actions
- `FullSheet` - 90% height, extensive content (inventory)

#### 2.2 Pickup Confirmation Sheet
**File**: `lib/presentation/widgets/overlays/pickup_confirmation_sheet.dart`

**Content**:
- Item image preview (from detection)
- Detected category with icon
- XP reward preview (+25 XP)
- "Pick Up" button (primary, full-width)
- "Skip" text button (secondary)

#### 2.3 XP Reward Sheet
**File**: `lib/presentation/widgets/overlays/xp_reward_sheet.dart`

**Animations**:
1. Sheet slides up (200ms)
2. XP number counts up (500ms)
3. Progress bar fills (300ms)
4. If level up: Confetti explosion + "Level Up!" banner
5. Auto-dismiss after 2s (or user swipes down)

**Content**:
- Large "+{amount} XP" text
- XP source label ("Trash Picked Up!")
- Progress bar update visualization
- Level up banner (conditional)

#### 2.4 Disposal Options Sheet
**File**: `lib/presentation/widgets/overlays/disposal_options_sheet.dart`

**Content**:
- Bin information (type, location, fill level)
- Compatible items from inventory (filtered by category)
- XP calculation preview
- "Dispose All" button
- "Select Items" button (opens item selector)

### Phase 3: Slide-In Panels

#### 3.1 Map Slide Panel
**File**: `lib/presentation/widgets/panels/map_slide_panel.dart`

**Behavior**:
- Slides from RIGHT edge
- Covers 80% of screen width
- Camera view dimmed (opacity 0.3) behind it
- Swipe right to dismiss
- Shows map with bins (existing map screen content)

**Trigger**: Tap "Nearby Bins" FAB

#### 3.2 Profile Slide Panel
**File**: `lib/presentation/widgets/panels/profile_slide_panel.dart`

**Behavior**:
- Slides from LEFT edge
- Covers 80% of screen width
- Shows user stats, badges, achievements
- Swipe left to dismiss

**Trigger**: Tap profile icon in HUD

#### 3.3 Inventory Slide Panel
**File**: `lib/presentation/widgets/panels/inventory_slide_panel.dart`

**Behavior**:
- Slides from BOTTOM
- Covers 70% of screen height
- Shows inventory items grouped by category
- Swipe down to dismiss

**Trigger**: Tap "Inventory" FAB

---

## 🔧 Service Layer Changes

### Phase 4: XP Service

#### 4.1 XP Service
**File**: `lib/core/services/business/xp_service.dart`

```dart
@Riverpod(keepAlive: true)
class XPService extends _$XPService {
  @override
  XPService build() {
    return this;
  }

  /// Award XP for an action
  Future<XPReward> awardXP(XPSource source, {Map<String, dynamic>? metadata}) async {
    final user = await ref.read(currentUserProvider.future);

    // Calculate base XP
    int baseXP = _getBaseXP(source);

    // Apply multipliers
    double multiplier = _calculateMultiplier(user, source, metadata);

    int finalXP = (baseXP * multiplier).round();

    // Update user XP
    final newXP = user.xpSystem.currentXP + finalXP;
    final levelUp = _checkLevelUp(newXP, user.xpSystem.level);

    // Save to database
    await _saveXPGain(user.id, finalXP, source);

    // Broadcast event
    _eventController.add(XPGainEvent(
      xpGained: finalXP,
      source: source,
      levelUp: levelUp,
    ));

    return XPReward(
      xpGained: finalXP,
      newTotalXP: newXP,
      leveledUp: levelUp != null,
      newLevel: levelUp?.newLevel,
    );
  }

  /// Check for daily streak
  Future<void> checkDailyStreak() async {
    // Award streak XP if eligible
  }

  /// Calculate XP for next level
  int xpForLevel(int level) {
    return (100 * pow(1.5, level - 1)).round();
  }
}
```

#### 4.2 Badge Service
**File**: `lib/core/services/business/badge_service.dart`

```dart
class BadgeService {
  /// Check if user unlocked any new badges
  Future<List<Badge>> checkBadgeUnlocks(User user) async {
    // Check conditions for each badge
    // Return newly unlocked badges
  }

  /// Award badge to user
  Future<void> awardBadge(String userId, Badge badge) async {
    // Save to database
    // Trigger badge unlock animation
  }
}
```

### Phase 5: Integration Changes

#### 5.1 Update Inventory Service
**File**: `lib/core/services/business/inventory_service.dart`

**Changes**:
```dart
Future<void> addItemFromDetectedObject(DetectedObject object) async {
  // Existing inventory logic...

  // NEW: Award XP for pickup
  final xpService = ref.read(xpServiceProvider);
  await xpService.awardXP(
    XPSource.trashPickedUp,
    metadata: {'category': object.category.name},
  );
}
```

#### 5.2 Update Disposal Service
**File**: `lib/core/services/camera/disposal_handling_service.dart`

**Changes**:
```dart
Future<void> disposeItems(List<InventoryItem> items, BinLocation bin) async {
  // Existing disposal logic...

  // NEW: Award XP for proper disposal
  final xpService = ref.read(xpServiceProvider);
  for (final item in items) {
    final correctCategory = item.category == bin.category;
    await xpService.awardXP(
      XPSource.properDisposal,
      metadata: {
        'correctCategory': correctCategory,
        'itemCount': items.length,
      },
    );
  }
}
```

---

## 🗄️ Data Model Changes

### Database Schema Updates

#### New Table: `xp_transactions`
```sql
CREATE TABLE xp_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  xp_amount INT NOT NULL,
  xp_source VARCHAR(50) NOT NULL,
  multiplier DECIMAL(3,2) DEFAULT 1.0,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_xp_transactions_user_id ON xp_transactions(user_id);
CREATE INDEX idx_xp_transactions_created_at ON xp_transactions(created_at);
```

#### New Table: `user_badges`
```sql
CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  badge_id VARCHAR(50) NOT NULL,
  unlocked_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);
```

#### Update Table: `users`
```sql
ALTER TABLE users
ADD COLUMN current_xp INT DEFAULT 0,
ADD COLUMN total_xp_earned INT DEFAULT 0,
ADD COLUMN current_streak INT DEFAULT 0,
ADD COLUMN longest_streak INT DEFAULT 0,
ADD COLUMN last_active_date DATE,
ADD COLUMN xp_level INT DEFAULT 1;

-- Keep total_points and level for migration
```

### Migration Strategy

#### Step 1: Data Migration Script
**File**: `database/migrations/001_add_xp_system.sql`

```sql
-- Migrate existing points to XP (1 point = 10 XP)
UPDATE users
SET current_xp = total_points * 10,
    total_xp_earned = total_points * 10,
    xp_level = level;

-- Initialize streak data
UPDATE users
SET current_streak = 1,
    last_active_date = CURRENT_DATE;
```

#### Step 2: App Migration Code
**File**: `lib/core/services/data/data_migration_service.dart`

```dart
class DataMigrationService {
  Future<void> migrateToXPSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('xp_migration_v1') ?? false;

    if (migrated) return;

    // Migrate local user data
    final user = await _loadLocalUser();
    if (user != null) {
      final migratedUser = user.copyWith(
        xpSystem: XPSystem(
          currentXP: user.totalPoints * 10,
          level: user.level,
          totalXPEarned: user.totalPoints * 10,
          currentStreak: 1,
          lastActiveDate: DateTime.now(),
        ),
      );
      await _saveLocalUser(migratedUser);
    }

    await prefs.setBool('xp_migration_v1', true);
  }
}
```

---

## 📱 Navigation Refactor

### Remove Bottom Tab Navigation

#### Before: `ar_navigation_shell.dart`
```dart
// 3-tab navigation: Home | Map | Profile
StatefulNavigationShell with bottom nav bar
```

#### After: Single Camera Screen
**File**: `lib/presentation/screens/camera/unified_camera_screen.dart`

```dart
class UnifiedCameraScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Camera view (persistent)
          ARCameraView(),

          // 2. Top HUD (XP bar, level, streak)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CameraHUD(),
          ),

          // 3. Floating action buttons (context-aware)
          Positioned(
            bottom: 32,
            right: 16,
            child: ContextActionButtons(),
          ),

          // 4. Dynamic bottom sheets (conditional)
          if (_showPickupSheet)
            PickupConfirmationSheet(...),

          if (_showXPReward)
            XPRewardSheet(...),

          // 5. Slide panels (conditional)
          if (_showMapPanel)
            MapSlidePanel(
              onClose: () => setState(() => _showMapPanel = false),
            ),

          if (_showProfilePanel)
            ProfileSlidePanel(
              onClose: () => setState(() => _showProfilePanel = false),
            ),
        ],
      ),
    );
  }
}
```

### Routing Changes

#### Update: `lib/core/routing/app_router.dart`

```dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => UnifiedCameraScreen(), // NEW: Single screen
    ),
    // Auth routes remain the same
    GoRoute(path: '/login', ...),
    GoRoute(path: '/signup', ...),

    // REMOVED: /home, /map, /profile routes
  ],
);
```

---

## 🎬 Animation & Feedback

### Haptic Feedback Strategy

| Action | Haptic Type | Duration |
|--------|-------------|----------|
| Object detected | Light | 10ms |
| Pickup confirmed | Medium | 30ms |
| XP gained | Light | 10ms |
| Level up | Heavy | 100ms + pattern |
| Bin scanned | Medium | 30ms |
| Badge unlocked | Heavy | 100ms |

**File**: `lib/core/utils/haptics_util.dart`

```dart
class HapticsUtil {
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> levelUpPattern() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
```

### Visual Feedback Animations

#### XP Gain Animation
**File**: `lib/presentation/widgets/animations/xp_gain_animation.dart`

1. **+XP Text** appears at tap location
2. **Flies up** to top HUD (curved path, 600ms)
3. **Progress bar** fills smoothly (300ms)
4. **Glow effect** on progress bar (200ms)
5. If level up: **Confetti explosion** + **Level badge spin**

#### Level Up Animation
**File**: `lib/presentation/widgets/animations/level_up_animation.dart`

1. **Screen flash** (white overlay, 100ms)
2. **Level badge** scales up 1.5x and spins (500ms)
3. **Confetti particles** explode from badge (1s)
4. **"LEVEL UP!"** banner slides in from top (300ms)
5. **New level number** counts up with sound effect

---

## 📊 Testing Strategy

### Unit Tests

#### XP Service Tests
**File**: `test/unit/xp_service_test.dart`

```dart
test('should award correct base XP for trash pickup', () async {
  final reward = await xpService.awardXP(XPSource.trashPickedUp);
  expect(reward.xpGained, 25);
});

test('should apply streak multiplier correctly', () async {
  // User with 5-day streak
  final reward = await xpService.awardXP(
    XPSource.trashPickedUp,
    metadata: {'streak': 5},
  );
  expect(reward.xpGained, 38); // 25 * 1.5
});

test('should trigger level up when XP threshold reached', () async {
  // User at 95 XP, level 1 (needs 100 for level 2)
  final reward = await xpService.awardXP(XPSource.trashPickedUp); // +25
  expect(reward.leveledUp, true);
  expect(reward.newLevel, 2);
});
```

### Widget Tests

#### Camera HUD Tests
**File**: `test/widget/camera_hud_test.dart`

```dart
testWidgets('should display XP progress bar with correct fill', (tester) async {
  await tester.pumpWidget(
    CameraHUD(xp: 50, maxXP: 100, level: 3),
  );

  final progressBar = find.byType(XPProgressBar);
  expect(progressBar, findsOneWidget);

  final widget = tester.widget<XPProgressBar>(progressBar);
  expect(widget.progress, 0.5);
});
```

### Integration Tests

#### Pickup Flow Test
**File**: `test/integration/pickup_xp_flow_test.dart`

```dart
testWidgets('complete pickup flow awards XP and updates UI', (tester) async {
  // 1. Detect object
  // 2. Tap to confirm pickup
  // 3. Verify XP animation
  // 4. Verify progress bar update
  // 5. Verify inventory updated
});
```

---

## 📅 Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Set up XP system backend and data models

- [ ] Create `XPSystem`, `Badge`, `Streak` models
- [ ] Create `xp_service.dart` with core XP logic
- [ ] Create database migration scripts
- [ ] Update `User` model with XP fields
- [ ] Write unit tests for XP calculations
- [ ] Implement data migration service

**Deliverable**: XP system functional in backend, testable via unit tests

### Phase 2: Camera HUD (Week 1-2)
**Goal**: Build persistent camera UI with XP indicators

- [ ] Create `CameraHUD` widget
- [ ] Build `XPProgressBar` with animations
- [ ] Build `LevelBadge` component
- [ ] Build `StreakCounter` component
- [ ] Create `XPGainAnimation` widget
- [ ] Add haptic feedback utilities
- [ ] Wire up to XP service providers

**Deliverable**: Top HUD displays live XP/level/streak data

### Phase 3: Bottom Sheets (Week 2)
**Goal**: Replace full-screen transitions with bottom sheets

- [ ] Create `BaseBottomSheet` component
- [ ] Build `PickupConfirmationSheet`
- [ ] Build `XPRewardSheet` with animations
- [ ] Build `DisposalOptionsSheet`
- [ ] Build `LevelUpSheet` celebration
- [ ] Add swipe-to-dismiss gestures
- [ ] Test on various screen sizes

**Deliverable**: All micro-interactions use bottom sheets

### Phase 4: Slide Panels (Week 2-3)
**Goal**: Convert Map and Profile to slide-in panels

- [ ] Create `MapSlidePanel` (slides from right)
- [ ] Create `ProfileSlidePanel` (slides from left)
- [ ] Create `InventorySlidePanel` (slides from bottom)
- [ ] Add dimming overlay for camera background
- [ ] Add swipe gestures to dismiss
- [ ] Migrate Map screen content to panel
- [ ] Migrate Profile screen content to panel

**Deliverable**: Map and Profile accessible as overlays

### Phase 5: Navigation Refactor (Week 3)
**Goal**: Remove bottom tabs, single camera screen

- [ ] Create `UnifiedCameraScreen` as main screen
- [ ] Remove `ARNavigationShell` bottom tabs
- [ ] Update router to use single camera route
- [ ] Add context-aware floating action buttons
- [ ] Migrate Home screen quick actions to FABs
- [ ] Update deep link handling
- [ ] Test navigation flows

**Deliverable**: Single-screen app with overlay navigation

### Phase 6: Integration & Polish (Week 3-4)
**Goal**: Wire everything together, animations, UX polish

- [ ] Integrate XP service with inventory service
- [ ] Integrate XP service with disposal service
- [ ] Add XP rewards to all user actions
- [ ] Implement daily streak checking
- [ ] Add badge unlock checks
- [ ] Polish all animations (timing, curves)
- [ ] Add sound effects (optional)
- [ ] Comprehensive testing (integration tests)
- [ ] Performance optimization (60 FPS target)

**Deliverable**: Fully functional camera-first UX

### Phase 7: Migration & Deployment (Week 4)
**Goal**: Safe rollout with data migration

- [ ] Run database migrations
- [ ] Test data migration with production data clone
- [ ] Add feature flag for gradual rollout
- [ ] Update onboarding to explain new UX
- [ ] Create migration guide for existing users
- [ ] Monitor XP system balance (too easy/hard?)
- [ ] Gather user feedback
- [ ] Iterate based on feedback

**Deliverable**: Production-ready camera-first app

---

## 🚨 Risk Assessment

### High Risk Items

1. **Performance**: Camera + overlays + animations may impact FPS
   - **Mitigation**: Profile with Flutter DevTools, optimize renders, use `const` widgets

2. **User Confusion**: Removing familiar navigation may confuse existing users
   - **Mitigation**: Add brief tutorial overlay on first launch, clear visual cues

3. **XP Balance**: Too easy → boring, too hard → frustrating
   - **Mitigation**: Start conservative, monitor metrics, adjust multipliers

4. **Data Migration**: Points → XP conversion may cause issues
   - **Mitigation**: Thorough testing, rollback plan, keep old data for 30 days

### Medium Risk Items

1. **Battery Drain**: Persistent camera may drain battery faster
   - **Mitigation**: Optimize camera processing, allow pause mode

2. **Gesture Conflicts**: Swipe gestures may conflict with camera controls
   - **Mitigation**: Use distinct swipe directions, clear drag handles

3. **Screen Size Variance**: Bottom sheets may look odd on tablets/small phones
   - **Mitigation**: Responsive sizing, test on multiple devices

---

## 📏 Success Metrics

### KPIs to Track

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Session Duration | ? | +30% | Analytics |
| Actions per Session | ? | +50% | Event tracking |
| User Retention (7-day) | ? | +20% | Cohort analysis |
| XP Gain Rate | N/A | 200-300 XP/session | Database query |
| Level Progression | N/A | Level 2 in 3 sessions | User analytics |
| Bottom Sheet Conversion | N/A | >80% completion | Funnel analysis |

### A/B Testing Plan

**Test**: Old navigation vs. new camera-first UX

- **Group A** (Control): Current bottom tab navigation
- **Group B** (Treatment): New camera-first UX
- **Duration**: 2 weeks
- **Sample Size**: 1000 users per group
- **Metrics**: Engagement, retention, actions/session

---

## 🛠️ Development Checklist

### Code Quality

- [ ] All new services have `@riverpod` providers
- [ ] All models have `fromJson`, `toJson`, `fromSupabase`, `toSupabase`
- [ ] All widgets have `const` constructors where possible
- [ ] All animations use `AnimationController` with proper disposal
- [ ] All bottom sheets are dismissible (swipe or tap outside)
- [ ] All XP calculations are unit tested
- [ ] All UI components have widget tests
- [ ] Integration tests cover critical paths

### Documentation

- [ ] Update CLAUDE.md with XP system architecture
- [ ] Document XP calculation formulas
- [ ] Document badge unlock conditions
- [ ] Add inline comments for complex XP logic
- [ ] Create user-facing changelog
- [ ] Update README with new UX description

### Accessibility

- [ ] All interactive elements have semantic labels
- [ ] XP progress bar has accessible description
- [ ] Bottom sheets have focus management
- [ ] Haptics can be disabled in settings
- [ ] Color contrast meets WCAG AA standards

---

## 🔄 Rollback Plan

If new UX causes critical issues:

1. **Feature Flag**: Toggle off camera-first UX via remote config
2. **Fallback Route**: Restore old `ARNavigationShell` in router
3. **Data Preservation**: Keep XP data but display as points (XP/10)
4. **User Communication**: Notify users of temporary revert
5. **Fix & Re-deploy**: Address issues, re-enable in 24-48h

---

## 📝 Open Questions

1. **Points vs XP**: Should we completely remove points or keep both?
   - **Recommendation**: Deprecate points, show XP only (clearer system)

2. **Max Level**: What should be the maximum achievable level?
   - **Recommendation**: No hard cap, exponential scaling naturally limits progression

3. **Badge Icons**: Create custom icons or use Material Icons?
   - **Recommendation**: Start with Material Icons, add custom later

4. **Sound Effects**: Should XP gains have audio feedback?
   - **Recommendation**: Optional, off by default (battery/data concerns)

5. **Offline XP**: Should XP accumulate offline and sync later?
   - **Recommendation**: Yes, queue XP transactions, sync when online

6. **Leaderboards**: Do we add XP-based leaderboards later?
   - **Recommendation**: Phase 8 feature, not MVP

---

## 🎉 Expected Outcomes

### User Experience
- ✅ **Faster task completion** - 2-3 taps instead of 5-7
- ✅ **More engaging** - Visible progress, instant feedback
- ✅ **Less context switching** - Camera always visible
- ✅ **Clearer goals** - XP bar shows exact progress

### Technical Benefits
- ✅ **Simpler navigation** - One main screen instead of three
- ✅ **Better performance** - Fewer full-screen rebuilds
- ✅ **Easier maintenance** - Centralized camera logic
- ✅ **More flexible** - Easy to add new overlay features

### Business Metrics
- ✅ **Higher engagement** - Gamification loop drives usage
- ✅ **Better retention** - Streaks encourage daily use
- ✅ **More actions** - Lower friction increases pickups
- ✅ **Viral potential** - Level/badge sharing features

---

## 📚 References

### Inspiration

- **Pokémon GO**: Persistent AR camera, XP system, streaks
- **Duolingo**: XP progression, streaks, bite-sized interactions
- **Snapchat**: Camera-first UX, overlay-based navigation
- **Instagram**: Bottom sheets for actions, minimal full screens

### Flutter Packages to Consider

- `flutter_slidable` - Swipeable list items
- `sliding_up_panel` - Bottom sheet alternative
- `confetti` - Celebration animations
- `flutter_animate` - Simplified animations
- `vibration` - Enhanced haptic feedback

---

**Last Updated**: 2025-11-15
**Status**: PLANNING PHASE
**Next Step**: Review plan → Start Phase 1 (XP System Backend)
