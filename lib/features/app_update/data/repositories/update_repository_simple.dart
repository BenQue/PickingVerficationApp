import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/apk_installer.dart';
import '../../domain/entities/update_info.dart';
import '../../domain/repositories/update_repository.dart';
import '../models/update_info_model.dart';

/// 简化版应用更新仓库实现 (使用dio下载 + 原生平台通道安装APK)
class UpdateRepositorySimple implements UpdateRepository {
  final Dio dio;
  final String updateServerUrl;

  /// 下载进度回调
  Function(int received, int total)? _onProgress;

  /// 下载取消令牌
  CancelToken? _cancelToken;

  UpdateRepositorySimple({
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
      // 1. 获取下载目录
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/warehouse_app_update.apk';

      // 2. 删除旧的APK文件（如果存在）
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 3. 创建取消令牌
      _cancelToken = CancelToken();

      // 4. 使用dio下载APK
      await dio.download(
        downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _onProgress?.call(received, total);
          }
        },
      );

      // 5. 下载完成，调用安装
      final success = await ApkInstaller.installApk(savePath);

      if (success) {
        return const Right(true);
      } else {
        return const Left(ServerFailure('打开APK文件失败'));
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return const Left(ServerFailure('下载已取消'));
      } else {
        return Left(ServerFailure('下载APK失败: ${e.message}'));
      }
    } catch (e) {
      return Left(ServerFailure('下载或安装失败: $e'));
    }
  }

  @override
  Future<void> cancelDownload() async {
    _cancelToken?.cancel('用户取消下载');
    _cancelToken = null;
  }

  /// 设置下载进度回调
  void setProgressCallback(Function(int received, int total) callback) {
    _onProgress = callback;
  }
}
