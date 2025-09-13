# Test Images for ML Detection

This directory contains test images organized by waste category for comprehensive ML detection testing.

## Directory Structure

```
test_images/
├── recyclable_objects/     # Recyclable items (bottles, cans, cardboard)
├── organic_waste/          # Organic/compostable items (food scraps, peels)
├── landfill_waste/         # General landfill items (mixed waste, non-recyclables)
├── ewaste/                 # Electronic waste (phones, batteries, cables)
├── hazardous_waste/        # Hazardous materials (chemicals, medical waste)
├── edge_cases/             # Edge case scenarios (blurry, dark, multiple objects)
├── qr_codes/               # QR code test images for bin scanning
└── calibration/            # Calibration images for different lighting/angles

```

## Image Categories

### Recyclable Objects
- plastic_bottle_001.jpg - Clear plastic water bottle (front view, good lighting)
- aluminum_can_001.jpg - Aluminum soda can (side view, natural lighting)
- cardboard_box_001.jpg - Cardboard shipping box (angled view, indoor lighting)
- glass_jar_001.jpg - Glass food jar (front view, bright lighting)
- paper_document_001.jpg - Stack of paper documents (top view, office lighting)

### Organic Waste
- apple_core_001.jpg - Apple core (side view, natural lighting)
- banana_peel_001.jpg - Banana peel (curved view, kitchen lighting)
- food_scraps_001.jpg - Mixed food scraps (top view, indoor lighting)
- leaves_001.jpg - Fallen leaves (scattered view, outdoor lighting)
- vegetable_peels_001.jpg - Potato peels (pile view, kitchen lighting)

### Landfill Waste
- plastic_bag_001.jpg - Plastic shopping bag (crumpled, indoor lighting)
- styrofoam_001.jpg - Styrofoam container (open view, fluorescent lighting)
- mixed_waste_001.jpg - Mixed non-recyclable items (cluttered view, poor lighting)
- wrapper_001.jpg - Candy wrapper (flat view, bright lighting)
- tissue_001.jpg - Used tissue (crumpled view, natural lighting)

### E-Waste
- smartphone_001.jpg - Modern smartphone (front view, clean background)
- laptop_001.jpg - Laptop computer (closed view, office lighting)
- battery_001.jpg - AA batteries (group view, white background)
- cable_001.jpg - USB cable (coiled view, desk lighting)
- circuit_board_001.jpg - Computer circuit board (flat view, technical lighting)

### Hazardous Waste
- paint_can_001.jpg - Paint can with warning labels (front view, garage lighting)
- chemical_bottle_001.jpg - Chemical bottle with hazard symbols (upright view, lab lighting)
- medical_waste_001.jpg - Medical syringe (safe view, clinical lighting)
- battery_acid_001.jpg - Car battery (side view, automotive lighting)
- cleaning_product_001.jpg - Household cleaner with warnings (front view, utility lighting)

### Edge Cases
- blurry_object_001.jpg - Motion-blurred recyclable item
- dark_lighting_001.jpg - Object in very low light conditions
- multiple_objects_001.jpg - Scene with 5+ different waste items
- partial_object_001.jpg - Object partially out of frame
- reflective_surface_001.jpg - Object on reflective surface causing glare
- cluttered_background_001.jpg - Object in very busy/cluttered environment
- extreme_angle_001.jpg - Object photographed from unusual angle
- tiny_object_001.jpg - Very small object (button battery)
- oversized_object_001.jpg - Large object filling entire frame

### QR Codes
- bin_qr_recycle_001.png - QR code for recycling bin
- bin_qr_organic_001.png - QR code for organic waste bin
- bin_qr_landfill_001.png - QR code for landfill bin
- bin_qr_ewaste_001.png - QR code for e-waste bin
- bin_qr_hazardous_001.png - QR code for hazardous waste bin
- damaged_qr_001.png - Partially damaged/unreadable QR code
- angled_qr_001.png - QR code photographed at steep angle

### Calibration
- white_balance_001.jpg - White balance reference under different lighting
- color_chart_001.jpg - Color accuracy reference chart
- resolution_test_001.jpg - High-detail image for resolution testing
- contrast_test_001.jpg - High contrast black/white patterns
- lighting_gradient_001.jpg - Gradient from dark to bright areas

## Usage in Tests

These images are referenced in test files using the `TestImageAssets` class:

```dart
final testImage = TestImageAssets.getImagePath('recyclable_objects/plastic_bottle_001.jpg');
final expectedResult = TestImageAssets.getExpectedResult('plastic_bottle_001');
```

## Image Requirements

- **Format**: JPEG for photos, PNG for QR codes and graphics
- **Resolution**: Minimum 640x480, recommended 1920x1080
- **File Size**: Maximum 2MB per image to keep test suite lightweight
- **Quality**: High enough for accurate ML detection, compressed for efficiency
- **Metadata**: Each image should have corresponding metadata in `test_image_metadata.dart`

## Adding New Images

1. Place image in appropriate category directory
2. Follow naming convention: `category_description_###.ext`
3. Add metadata entry in `test_image_metadata.dart`
4. Update this README if adding new categories
5. Ensure image is properly licensed for testing use

## Performance Considerations

- Images are loaded on-demand during tests
- Use `TestImageAssets.preloadImages()` for performance-critical tests
- Consider using smaller images for bulk/performance testing
- Large image sets should be marked with `@tags(['slow'])` for selective running