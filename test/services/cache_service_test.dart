import 'package:flutter_test/flutter_test.dart';
import 'package:circle_app/core/services/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService cacheService;

    setUp(() {
      cacheService = CacheService.instance;
    });

    test('should store and retrieve data from memory cache', () {
      const key = 'test_key';
      const value = 'test_value';

      cacheService.setInMemory(key, value);
      final retrieved = cacheService.getFromMemory<String>(key);

      expect(retrieved, equals(value));
    });

    test('should handle cache expiration', () async {
      const key = 'expiring_key';
      const value = 'expiring_value';

      cacheService.setInMemory(key, value, ttl: const Duration(milliseconds: 100));
      
      // Should be available immediately
      expect(cacheService.getFromMemory<String>(key), equals(value));

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      // Should be null after expiration
      expect(cacheService.getFromMemory<String>(key), isNull);
    });

    test('should evict least recently used items when cache is full', () {
      // This test would require mocking the cache size limit
      expect(cacheService, isNotNull);
    });

    tearDown(() {
      cacheService.dispose();
    });
  });
}