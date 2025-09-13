import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'test_utils.dart';

/// Helper functions for widget testing with Riverpod and routing
class WidgetTestHelpers {
  /// Create a test app with Riverpod providers and routing
  static Widget createTestApp({
    required Widget child,
    List<Override> overrides = const [],
    GoRouter? router,
    ThemeData? theme,
  }) {
    final container = ProviderContainer(overrides: overrides);
    
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router ?? _createDefaultRouter(child),
        theme: theme ?? _createTestTheme(),
      ),
    );
  }

  /// Create a simple test widget without routing
  static Widget createSimpleTestWidget({
    required Widget child,
    List<Override> overrides = const [],
    ThemeData? theme,
  }) {
    final container = ProviderContainer(overrides: overrides);
    
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: child,
        theme: theme ?? _createTestTheme(),
      ),
    );
  }

  /// Create a default router for testing
  static GoRouter _createDefaultRouter(Widget child) {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => child,
        ),
      ],
    );
  }

  /// Create a test theme
  static ThemeData _createTestTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    );
  }

  /// Pump widget with standard test setup
  static Future<void> pumpTestWidget(
    WidgetTester tester,
    Widget widget, {
    List<Override> overrides = const [],
    Duration? settleDuration,
  }) async {
    await tester.pumpWidget(
      createTestApp(child: widget, overrides: overrides),
    );
    await tester.pumpAndSettle(
      settleDuration ?? const Duration(milliseconds: 500),
    );
  }

  /// Find widget by type with optional index
  static Finder findByType<T extends Widget>([int index = 0]) {
    final finder = find.byType(T);
    if (index > 0) {
      return finder.at(index);
    }
    return finder;
  }

  /// Find widget by key
  static Finder findByKey(Key key) {
    return find.byKey(key);
  }

  /// Find widget by text
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Find widget by icon
  static Finder findByIcon(IconData icon) {
    return find.byIcon(icon);
  }

  /// Find widget by combining multiple finders (OR logic)
  static Finder findAny(List<Finder> finders) {
    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
    }
    return finders.first; // Return first finder if none found
  }

  /// Find widget by text or icon (common pattern)
  static Finder findByTextOrIcon(String text, IconData icon) {
    return findAny([find.text(text), find.byIcon(icon)]);
  }

  /// Tap widget and settle
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder, {
    Duration? settleDuration,
  }) async {
    await tester.tap(finder);
    await tester.pumpAndSettle(
      settleDuration ?? const Duration(milliseconds: 300),
    );
  }

  /// Enter text and settle
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration? settleDuration,
  }) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle(
      settleDuration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scroll widget and settle
  static Future<void> scrollAndSettle(
    WidgetTester tester,
    Finder finder,
    Offset offset, {
    Duration? settleDuration,
  }) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle(
      settleDuration ?? const Duration(milliseconds: 500),
    );
  }

  /// Verify widget exists
  static void expectWidgetExists<T extends Widget>() {
    expect(find.byType(T), findsOneWidget);
  }

  /// Verify widget does not exist
  static void expectWidgetNotExists<T extends Widget>() {
    expect(find.byType(T), findsNothing);
  }

  /// Verify text exists
  static void expectTextExists(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verify text does not exist
  static void expectTextNotExists(String text) {
    expect(find.text(text), findsNothing);
  }

  /// Verify widget count
  static void expectWidgetCount<T extends Widget>(int count) {
    expect(find.byType(T), findsNWidgets(count));
  }

  // Provider overrides are handled directly in test files

  /// Wait for widget to appear
  static Future<void> waitForWidget<T extends Widget>(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await TestUtils.waitForCondition(
      () => find.byType(T).evaluate().isNotEmpty,
      timeout: timeout,
    );
    await tester.pumpAndSettle();
  }

  /// Wait for text to appear
  static Future<void> waitForText(
    WidgetTester tester,
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await TestUtils.waitForCondition(
      () => find.text(text).evaluate().isNotEmpty,
      timeout: timeout,
    );
    await tester.pumpAndSettle();
  }

  /// Simulate loading state
  static Future<void> simulateLoadingState(
    WidgetTester tester, {
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    await tester.pump();
    await Future.delayed(duration);
    await tester.pumpAndSettle();
  }

  /// Verify loading indicator
  static void expectLoadingIndicator() {
    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
    );
  }

  /// Verify error message
  static void expectErrorMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  // Router testing methods removed - use GoRouter directly in tests

  /// Create test gesture detector
  static Widget createTestGestureDetector({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }

  /// Simulate gesture
  static Future<void> simulateGesture(
    WidgetTester tester,
    Finder finder,
    String gesture,
  ) async {
    switch (gesture) {
      case 'tap':
        await tester.tap(finder);
        break;
      case 'longPress':
        await tester.longPress(finder);
        break;
      case 'doubleTap':
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(finder);
        break;
    }
    await tester.pumpAndSettle();
  }

  /// Create test scaffold
  static Widget createTestScaffold({
    required Widget body,
    AppBar? appBar,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
  }) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  /// Verify scaffold elements
  static void verifyScaffoldElements({
    bool hasAppBar = false,
    bool hasFloatingActionButton = false,
    bool hasBottomNavigationBar = false,
  }) {
    if (hasAppBar) {
      expect(find.byType(AppBar), findsOneWidget);
    }
    if (hasFloatingActionButton) {
      expect(find.byType(FloatingActionButton), findsOneWidget);
    }
    if (hasBottomNavigationBar) {
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    }
  }

  /// Create test list view
  static Widget createTestListView({
    required List<Widget> children,
    ScrollController? controller,
  }) {
    return ListView(
      controller: controller,
      children: children,
    );
  }

  /// Scroll to widget in list
  static Future<void> scrollToWidget(
    WidgetTester tester,
    Finder listFinder,
    Finder itemFinder,
  ) async {
    await tester.scrollUntilVisible(
      itemFinder,
      500.0,
      scrollable: listFinder,
    );
    await tester.pumpAndSettle();
  }
}