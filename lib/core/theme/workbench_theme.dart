import 'package:flutter/material.dart';

/// WMS工作台统一风格配置
/// 提供一致的输入框、按钮、卡片样式
class WorkbenchTheme {
  // ==================== 颜色定义 ====================

  /// 主要功能按钮颜色 - 鲜艳蓝色
  static const Color primaryButtonColor = Color(0xFF1976D2); // Material Blue 700 - 更深更鲜艳
  static const Color primaryButtonTextColor = Colors.white;

  /// 输入框聚焦边框颜色
  static const Color inputFocusBorderColor = Color(0xFF1976D2);

  /// 输入框普通边框颜色
  static final Color inputNormalBorderColor = Colors.grey.shade400;

  /// 输入框错误边框颜色
  static const Color inputErrorBorderColor = Colors.red;

  /// 信息提示背景色
  static final Color infoBackgroundColor = Colors.blue.shade50;
  static final Color infoBorderColor = Colors.blue.shade200;
  static const Color infoTextColor = Colors.blue;

  /// 成功状态颜色
  static final Color successBackgroundColor = Colors.green.shade50;
  static final Color successColor = Colors.green.shade700;

  /// 错误状态颜色
  static final Color errorBackgroundColor = Colors.red.shade50;
  static final Color errorColor = Colors.red.shade600;

  // ==================== 尺寸定义 ====================

  /// 输入框圆角半径
  static const double inputBorderRadius = 12.0;

  /// 输入框边框宽度
  static const double inputBorderWidth = 2.0;
  static const double inputFocusBorderWidth = 3.0;

  /// 按钮圆角半径
  static const double buttonBorderRadius = 12.0;

  /// 卡片圆角半径
  static const double cardBorderRadius = 12.0;

  /// 功能菜单卡片尺寸（任务面板）
  static const double menuCardHeight = 140.0;
  static const double menuCardIconSize = 48.0;

  // ==================== 文本样式 ====================

  /// 输入框文本样式
  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  /// 输入框提示文本样式
  static const TextStyle inputHintStyle = TextStyle(fontSize: 18);

  /// 输入框错误文本样式
  static const TextStyle inputErrorStyle = TextStyle(fontSize: 16);

  /// 主按钮文本样式
  static const TextStyle primaryButtonTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  /// 次要按钮文本样式
  static const TextStyle secondaryButtonTextStyle = TextStyle(
    fontSize: 18,
  );

  /// 功能菜单标题样式
  static const TextStyle menuTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  /// 功能菜单副标题样式
  static const TextStyle menuSubtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // ==================== 输入框装饰器 ====================

  /// 获取统一的输入框装饰
  static InputDecoration getInputDecoration({
    required String hintText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: const BorderSide(width: inputBorderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: BorderSide(
          width: inputBorderWidth,
          color: inputNormalBorderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: const BorderSide(
          width: inputFocusBorderWidth,
          color: inputFocusBorderColor,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
        borderSide: const BorderSide(
          width: inputBorderWidth,
          color: inputErrorBorderColor,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      hintStyle: inputHintStyle,
      errorStyle: inputErrorStyle,
    );
  }

  // ==================== 按钮样式 ====================

  /// 获取主要功能按钮样式
  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      backgroundColor: primaryButtonColor,
      foregroundColor: primaryButtonTextColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
      ),
      elevation: 2,
      textStyle: primaryButtonTextStyle,
    );
  }

  /// 获取次要功能按钮样式
  static ButtonStyle getSecondaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(16),
      textStyle: secondaryButtonTextStyle,
    );
  }

  /// 获取文本按钮样式
  static ButtonStyle getTextButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      padding: const EdgeInsets.all(16),
      textStyle: const TextStyle(fontSize: 16),
    );
  }

  // ==================== 卡片样式 ====================

  /// 获取信息提示卡片装饰
  static BoxDecoration getInfoCardDecoration() {
    return BoxDecoration(
      color: infoBackgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: infoBorderColor,
        width: 1,
      ),
    );
  }

  /// 获取成功状态卡片装饰
  static BoxDecoration getSuccessCardDecoration() {
    return BoxDecoration(
      color: successBackgroundColor,
      borderRadius: BorderRadius.circular(cardBorderRadius),
    );
  }

  /// 获取错误状态卡片装饰
  static BoxDecoration getErrorCardDecoration() {
    return BoxDecoration(
      color: errorBackgroundColor,
      borderRadius: BorderRadius.circular(cardBorderRadius),
    );
  }

  // ==================== 功能菜单卡片 ====================

  /// 创建统一的功能菜单卡片（鲜艳纯色版本）
  static Widget buildFeatureMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? backgroundColor,
    bool isEnabled = true,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        child: Container(
          height: menuCardHeight,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            color: isEnabled ? iconColor : Colors.grey.shade200,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: menuCardIconSize,
                color: isEnabled ? Colors.white : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: menuTitleStyle.copyWith(
                  color: isEnabled ? Colors.white : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: menuSubtitleStyle.copyWith(
                  color: isEnabled ? Colors.white.withOpacity(0.95) : Colors.grey.shade400,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 创建"开发中"功能菜单卡片
  static Widget buildDevelopingMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return buildFeatureMenuCard(
      context: context,
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: '待开发',
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('该功能正在开发中，敬请期待'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      isEnabled: false,
    );
  }
}
