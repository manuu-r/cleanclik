import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cleanclik/core/models/camera_models.dart';
import 'package:cleanclik/core/services/platform/hand_tracking_service.dart';
import 'package:cleanclik/core/services/platform/hand_coordinate_transformer.dart';
import 'package:cleanclik/core/services/business/pickup_config.dart';
import 'package:cleanclik/core/utils/business/pickup_calculations_util.dart';

// [DEBUG VERSION 2] More logging in _isObjectHeld.

class PickupService {
  final Map<String, _PickupState> _objectStates = {};
  final List<String> _pickedUpItemIds = [];
  final StreamController<PickupEvent> _eventsController =
      StreamController<PickupEvent>.broadcast();

  Stream<PickupEvent> get eventsStream => _eventsController.stream;

  Size? _screenSize;
  Size? _imageSize;
  bool _isInitialized = false;
  DateTime _lastFrameProcessTime = DateTime.now();
  int _skippedFrames = 0;
  int _frameCounter = 0;

  List<String> get pickedUpItemIds => List.unmodifiable(_pickedUpItemIds);
  int get pickedUpCount => _pickedUpItemIds.length;

  Future<void> initialize({bool testMode = false}) async {
    if (_isInitialized) return;
    print('🎯 [PICKUP] Initializing pickup detection service...');
    PickupConfig.testMode = testMode;
    if (PickupConfig.testMode) {
      print('🧪 [PICKUP] Test mode enabled');
    }
    PickupConfig.printConfiguration();
    _isInitialized = true;
    print('✅ [PICKUP] Pickup detection initialized successfully');
  }

  void setCoordinateContext(Size screenSize, Size imageSize) {
    _screenSize = screenSize;
    _imageSize = imageSize;
  }

