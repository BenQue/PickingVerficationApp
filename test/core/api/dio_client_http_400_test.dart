import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/core/api/dio_client.dart';

/// 测试 DioClient 对 HTTP 400 错误的处理
void main() {
  group('DioClient HTTP 400 Handling', () {
    late DioClient dioClient;

    setUp(() {
      dioClient = DioClient();
      dioClient.initialize();
    });

    test('应该将 HTTP 400 视为错误并触发 DioException', () async {
      // 这个测试验证 validateStatus 配置是否正确
      // HTTP 400 应该触发异常，而不是被当作正常响应

      final dio = dioClient.dio;

      // 验证 validateStatus 配置
      final baseOptions = dio.options;

      // 测试不同状态码
      expect(baseOptions.validateStatus!(200), isTrue,
          reason: 'HTTP 200 应该被视为有效响应');
      expect(baseOptions.validateStatus!(201), isTrue,
          reason: 'HTTP 201 应该被视为有效响应');
      expect(baseOptions.validateStatus!(300), isTrue,
          reason: 'HTTP 300 应该被视为有效响应');
      expect(baseOptions.validateStatus!(399), isTrue,
          reason: 'HTTP 399 应该被视为有效响应');

      // 关键测试：400-499 应该被视为错误
      expect(baseOptions.validateStatus!(400), isFalse,
          reason: 'HTTP 400 应该被视为错误响应，触发 DioException');
      expect(baseOptions.validateStatus!(404), isFalse,
          reason: 'HTTP 404 应该被视为错误响应');
      expect(baseOptions.validateStatus!(500), isFalse,
          reason: 'HTTP 500 应该被视为错误响应');
    });

    test('验证 DioClient 的基本配置', () {
      final dio = dioClient.dio;
      final options = dio.options;

      // 验证基本配置
      expect(options.baseUrl, equals('http://10.163.130.173:8001'));
      expect(options.connectTimeout, equals(const Duration(seconds: 10)));
      expect(options.receiveTimeout, equals(const Duration(seconds: 10)));
      expect(options.sendTimeout, equals(const Duration(seconds: 10)));

      // 验证请求头
      expect(options.headers['Content-Type'], equals('application/json'));
      expect(options.headers['Accept'], equals('application/json'));
    });
  });
}
