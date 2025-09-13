import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanclik/presentation/widgets/map/bin_marker.dart';

import '../../../helpers/base_widget_test.dart';
import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('BinMarker Widget Tests', () {
    late BaseWidgetTest testHelper;

    setUp(() {
      testHelper = _BinMarkerTestHelper();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    group('Basic Rendering', () {
      testWidgets('should render recycling bin marker', (tester) async {
        // Arrange
        BinData? tappedBin;
        final binData = const BinData(
          name: 'Recycling Bin #001',
          type: 'recycling',
          fillLevel: 75,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) => tappedBin = bin,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byType(GestureDetector), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('should render organic bin marker', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'Organic Bin #002',
          type: 'organic',
          fillLevel: 50,
          lat: 37.7849,
          lng: -122.4094,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should render e-waste bin marker', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'E-waste Bin #003',
          type: 'e-waste',
          fillLevel: 25,
          lat: 37.7649,
          lng: -122.4294,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.electrical_services), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should render hazardous bin marker', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'Hazardous Bin #004',
          type: 'hazardous',
          fillLevel: 90,
          lat: 37.7549,
          lng: -122.4394,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should render general bin marker', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'General Bin #005',
          type: 'general',
          fillLevel: 60,
          lat: 37.7449,
          lng: -122.4494,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('Interaction Handling', () {
      testWidgets('should handle tap events and pass correct bin data', (tester) async {
        // Arrange
        BinData? tappedBin;
        final binData = const BinData(
          name: 'Test Bin',
          type: 'recycling',
          fillLevel: 80,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) => tappedBin = bin,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();

        // Assert
        expect(tappedBin, isNotNull);
        expect(tappedBin!.name, equals('Test Bin'));
        expect(tappedBin!.type, equals('recycling'));
        expect(tappedBin!.fillLevel, equals(80));
        expect(tappedBin!.lat, equals(37.7749));
        expect(tappedBin!.lng, equals(-122.4194));
      });

      testWidgets('should handle multiple taps', (tester) async {
        // Arrange
        int tapCount = 0;
        final binData = const BinData(
          name: 'Multi-tap Bin',
          type: 'organic',
          fillLevel: 45,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) => tapCount++,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();

        // Assert
        expect(tapCount, equals(2));
      });
    });

    group('Visual Styling', () {
      testWidgets('should have circular container with border', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'Styled Bin',
          type: 'recycling',
          fillLevel: 70,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        
        expect(decoration.shape, equals(BoxShape.circle));
        expect(decoration.border, isNotNull);
      });

      testWidgets('should use correct colors for different bin types', (tester) async {
        final binTypes = ['recycling', 'organic', 'e-waste', 'hazardous', 'general'];
        
        for (final binType in binTypes) {
          // Arrange
          final binData = BinData(
            name: '$binType Bin',
            type: binType,
            fillLevel: 50,
            lat: 37.7749,
            lng: -122.4194,
          );

          final widget = BinMarker(
            bin: binData,
            onTap: (bin) {},
          );

          // Act
          await tester.pumpWidget(WidgetTestHelpers.createTestApp(child: widget));
          await tester.pumpAndSettle();

          // Assert
          expect(find.byType(Container), findsOneWidget);
          
          final container = tester.widget<Container>(find.byType(Container));
          final decoration = container.decoration as BoxDecoration;
          expect(decoration.color, isNotNull);
        }
      });

      testWidgets('should show white icon on colored background', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'Icon Test Bin',
          type: 'recycling',
          fillLevel: 85,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) {},
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(Colors.white));
        expect(icon.size, equals(20));
      });
    });

    group('Icon Selection', () {
      testWidgets('should use delete_outline icon for recycling bins', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'Recycling Bin',
          type: 'recycling',
          fillLevel: 50,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(bin: binData, onTap: (bin) {});

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('should use electrical_services icon for e-waste bins', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'E-waste Bin',
          type: 'e-waste',
          fillLevel: 30,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(bin: binData, onTap: (bin) {});

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.electrical_services), findsOneWidget);
      });

      testWidgets('should use warning icon for hazardous bins', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'Hazardous Bin',
          type: 'hazardous',
          fillLevel: 95,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(bin: binData, onTap: (bin) {});

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('should use default icon for unknown bin types', (tester) async {
        // Arrange
        final binData = const BinData(
          name: 'Unknown Bin',
          type: 'unknown_type',
          fillLevel: 40,
          lat: 37.7749,
          lng: -122.4194,
        );

        final widget = BinMarker(bin: binData, onTap: (bin) {});

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);

        // Assert
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    group('BinData Model', () {
      testWidgets('should handle all BinData properties correctly', (tester) async {
        // Arrange
        BinData? receivedBin;
        final binData = const BinData(
          name: 'Complete Bin Data',
          type: 'recycling',
          fillLevel: 65,
          lat: 40.7128,
          lng: -74.0060,
        );

        final widget = BinMarker(
          bin: binData,
          onTap: (bin) => receivedBin = bin,
        );

        // Act
        await WidgetTestHelpers.pumpTestWidget(tester, widget);
        await tester.tap(find.byType(GestureDetector));

        // Assert
        expect(receivedBin, isNotNull);
        expect(receivedBin!.name, equals('Complete Bin Data'));
        expect(receivedBin!.type, equals('recycling'));
        expect(receivedBin!.fillLevel, equals(65));
        expect(receivedBin!.lat, equals(40.7128));
        expect(receivedBin!.lng, equals(-74.0060));
      });
    });
  });
}

class _BinMarkerTestHelper extends BaseWidgetTest {}