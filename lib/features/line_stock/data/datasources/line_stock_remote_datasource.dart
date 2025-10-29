import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api_response_model.dart';
import '../models/line_stock_model.dart';
import '../models/transfer_request_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../core/constants.dart';

/// Remote Data Source Interface
abstract class LineStockRemoteDataSource {
  /// Query stock by barcode
  Future<LineStockModel> queryByBarcode({
    required String barcode,
    int? factoryId,
  });

  /// Transfer stock to target location
  Future<bool> transferStock({
    required String locationCode,
    required List<String> barCodes,
  });
}

/// Remote Data Source Implementation
class LineStockRemoteDataSourceImpl implements LineStockRemoteDataSource {
  final Dio dio;

  LineStockRemoteDataSourceImpl({required this.dio});

  @override
  Future<LineStockModel> queryByBarcode({
    required String barcode,
    int? factoryId,
  }) async {
    try {
      // Use factoryId from parameter, or default to 2 for now (TODO: get from user login)
      final useFactoryId = factoryId ?? 2;

      debugPrint('[LineStock] 开始查询条码: $barcode, factoryId: $useFactoryId');
      debugPrint('[LineStock] API路径: ${LineStockConstants.queryApiPath}');

      final response = await dio.get(
        LineStockConstants.queryApiPath,
        queryParameters: {
          'barcode': barcode,
          'factoryid': useFactoryId,
        },
      );

      debugPrint('[LineStock] 响应状态码: ${response.statusCode}');
      debugPrint('[LineStock] 响应数据: ${response.data}');

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) {
          // Handle case where data might be bool (false) on error
          if (data is Map<String, dynamic>) {
            return LineStockModel.fromJson(data);
          }
          return null;
        },
      );

      debugPrint('[LineStock] API响应解析: success=${apiResponse.isSuccess}, message=${apiResponse.message}');

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        debugPrint('[LineStock] 查询失败: ${apiResponse.message}');
        throw ServerException(apiResponse.message);
      }
    } on ServerException catch (e) {
      debugPrint('[LineStock] ServerException: ${e.toString()}');
      rethrow;
    } on NetworkException catch (e) {
      debugPrint('[LineStock] NetworkException: ${e.toString()}');
      rethrow;
    } on DioException catch (e) {
      debugPrint('[LineStock] DioException: type=${e.type}, message=${e.message}');
      debugPrint('[LineStock] Response: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('[LineStock] 未知错误: $e');
      throw ServerException('${LineStockConstants.unknownError}: $e');
    }
  }

  @override
  Future<bool> transferStock({
    required String locationCode,
    required List<String> barCodes,
  }) async {
    try {
      final request = TransferRequestModel(
        locationCode: locationCode,
        barCodes: barCodes,
      );

      final response = await dio.post(
        LineStockConstants.transferApiPath,
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as bool,
      );

      if (apiResponse.isSuccess) {
        return apiResponse.data ?? false;
      } else {
        throw ServerException(apiResponse.message);
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('${LineStockConstants.unknownError}: $e');
    }
  }

  /// Handle Dio exceptions and convert to domain exceptions
  Exception _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException('网络连接超时');
    } else if (e.type == DioExceptionType.badResponse) {
      final message = e.response?.data['message'] as String?;
      return ServerException(message ?? LineStockConstants.serverError);
    } else {
      return NetworkException(LineStockConstants.networkError);
    }
  }
}
