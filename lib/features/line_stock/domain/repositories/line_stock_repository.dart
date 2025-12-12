import 'package:dartz/dartz.dart';
import '../entities/line_stock_entity.dart';
import '../entities/handover_item.dart';
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

  /// Query stock by material code
  /// Returns either a Failure or list of LineStock entities for all batches
  Future<Either<Failure, List<LineStock>>> queryByMaterialCode({
    required String materialCode,
    int? factoryId,
  });

  /// Transfer stock to target location
  /// Returns either a Failure or success boolean
  Future<Either<Failure, bool>> transferStock({
    required String locationCode,
    required List<String> barCodes,
  });

  /// Query handover item by barcode for receiving
  /// Returns either a Failure or HandoverItem entity
  Future<Either<Failure, HandoverItem>> getHandoverByBarcode({
    required String barcode,
    int? factoryId,
  });

  /// Confirm handover/receiving for given barcodes
  /// Returns either a Failure or success message
  Future<Either<Failure, String>> confirmHandover({
    required List<String> barCodes,
  });
}
