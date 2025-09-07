# Implementation Plan

- [x] 1. Update Existing Code for Simplified Waste Categorization
  - Modify existing `WasteCategory` enum to remove landfill and keep only four categories (recycle, organic, ewaste, hazardous)
  - Update existing category mapping logic in `ARDetectionService` to map: FASHION_GOOD → recycle, HOME_GOOD → recycle, FOOD/PLANT → organic, and objects detected as both FASHION_GOOD and HOME_GOOD → ewaste
  - Modify existing object processing code to ignore and skip PLACE objects and unknown ML Kit categories completely, and add logic to detect objects with multiple categories (FASHION_GOOD + HOME_GOOD) and categorize them as ewaste
  - Update existing logging statements to include category mapping decisions and skipped objects
  - Modify existing UI components that reference waste categories to work with the simplified four-category system
  - Update existing unit tests to cover the new category mapping logic and ignored categories
  - Modify existing integration tests to validate PLACE and unknown categories are ignored
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 4.2_