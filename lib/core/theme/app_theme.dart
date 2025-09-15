import 'package:flutter/material.dart';
import 'package:cleanclik/core/theme/app_colors.dart';
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/theme/ar_theme_extensions.dart';

/// UI constants for the AR-first design system with Material 3 expressive design
class UIConstants {
  // 8dp Grid System - Material 3 Expressive
  static const double gridUnit = 8.0;
  static const double spacing1 = gridUnit * 0.5; // 4dp
  static const double spacing2 = gridUnit * 1; // 8dp
  static const double spacing3 = gridUnit * 1.5; // 12dp
  static const double spacing4 = gridUnit * 2; // 16dp
  static const double spacing5 = gridUnit * 2.5; // 20dp
  static const double spacing6 = gridUnit * 3; // 24dp
  static const double spacing8 = gridUnit * 4; // 32dp
  static const double spacing10 = gridUnit * 5; // 40dp
  static const double spacing12 = gridUnit * 6; // 48dp
  static const double spacing16 = gridUnit * 8; // 64dp

  // Component Sizing (aligned to 8dp grid)
  static const double minTouchTarget = 44.0; // Accessibility minimum
  static const double buttonHeight = 56.0; // 7 * 8dp
  static const double iconButtonSize = 48.0; // 6 * 8dp
  static const double fabSize = 56.0; // 7 * 8dp
  static const double fabMiniSize = 40.0; // 5 * 8dp

  // Floating Action Hub
  static const double hubSize = 64.0; // 8 * 8dp
  static const double hubExpandedSize = 200.0; // 25 * 8dp
  static const double hubActionSize = 48.0; // 6 * 8dp
  static const double hubAnimationDuration = 300.0;

  // Screen Layout
  static const double arViewPercentage = 0.8;
  static const double bottomPanelMinHeight = 120.0; // 15 * 8dp
  static const double bottomPanelMaxHeight = 400.0; // 50 * 8dp
  static const double edgeControlsMargin = spacing4; // 16dp

  // Glassmorphism (Material 3 surface treatments)
  static const double glassBlurRadius = 10.0;
  static const double glassOpacity = 0.15; // Legacy - use GlassLevel instead
  static const double glassBorderOpacity = 0.2;
  
  // Enhanced Glassmorphism System (0.25-0.35 opacity range)
  static const double glassPrimaryOpacity = 0.35; // High importance content
  static const double glassSecondaryOpacity = 0.25; // Medium importance content
  static const double glassTertiaryOpacity = 0.15; // Low importance content
  static const double glassEnhancedBlurRadius = 12.0; // Improved blur
  static const double glassEnhancedBorderOpacity = 0.3; // Better contrast

  // Border Radius (Material 3 Expressive - larger, more rounded)
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusXXLarge = 40.0;
  static const double radiusRound = 50.0;

  // Enhanced Animation Tokens (Material 3 motion system)
  static const double breathingAnimationDuration = 2000.0;
  static const double morphingAnimationDuration = 400.0;
  static const double particleAnimationDuration = 1500.0;
  static const double fastAnimationDuration = 200.0;
  static const double mediumAnimationDuration = 300.0;
  static const double slowAnimationDuration = 500.0;
  
  // Material 3 Motion Tokens
  static const double motionDurationShort1 = 50.0; // Micro-interactions
  static const double motionDurationShort2 = 100.0; // Simple transitions
  static const double motionDurationShort3 = 150.0; // Small component changes
  static const double motionDurationShort4 = 200.0; // Medium component changes
  static const double motionDurationMedium1 = 250.0; // Large component changes
  static const double motionDurationMedium2 = 300.0; // Complex transitions
  static const double motionDurationMedium3 = 350.0; // Screen transitions
  static const double motionDurationMedium4 = 400.0; // Large screen changes
  static const double motionDurationLong1 = 450.0; // Complex screen transitions
  static const double motionDurationLong2 = 500.0; // Full screen changes
  static const double motionDurationLong3 = 550.0; // Complex animations
  static const double motionDurationLong4 = 600.0; // Extended animations
  
