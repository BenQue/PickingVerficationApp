import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:r_upgrade/r_upgrade.dart';
import '../../data/repositories/update_repository_impl.dart';
import '../../domain/repositories/update_repository.dart';
import 'update_event.dart';
import 'update_state.dart';

/// 应用更新BLoC
class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  final UpdateRepository updateRepository;
  StreamSubscription<DownloadInfo>? _downloadSubscription;

  UpdateBloc({required this.updateRepository}) : super(const UpdateInitial()) {
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
    // 开始监听下载进度
    if (updateRepository is UpdateRepositoryImpl) {
      _downloadSubscription?.cancel();
      _downloadSubscription =
          (updateRepository as UpdateRepositoryImpl).downloadProgressStream.listen(
        (downloadInfo) {
          add(DownloadProgressUpdated(
            progress: downloadInfo.percent! / 100.0,
            currentBytes: downloadInfo.planTime?.toInt() ?? 0,
            totalBytes: downloadInfo.total?.toInt() ?? 0,
          ));
        },
      );
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
        _downloadSubscription?.cancel();
        emit(UpdateFailure(failure.message));
      },
      (_) {
        // 下载已开始，进度会通过 DownloadProgressUpdated 事件更新
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
      _downloadSubscription?.cancel();
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
    _downloadSubscription?.cancel();
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

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
