import '../../domain/entities/update_info.dart';

/// 应用更新信息数据模型
class UpdateInfoModel extends UpdateInfo {
  const UpdateInfoModel({
    required super.versionCode,
    required super.versionName,
    required super.downloadUrl,
    required super.updateLog,
    required super.forceUpdate,
    required super.minSupportedVersion,
    required super.fileSize,
    super.releaseDate,
    super.md5,
  });

  /// 从JSON创建模型
  factory UpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return UpdateInfoModel(
      versionCode: json['versionCode'] as int,
      versionName: json['versionName'] as String,
      downloadUrl: json['downloadUrl'] as String,
      updateLog: json['updateLog'] as String,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      minSupportedVersion: json['minSupportedVersion'] as int? ?? 0,
      fileSize: json['fileSize'] as int,
      releaseDate: json['releaseDate'] as String?,
      md5: json['md5'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'versionCode': versionCode,
      'versionName': versionName,
      'downloadUrl': downloadUrl,
      'updateLog': updateLog,
      'forceUpdate': forceUpdate,
      'minSupportedVersion': minSupportedVersion,
      'fileSize': fileSize,
      if (releaseDate != null) 'releaseDate': releaseDate,
      if (md5 != null) 'md5': md5,
    };
  }

  /// 转换为实体
  UpdateInfo toEntity() {
    return UpdateInfo(
      versionCode: versionCode,
      versionName: versionName,
      downloadUrl: downloadUrl,
      updateLog: updateLog,
      forceUpdate: forceUpdate,
      minSupportedVersion: minSupportedVersion,
      fileSize: fileSize,
      releaseDate: releaseDate,
      md5: md5,
    );
  }
}
