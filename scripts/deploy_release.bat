@echo off
REM ============================================
REM 一键发布新版本
REM 1. 构建APK
REM 2. 更新version.json
REM 3. 复制到releases目录
REM ============================================
setlocal enabledelayedexpansion

echo.
echo ========================================
echo    仓库应用一键发布工具
echo ========================================
echo.

REM 读取当前版本
for /f "tokens=2 delims=:+" %%a in ('findstr /r "version:" ..\pubspec.yaml') do (
    set FULL_VERSION=%%a
    set FULL_VERSION=!FULL_VERSION: =!
)

REM 解析版本号和构建号
for /f "tokens=1,2 delims=+" %%a in ("%FULL_VERSION%") do (
    set VERSION_NAME=%%a
    set VERSION_CODE=%%b
)

echo 当前版本: %VERSION_NAME%
echo 构建号: %VERSION_CODE%
echo.

REM 询问是否继续
set /p CONFIRM="使用此版本进行发布? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo 已取消发布
    exit /b 0
)

echo.
echo [步骤 1/5] 清理旧构建...
call flutter clean
if errorlevel 1 (
    echo [错误] 清理失败
    pause
    exit /b 1
)

echo.
echo [步骤 2/5] 获取依赖...
call flutter pub get
if errorlevel 1 (
    echo [错误] 获取依赖失败
    pause
    exit /b 1
)

echo.
echo [步骤 3/5] 构建Release APK...
call flutter build apk --release
if errorlevel 1 (
    echo [错误] 构建失败
    pause
    exit /b 1
)

echo.
echo [步骤 4/5] 复制APK到releases目录...
set APK_FILE=warehouse-app-v%VERSION_NAME%-build%VERSION_CODE%.apk
copy /Y ..\build\app\outputs\flutter-apk\app-release.apk ..\releases\%APK_FILE%
if errorlevel 1 (
    echo [错误] 复制APK失败
    pause
    exit /b 1
)

echo.
echo [步骤 5/5] 更新version.json配置...
call update_version.bat

echo.
echo ========================================
echo 发布完成!
echo ========================================
echo.
echo APK文件: releases\%APK_FILE%
echo 配置文件: releases\version.json
echo.
echo 下一步:
echo 1. 将releases目录上传到服务器
echo 2. 在HFS中刷新目录
echo 3. 通知用户更新应用
echo.
pause
