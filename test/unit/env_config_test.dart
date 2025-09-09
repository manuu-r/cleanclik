import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/utils/env_config.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('EnvConfig', () {
    setUp(() {
      EnvConfig.reset();
    });

    test('should throw when not loaded', () {
      expect(
        () => EnvConfig.get('TEST_KEY'),
        throwsA(isA<StateError>()),
      );
    });

    test('should return empty string for missing key', () async {
      await EnvConfig.load();
      expect(EnvConfig.get('MISSING_KEY'), equals(''));
    });

    test('should return default value for missing key', () async {
      await EnvConfig.load();
      expect(
        EnvConfig.getOrDefault('MISSING_KEY', 'default'),
        equals('default'),
      );
    });

    test('should check if key exists', () async {
      await EnvConfig.load();
      expect(EnvConfig.has('MISSING_KEY'), isFalse);
    });

    test('should load successfully', () async {
      await EnvConfig.load();
      // Should not throw
      expect(EnvConfig.getAll(), isA<Map<String, String>>());
    });

    test('should handle multiple loads', () async {
      await EnvConfig.load();
      await EnvConfig.load(); // Should not throw or cause issues
      expect(EnvConfig.getAll(), isA<Map<String, String>>());
    });
  });
}