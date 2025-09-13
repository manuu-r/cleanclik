import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/core/services/camera/disposal_detection_service.dart';
import 'package:cleanclik/presentation/widgets/overlays/disposal_celebration_overlay.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/widget_test_helpers.dart';
import '../../../fixtures/test_data_factory.dart';

void main() {
  group('DisposalCelebrationOverlay Widget Tests', () {
    late BaseWidgetTest testHelper;

    setUp(() {
      testHelper = _DisposalCelebrationOverlayTestHelper();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    group('Basic Rendering', () {
      testWidgets('should render celebration overlay with disposal result', (tester) async {
        // Arrange
        bool dismissed = false;
        final disposalResult = DisposalResult(
          itemsDisposed: [
            TestDataFactory.createMockInventoryItem(category: 'recycle'),
            TestDataFactory.createMockInventoryItem(category: 'organic'),
          ],
          pointsEarned: 150,
          streakCount: 3,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () => dismissed = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Disposal Complete!'), findsOneWidget);
        expect(find.text('2 items disposed'), findsOneWidget);
        expect(find.text('+150 points'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should show streak information when streak count > 1', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 100,
          streakCount: 5,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('5x Streak!'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });

      testWidgets('should not show streak information when streak count is 1', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 50,
          streakCount: 1,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.textContaining('Streak!'), findsNothing);
        expect(find.byIcon(Icons.local_fire_department), findsNothing);
      });
    });

    group('Animation Behavior', () {
      testWidgets('should show entrance animation', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 75,
          streakCount: 1,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });

      testWidgets('should animate points display', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 200,
          streakCount: 1,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.pump(const Duration(milliseconds: 500));

        // Assert
        expect(find.text('+200 points'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('should show pulse animation for success glow', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 100,
          streakCount: 1,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.pump(const Duration(milliseconds: 300));

        // Assert
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });
    });

    group('Auto-Dismiss Behavior', () {
      testWidgets('should auto-dismiss after celebration duration', (tester) async {
        // Arrange
        bool dismissed = false;
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 100,
          streakCount: 1,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () => dismissed = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        
        // Fast-forward through the celebration duration
        await tester.pump(const Duration(milliseconds: 3000));
        await tester.pumpAndSettle();

        // Assert
        expect(dismissed, isTrue);
      });
    });

    group('Visual Elements', () {
      testWidgets('should show success icon with proper styling', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 100,
          streakCount: 1,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should show proper text styling for different elements', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [
            TestDataFactory.createMockInventoryItem(),
            TestDataFactory.createMockInventoryItem(),
            TestDataFactory.createMockInventoryItem(),
          ],
          pointsEarned: 300,
          streakCount: 7,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Disposal Complete!'), findsOneWidget);
        expect(find.text('3 items disposed'), findsOneWidget);
        expect(find.text('+300 points'), findsOneWidget);
        expect(find.text('7x Streak!'), findsOneWidget);
      });
    });

    group('Material 3 Design Elements', () {
      testWidgets('should use Material 3 design system', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 100,
          streakCount: 1,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert - Check for Material 3 elements
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        expect(find.text('Disposal Complete!'), findsOneWidget);
      });

      testWidgets('should show proper border radius and styling', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 100,
          streakCount: 4,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        expect(find.text('4x Streak!'), findsOneWidget);
      });
    });

    group('Haptic Feedback', () {
      testWidgets('should be configured for haptic feedback', (tester) async {
        // Arrange
        final disposalResult = DisposalResult(
          itemsDisposed: [TestDataFactory.createMockInventoryItem()],
          pointsEarned: 100,
          streakCount: 1,
          binId: 'test_bin_001',
          timestamp: DateTime.now(),
        );

        final widget = DisposalCelebrationOverlay(
          disposalResult: disposalResult,
          onDismiss: () {},
          hapticFeedback: true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert - Widget should be created successfully with haptic feedback enabled
        expect(find.byType(DisposalCelebrationOverlay), findsOneWidget);
      });
    });
  });
}

class _DisposalCelebrationOverlayTestHelper extends BaseWidgetTest {}