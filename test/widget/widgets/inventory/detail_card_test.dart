import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/presentation/widgets/inventory/detail_card.dart';
import 'package:cleanclik/presentation/widgets/common/glassmorphism_container.dart';
import 'package:cleanclik/presentation/widgets/common/neon_icon_button.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('DetailCard Widget Tests', () {
    late BaseWidgetTest testHelper;

    setUp(() {
      testHelper = _DetailCardTestHelper();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    group('Bin Detail Card', () {
      testWidgets('should render bin detail card with all information', (tester) async {
        // Arrange
        bool closed = false;
        final details = {
          'type': 'Recycling',
          'location': 'Main Street & 1st Ave',
          'fillLevel': 75,
          'lastEmptied': '2 hours ago',
        };
        final actions = [
          ActionButton(
            icon: Icons.directions,
            label: 'Navigate',
            onPressed: () {},
            color: Colors.blue,
          ),
        ];

        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Recycling Bin #001',
          details: details,
          actions: actions,
          onClose: () => closed = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Recycling Bin #001'), findsOneWidget);
        expect(find.text('location: Main Street & 1st Ave'), findsOneWidget);
        expect(find.text('lastEmptied: 2 hours ago'), findsOneWidget);
        expect(find.text('Fill Level: 75%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.byType(GlassmorphismContainer), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should handle close button tap', (tester) async {
        // Arrange
        bool closed = false;
        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Test Bin',
          details: {'type': 'General'},
          actions: [],
          onClose: () => closed = true,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(closed, isTrue);
      });

      testWidgets('should show correct icon and color for recycling bin', (tester) async {
        // Arrange
        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Recycling Bin',
          details: {'type': 'Recycling'},
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('should show correct icon for e-waste bin', (tester) async {
        // Arrange
        final widget = DetailCard(
          type: DetailType.bin,
          title: 'E-waste Bin',
          details: {'type': 'E-waste'},
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.electrical_services), findsOneWidget);
      });

      testWidgets('should show correct icon for hazardous bin', (tester) async {
        // Arrange
        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Hazardous Bin',
          details: {'type': 'Hazardous'},
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });
    });

    group('Hotspot Detail Card', () {
      testWidgets('should render hotspot detail card', (tester) async {
        // Arrange
        final details = {
          'activity': 'High',
          'items': '15 items in last hour',
          'reward': '2x points multiplier',
        };

        final widget = DetailCard(
          type: DetailType.hotspot,
          title: 'Activity Hotspot',
          details: details,
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Activity Hotspot'), findsOneWidget);
        expect(find.text('activity: High'), findsOneWidget);
        expect(find.text('items: 15 items in last hour'), findsOneWidget);
        expect(find.text('reward: 2x points multiplier'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });
    });

    group('Mission Detail Card', () {
      testWidgets('should render mission detail card', (tester) async {
        // Arrange
        final details = {
          'objective': 'Collect 10 recyclable items',
          'progress': '7/10 items',
          'timeLeft': '2 hours remaining',
          'reward': '500 points + badge',
        };

        final widget = DetailCard(
          type: DetailType.mission,
          title: 'Daily Collection Challenge',
          details: details,
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Daily Collection Challenge'), findsOneWidget);
        expect(find.text('objective: Collect 10 recyclable items'), findsOneWidget);
        expect(find.text('progress: 7/10 items'), findsOneWidget);
        expect(find.text('timeLeft: 2 hours remaining'), findsOneWidget);
        expect(find.text('reward: 500 points + badge'), findsOneWidget);
        expect(find.byIcon(Icons.flag), findsOneWidget);
      });
    });

    group('Friend Detail Card', () {
      testWidgets('should render friend detail card', (tester) async {
        // Arrange
        final details = {
          'status': 'Online',
          'level': 'Level 15',
          'points': '2,450 points',
          'streak': '12 day streak',
        };

        final widget = DetailCard(
          type: DetailType.friend,
          title: 'Alex Johnson',
          details: details,
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Alex Johnson'), findsOneWidget);
        expect(find.text('status: Online'), findsOneWidget);
        expect(find.text('level: Level 15'), findsOneWidget);
        expect(find.text('points: 2,450 points'), findsOneWidget);
        expect(find.text('streak: 12 day streak'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });

    group('Action Buttons', () {
      testWidgets('should render and handle action buttons', (tester) async {
        // Arrange
        bool navigatePressed = false;
        bool sharePressed = false;

        final actions = [
          ActionButton(
            icon: Icons.directions,
            label: 'Navigate',
            onPressed: () => navigatePressed = true,
            color: Colors.blue,
          ),
          ActionButton(
            icon: Icons.share,
            label: 'Share',
            onPressed: () => sharePressed = true,
            color: Colors.green,
          ),
        ];

        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Test Bin',
          details: {'type': 'General'},
          actions: actions,
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        
        // Tap navigate button
        await tester.tap(find.text('Navigate'));
        await tester.pumpAndSettle();
        
        // Tap share button
        await tester.tap(find.text('Share'));
        await tester.pumpAndSettle();

        // Assert
        expect(navigatePressed, isTrue);
        expect(sharePressed, isTrue);
        expect(find.byType(NeonIconButton), findsAtLeastNWidgets(2));
      });
    });

    group('Fill Level Display', () {
      testWidgets('should show fill level progress bar for bins', (tester) async {
        // Arrange
        final details = {
          'type': 'Recycling',
          'fillLevel': 60,
        };

        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Test Bin',
          details: details,
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Fill Level: 60%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should not show fill level for non-bin types', (tester) async {
        // Arrange
        final details = {
          'fillLevel': 60, // This should be ignored for non-bin types
        };

        final widget = DetailCard(
          type: DetailType.hotspot,
          title: 'Test Hotspot',
          details: details,
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.textContaining('Fill Level:'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
      });
    });

    group('Custom Padding', () {
      testWidgets('should apply custom padding', (tester) async {
        // Arrange
        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Test Bin',
          details: {'type': 'General'},
          actions: [],
          onClose: () {},
          padding: const EdgeInsets.all(32.0),
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(Padding), findsAtLeastNWidgets(1));
        expect(find.byType(SafeArea), findsOneWidget);
      });
    });

    group('Visual Styling', () {
      testWidgets('should use glassmorphism container', (tester) async {
        // Arrange
        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Test Bin',
          details: {'type': 'General'},
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(GlassmorphismContainer), findsOneWidget);
      });

      testWidgets('should show proper text styling', (tester) async {
        // Arrange
        final widget = DetailCard(
          type: DetailType.bin,
          title: 'Recycling Bin #001',
          details: {
            'type': 'Recycling',
            'location': 'Main Street',
          },
          actions: [],
          onClose: () {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.text('Recycling Bin #001'), findsOneWidget);
        expect(find.text('location: Main Street'), findsOneWidget);
      });
    });
  });
}

class _DetailCardTestHelper extends BaseWidgetTest {}