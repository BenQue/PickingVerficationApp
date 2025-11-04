/// 应用配置
class AppConfig {
  /// API基础URL
  static const String apiBaseUrl = 'http://192.168.1.100:8080/api';

  /// 更新服务器URL
  /// 公司内网Windows服务器地址
  /// IP: 10.163.130.173
  /// 端口: 8000 (80端口已被占用)
  static const String updateServerUrl = 'http://10.163.130.173:8000';

  /// 是否启用自动更新检查
  static const bool enableAutoUpdate = true;

  /// 启动时是否检查更新
  static const bool checkUpdateOnStartup = true;

  /// 是否在WiFi下自动下载更新
  static const bool autoDownloadOnWifi = false;

  /// 更新检查间隔（小时）
  static const int updateCheckIntervalHours = 24;

  AppConfig._();
}
