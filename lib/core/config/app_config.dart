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

  /// ========== 用户配置 ==========

  /// 默认员工ID
  ///
  /// 用于API请求中的 updateBy 字段。
  ///
  /// **重要**: 此值必须是服务器端数据库中存在的有效员工ID。
  /// 如果服务器返回HTTP 400错误，请联系服务器管理员确认有效的员工ID。
  ///
  /// 常见的有效值示例:
  /// - 'operator' - 通用操作员账号
  /// - 'admin' - 管理员账号
  /// - 具体的员工工号，如: 'EMP001', 'USER123' 等
  static const String defaultEmployeeId = 'operator';

  /// 默认工作中心代码
  ///
  /// 用于API请求中的 workCenter 字段。
  ///
  /// **重要**: 此值必须是服务器端数据库中存在的有效工作中心代码。
  /// 如果服务器返回HTTP 400错误，请联系服务器管理员确认有效的工作中心代码。
  ///
  /// 常见的有效值示例:
  /// - 'WC001' - 工作中心1
  /// - 'ASSEMBLY' - 装配车间
  /// - 'WAREHOUSE' - 仓库
  /// - 具体的工作中心编码，如: 'WC-A-01', 'PROD_LINE_1' 等
  static const String defaultWorkCenter = 'WC001';

  /// ========== 调试配置 ==========

  /// 是否启用详细的API调试日志
  ///
  /// 设置为 true 时会输出详细的API请求和响应日志，
  /// 用于诊断HTTP 400等错误。
  ///
  /// **注意**: 生产环境应设置为 false 以避免敏感信息泄露。
  static const bool enableApiDebugLogging = true;

  /// API超时时间（毫秒）
  ///
  /// 默认30秒超时，适用于工业环境中可能的网络延迟。
  static const int apiTimeoutMs = 30000;

  /// ========== 配置验证方法 ==========

  /// 验证用户配置是否有效
  ///
  /// 检查配置是否有效。返回错误消息列表，空列表表示配置有效。
  static List<String> validateUserConfig() {
    final errors = <String>[];

    if (defaultEmployeeId.isEmpty) {
      errors.add('默认员工ID不能为空');
    }

    if (defaultWorkCenter.isEmpty) {
      errors.add('默认工作中心代码不能为空');
    }

    // 检查是否仍在使用可能无效的占位符值
    if (defaultEmployeeId.length < 3) {
      errors.add('员工ID格式可能无效（长度过短）');
    }

    if (defaultWorkCenter.length < 3) {
      errors.add('工作中心代码格式可能无效（长度过短）');
    }

    return errors;
  }

  /// 获取配置摘要（用于日志和诊断）
  static String getConfigSummary() {
    return '''
========== 应用配置摘要 ==========
API服务器: $apiBaseUrl
更新服务器: $updateServerUrl
员工ID: $defaultEmployeeId
工作中心: $defaultWorkCenter
API调试日志: ${enableApiDebugLogging ? '启用' : '禁用'}
API超时: ${apiTimeoutMs}ms
自动更新: ${enableAutoUpdate ? '启用' : '禁用'}
================================
''';
  }

  AppConfig._();
}
