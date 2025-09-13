import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'mock_services.mocks.dart';

// This is a helper class, not a test file
void main() {
  // No tests in this file - it's a helper class
}

/// Base class for service unit tests with common setup and teardown
abstract class BaseServiceTest {
  late MockGoRouter mockRouter;
  ProviderContainer? container;
  late List<Override> providerOverrides;

  /// Set up mocks and test environment before each test
  void setUpMocks() {
    mockRouter = MockGoRouter();
    providerOverrides = [];
  }

  /// Set up Riverpod container with provider overrides
  void setUpRiverpodContainer() {
    container = ProviderContainer(
      overrides: providerOverrides,
    );
  }

  /// Clean up resources after each test
  void tearDownMocks() {
    container?.dispose();
    reset(mockRouter);
  }

  /// Add a provider override to the test container
  void addProviderOverride(Override override) {
    providerOverrides.add(override);
  }

  /// Configure mock router with default navigation behavior
  void configureMockRouter() {
    when(mockRouter.go(any)).thenReturn(null);
    when(mockRouter.push(any)).thenAnswer((_) async => null);
    when(mockRouter.pop()).thenReturn(null);
  }

  /// Create a test-specific provider container with overrides
  ProviderContainer createTestContainer(List<Override> overrides) {
    return ProviderContainer(
      overrides: [...providerOverrides, ...overrides],
    );
  }
}