  // Material 3 Easing Curves (implemented as curve names for reference)
  // Use with Curves.easeInOut, Curves.easeOut, etc.
  static const String motionEasingStandard = 'easeInOut'; // Standard easing
  static const String motionEasingDecelerate = 'easeOut'; // Decelerate easing
  static const String motionEasingAccelerate = 'easeIn'; // Accelerate easing
  static const String motionEasingEmphasized = 'easeInOutCubic'; // Emphasized easing

  // Touch Targets
  static const double thumbReachRadius = 75.0;

  // Progress Rings
  static const double progressRingSize = 60.0; // 7.5 * 8dp
  static const double progressRingStrokeWidth = 4.0;

  // Neon Effects (zero shadows in Material 3 expressive)
  static const double neonGlowRadius = 0.0; // No shadows
  static const double neonBlurRadius = 0.0; // No shadows

  // Typography Scale (Material 3 expressive)
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;

  // Layout Constraints
  static const double maxContentWidth = 600.0;
  static const double sideMargin = spacing4; // 16dp
  static const double cardPadding = spacing6; // 24dp
  static const double sectionSpacing = spacing8; // 32dp
}

class AppTheme {
  /// Material 3 expressive color scheme for light theme
  static ColorScheme get _lightColorScheme {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      // Primary colors
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: NeonColors.electricGreen.withValues(alpha: 0.12),
      onPrimaryContainer: AppColors.primary,
      
      // Secondary colors
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: NeonColors.oceanBlue.withValues(alpha: 0.12),
      onSecondaryContainer: NeonColors.oceanBlue,
      
      // Tertiary colors
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accent.withValues(alpha: 0.12),
      onTertiaryContainer: AppColors.accent,
      
      // Surface colors
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF7F2FA),
      surfaceContainer: const Color(0xFFF1ECF4),
      surfaceContainerHigh: const Color(0xFFEBE6EE),
      surfaceContainerHighest: const Color(0xFFE6E0E9),
      surfaceTint: NeonColors.surfaceTintLight,
      
      // Outline colors
      outline: NeonColors.outlineLight,
      outlineVariant: NeonColors.outlineVariantLight,
      
      // Error colors
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.12),
      onErrorContainer: AppColors.error,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      extensions: [
        ARThemeExtension.light(),
        AnimationThemeExtension.standard(),
      ],
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: AppColors.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.radiusXLarge)),
        color: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          borderSide: BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  /// Material 3 expressive color scheme for dark theme
  static ColorScheme get _darkColorScheme {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      // Primary colors
      primary: NeonColors.electricGreen,
      onPrimary: const Color(0xFF003910),
      primaryContainer: const Color(0xFF005319),
      onPrimaryContainer: NeonColors.glowGreen,
      
      // Secondary colors
      secondary: NeonColors.oceanBlue,
      onSecondary: const Color(0xFF001D36),
      secondaryContainer: const Color(0xFF004B73),
      onSecondaryContainer: NeonColors.glowBlue,
      
      // Tertiary colors
      tertiary: AppColors.accent,
      onTertiary: const Color(0xFF003910),
      tertiaryContainer: const Color(0xFF005319),
      onTertiaryContainer: AppColors.accent,
      
      // Surface colors
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceContainerLowest: const Color(0xFF0F0D13),
      surfaceContainerLow: const Color(0xFF1D1B20),
      surfaceContainer: const Color(0xFF211F26),
      surfaceContainerHigh: const Color(0xFF2B2930),
      surfaceContainerHighest: const Color(0xFF36343B),
      surfaceTint: NeonColors.surfaceTintDark,
      
      // Outline colors
      outline: NeonColors.outlineDark,
      outlineVariant: NeonColors.outlineVariantDark,
      
      // Error colors
      error: AppColors.error,
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      extensions: [ARThemeExtension.dark(), AnimationThemeExtension.standard()],
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: AppColors.darkOnSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.radiusXLarge)),
        color: AppColors.darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          borderSide: BorderSide(color: AppColors.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          borderSide: BorderSide(color: AppColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusXLarge),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
