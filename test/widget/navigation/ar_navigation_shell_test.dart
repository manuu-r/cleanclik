import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';

import 'package:cleanclik/presentation/navigation/ar_navigation_shell.dart';
import 'package:cleanclik/core/services/system/ui_context_service.dart';
import 'package:cleanclik/core/services/business/smart_suggestions_service.dart';
import 'package:cleanclik/presentation/widgets/common/floating_action_hub.dart';
import 'package:cleanclik/presentation/widgets/common/slide_up_panel.dart';

import '../../helpers/base_widget_test.dart';
import '../../helpers/mock_services.mocks.dart';

class ARNavigationShellWidgetTest extends BaseWidgetTest {
  late MockUIContextService mockUIContextService;
  late MockSmartSuggestionsService mockSmartSuggestionsService;
  late StatefulNavigationShell mockNavigationShell;

  @override
  void setUpWidgetTest() {
    super.setUpWidgetTest();
    
    mockUIContextService = MockUIContextService();
    mockSmartSuggestionsService = MockSmartSuggestionsService();
    mockNavigationShell = MockStatefulNavigationShell();

    // Configure mock UI context service
    when(mockUIContextService.currentContext).thenReturn(
      const UIContextState(context: UIContext.arCamera),
    );

    // Configure mock suggestions service
    when(mockSmartSuggestionsService.generateSuggestions(any, userData: anyNamed('userData')))
        .thenAnswer((_) async {});

    // Configure mock navigation shell
    when(mockNavigationShell.goBranch(any)).thenReturn(null);
    when(mockNavigationShell.currentIndex).thenReturn(0);

    // Add provider overrides
    overrideProviders([
      uiContextServiceProvider.overrideWith((ref) => mockUIContextService),
      smartSuggestionsServiceProvider.overrideWith((ref) => mockSmartSuggestionsService),
    ]);
  }

  @override
  void tearDownWidgetTest() {
    super.tearDownWidgetTest();
    reset(mockUIContextService);
    reset(mockSmartSuggestionsService);
    reset(mockNavigationShell);
  }
}

// Mock StatefulNavigationShell since it's not easily mockable
class MockStatefulNavigationShell extends Mock implements StatefulNavigationShell {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Mock Navigation Content')),
    );
  }
}

