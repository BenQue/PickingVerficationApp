import 'package:dio/dio.dart';
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
      final response = await dio.get(
        LineStockConstants.queryApiPath,
        queryParameters: {
          'barcode': barcode,
          if (factoryId != null) 'factoryid': factoryId,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => LineStockModel.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data!;
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
