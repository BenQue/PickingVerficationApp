import 'package:equatable/equatable.dart';

/// 应用更新信息实体
class UpdateInfo extends Equatable {
  /// 版本号（用于比较）
  final int versionCode;

  /// 版本名称（显示用）
  final String versionName;

  /// APK下载地址
  final String downloadUrl;

  /// 更新日志
  final String updateLog;

  /// 是否强制更新
  final bool forceUpdate;

  /// 最低支持版本号
  final int minSupportedVersion;

  /// APK文件大小（字节）
  final int fileSize;

  /// 发布日期
  final String? releaseDate;

  /// MD5校验值（可选）
  final String? md5;

  const UpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.downloadUrl,
    required this.updateLog,
    required this.forceUpdate,
    required this.minSupportedVersion,
    required this.fileSize,
    this.releaseDate,
    this.md5,
  });

  /// 格式化文件大小为可读字符串
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  List<Object?> get props => [
        versionCode,
        versionName,
        downloadUrl,
        updateLog,
        forceUpdate,
        minSupportedVersion,
        fileSize,
        releaseDate,
        md5,
      ];
}
