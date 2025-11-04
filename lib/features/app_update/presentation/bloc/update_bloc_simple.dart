import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/update_repository_simple.dart';
import '../../domain/repositories/update_repository.dart';
import 'update_event.dart';
import 'update_state.dart';

/// 简化版应用更新BLoC
class UpdateBlocSimple extends Bloc<UpdateEvent, UpdateState> {
  final UpdateRepository updateRepository;

  UpdateBlocSimple({required this.updateRepository}) : super(const UpdateInitial()) {
    // 检查更新
    on<CheckUpdateRequested>(_onCheckUpdateRequested);

    // 开始下载
    on<DownloadUpdateRequested>(_onDownloadUpdateRequested);

    // 下载进度更新
    on<DownloadProgressUpdated>(_onDownloadProgressUpdated);

    // 取消下载
    on<CancelDownloadRequested>(_onCancelDownloadRequested);

    // 忽略更新
    on<IgnoreUpdateRequested>(_onIgnoreUpdateRequested);
  }

  /// 处理检查更新
  Future<void> _onCheckUpdateRequested(
    CheckUpdateRequested event,
    Emitter<UpdateState> emit,
  ) async {
    emit(const UpdateChecking());

    final result = await updateRepository.checkForUpdate();

    result.fold(
      (failure) => emit(UpdateFailure(failure.message)),
      (updateInfo) {
        if (updateInfo != null) {
          emit(UpdateAvailable(updateInfo));
        } else {
          emit(UpdateNotAvailable(showMessage: !event.silent));
        }
      },
    );
  }

  /// 处理下载更新
  Future<void> _onDownloadUpdateRequested(
    DownloadUpdateRequested event,
    Emitter<UpdateState> emit,
  ) async {
    // 设置下载进度回调
    if (updateRepository is UpdateRepositorySimple) {
      (updateRepository as UpdateRepositorySimple).setProgressCallback((received, total) {
        add(DownloadProgressUpdated(
          progress: received / total,
          currentBytes: received,
          totalBytes: total,
        ));
      });
    }

    // 开始下载
    emit(const UpdateDownloading(
      progress: 0.0,
      currentBytes: 0,
      totalBytes: 0,
    ));

    final result = await updateRepository.downloadAndInstall(event.downloadUrl);

    result.fold(
      (failure) {
        emit(UpdateFailure(failure.message));
      },
      (_) {
        // 下载完成并已调用安装
        emit(const UpdateDownloaded());
      },
    );
  }

  /// 处理下载进度更新
  void _onDownloadProgressUpdated(
    DownloadProgressUpdated event,
    Emitter<UpdateState> emit,
  ) {
    if (event.progress >= 1.0) {
      // 下载完成
      emit(const UpdateDownloaded());
    } else {
      // 更新进度
      emit(UpdateDownloading(
        progress: event.progress,
        currentBytes: event.currentBytes,
        totalBytes: event.totalBytes,
      ));
    }
  }

  /// 处理取消下载
  Future<void> _onCancelDownloadRequested(
    CancelDownloadRequested event,
    Emitter<UpdateState> emit,
  ) async {
    await updateRepository.cancelDownload();
    emit(const UpdateInitial());
  }

  /// 处理忽略更新
  void _onIgnoreUpdateRequested(
    IgnoreUpdateRequested event,
    Emitter<UpdateState> emit,
  ) {
    emit(const UpdateIgnored());
  }
}
