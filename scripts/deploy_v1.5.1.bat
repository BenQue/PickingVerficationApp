@echo off
REM ========================================
REM 部署 v1.5.1 到 HFS 更新服务器
REM ========================================

echo.
echo ========================================
echo 仓库应用自动更新部署脚本
echo 版本：v1.5.1 (Build 41)
echo ========================================
echo.

REM 设置变量
set VERSION=1.5.1
set BUILD=41
set HFS_DIR=C:\HFS
set SOURCE_DIR=%~dp0..\releases

echo [1/4] 检查 HFS 服务器目录...
if not exist "%HFS_DIR%" (
    echo ❌ 错误：HFS 目录不存在 %HFS_DIR%
    echo 请先安装并配置 HFS 服务器
    pause
    exit /b 1
)
echo ✓ HFS 目录存在

echo.
echo [2/4] 复制 version.json...
copy /Y "%SOURCE_DIR%\version.json" "%HFS_DIR%\version.json"
if errorlevel 1 (
    echo ❌ 复制 version.json 失败
    pause
    exit /b 1
)
echo ✓ version.json 已更新

echo.
echo [3/4] 复制 APK 文件...
echo 源文件：%SOURCE_DIR%\warehouse-app-v%VERSION%-build%BUILD%.apk
echo 目标目录：%HFS_DIR%\
copy /Y "%SOURCE_DIR%\warehouse-app-v%VERSION%-build%BUILD%.apk" "%HFS_DIR%\"
if errorlevel 1 (
    echo ❌ 复制 APK 文件失败
    pause
    exit /b 1
)
echo ✓ APK 文件已部署

echo.
echo [4/4] 验证部署...
if exist "%HFS_DIR%\version.json" (
    echo ✓ version.json 已存在
) else (
    echo ❌ version.json 不存在
)

if exist "%HFS_DIR%\warehouse-app-v%VERSION%-build%BUILD%.apk" (
    echo ✓ APK 文件已存在
) else (
    echo ❌ APK 文件不存在
)

echo.
echo ========================================
echo 部署完成！
echo ========================================
echo.
echo 更新服务器信息：
echo URL: http://10.163.130.173:8000
echo 版本配置：%HFS_DIR%\version.json
echo APK 文件：%HFS_DIR%\warehouse-app-v%VERSION%-build%BUILD%.apk
echo.
echo 下一步：
echo 1. 确保 HFS 服务器正在运行
echo 2. 在 PDA 设备上测试更新功能
echo 3. 查看测试指南：docs\UPDATE_TEST_GUIDE.md
echo.
pause
