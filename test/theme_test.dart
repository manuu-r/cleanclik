import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/theme/app_theme.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';

void main() {
  group('Enhanced Theme System Tests', () {
    test('UIConstants should have enhanced opacity values', () {
      // Test enhanced glassmorphism opacity values
      expect(UIConstants.glassPrimaryOpacity, equals(0.35));
      expect(UIConstants.glassSecondaryOpacity, equals(0.25));
      expect(UIConstants.glassTertiaryOpacity, equals(0.15));
      expect(UIConstants.glassEnhancedBlurRadius, equals(12.0));
      expect(UIConstants.glassEnhancedBorderOpacity, equals(0.3));
    });

    test('UIConstants should have Material 3 motion tokens', () {
      // Test Material 3 motion duration tokens
      expect(UIConstants.motionDurationShort1, equals(50.0));
      expect(UIConstants.motionDurationShort2, equals(100.0));
      expect(UIConstants.motionDurationShort3, equals(150.0));
      expect(UIConstants.motionDurationShort4, equals(200.0));
      expect(UIConstants.motionDurationMedium1, equals(250.0));
      expect(UIConstants.motionDurationMedium2, equals(300.0));
      expect(UIConstants.motionDurationMedium3, equals(350.0));
      expect(UIConstants.motionDurationMedium4, equals(400.0));
      expect(UIConstants.motionDurationLong1, equals(450.0));
      expect(UIConstants.motionDurationLong2, equals(500.0));
      expect(UIConstants.motionDurationLong3, equals(550.0));
      expect(UIConstants.motionDurationLong4, equals(600.0));
    });

    test('NeonColors should have enhanced contrast ratios', () {
      // Test enhanced contrast colors
      expect(NeonColors.electricGreen, equals(const Color(0xFF2E7D32)));
      expect(NeonColors.oceanBlue, equals(const Color(0xFF1976D2)));
      expect(NeonColors.earthOrange, equals(const Color(0xFFE65100)));
      expect(NeonColors.solarYellow, equals(const Color(0xFFF57F17)));
      expect(NeonColors.cosmicPurple, equals(const Color(0xFF7B1FA2)));
      expect(NeonColors.toxicPurple, equals(const Color(0xFF512DA8)));
    });

    test('NeonColors should have Material 3 state layer opacities', () {
      // Test Material 3 state layer opacity constants
      expect(NeonColors.stateLayerOpacityHover, equals(0.08));
      expect(NeonColors.stateLayerOpacityFocus, equals(0.12));
      expect(NeonColors.stateLayerOpacityPressed, equals(0.16));
      expect(NeonColors.stateLayerOpacityDragged, equals(0.16));
      expect(NeonColors.stateLayerOpacitySelected, equals(0.12));
      expect(NeonColors.stateLayerOpacityActivated, equals(0.12));
    });

    test('NeonColors state layer methods should work correctly', () {
      const testColor = Color(0xFF2E7D32);
      
      // Test state layer color generation
      final hoverColor = NeonColors.getHoverStateLayer(testColor);
      expect(hoverColor.alpha, equals((255 * 0.08).round()));
      
      final focusColor = NeonColors.getFocusStateLayer(testColor);
      expect(focusColor.alpha, equals((255 * 0.12).round()));
      
      final pressedColor = NeonColors.getPressedStateLayer(testColor);
      expect(pressedColor.alpha, equals((255 * 0.16).round()));
    });

    testWidgets('AppTheme should create valid Material 3 themes', (tester) async {
      // Test light theme creation
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
      expect(lightTheme.colorScheme.primary, isNotNull);
      expect(lightTheme.colorScheme.primaryContainer, isNotNull);
      expect(lightTheme.colorScheme.surfaceContainer, isNotNull);
      
      // Test dark theme creation
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.useMaterial3, isTrue);
      expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
      expect(darkTheme.colorScheme.primary, isNotNull);
      expect(darkTheme.colorScheme.primaryContainer, isNotNull);
      expect(darkTheme.colorScheme.surfaceContainer, isNotNull);
    });

    test('AnimationThemeExtension should have enhanced motion system', () {
      final animationTheme = AnimationThemeExtension.standard();
      
      // Test Material 3 motion durations
      expect(animationTheme.motionShort1, equals(const Duration(milliseconds: 50)));
      expect(animationTheme.motionShort2, equals(const Duration(milliseconds: 100)));
      expect(animationTheme.motionShort3, equals(const Duration(milliseconds: 150)));
      expect(animationTheme.motionShort4, equals(const Duration(milliseconds: 200)));
      expect(animationTheme.motionMedium1, equals(const Duration(milliseconds: 250)));
      expect(animationTheme.motionMedium2, equals(const Duration(milliseconds: 300)));
      expect(animationTheme.motionMedium3, equals(const Duration(milliseconds: 350)));
      expect(animationTheme.motionMedium4, equals(const Duration(milliseconds: 400)));
      expect(animationTheme.motionLong1, equals(const Duration(milliseconds: 450)));
      expect(animationTheme.motionLong2, equals(const Duration(milliseconds: 500)));
      expect(animationTheme.motionLong3, equals(const Duration(milliseconds: 550)));
      expect(animationTheme.motionLong4, equals(const Duration(milliseconds: 600)));
      
      // Test specialized curves
      expect(animationTheme.standardEasing, equals(Curves.easeInOut));
      expect(animationTheme.decelerateEasing, equals(Curves.easeOut));
      expect(animationTheme.accelerateEasing, equals(Curves.easeIn));
      expect(animationTheme.emphasizedEasing, equals(Curves.easeInOutCubic));
      expect(animationTheme.breathingCurve, equals(Curves.easeInOutSine));
      expect(animationTheme.morphingCurve, equals(Curves.easeInOutQuart));
      expect(animationTheme.particleCurve, equals(Curves.easeOutExpo));
      expect(animationTheme.microInteractionCurve, equals(Curves.easeOutQuint));
    });

    test('AnimationThemeExtension helper methods should work correctly', () {
      final animationTheme = AnimationThemeExtension.standard();
      
      // Test helper method durations
      expect(animationTheme.microInteractionDuration, equals(const Duration(milliseconds: 50)));
      expect(animationTheme.simpleTransitionDuration, equals(const Duration(milliseconds: 100)));
      expect(animationTheme.componentChangeDuration, equals(const Duration(milliseconds: 200)));
      expect(animationTheme.screenTransitionDuration, equals(const Duration(milliseconds: 350)));
      expect(animationTheme.complexAnimationDuration, equals(const Duration(milliseconds: 500)));
      
      // Test helper method curves
      expect(animationTheme.microInteractionEasing, equals(Curves.easeOutQuint));
      expect(animationTheme.standardTransitionEasing, equals(Curves.easeInOut));
      expect(animationTheme.emphasizedTransitionEasing, equals(Curves.easeInOutCubic));
    });

    test('AnimationConfig should create proper configurations', () {
      final animationTheme = AnimationThemeExtension.standard();
      
      // Test micro-interaction config
      final microConfig = AnimationConfig.microInteraction(animationTheme);
      expect(microConfig.duration, equals(const Duration(milliseconds: 50)));
      expect(microConfig.curve, equals(Curves.easeOutQuint));
      
      // Test simple transition config
      final simpleConfig = AnimationConfig.simpleTransition(animationTheme);
      expect(simpleConfig.duration, equals(const Duration(milliseconds: 100)));
      expect(simpleConfig.curve, equals(Curves.easeInOut));
      
      // Test component change config
      final componentConfig = AnimationConfig.componentChange(animationTheme);
      expect(componentConfig.duration, equals(const Duration(milliseconds: 200)));
      expect(componentConfig.curve, equals(Curves.easeInOutCubic));
      
      // Test screen transition config
      final screenConfig = AnimationConfig.screenTransition(animationTheme);
      expect(screenConfig.duration, equals(const Duration(milliseconds: 350)));
      expect(screenConfig.curve, equals(Curves.easeInOutCubic));
      expect(screenConfig.reverseDuration, equals(const Duration(milliseconds: 300)));
      expect(screenConfig.reverseCurve, equals(Curves.easeOut));
    });

    test('ARThemeExtension should have enhanced glassmorphism', () {
      final lightARTheme = ARThemeExtension.light();
      final darkARTheme = ARThemeExtension.dark();
      
      // Test enhanced opacity values
      expect(lightARTheme.glassOpacity, equals(0.25)); // Enhanced from 0.15
      expect(darkARTheme.glassOpacity, equals(0.2)); // Enhanced from 0.1
      
      // Test that neon glow is empty (Material 3 expressive - no shadows)
      expect(lightARTheme.neonGlow, isEmpty);
      expect(darkARTheme.neonGlow, isEmpty);
      
      // Test neon colors
      expect(lightARTheme.neonAccent, equals(NeonColors.electricGreen));
      expect(darkARTheme.neonAccent, equals(NeonColors.electricGreen));
    });
  });
}