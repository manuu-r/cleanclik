# Design Document

## Overview

This design outlines a comprehensive reorganization of the CleanClik Flutter project from a flat file structure to a feature-based, domain-driven architecture. The reorganization will group related services and widgets by functional domain while maintaining clean architecture principles and ensuring zero code modification during the move process.

## Architecture

### Current Structure Analysis
- **Services**: 50+ services in a single flat directory without categorization
- **Widgets**: 35+ widgets mostly in a flat directory with minimal organization
- **Screens**: Already well-organized by feature (auth, camera, debug, leaderboard, map, profile)

### Target Architecture
```
lib/
├── core/
│   ├── services/
│   │   ├── auth/              # Authentication & user management
│   │   ├── camera/            # Camera, AR, ML detection
│   │   ├── data/              # Database, storage, sync
│   │   ├── location/          # GPS, mapping, proximity
│   │   ├── social/            # Sharing, leaderboards, achievements
│   │   ├── platform/          # Platform-specific implementations
│   │   └── system/            # Core system services (logging, performance)
│   └── [existing core directories remain unchanged]
└── presentation/
    ├── widgets/
    │   ├── camera/            # AR camera related widgets
    │   ├── map/               # Map and location widgets
    │   ├── inventory/         # Inventory and object widgets
    │   ├── social/            # Social and sharing widgets
    │   ├── overlays/          # All overlay widgets
    │   ├── animations/        # Animation widgets
    │   ├── debug/             # Debug and diagnostic widgets
    │   └── common/            # Shared/reusable widgets
    └── [screens remain unchanged - already well organized]
```

## Components and Interfaces

### Service Organization Strategy

#### Authentication Services (`lib/core/services/auth/`)
- `user_service.dart` + `user_service.g.dart`
- `user_database_service.dart`
- `token_service.dart` + `token_service.g.dart`
- `supabase_config_service.dart`

#### Camera & AR Services (`lib/core/services/camera/`)
- `camera_resource_manager.dart`
- `ml_detection_service.dart`
- `disposal_detection_service.dart`
- `qr_camera_controller.dart`
- `qr_bin_service.dart`
- `integrated_ml_detection.dart` (if service-related)
- `integrated_qr_scanner.dart` (if service-related)

#### Data Services (`lib/core/services/data/`)
- `database_service.dart`
- `database_service_provider.dart` + `database_service_provider.g.dart`
- `local_storage_service.dart` + `local_storage_service.g.dart`
- `sync_service.dart` + `sync_service.g.dart`
- `data_migration_service.dart` + `data_migration_service.g.dart`
- `inventory_database_service.dart`
- `achievement_database_service.dart`
- `category_stats_database_service.dart`
- `leaderboard_database_service.dart`

#### Location Services (`lib/core/services/location/`)
- `location_service.dart`
- `bin_location_service.dart`
- `bin_matching_service.dart`
- `map_data_service.dart`

#### Social Services (`lib/core/services/social/`)
- `social_sharing_service.dart`
- `social_card_generation_service.dart`
- `card_renderer.dart`
- `leaderboard_service.dart` + `leaderboard_service.g.dart`
- `deep_link_service.dart` + `deep_link_service.g.dart`

#### Platform Services (`lib/core/services/platform/`)
- `platform_hand_tracking_factory.dart`
- `android_hand_tracking_service.dart`
- `ios_hand_tracking_service.dart`
- `platform_optimizer.dart`
- `enhanced_gesture_recognition_service.dart`
- `hand_tracking_service.dart`
- `hand_coordinate_transformer.dart`

#### System Services (`lib/core/services/system/`)
- `logging_service.dart`
- `performance_service.dart`
- `haptic_service.dart`
- `sound_service.dart`
- `ui_context_service.dart`

#### Business Logic Services (`lib/core/services/business/`)
- `inventory_service.dart` + `inventory_service.g.dart`
- `object_management_service.dart`
- `smart_suggestions_service.dart`
- `motivational_message_service.dart`

### Widget Organization Strategy

#### Camera Widgets (`lib/presentation/widgets/camera/`)
- `enhanced_object_overlay.dart`
- `qr_scanner_overlay.dart`
- `integrated_ml_detection.dart` (if widget-related)
- `integrated_qr_scanner.dart` (if widget-related)
- `hand_skeleton_painter.dart`
- `coordinate_debug_widget.dart`
- `coordinate_diagnostic_overlay.dart`

#### Map Widgets (`lib/presentation/widgets/map/`)
- `bin_marker.dart`
- `friend_marker.dart`
- `hotspot_marker.dart`
- `mission_marker.dart`
- `layer_toggle.dart`
- `layer_toggle_column.dart`

#### Inventory Widgets (`lib/presentation/widgets/inventory/`)
- `detail_card.dart`
- `smart_suggestion_card.dart`
- `smart_suggestions_overlay.dart`

#### Social Widgets (`lib/presentation/widgets/social/`)
- `achievement_card_widget.dart`
- `floating_share_overlay.dart`

#### Overlay Widgets (`lib/presentation/widgets/overlays/`)
- `bin_feedback_overlay.dart`
- `bin_match_feedback_widget.dart`
- `disposal_celebration_overlay.dart`
- `disposal_confirmation_dialog.dart`
- `high_priority_overlay.dart`
- `debug_overlay_widget.dart`

#### Animation Widgets (`lib/presentation/widgets/animations/`)
- `breathing_widget.dart`
- `morphing_icon.dart`
- `particle_system.dart`
- `progress_ring.dart`

#### Common Widgets (`lib/presentation/widgets/common/`)
- `app_card.dart` (already exists)
- `glassmorphism_container.dart`
- `neon_icon_button.dart`
- `floating_action_hub.dart`
- `slide_up_panel.dart`
- `manual_sync_button.dart`
- `sync_status_indicator.dart`

## Data Models

### File Movement Tracking
```dart
class FileMovement {
  final String originalPath;
  final String newPath;
  final String category;
  final String reason;
}
```

### Organization Categories
```dart
enum ServiceCategory {
  auth,
  camera,
  data,
  location,
  social,
  platform,
  system,
  business
}

enum WidgetCategory {
  camera,
  map,
  inventory,
  social,
  overlays,
  animations,
  common
}
```

## Error Handling

### File Movement Safety
- Validate source file exists before attempting move
- Ensure target directory exists before moving files
- Handle file system permissions gracefully
- Provide rollback capability if moves fail
- Log all file movements for audit trail

### Import Preservation
- Maintain exact file contents during moves
- Do not modify any import statements during reorganization
- Preserve all existing functionality exactly as-is
- Document any files that may need import updates post-reorganization

## Testing Strategy

### Pre-Move Validation
- Verify all source files exist and are readable
- Confirm target directory structure can be created
- Test file system permissions for all operations

### Post-Move Verification
- Confirm all files moved to correct locations
- Verify file contents remain unchanged
- Ensure no files were lost or corrupted during moves
- Validate directory structure matches design

### Rollback Testing
- Test ability to revert all file movements
- Verify rollback restores original structure exactly
- Confirm no data loss during rollback operations

## Implementation Phases

### Phase 1: Service Organization
1. Create new service directory structure
2. Move services to appropriate domain directories
3. Verify all services moved correctly

### Phase 2: Widget Organization  
1. Create new widget directory structure
2. Move widgets to appropriate feature directories
3. Verify all widgets moved correctly

### Phase 3: Validation
1. Run comprehensive verification checks
2. Document any import statements that will need updating
3. Provide summary of reorganization changes