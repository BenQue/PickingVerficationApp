import 'package:dartz/dartz.dart';
import '../../domain/repositories/line_stock_repository.dart';
import '../../domain/entities/line_stock_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/line_stock_remote_datasource.dart';

/// Repository Implementation
class LineStockRepositoryImpl implements LineStockRepository {
  final LineStockRemoteDataSource remoteDataSource;

  LineStockRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, LineStock>> queryByBarcode({
    required String barcode,
    int? factoryId,
  }) async {
    try {
      final model = await remoteDataSource.queryByBarcode(
        barcode: barcode,
        factoryId: factoryId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('未知错误：$e'));
    }
  }

  @override
  Future<Either<Failure, bool>> transferStock({
    required String locationCode,
    required List<String> barCodes,
  }) async {
    try {
      final result = await remoteDataSource.transferStock(
        locationCode: locationCode,
        barCodes: barCodes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('未知错误：$e'));
    }
  }
}
