import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Configuration for golden tests
class GoldenTestConfig {
  /// Standard phone sizes for testing
  static const Size iphoneSE = Size(320, 568);
  static const Size iphone13 = Size(375, 812);
  static const Size iphone13Pro = Size(390, 844);
  static const Size pixel5 = Size(393, 851);
  
  /// Standard tablet sizes for testing
  static const Size ipadMini = Size(768, 1024);
  static const Size ipadPro = Size(1024, 1366);
  static const Size androidTablet = Size(800, 1280);
  
  /// Landscape orientations
  static const Size iphone13Landscape = Size(812, 375);
  static const Size ipadLandscape = Size(1024, 768);
  
  /// Common device configurations for multi-screen testing
  static const List<Device> testDevices = [
    Device.phone,
    Device.iphone11,
    Device.tabletPortrait,
    Device.tabletLandscape,
  ];
  
  /// Initialize golden test configuration
  static Future<void> initialize() async {
    await loadAppFonts();
  }
  
  /// Create a test theme for consistent golden tests
  static ThemeData createTestTheme({bool isDark = false}) {
    return isDark ? ThemeData.dark() : ThemeData.light();
  }
  
  /// Create accessibility test configuration
  static MediaQueryData createAccessibilityMediaQuery({
    double textScaleFactor = 1.0,
    bool boldText = false,
    bool highContrast = false,
    bool disableAnimations = false,
  }) {
    return MediaQueryData(
      textScaleFactor: textScaleFactor,
      boldText: boldText,
      highContrast: highContrast,
      disableAnimations: disableAnimations,
    );
  }
  
  /// Wrapper for accessibility testing
  static Widget createAccessibilityWrapper(
    Widget child, {
    double textScaleFactor = 1.0,
    bool boldText = false,
    bool highContrast = false,
    bool disableAnimations = false,
  }) {
    return MediaQuery(
      data: createAccessibilityMediaQuery(
        textScaleFactor: textScaleFactor,
        boldText: boldText,
        highContrast: highContrast,
        disableAnimations: disableAnimations,
      ),
      child: child,
    );
  }
}

/// Extension for golden test utilities
extension GoldenTestExtensions on WidgetTester {
  /// Pump widget with golden test configuration
  Future<void> pumpGoldenWidget(
    Widget widget, {
    Size? surfaceSize,
    Duration? duration,
  }) async {
    await pumpWidgetBuilder(
      widget,
      surfaceSize: surfaceSize ?? GoldenTestConfig.iphone13,
    );
    
    if (duration != null) {
      await pump(duration);
    } else {
      await pumpAndSettle();
    }
  }
  
  /// Capture golden file with standard naming
  Future<void> expectGolden(
    Finder finder,
    String fileName, {
    String? variant,
  }) async {
    final fullFileName = variant != null ? '${fileName}_$variant.png' : '$fileName.png';
    await expectLater(finder, matchesGoldenFile(fullFileName));
  }
}