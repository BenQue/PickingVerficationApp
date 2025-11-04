import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/update_info.dart';

/// 应用更新仓库接口
abstract class UpdateRepository {
  /// 检查是否有新版本
  /// 返回 Right(UpdateInfo) 如果有新版本
  /// 返回 Right(null) 如果已是最新版本
  /// 返回 Left(Failure) 如果发生错误
  Future<Either<Failure, UpdateInfo?>> checkForUpdate();

  /// 下载并安装APK
  /// 返回 Right(true) 如果成功启动下载和安装
  /// 返回 Left(Failure) 如果发生错误
  Future<Either<Failure, bool>> downloadAndInstall(String downloadUrl);

  /// 取消下载
  Future<void> cancelDownload();
}
