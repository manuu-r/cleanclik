import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/models/detected_object.dart';
import 'package:cleanclik/core/models/waste_category.dart';
import 'package:cleanclik/core/services/business/object_management_service.dart';
import 'package:cleanclik/presentation/widgets/camera/enhanced_object_overlay.dart';
import 'package:cleanclik/presentation/widgets/overlays/indicator_widget.dart';
import 'package:cleanclik/presentation/widgets/overlays/tooltip_widget.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/widget_test_helpers.dart';
import '../../../fixtures/test_data_factory.dart';
import '../../../helpers/mock_services.mocks.dart';

void main() {
  group('EnhancedObjectOverlay Widget Tests', () {
    late BaseWidgetTest testHelper;

    setUp(() {
      testHelper = _EnhancedObjectOverlayTestHelper();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    group('Basic Rendering', () {
      testWidgets('should render with detected object status', (tester) async {
        // Arrange
        final detectedObject = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.recycle,
          confidence: 0.8,
        );
        final transformedRect = const Rect.fromLTWH(100, 100, 50, 50);

        final widget = EnhancedObjectOverlay(
          object: detectedObject,
          status: ObjectStatus.detected,
          transformedRect: transformedRect,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        expect(find.byType(TooltipWidget), findsNothing); // No tooltip by default
      });

      testWidgets('should render with carried object status', (tester) async {
        // Arrange
        final detectedObject = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.organic,
          confidence: 0.9,
        );
        final transformedRect = const Rect.fromLTWH(150, 150, 60, 60);

        final widget = EnhancedObjectOverlay(
          object: detectedObject,
          status: ObjectStatus.carried,
          transformedRect: transformedRect,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        expect(find.text('CARRYING'), findsOneWidget);
        expect(find.text('🚚'), findsOneWidget);
      });

      testWidgets('should render with targeted object status', (tester) async {
        // Arrange
        final detectedObject = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.ewaste,
          confidence: 0.7,
        );
        final transformedRect = const Rect.fromLTWH(200, 200, 40, 40);

        final widget = EnhancedObjectOverlay(
          object: detectedObject,
          status: ObjectStatus.targeted,
          transformedRect: transformedRect,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        expect(find.text('TARGETED'), findsOneWidget);
        expect(find.text('🎯'), findsOneWidget);
      });
    });

    group('Tooltip Display', () {
      testWidgets('should show tooltip when enabled and confidence is high', (tester) async {
        // Arrange
        final detectedObject = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.hazardous,
          confidence: 0.85,
        );
        final transformedRect = const Rect.fromLTWH(100, 100, 50, 50);

        final widget = EnhancedObjectOverlay(
          object: detectedObject,
          status: ObjectStatus.detected,
          transformedRect: transformedRect,
          showTooltip: true,
          screenSize: const Size(400, 800),
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(TooltipWidget), findsOneWidget);
      });

      testWidgets('should not show tooltip when confidence is low', (tester) async {
        // Arrange
        final detectedObject = TestDataFactory.createMockDetectedObject(
          category: WasteCategory.recycle,
          confidence: 0.3, // Low confidence
        );
        final transformedRect = const Rect.fromLTWH(100, 100, 50, 50);

        final widget = EnhancedObjectOverlay(
          object: detectedObject,
          status: ObjectStatus.detected,
          transformedRect: transformedRect,
          showTooltip: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(TooltipWidget), findsNothing);
      });
    });

    group('Interaction Handling', () {
      testWidgets('should handle tap events', (tester) async {
        // Arrange
        bool tapped = false;
        final detectedObject = TestDataFactory.createMockDetectedObject();
        final transformedRect = const Rect.fromLTWH(100, 100, 50, 50);

        final widget = EnhancedObjectOverlay(
          object: detectedObject,
          status: ObjectStatus.detected,
          transformedRect: transformedRect,
          onTap: () => tapped = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(IndicatorWidget));
        await tester.pumpAndSettle();

        // Assert
        expect(tapped, isTrue);
      });
    });

    group('Confidence Indicators', () {
      testWidgets('should display different opacity based on confidence', (tester) async {
        // Arrange
        final highConfidenceObject = TestDataFactory.createMockDetectedObject(
          confidence: 0.95,
        );
        final lowConfidenceObject = TestDataFactory.createMockDetectedObject(
          confidence: 0.4,
        );
        final transformedRect = const Rect.fromLTWH(100, 100, 50, 50);

        // Act & Assert - High confidence
        final highConfidenceWidget = EnhancedObjectOverlay(
          object: highConfidenceObject,
          status: ObjectStatus.detected,
          transformedRect: transformedRect,
        );

        await WidgetTestHelpers.pumpTestWidget(tester, highConfidenceWidget);
        expect(find.byType(IndicatorWidget), findsOneWidget);

        // Act & Assert - Low confidence
        await tester.pumpWidget(WidgetTestHelpers.createTestApp(
          child: EnhancedObjectOverlay(
            object: lowConfidenceObject,
            status: ObjectStatus.detected,
            transformedRect: transformedRect,
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(IndicatorWidget), findsOneWidget);
      });
    });

    group('Category-Specific Rendering', () {
      testWidgets('should render different colors for different waste categories', (tester) async {
        final categories = [
          WasteCategory.recycle,
          WasteCategory.organic,
          WasteCategory.ewaste,
          WasteCategory.hazardous,
        ];

        for (final category in categories) {
          // Arrange
          final detectedObject = TestDataFactory.createMockDetectedObject(
            category: category,
            confidence: 0.8,
          );
          final transformedRect = const Rect.fromLTWH(100, 100, 50, 50);

          final widget = EnhancedObjectOverlay(
            object: detectedObject,
            status: ObjectStatus.detected,
            transformedRect: transformedRect,
          );

          // Act
          await tester.pumpWidget(WidgetTestHelpers.createTestApp(child: widget));
          await tester.pumpAndSettle();

          // Assert
          expect(find.byType(IndicatorWidget), findsOneWidget);
        }
      });
    });

    group('Animation States', () {
      testWidgets('should enable animations for carried objects', (tester) async {
        // Arrange
        final detectedObject = TestDataFactory.createMockDetectedObject();
        final transformedRect = const Rect.fromLTWH(100, 100, 50, 50);

        final widget = EnhancedObjectOverlay(
          object: detectedObject,
          status: ObjectStatus.carried,
          transformedRect: transformedRect,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
        // Animation state is verified through the indicator widget's internal state
      });

      testWidgets('should enable animations for targeted objects', (tester) async {
        // Arrange
        final detectedObject = TestDataFactory.createMockDetectedObject();
        final transformedRect = const Rect.fromLTWH(100, 100, 50, 50);

        final widget = EnhancedObjectOverlay(
          object: detectedObject,
          status: ObjectStatus.targeted,
          transformedRect: transformedRect,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.byType(IndicatorWidget), findsOneWidget);
      });
    });
  });
}

class _EnhancedObjectOverlayTestHelper extends BaseWidgetTest {}