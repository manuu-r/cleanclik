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
  static const double glassOpacity = 0.15;
  static const double glassBorderOpacity = 0.2;
  
  // Border Radius (aligned to 4dp increments)
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusRound = 28.0;
  
  // Animations (Material 3 motion tokens)
  static const double breathingAnimationDuration = 2000.0;
  static const double morphingAnimationDuration = 400.0;
  static const double particleAnimationDuration = 1500.0;
  static const double fastAnimationDuration = 200.0;
  static const double mediumAnimationDuration = 300.0;
  static const double slowAnimationDuration = 500.0;
  
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