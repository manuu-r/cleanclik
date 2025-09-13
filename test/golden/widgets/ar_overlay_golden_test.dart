import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_widgets.dart';

void main() {
  group('AR Overlay Components Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    group('EnhancedObjectOverlay', () {
      testGoldens('EnhancedObjectOverlay with recycle object', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const EnhancedObjectOverlay(
              detectedObject: {'category': 'recycle', 'confidence': 0.95},
              screenSize: Size(375, 812),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(EnhancedObjectOverlay),
          matchesGoldenFile('enhanced_object_overlay_recycle.png'),
        );
      });

      testGoldens('EnhancedObjectOverlay with organic object', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const EnhancedObjectOverlay(
              detectedObject: {'category': 'organic', 'confidence': 0.87},
              screenSize: Size(375, 812),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(EnhancedObjectOverlay),
          matchesGoldenFile('enhanced_object_overlay_organic.png'),
        );
      });

      testGoldens('EnhancedObjectOverlay with low confidence', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const EnhancedObjectOverlay(
              detectedObject: {'category': 'ewaste', 'confidence': 0.45},
              screenSize: Size(375, 812),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(EnhancedObjectOverlay),
          matchesGoldenFile('enhanced_object_overlay_low_confidence.png'),
        );
      });

      testGoldens('EnhancedObjectOverlay dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const EnhancedObjectOverlay(
              detectedObject: {'category': 'hazardous', 'confidence': 0.92},
              screenSize: Size(375, 812),
            ),
          ),
          theme: ThemeData.dark(),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(EnhancedObjectOverlay),
          matchesGoldenFile('enhanced_object_overlay_dark.png'),
        );
      });
    });

    group('IndicatorWidget', () {
      testGoldens('IndicatorWidget recycle category', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const IndicatorWidget(
              category: WasteCategory.recycle,
              confidence: 0.95,
              position: Offset(100, 200),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(IndicatorWidget),
          matchesGoldenFile('indicator_widget_recycle.png'),
        );
      });

      testGoldens('IndicatorWidget organic category', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const IndicatorWidget(
              category: WasteCategory.organic,
              confidence: 0.87,
              position: Offset(150, 300),
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(IndicatorWidget),
          matchesGoldenFile('indicator_widget_organic.png'),
        );
      });

      testGoldens('IndicatorWidget with animation', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: const IndicatorWidget(
              category: WasteCategory.ewaste,
              confidence: 0.92,
              position: Offset(200, 400),
              isAnimating: true,
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pump(const Duration(milliseconds: 150)); // Capture mid-animation

        await expectLater(
          find.byType(IndicatorWidget),
          matchesGoldenFile('indicator_widget_animated.png'),
        );
      });
    });

    group('DisposalCelebrationOverlay', () {
      testGoldens('DisposalCelebrationOverlay success', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const DisposalCelebrationOverlay(
            isVisible: true,
            category: WasteCategory.recycle,
            pointsEarned: 50,
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(DisposalCelebrationOverlay),
          matchesGoldenFile('disposal_celebration_overlay_success.png'),
        );
      });

      testGoldens('DisposalCelebrationOverlay with achievement', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const DisposalCelebrationOverlay(
            isVisible: true,
            category: WasteCategory.organic,
            pointsEarned: 75,
            achievementUnlocked: 'Eco Warrior',
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(DisposalCelebrationOverlay),
          matchesGoldenFile('disposal_celebration_overlay_achievement.png'),
        );
      });

      testGoldens('DisposalCelebrationOverlay with streak multiplier', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const DisposalCelebrationOverlay(
            isVisible: true,
            category: WasteCategory.ewaste,
            pointsEarned: 150,
            streakMultiplier: 2.5,
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(DisposalCelebrationOverlay),
          matchesGoldenFile('disposal_celebration_overlay_streak.png'),
        );
      });

      testGoldens('DisposalCelebrationOverlay dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const DisposalCelebrationOverlay(
            isVisible: true,
            category: WasteCategory.hazardous,
            pointsEarned: 100,
          ),
          theme: ThemeData.dark(),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(DisposalCelebrationOverlay),
          matchesGoldenFile('disposal_celebration_overlay_dark.png'),
        );
      });
    });

    group('Multiple Overlays', () {
      testGoldens('Multiple AR overlays with different categories', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          Container(
            width: 375,
            height: 812,
            color: Colors.black,
            child: Stack(
              children: [
                Positioned(
                  left: 50,
                  top: 200,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.recycling, color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        const Text('RECYCLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        const Text('95%', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 200,
                  top: 400,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco, color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        const Text('ORGANIC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        const Text('87%', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 300,
                  top: 500,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(Container).first,
          matchesGoldenFile('multiple_ar_overlays.png'),
        );
      });
    });
  });
}