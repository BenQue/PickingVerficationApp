import 'dart:io';
import 'package:flutter/services.dart';

/// APK安装工具类
/// 使用平台通道调用Android原生安装功能
class ApkInstaller {
  static const MethodChannel _channel = MethodChannel('com.example.picking_verification_app/apk_installer');

  /// 安装APK文件
  ///
  /// [apkPath] APK文件的绝对路径
  ///
  /// 返回安装是否成功触发
  static Future<bool> installApk(String apkPath) async {
    try {
      // 检查文件是否存在
      final file = File(apkPath);
      if (!await file.exists()) {
        throw Exception('APK文件不存在: $apkPath');
      }

      // 调用原生方法安装APK
      final bool result = await _channel.invokeMethod('installApk', {
        'apkPath': apkPath,
      });

      return result;
    } on PlatformException catch (e) {
      throw Exception('安装APK失败: ${e.message}');
    }
  }
}
