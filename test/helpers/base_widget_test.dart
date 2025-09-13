import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

import 'mock_services.mocks.dart';

// This is a helper class, not a test file
void main() {
  // No tests in this file - it's a helper class
}

/// Base class for widget tests with Riverpod and routing support
class BaseWidgetTest {
  late MockGoRouter mockRouter;
  ProviderContainer? container;
  late List<Override> providerOverrides;

  BaseWidgetTest() {
    mockRouter = MockGoRouter();
    providerOverrides = [];
    configureMockRouter();
  }

  /// Set up widget test environment
  void setUpWidgetTest() {
    mockRouter = MockGoRouter();
    providerOverrides = [];
    configureMockRouter();
  }

  /// Clean up widget test resources
  void tearDownWidgetTest() {
    container?.dispose();
    reset(mockRouter);
  }

  /// Create a test widget wrapped with necessary providers
  Widget createTestWidget(
    Widget child, {
    List<Override> overrides = const [],
    ThemeData? theme,
  }) {
    final allOverrides = [...providerOverrides, ...overrides];
    container = ProviderContainer(overrides: allOverrides);
    
    return UncontrolledProviderScope(
      container: container!,
      child: MaterialApp.router(
        theme: theme ?? ThemeData(),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => child,
            ),
          ],
        ),
      ),
    );
  }

  /// Create a test widget with custom router configuration
  Widget createTestWidgetWithRouter(Widget child, GoRouter router) {
    container = ProviderContainer(overrides: providerOverrides);
    
    return UncontrolledProviderScope(
      container: container!,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  /// Pump widget and settle animations
  Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Override providers for testing
  void overrideProviders(List<Override> overrides) {
    providerOverrides.addAll(overrides);
  }

  /// Configure mock router with default behavior
  void configureMockRouter() {
    when(mockRouter.go(any)).thenReturn(null);
    when(mockRouter.push(any)).thenAnswer((_) async => null);
    when(mockRouter.pop()).thenReturn(null);
    when(mockRouter.canPop()).thenReturn(true);
  }

  /// Create a provider override for testing (simplified)
  void addProviderOverride(Override override) {
    providerOverrides.add(override);
  }

  /// Find widget by type in the widget tree
  Finder findWidgetByType<T extends Widget>() {
    return find.byType(T);
  }

  /// Find widget by key in the widget tree
  Finder findWidgetByKey(Key key) {
    return find.byKey(key);
  }

  /// Verify that a widget exists in the tree
  void expectWidgetExists<T extends Widget>() {
    expect(find.byType(T), findsOneWidget);
  }

  /// Verify that a widget does not exist in the tree
  void expectWidgetNotExists<T extends Widget>() {
    expect(find.byType(T), findsNothing);
  }
}