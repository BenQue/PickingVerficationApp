import 'package:equatable/equatable.dart';
import '../../domain/entities/update_info.dart';

/// 更新状态基类
abstract class UpdateState extends Equatable {
  const UpdateState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class UpdateInitial extends UpdateState {
  const UpdateInitial();
}

/// 检查更新中
class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

/// 有新版本可用
class UpdateAvailable extends UpdateState {
  final UpdateInfo updateInfo;

  const UpdateAvailable(this.updateInfo);

  @override
  List<Object?> get props => [updateInfo];
}

/// 已是最新版本
class UpdateNotAvailable extends UpdateState {
  /// 是否显示提示消息
  final bool showMessage;

  /// 时间戳，确保每次状态都被认为是新的
  final int timestamp;

  UpdateNotAvailable({this.showMessage = false})
      : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [showMessage, timestamp];
}

/// 下载中
class UpdateDownloading extends UpdateState {
  final double progress;
  final int currentBytes;
  final int totalBytes;

  const UpdateDownloading({
    required this.progress,
    required this.currentBytes,
    required this.totalBytes,
  });

  /// 格式化的进度文本
  String get progressText {
    final current = (currentBytes / (1024 * 1024)).toStringAsFixed(1);
    final total = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    return '$current MB / $total MB';
  }

  /// 百分比文本
  String get percentText {
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  @override
  List<Object?> get props => [progress, currentBytes, totalBytes];
}

/// 下载完成（准备安装）
class UpdateDownloaded extends UpdateState {
  const UpdateDownloaded();
}

/// 更新失败
class UpdateFailure extends UpdateState {
  final String message;

  /// 时间戳，确保每次状态都被认为是新的
  final int timestamp;

  UpdateFailure(this.message)
      : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [message, timestamp];
}

/// 已忽略更新
class UpdateIgnored extends UpdateState {
  const UpdateIgnored();
}
