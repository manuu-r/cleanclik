# MediaPipe Hand Tracking Models

This directory contains placeholder files for the MediaPipe hand tracking models. To enable hand tracking functionality, you need to download the actual TensorFlow Lite models.

## Required Models

1. **palm_detection_full.tflite** - Detects hand bounding boxes
2. **hand_landmark.tflite** - Extracts 21 hand landmarks

## How to Download

### Option 1: Download from MediaPipe Repository

1. Download the MediaPipe Hands task file:
   ```bash
   curl -o hand_landmarker.task https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task
   ```

2. Extract the TensorFlow Lite models from the .task file:
   - The .task file is actually a ZIP archive
   - Extract `palm_detection_full.tflite` and `hand_landmark.tflite`
   - Place them in this directory

### Option 2: Use Alternative Models

You can also use compatible TensorFlow Lite models from:
- TensorFlow Hub
- MediaPipe Solutions
- Custom trained models

## Model Requirements

- **Input**: 256x256 RGB image, normalized to [-1, 1]
- **Output**: 
  - Detection model: Bounding box coordinates [ymin, xmin, ymax, xmax]
  - Landmark model: 21 landmarks with x, y, z coordinates (63 values total)

## Performance Notes

- Models are optimized for mobile devices
- Target performance: ~30 FPS on high-end devices, ~15 FPS on mid-range
- Use float16 models for better performance on mobile GPUs

## Current Status

⚠️ **Placeholder files are currently in place**
- The app will build and run but hand tracking will not function
- Replace placeholder files with actual models to enable hand tracking
- Check the debug overlay in the app to see hand tracking status