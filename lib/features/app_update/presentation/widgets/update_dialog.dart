import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/update_info.dart';
import '../bloc/update_bloc_simple.dart';
import '../bloc/update_event.dart';
import '../bloc/update_state.dart';

/// 应用更新对话框
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateBlocSimple, UpdateState>(
      listener: (context, state) {
        if (state is UpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return WillPopScope(
          // 强制更新时不允许关闭对话框
          onWillPop: () async => !updateInfo.forceUpdate,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.system_update,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  updateInfo.forceUpdate ? '发现新版本（必须更新）' : '发现新版本',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            content: _buildContent(context, state),
            actions: _buildActions(context, state),
          ),
        );
      },
    );
  }

  /// 构建对话框内容
  Widget _buildContent(BuildContext context, UpdateState state) {
    if (state is UpdateDownloading) {
      return _buildDownloadingContent(state);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 版本信息
          _buildVersionInfo(),
          const SizedBox(height: 16),

          // 更新日志
          _buildUpdateLog(),

          // 文件大小和发布日期
          const SizedBox(height: 16),
          _buildMetaInfo(),
        ],
      ),
    );
  }

  /// 版本信息
  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '最新版本:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            updateInfo.versionName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// 更新日志
  Widget _buildUpdateLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '更新内容:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            updateInfo.updateLog,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// 元信息（文件大小、发布日期）
  Widget _buildMetaInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.storage, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              updateInfo.fileSizeFormatted,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        if (updateInfo.releaseDate != null)
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                updateInfo.releaseDate!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 下载中的内容
  Widget _buildDownloadingContent(UpdateDownloading state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        CircularProgressIndicator(
          value: state.progress,
          strokeWidth: 6,
        ),
        const SizedBox(height: 24),
        Text(
          state.percentText,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.progressText,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '正在下载更新，请稍候...',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  /// 构建操作按钮
  List<Widget> _buildActions(BuildContext context, UpdateState state) {
    if (state is UpdateDownloading) {
      return [
        TextButton(
          onPressed: () {
            context.read<UpdateBlocSimple>().add(const CancelDownloadRequested());
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
      ];
    }

    return [
      // 稍后更新按钮（仅在非强制更新时显示）
      if (!updateInfo.forceUpdate)
        TextButton(
          onPressed: () {
            context.read<UpdateBlocSimple>().add(const IgnoreUpdateRequested());
            Navigator.of(context).pop();
          },
          child: const Text('稍后'),
        ),

      // 立即更新按钮
      ElevatedButton(
        onPressed: state is UpdateDownloading
            ? null
            : () {
                context.read<UpdateBlocSimple>().add(
                      DownloadUpdateRequested(updateInfo.downloadUrl),
                    );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text(
          '立即更新',
          style: TextStyle(fontSize: 16),
        ),
      ),
    ];
  }
}

/// 显示更新对话框
void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
  showDialog(
    context: context,
    barrierDismissible: !updateInfo.forceUpdate,
    builder: (context) => UpdateDialog(updateInfo: updateInfo),
  );
}
