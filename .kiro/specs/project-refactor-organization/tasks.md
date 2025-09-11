# Implementation Plan

- [x] 1. Create complete directory structure and reorganize all services
  - Create service subdirectories: auth, camera, data, location, social, platform, system, business
  - Move authentication services (user_service, token_service, supabase_config_service, user_database_service) to auth/
  - Move camera/AR services (camera_resource_manager, ml_detection_service, disposal_detection_service, qr_camera_controller, qr_bin_service) to camera/
  - Move data services (database_service, local_storage_service, sync_service, data_migration_service, all *_database_service files) to data/
  - Move location services (location_service, bin_location_service, bin_matching_service, map_data_service) to location/
  - Move social services (social_sharing_service, social_card_generation_service, card_renderer, leaderboard_service, deep_link_service) to social/
  - Move platform services (all hand tracking services, platform_optimizer, enhanced_gesture_recognition_service) to platform/
  - Move system services (logging_service, performance_service, haptic_service, sound_service, ui_context_service) to system/
  - Move business services (inventory_service, object_management_service, smart_suggestions_service, motivational_message_service) to business/
  - _Requirements: 1.1, 1.2, 3.1, 3.3, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 2. Create widget directory structure and reorganize all widgets
  - Create widget subdirectories: camera, map, inventory, social, overlays, animations, debug
  - Move camera widgets (enhanced_object_overlay, qr_scanner_overlay, hand_skeleton_painter, coordinate widgets, integrated ML/QR widgets) to camera/
  - Move map widgets (all marker widgets, layer_toggle widgets) to map/
  - Move inventory widgets (detail_card, smart_suggestion widgets) to inventory/
  - Move social widgets (achievement_card_widget, floating_share_overlay) to social/
  - Move overlay widgets (bin_feedback_overlay, disposal overlays, high_priority_overlay) to overlays/
  - Move animation widgets (breathing_widget, morphing_icon, particle_system, progress_ring) to animations/
  - Move debug widgets (debug_overlay_widget) to debug/
  - Move remaining common widgets (glassmorphism_container, neon_icon_button, floating_action_hub, slide_up_panel, sync widgets) to common/
  - _Requirements: 2.1, 2.2, 2.4, 3.1, 3.3, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 3. Update all import statements and cleanup
  - Update import statements in all files to reflect new service directory structure
  - Update import statements in all files to reflect new widget directory structure
  - Fix any broken imports caused by the file reorganization
  - Remove any empty directories left after file moves
  - Verify all files compile and run correctly after import updates
  - _Requirements: 6.1, 6.2, 6.3, 6.5_