@echo off
REM ============================================
REM 自动更新 version.json 配置文件
REM ============================================
setlocal enabledelayedexpansion

echo.
echo ========================================
echo    仓库应用版本配置工具
echo ========================================
echo.

REM 获取用户输入
set /p VERSION_CODE="请输入版本号 (例如: 40): "
set /p VERSION_NAME="请输入版本名称 (例如: 1.5.0): "
set /p SERVER_IP="请输入服务器IP地址 (例如: 192.168.1.100): "

REM 设置默认值
if "%VERSION_CODE%"=="" set VERSION_CODE=39
if "%VERSION_NAME%"=="" set VERSION_NAME=1.4.5
if "%SERVER_IP%"=="" set SERVER_IP=YOUR_SERVER_IP

REM 构造APK文件名
set APK_FILE=warehouse-app-v%VERSION_NAME%-build%VERSION_CODE%.apk

REM 检查APK文件是否存在
if not exist "..\releases\%APK_FILE%" (
    echo.
    echo [警告] APK文件不存在: %APK_FILE%
    echo 请确保已经构建并复制APK到releases目录
    echo.
    set /p CONTINUE="是否继续生成配置文件? (Y/N): "
    if /i not "!CONTINUE!"=="Y" exit /b 1
)

REM 获取APK文件大小
for %%A in ("..\releases\%APK_FILE%") do set FILE_SIZE=%%~zA

REM 获取当前日期
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set YEAR=%%c
    set MONTH=%%a
    set DAY=%%b
)
set RELEASE_DATE=%YEAR%-%MONTH%-%DAY%

REM 询问更新类型
set /p FORCE_UPDATE="是否强制更新? (Y/N, 默认N): "
if /i "%FORCE_UPDATE%"=="Y" (
    set FORCE_FLAG=true
) else (
    set FORCE_FLAG=false
)

set /p MIN_VERSION="最低支持版本号 (默认30): "
if "%MIN_VERSION%"=="" set MIN_VERSION=30

echo.
echo 请输入更新说明 (每行一条,输入空行结束):
set UPDATE_LOG=
set LINE_COUNT=0
:input_loop
set /p "LINE=第!LINE_COUNT!条> "
if "!LINE!"=="" goto end_input
if !LINE_COUNT! equ 0 (
    set UPDATE_LOG=• !LINE!
) else (
    set UPDATE_LOG=!UPDATE_LOG!\n• !LINE!
)
set /p LINE_COUNT=!LINE_COUNT!+1
goto input_loop
:end_input

if "%UPDATE_LOG%"=="" set UPDATE_LOG=• 版本更新

REM 生成 version.json
echo.
echo 正在生成 version.json...
echo.

(
echo {
echo   "versionCode": %VERSION_CODE%,
echo   "versionName": "%VERSION_NAME%",
echo   "downloadUrl": "http://%SERVER_IP%/%APK_FILE%",
echo   "updateLog": "%UPDATE_LOG%",
echo   "forceUpdate": %FORCE_FLAG%,
echo   "minSupportedVersion": %MIN_VERSION%,
echo   "fileSize": %FILE_SIZE%,
echo   "releaseDate": "%RELEASE_DATE%"
echo }
) > ..\releases\version.json

echo ========================================
echo 配置文件已生成!
echo ========================================
echo.
echo 版本信息:
echo   版本号: %VERSION_CODE%
echo   版本名: %VERSION_NAME%
echo   APK文件: %APK_FILE%
echo   文件大小: %FILE_SIZE% 字节
echo   下载地址: http://%SERVER_IP%/%APK_FILE%
echo   强制更新: %FORCE_FLAG%
echo   发布日期: %RELEASE_DATE%
echo.
echo 配置文件位置: ..\releases\version.json
echo.
echo ========================================
echo 下一步操作:
echo 1. 将 releases 目录复制到 Windows 服务器
echo 2. 在HFS中添加 releases 目录
echo 3. 确保PDA设备可以访问 http://%SERVER_IP%
echo ========================================
echo.

pause
