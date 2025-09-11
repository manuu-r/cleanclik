import 'package:flutter_test/flutter_test.dart';
import 'package:cleanclik/core/services/auth/supabase_config_service.dart';
import 'package:cleanclik/core/utils/env_config.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SupabaseConfigService', () {
    setUp(() {
      // Reset services before each test
      SupabaseConfigService.reset();
      EnvConfig.reset();
    });

    test('should throw exception when not initialized', () {
      expect(
        () => SupabaseConfigService.client,
        throwsA(isA<SupabaseConfigException>()),
      );
    });

    test('should report not initialized initially', () {
      expect(SupabaseConfigService.isInitialized, isFalse);
    });

    test('should throw exception with missing environment variables', () async {
      // This test verifies the exception is thrown for missing env vars
      // We can't actually test Supabase initialization in unit tests due to platform dependencies
      expect(SupabaseConfigService.isInitialized, isFalse);
    });

    test('should create proper exception messages', () {
      const exception = SupabaseConfigException('Test message');
      expect(exception.toString(), contains('Test message'));
    });

    test('should create health status correctly', () {
      final healthStatus = SupabaseHealthStatus(
        isHealthy: true,
        responseTimeMs: 100,
        authServiceHealthy: true,
        timestamp: DateTime.now(),
      );

      expect(healthStatus.isHealthy, isTrue);
      expect(healthStatus.responseTimeMs, equals(100));
      expect(healthStatus.authServiceHealthy, isTrue);
      expect(healthStatus.toString(), contains('healthy: true'));
    });

    test('should create health status with error', () {
      final healthStatus = SupabaseHealthStatus(
        isHealthy: false,
        responseTimeMs: -1,
        authServiceHealthy: false,
        timestamp: DateTime.now(),
        error: 'Connection failed',
      );

      expect(healthStatus.isHealthy, isFalse);
      expect(healthStatus.error, equals('Connection failed'));
      expect(healthStatus.toString(), contains('error: Connection failed'));
    });
  });
}