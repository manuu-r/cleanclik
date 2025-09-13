import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/base_widget_test.dart';
import '../mock_providers.dart';
import '../mock_screens.dart';

void main() {
  group('Authentication Screens Golden Tests', () {
    late BaseWidgetTest baseTest;

    setUp(() {
      baseTest = BaseWidgetTest();
    });

    group('LoginScreen', () {
      testGoldens('LoginScreen renders correctly in light theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const LoginScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_out', 'user': null})),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('login_screen_light.png'),
        );
      });

      testGoldens('LoginScreen renders correctly in dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const LoginScreen(),
          theme: ThemeData.dark(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_out', 'user': null})),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('login_screen_dark.png'),
        );
      });

      testGoldens('LoginScreen with loading state', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const LoginScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue<Map<String, dynamic>>.loading()),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pump(); // Don't settle to capture loading state

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('login_screen_loading.png'),
        );
      });

      testGoldens('LoginScreen with error state', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const LoginScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue<Map<String, dynamic>>.error(
              'Invalid email or password',
              StackTrace.empty,
            )),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('login_screen_error.png'),
        );
      });
    });

    group('SignUpScreen', () {
      testGoldens('SignUpScreen renders correctly in light theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const SignUpScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_out', 'user': null})),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(SignUpScreen),
          matchesGoldenFile('signup_screen_light.png'),
        );
      });

      testGoldens('SignUpScreen renders correctly in dark theme', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const SignUpScreen(),
          theme: ThemeData.dark(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_out', 'user': null})),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(SignUpScreen),
          matchesGoldenFile('signup_screen_dark.png'),
        );
      });

      testGoldens('SignUpScreen tablet layout', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const SignUpScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_out', 'user': null})),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(1024, 768),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(SignUpScreen),
          matchesGoldenFile('signup_screen_tablet.png'),
        );
      });
    });

    group('EmailVerificationScreen', () {
      testGoldens('EmailVerificationScreen renders correctly', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const EmailVerificationScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'email_verification_pending', 'user': null})),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(EmailVerificationScreen),
          matchesGoldenFile('email_verification_screen.png'),
        );
      });
    });

    group('AuthWrapper', () {
      testGoldens('AuthWrapper with unauthenticated state', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const AuthWrapper(child: Placeholder()),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue.data({'status': 'signed_out', 'user': null})),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(AuthWrapper),
          matchesGoldenFile('auth_wrapper_unauthenticated.png'),
        );
      });

      testGoldens('AuthWrapper with loading state', (tester) async {
        await loadAppFonts();
        
        final widget = baseTest.createTestWidget(
          const AuthWrapper(child: Placeholder()),
          overrides: [
            authStateProvider.overrideWith((ref) => const AsyncValue<Map<String, dynamic>>.loading()),
          ],
        );

        await tester.pumpWidgetBuilder(
          widget,
          surfaceSize: const Size(375, 812),
        );
        await tester.pump(); // Don't settle to capture loading state

        await expectLater(
          find.byType(AuthWrapper),
          matchesGoldenFile('auth_wrapper_loading.png'),
        );
      });
    });
  });
}