  void processFrame(
    List<DetectedObject> detectedObjects,
    List<HandLandmark> handLandmarks,
  ) {
    if (!_isInitialized || _screenSize == null || _imageSize == null) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameProcessTime) < PickupConfig.minFrameInterval) {
      _skippedFrames++;
      return;
    }
    _lastFrameProcessTime = now;
    _frameCounter++;

    print('\n--- FRAME #$_frameCounter ---');
    print(
      '[DEBUG] Detected ${detectedObjects.length} objects and ${handLandmarks.length} hands.',
    );

    final detectedObjectIds = detectedObjects
        .map((obj) => obj.objectId)
        .toSet();
    if (detectedObjectIds.isNotEmpty) {
      print('[DEBUG] Detected IDs: ${detectedObjectIds.join(",")}');
    }

    for (final obj in detectedObjects) {
      final state = _objectStates.putIfAbsent(
        obj.objectId,
        () => _PickupState(objectId: obj.objectId),
      );
      state.objectInfo = obj;
      final isHeld = _isObjectHeld(obj, handLandmarks);
      _updateObjectState(state, isHeld);
    }

    final lostIds = _objectStates.keys.toSet().difference(detectedObjectIds);
    if (lostIds.isNotEmpty) {
      print('[DEBUG] Lost IDs being processed: ${lostIds.join(",")}');
      final isAnyHandGrasping = _isAnyHandGrasping(handLandmarks);
      print('[DEBUG] Any hand grasping for lost objects? $isAnyHandGrasping');
      for (final lostId in lostIds) {
        final state = _objectStates[lostId]!;
        if (state.status == _PickupStatus.targeted ||
            state.status == _PickupStatus.pickedUp) {
          _updateObjectState(state, isAnyHandGrasping);
        }
      }
    }

    _cleanupStaleStates(detectedObjectIds);
  }

  void _updateObjectState(_PickupState state, bool isHeld) {
    final initialStatus = state.status;
    // print('[DEBUG] UpdateState for ${state.objectId.substring(0, 5)}... | CurrentStatus: ${state.status}, isHeld: $isHeld, confFrames: ${state.confirmationFrames}, relFrames: ${state.releaseFrames}');

    switch (state.status) {
      case _PickupStatus.none:
        if (isHeld && state.objectInfo != null) {
          state.status = _PickupStatus.targeted;
          state.confirmationFrames = 1;
        }
        break;

      case _PickupStatus.targeted:
        if (isHeld) {
          state.confirmationFrames++;
          if (state.confirmationFrames >= PickupConfig.stabilityFrames) {
            if (state.objectInfo != null) {
              _confirmPickup(state.objectInfo!);
              state.status = _PickupStatus.pickedUp;
            } else {
              state.status = _PickupStatus.none;
              state.confirmationFrames = 0;
            }
          }
        } else {
          state.status = _PickupStatus.none;
          state.confirmationFrames = 0;
        }
        break;

      case _PickupStatus.pickedUp:
        if (!isHeld) {
          state.releaseFrames++;
          if (state.releaseFrames >= PickupConfig.releaseFramesThreshold) {
            _handleRelease(state.objectId);
          }
        } else {
          state.releaseFrames = 0;
        }
        break;
    }

    if (initialStatus != state.status) {
      print(
        '[DEBUG] ❗️❗️❗️ STATE CHANGE for ${state.objectId.substring(0, 5)}...: $initialStatus -> ${state.status}',
      );
    }
  }

  bool _isObjectHeld(DetectedObject obj, List<HandLandmark> handLandmarks) {
    print(
      '[DEBUG] Checking hold status for ${obj.objectId.substring(0, 5)}...',
    );
    var i = 0;
    for (final hand in handLandmarks) {
      final transformResult = HandCoordinateTransformer.transformHandCenter(
        hand.normalizedLandmarks,
        _screenSize!,
        _imageSize!,
      );
      if (!transformResult.isValid) {
        print('[DEBUG] Hand $i: Invalid transform.');
        i++;
        continue;
      }

      final handPosition = transformResult.screenCoordinates;
      final distance = PickupCalculationsUtil.calculateProximity(
        handPosition,
        obj.boundingBox,
      );
      final zone = PickupCalculationsUtil.getProximityZone(distance);
      final transformedLandmarks =
          HandCoordinateTransformer.transformAllLandmarks(
            hand.normalizedLandmarks,
            _screenSize!,
            _imageSize!,
          );
      final isGrasping = PickupCalculationsUtil.isGraspDetected(
        transformedLandmarks,
      );

      print(
        '[DEBUG] Hand $i vs ${obj.objectId.substring(0, 5)}... | Dist: ${distance.toStringAsFixed(2)}, Zone: $zone, Grasp: $isGrasping',
      );

      if (zone == ProximityZone.near && isGrasping) {
        print('[DEBUG] ==> HELD! Conditions met for Hand $i.');
        return true;
      }
      i++;
    }
    print('[DEBUG] ==> NOT HELD. No hand met conditions.');
    return false;
  }

  bool _isAnyHandGrasping(List<HandLandmark> handLandmarks) {
    if (handLandmarks.isEmpty) return false;
    for (final hand in handLandmarks) {
      final transformedLandmarks =
          HandCoordinateTransformer.transformAllLandmarks(
            hand.normalizedLandmarks,
            _screenSize!,
            _imageSize!,
          );
      if (PickupCalculationsUtil.isGraspDetected(transformedLandmarks)) {
        return true;
      }
    }
    return false;
  }

  void _confirmPickup(DetectedObject obj) {
    if (_pickedUpItemIds.contains(obj.objectId)) return;

    if (_pickedUpItemIds.length >= PickupConfig.maxPickedUpObjects) {
      print('🚫 [PICKUP] At capacity, cannot pick up ${obj.codeName}');
      return;
    }

    _pickedUpItemIds.add(obj.objectId);
    print('✅✅✅ [PICKUP] Item picked up: ${obj.codeName} (ID: ${obj.objectId})');

    _eventsController.add(
      PickupEvent.itemPickedUp(
        itemId: obj.objectId,
        category: obj.category,
        codeName: obj.codeName,
        confidence: obj.confidence,
        trackingId: obj.trackingId,
      ),
    );
  }

  void _handleRelease(String objectId) {
    if (_pickedUpItemIds.remove(objectId)) {
      print('📤📤📤 [PICKUP] Item released: $objectId');
      final state = _objectStates[objectId];
      if (state != null) {
        state.status = _PickupStatus.none;
        state.confirmationFrames = 0;
        state.releaseFrames = 0;
      }
      _eventsController.add(PickupEvent.itemReleased(objectId));
    }
  }

  void _cleanupStaleStates(Set<String> currentIds) {
    final idsToRemove = <String>[];
    _objectStates.forEach((id, state) {
      final isStale = !currentIds.contains(id);
      if (isStale && (state.status == _PickupStatus.none)) {
        idsToRemove.add(id);
      }
    });

    if (idsToRemove.isNotEmpty) {
      print(
        '[DEBUG] Cleaning up stale states for IDs: ${idsToRemove.join(', ')}',
      );
      for (var id in idsToRemove) {
        _objectStates.remove(id);
      }
    }
  }

  Future<void> dispose() async {
    print('🧹 [PICKUP] Disposing pickup service...');
    await _eventsController.close();
    _objectStates.clear();
    _pickedUpItemIds.clear();
    _isInitialized = false;
    print('✅ [PICKUP] Pickup service disposed');
  }
}

enum _PickupStatus { none, targeted, pickedUp }

class _PickupState {
  final String objectId;
  _PickupStatus status = _PickupStatus.none;
  DetectedObject? objectInfo;
  int confirmationFrames = 0;
  int releaseFrames = 0;

  _PickupState({required this.objectId});
}

sealed class PickupEvent {
  const PickupEvent();

  factory PickupEvent.itemPickedUp({
    required String itemId,
    required String category,
    required String codeName,
    required double confidence,
    required String trackingId,
  }) = ItemPickedUpEvent;

  factory PickupEvent.itemReleased(String itemId) = ItemReleasedEvent;
}

class ItemPickedUpEvent extends PickupEvent {
  final String itemId;
  final String category;
  final String codeName;
  final double confidence;
  final String trackingId;

  const ItemPickedUpEvent({
    required this.itemId,
    required this.category,
    required this.codeName,
    required this.confidence,
    required this.trackingId,
  });
}

class ItemReleasedEvent extends PickupEvent {
  final String itemId;
  const ItemReleasedEvent(this.itemId);
}

enum ObjectStatus { detected, targeted, carried }
