# Implementation Plan

- [x] 1. Fix QR Scanner Navigation and Widget Positioning Issues
  - **Create Camera Mode Management**: Create `CameraMode` enum with `arDetection` and `qrScanning` values, and `CameraState` model to track current mode and initialization status
  - **Update Route Configuration**: Modify camera route in `app_router.dart` to accept query parameters, parse `mode` parameter, and pass to AR camera screen with validation and fallback
  - **Fix Home Screen Navigation**: Change QR scanner button navigation from `context.push(Routes.camera)` to `context.push('${Routes.camera}?mode=qr')` to automatically activate QR scanning mode
  - **Enhance AR Camera Screen**: Add optional `initialMode` parameter to constructor, implement mode initialization logic in `initState()`, and add automatic QR scanner activation when mode is 'qr'
  - **Fix Widget Tree Structure**: Fix `_buildScanLineOverlay()` method in `qr_scanner_overlay.dart` by wrapping scan line animation Positioned widget in proper Stack container to prevent ParentDataWidget errors
  - **Implement Camera Resource Management**: Add proper camera disposal when switching between AR and QR modes, implement resource cleanup in dispose() method, and handle camera permission conflicts gracefully
  - **Add Error Handling**: Implement graceful handling of camera initialization failures, add retry mechanisms, provide clear error messages, and prevent race conditions during mode switches
  - **Test and Validate**: Verify navigation from home screen opens QR scanner directly, QR overlay renders without crashes, smooth mode transitions, and proper resource cleanup
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5_