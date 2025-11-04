import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:r_upgrade/r_upgrade.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/update_info.dart';
import '../../domain/repositories/update_repository.dart';
import '../models/update_info_model.dart';

/// 应用更新仓库实现
class UpdateRepositoryImpl implements UpdateRepository {
  final Dio dio;
  final String updateServerUrl;

  /// 下载任务ID
  int? _downloadId;

  UpdateRepositoryImpl({
    required this.dio,
    required this.updateServerUrl,
  });

  @override
  Future<Either<Failure, UpdateInfo?>> checkForUpdate() async {
    try {
      // 1. 请求服务器版本信息
      final response = await dio.get(
        '$updateServerUrl/version.json',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      // 2. 解析服务器版本信息
      final serverVersionModel = UpdateInfoModel.fromJson(response.data);
      final serverVersion = serverVersionModel.toEntity();

      // 3. 获取当前应用版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(packageInfo.buildNumber);

      // 4. 比较版本号
      if (serverVersion.versionCode > currentVersionCode) {
        // 有新版本
        return Right(serverVersion);
      } else if (currentVersionCode < serverVersion.minSupportedVersion) {
        // 当前版本过低，强制更新
        return Right(serverVersion);
      } else {
        // 已是最新版本
        return const Right(null);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return const Left(NetworkFailure('网络连接超时，请检查网络设置'));
      } else if (e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure('无法连接到更新服务器'));
      } else {
        return Left(ServerFailure('检查更新失败: ${e.message}'));
      }
    } catch (e) {
      return Left(ServerFailure('检查更新失败: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> downloadAndInstall(String downloadUrl) async {
    try {
      // 使用 r_upgrade 下载并安装APK
      _downloadId = await RUpgrade.upgrade(
        downloadUrl,
        fileName: 'warehouse_app_update.apk',
        isAutoRequestInstall: true, // 下载完成后自动弹出安装对话框
        upgradeFlavor: UpgradeFlavor.normal,
        notificationVisibility: NotificationVisibility.VISIBILITY_VISIBLE,
        notificationStyle: NotificationStyle.planTime,
        useDownloadManager: false, // 使用r_upgrade内置下载器
      );

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('下载APK失败: $e'));
    }
  }

  @override
  Future<void> cancelDownload() async {
    if (_downloadId != null) {
      try {
        await RUpgrade.cancel(_downloadId!);
        _downloadId = null;
      } catch (e) {
        // 忽略取消下载的错误
      }
    }
  }

  /// 获取下载进度流
  Stream<DownloadInfo> get downloadProgressStream {
    return RUpgrade.stream;
  }
}
