import 'package:equatable/equatable.dart';

/// 更新事件基类
abstract class UpdateEvent extends Equatable {
  const UpdateEvent();

  @override
  List<Object?> get props => [];
}

/// 检查更新事件
class CheckUpdateRequested extends UpdateEvent {
  /// 是否静默检查（不显示"已是最新版本"提示）
  final bool silent;

  const CheckUpdateRequested({this.silent = true});

  @override
  List<Object?> get props => [silent];
}

/// 开始下载更新事件
class DownloadUpdateRequested extends UpdateEvent {
  final String downloadUrl;

  const DownloadUpdateRequested(this.downloadUrl);

  @override
  List<Object?> get props => [downloadUrl];
}

/// 取消下载事件
class CancelDownloadRequested extends UpdateEvent {
  const CancelDownloadRequested();
}

/// 下载进度更新事件
class DownloadProgressUpdated extends UpdateEvent {
  final double progress;
  final int currentBytes;
  final int totalBytes;

  const DownloadProgressUpdated({
    required this.progress,
    required this.currentBytes,
    required this.totalBytes,
  });

  @override
  List<Object?> get props => [progress, currentBytes, totalBytes];
}

/// 忽略此次更新事件
class IgnoreUpdateRequested extends UpdateEvent {
  const IgnoreUpdateRequested();
}