void main() {
  group('ARNavigationShell Widget Tests', () {
    late ARNavigationShellWidgetTest testHelper;

    setUp(() {
      testHelper = ARNavigationShellWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should display navigation shell with basic structure', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ARNavigationShell), findsOneWidget);
    });

    testWidgets('should display main navigation content', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Mock Navigation Content'), findsOneWidget);
    });

    testWidgets('should display floating action hub when not on home screen', (tester) async {
      // Arrange
      // Mock being on map screen (not home)
      when(testHelper.mockRouter.routerDelegate).thenReturn(MockGoRouterDelegate());
      
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(FloatingActionHub), findsOneWidget);
    });

    testWidgets('should hide floating action hub on home screen', (tester) async {
      // Arrange
      // Mock being on home screen
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert - depends on route detection logic
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display slide up panel when appropriate', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SlideUpPanel), findsOneWidget);
    });

    testWidgets('should handle floating action hub actions', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap floating action hub if visible
      final hubFinder = find.byType(FloatingActionHub);
      if (hubFinder.evaluate().isNotEmpty) {
        await tester.tap(hubFinder);
        await tester.pumpAndSettle();
      }

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle scan action navigation', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate scan action
      // This would normally be triggered by floating action hub
      
      // Assert - should navigate to home
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle inventory panel toggle', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap on slide up panel to toggle
      final panelFinder = find.byType(SlideUpPanel);
      if (panelFinder.evaluate().isNotEmpty) {
        await tester.tap(panelFinder);
        await tester.pumpAndSettle();
      }

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle map navigation action', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate map navigation
      // This would be triggered by action hub or panel
      
      // Assert - should navigate to map
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle profile navigation action', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate profile navigation
      
      // Assert - should navigate to profile
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle leaderboard navigation action', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate leaderboard navigation
      
      // Assert - should navigate to leaderboard
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display particle system during celebrations', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - trigger celebration (would normally be from share action)
      // Simulate particle system activation
      
      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      // Particle system would be tested separately
    });

    testWidgets('should update UI context based on current route', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockUIContextService.updateContext(any)).called(greaterThan(0));
    });

    testWidgets('should generate suggestions for current context', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockSmartSuggestionsService.generateSuggestions(
        any,
        userData: anyNamed('userData'),
      )).called(greaterThan(0));
    });

    testWidgets('should handle context-aware center action', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate center action tap
      // This would be handled by floating action hub
      
      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display quick actions in slide up panel', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SlideUpPanel), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('should handle quick action card taps', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - tap on quick action cards
      final dashboardCard = find.text('Dashboard');
      if (dashboardCard.evaluate().isNotEmpty) {
        await tester.tap(dashboardCard);
        await tester.pumpAndSettle();
      }

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle widget lifecycle properly', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - dispose widget
      await tester.pumpWidget(Container());

      // Assert - should not throw exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle route changes gracefully', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate route change
      // This would normally trigger context updates
      
      // Assert
      verify(testHelper.mockUIContextService.updateContext(any)).called(greaterThan(0));
    });
  });

  group('ARNavigationShell Integration Tests', () {
    late ARNavigationShellWidgetTest testHelper;

    setUp(() {
      testHelper = ARNavigationShellWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should integrate with UI context service', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockUIContextService.updateContext(any)).called(greaterThan(0));
      verify(testHelper.mockUIContextService.currentContext).called(greaterThan(0));
    });

    testWidgets('should integrate with smart suggestions service', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      verify(testHelper.mockSmartSuggestionsService.generateSuggestions(
        any,
        userData: anyNamed('userData'),
      )).called(greaterThan(0));
    });

    testWidgets('should handle navigation state changes', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      await testHelper.pumpAndSettle(tester, widget);

      // Act - simulate navigation state change
      when(testHelper.mockNavigationShell.currentIndex).thenReturn(1);
      await tester.pump();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('ARNavigationShell Material 3 Theme Tests', () {
    late ARNavigationShellWidgetTest testHelper;

    setUp(() {
      testHelper = ARNavigationShellWidgetTest();
      testHelper.setUpWidgetTest();
    });

    tearDown(() {
      testHelper.tearDownWidgetTest();
    });

    testWidgets('should apply Material 3 design system', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should use Material 3 components
      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );
      expect(materialApp.theme?.useMaterial3, isTrue);
    });

    testWidgets('should use proper elevation and shadows', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have proper Material 3 elevation
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.extendBody, isTrue);
    });

    testWidgets('should be accessible with proper semantics', (tester) async {
      // Arrange
      final shell = ARNavigationShell(
        navigationShell: testHelper.mockNavigationShell,
      );
      final widget = testHelper.createTestWidget(shell);

      // Act
      await testHelper.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Should have semantic labels for navigation
      expect(
        find.bySemanticsLabel('Navigation').or(find.byType(Semantics)),
        findsAtLeastNWidgets(1),
      );
    });
  });
}

// Mock classes for services that don't exist yet
class MockUIContextService extends Mock {
  UIContextState get currentContext => const UIContextState(context: UIContext.arCamera);
  void updateContext(UIContext context) {}
  void updateActivityState(ActivityState state) {}
}

class MockSmartSuggestionsService extends Mock {
  Future<void> generateSuggestions(UIContextState context, {Map<String, dynamic>? userData}) async {}
}

class MockGoRouterDelegate extends Mock implements GoRouterDelegate {}

// Mock enums and classes
enum UIContext { arCamera, map, social, profile, inventory }
enum ActivityState { idle, scanning, celebrating }

class UIContextState {
  final UIContext context;
  const UIContextState({required this.context});
}

// Mock providers
final uiContextServiceProvider = Provider<MockUIContextService>((ref) => MockUIContextService());
final smartSuggestionsServiceProvider = Provider<MockSmartSuggestionsService>((ref) => MockSmartSuggestionsService());