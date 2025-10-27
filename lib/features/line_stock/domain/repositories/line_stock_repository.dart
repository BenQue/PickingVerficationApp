import 'package:dartz/dartz.dart';
import '../entities/line_stock_entity.dart';
import '../../../../core/error/failures.dart';

/// Line Stock Repository Interface
/// Defines the contract for line stock data operations
abstract class LineStockRepository {
  /// Query stock by barcode
  /// Returns either a Failure or LineStock entity
  Future<Either<Failure, LineStock>> queryByBarcode({
    required String barcode,
    int? factoryId,
  });

  /// Transfer stock to target location
  /// Returns either a Failure or success boolean
  Future<Either<Failure, bool>> transferStock({
    required String locationCode,
    required List<String> barCodes,
  });
}
