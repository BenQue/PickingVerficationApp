import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/core/api/dio_client.dart';

void main() {
  group('DioClient Tests', () {
    late DioClient dioClient;

    setUp(() {
      dioClient = DioClient();
    });

    test('should be a singleton', () {
      final instance1 = DioClient();
      final instance2 = DioClient();
      
      expect(identical(instance1, instance2), true);
    });

    test('should initialize without errors', () {
      expect(() => dioClient.initialize(), returnsNormally);
    });

    test('should have dio instance after initialization', () {
      dioClient.initialize();
      expect(dioClient.dio, isNotNull);
    });

    test('should have correct base configuration', () {
      dioClient.initialize();
      final dio = dioClient.dio;
      
      expect(dio.options.baseUrl, 'https://api.example.com');
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 10));
      expect(dio.options.sendTimeout, const Duration(seconds: 10));
      expect(dio.options.headers['Content-Type'], 'application/json');
      expect(dio.options.headers['Accept'], 'application/json');
    });

    test('should have interceptors configured', () {
      dioClient.initialize();
      final dio = dioClient.dio;
      
      // Should have at least 2 interceptors (auth + logging)
      expect(dio.interceptors.length, greaterThanOrEqualTo(2));
    });
  });
}