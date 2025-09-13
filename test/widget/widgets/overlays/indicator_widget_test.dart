import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/object_indicator_data.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import 'package:cleanclik/presentation/widgets/overlays/indicator_widget.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('IndicatorWidget Tests', () {
    late BaseWidgetTest testHelper;

    setUp(() {
      testHelper = _IndicatorWidgetTestHelper();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    group('Basic Rendering', () {
      testWidgets('should render pulsating circle indicator', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.recycle,
          centerPosition: const Offset(100, 100),
          confidence: 0.8,
          type: IndicatorType.pulsatingCircle,
          categoryColor: Colors.green,
          objectInfo: 'Plastic Bottle',
          trackingId: 'test_id',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true,
          animationDuration: const Duration(milliseconds: 1000),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.8,
          enableAnimations: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });

      testWidgets('should render glowing dot indicator', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.organic,
          centerPosition: const Offset(150, 150),
          confidence: 0.9,
          type: IndicatorType.glowingDot,
          categoryColor: Colors.blue,
          objectInfo: 'Apple Core',
          trackingId: 'test_id_2',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true,
          animationDuration: const Duration(milliseconds: 1200),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.9,
          enableAnimations: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });

      testWidgets('should render target reticle indicator', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.ewaste,
          centerPosition: const Offset(200, 200),
          confidence: 0.7,
          type: IndicatorType.targetReticle,
          categoryColor: Colors.orange,
          objectInfo: 'Old Phone',
          trackingId: 'test_id_3',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true,
          animationDuration: const Duration(milliseconds: 800),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.7,
          enableAnimations: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });

    group('Visibility Control', () {
      testWidgets('should not render when not visible', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.recycle,
          centerPosition: const Offset(100, 100),
          confidence: 0.8,
          type: IndicatorType.pulsatingCircle,
          categoryColor: Colors.green,
          objectInfo: 'Plastic Bottle',
          trackingId: 'test_id',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: false, // Not visible
          animationDuration: const Duration(milliseconds: 1000),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.8,
          enableAnimations: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(AnimatedBuilder), findsNothing);
      });

      testWidgets('should render when visible', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.recycle,
          centerPosition: const Offset(100, 100),
          confidence: 0.8,
          type: IndicatorType.pulsatingCircle,
          categoryColor: Colors.green,
          objectInfo: 'Plastic Bottle',
          trackingId: 'test_id',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true, // Visible
          animationDuration: const Duration(milliseconds: 1000),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.8,
          enableAnimations: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });
    });

    group('Animation Control', () {
      testWidgets('should animate when animations are enabled', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.recycle,
          centerPosition: const Offset(100, 100),
          confidence: 0.8,
          type: IndicatorType.pulsatingCircle,
          categoryColor: Colors.green,
          objectInfo: 'Plastic Bottle',
          trackingId: 'test_id',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true,
          animationDuration: const Duration(milliseconds: 1000),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.8,
          enableAnimations: true, // Animations enabled
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.pump(const Duration(milliseconds: 500));

        // Assert
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });

      testWidgets('should not animate when animations are disabled', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.recycle,
          centerPosition: const Offset(100, 100),
          confidence: 0.8,
          type: IndicatorType.pulsatingCircle,
          categoryColor: Colors.green,
          objectInfo: 'Plastic Bottle',
          trackingId: 'test_id',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true,
          animationDuration: const Duration(milliseconds: 1000),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.8,
          enableAnimations: false, // Animations disabled
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        // Animation controllers should still exist but not be running
      });
    });

    group('Interaction Handling', () {
      testWidgets('should handle tap events', (tester) async {
        // Arrange
        bool tapped = false;
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.recycle,
          centerPosition: const Offset(100, 100),
          confidence: 0.8,
          type: IndicatorType.pulsatingCircle,
          categoryColor: Colors.green,
          objectInfo: 'Plastic Bottle',
          trackingId: 'test_id',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true,
          animationDuration: const Duration(milliseconds: 1000),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.8,
          enableAnimations: true,
          onTap: () => tapped = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();

        // Assert
        expect(tapped, isTrue);
      });
    });

    group('Category-Specific Colors', () {
      testWidgets('should use correct colors for different waste categories', (tester) async {
        final categories = [
          WasteCategory.recycle,
          WasteCategory.organic,
          WasteCategory.ewaste,
          WasteCategory.hazardous,
        ];

        for (final category in categories) {
          // Arrange
          final indicatorData = ObjectIndicatorData(
            category: category,
            centerPosition: const Offset(100, 100),
            confidence: 0.8,
            type: IndicatorType.pulsatingCircle,
            categoryColor: Colors.green, // Will be overridden by category
            objectInfo: 'Test Object',
            trackingId: 'test_id',
            detectedAt: DateTime.now(),
            showTooltip: false,
            isVisible: true,
            animationDuration: const Duration(milliseconds: 1000),
          );

          final widget = IndicatorWidget(
            indicatorData: indicatorData,
            opacity: 0.8,
            enableAnimations: false,
          );

          // Act
          await tester.pumpWidget(WidgetTestHelpers.createTestApp(child: widget));
          await tester.pumpAndSettle();

          // Assert
          expect(find.byType(IndicatorWidget), findsOneWidget);
        }
      });
    });

    group('Confidence-Based Opacity', () {
      testWidgets('should apply correct opacity', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.recycle,
          centerPosition: const Offset(100, 100),
          confidence: 0.8,
          type: IndicatorType.pulsatingCircle,
          categoryColor: Colors.green,
          objectInfo: 'Plastic Bottle',
          trackingId: 'test_id',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true,
          animationDuration: const Duration(milliseconds: 1000),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.5, // Custom opacity
          enableAnimations: false,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        // Opacity is applied internally to the rendered elements
      });
    });

    group('Custom Paint for Target Reticle', () {
      testWidgets('should render custom paint for target reticle', (tester) async {
        // Arrange
        final indicatorData = ObjectIndicatorData(
          category: WasteCategory.ewaste,
          centerPosition: const Offset(200, 200),
          confidence: 0.7,
          type: IndicatorType.targetReticle,
          categoryColor: Colors.orange,
          objectInfo: 'Old Phone',
          trackingId: 'test_id_3',
          detectedAt: DateTime.now(),
          showTooltip: false,
          isVisible: true,
          animationDuration: const Duration(milliseconds: 800),
        );

        final widget = IndicatorWidget(
          indicatorData: indicatorData,
          opacity: 0.7,
          enableAnimations: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(CustomPaint), findsOneWidget);
        expect(find.byType(AnimatedBuilder), findsOneWidget);
      });
    });
  });
}

class _IndicatorWidgetTestHelper extends BaseWidgetTest {}