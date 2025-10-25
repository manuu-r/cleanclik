import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/presentation/widgets/overlays/tooltip_widget.dart';

void main() {
  group('Concise Tooltip Tests', () {
    testWidgets('should display concise tooltip with object info', (
      tester,
    ) async {
      // Create concise tooltip widget
      final tooltip = TooltipWidget(
        category: WasteCategory.recycle,
        objectInfo: 'Plastic Bottle',
        indicatorPosition: const Offset(100, 100),
        screenSize: const Size(400, 800),
        isVisible: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Stack(children: [tooltip])),
        ),
      );

      await tester.pump();

      // Verify tooltip is displayed
      expect(find.byType(TooltipWidget), findsOneWidget);

      // Verify object info is shown (should not be truncated for short names)
      expect(find.textContaining('Plastic'), findsOneWidget);

      // Verify category icon is shown
      expect(find.byIcon(Icons.recycling), findsOneWidget);
    });

    testWidgets('should truncate long object names', (tester) async {
      // Create tooltip with long object name
      final tooltip = TooltipWidget(
        category: WasteCategory.recycle,
        objectInfo: 'Very Long Object Name That Should Be Truncated',
        indicatorPosition: const Offset(100, 100),
        screenSize: const Size(400, 800),
        isVisible: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Stack(children: [tooltip])),
        ),
      );

      await tester.pump();

      // Verify tooltip is displayed
      expect(find.byType(TooltipWidget), findsOneWidget);

      // Verify object name is truncated
      expect(find.text('Very Long...'), findsOneWidget);
    });

    testWidgets('should display confidence badge when available', (
      tester,
    ) async {
      final tooltip = TooltipWidget(
        category: WasteCategory.recycle,
        objectInfo: 'Test Object',
        indicatorPosition: const Offset(100, 100),
        screenSize: const Size(400, 800),
        isVisible: true,
        categoryConfidence: 0.85,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Stack(children: [tooltip])),
        ),
      );

      await tester.pump();

      // Verify confidence badge is shown
      expect(find.text('85%'), findsOneWidget);
    });
  });
}
