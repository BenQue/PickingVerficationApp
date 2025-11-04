# Release Notes - v1.5.0 (Build 40)

**Release Date:** 2025-01-04
**APK Size:** 78 MB
**Min Android Version:** API Level 21 (Android 5.0)

## 🎉 New Features

### 📲 Automatic Update System
- **Background Update Check**: The app now automatically checks for updates on startup
- **Smart Update Notifications**: Non-intrusive update prompts with detailed version information
- **Download Progress Tracking**: Real-time download progress indicator with percentage and file size
- **One-Click Installation**: Seamless APK installation through native Android installer
- **Force Update Support**: Critical updates can be marked as mandatory
- **Manual Update Check**: Users can manually check for updates from the employee info dialog

### ✨ Update Dialog Features
- **Version Information Display**: Shows new version number and release notes
- **File Size and Release Date**: Transparent information about update package
- **Background Download**: Non-blocking downloads that don't interrupt workflow
- **Cancellable Downloads**: Users can cancel downloads if needed
- **WiFi Detection**: Optional automatic download on WiFi networks

## 🔧 Technical Implementation

### Architecture
- **Clean Architecture Pattern**: Separation of concerns with data/domain/presentation layers
- **BLoC State Management**: Reactive UI updates with UpdateBlocSimple
- **Native Platform Channels**: Custom Kotlin implementation for APK installation
- **Dio HTTP Client**: Reliable download with progress callbacks
- **Error Handling**: Comprehensive failure management with user-friendly messages

### Components Added
- `lib/features/app_update/`: Complete update feature module
- `lib/core/utils/apk_installer.dart`: Native APK installer utility
- `android/app/src/main/kotlin/.../MainActivity.kt`: Enhanced with update support
- `lib/core/config/app_config.dart`: Update server configuration

### Configuration
- **Update Server URL**: `http://10.163.130.173:8000`
- **Auto-check on Startup**: Enabled by default
- **Silent Check**: No UI disturbance if already up-to-date
- **Version Comparison**: Uses versionCode (integer) for accurate comparison

## 📋 Update Flow

1. **App Launch**: Silent version check in background
2. **New Version Detected**: Update dialog appears automatically
3. **User Choice**:
   - "立即更新" (Update Now): Downloads and installs immediately
   - "稍后" (Later): Dismisses dialog, can check manually later
4. **Download**: Progress bar shows download status
5. **Installation**: Android native installer opens automatically
6. **Completion**: User confirms installation to upgrade

## 🔐 Permissions Added

```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

## 🚀 Testing Instructions

### Server Setup
1. Ensure HFS server is running on `10.163.130.173:8000`
2. Update `version.json` with new version info
3. Place APK file in server root directory

### Client Testing
1. Install v1.5.0 on PDA device
2. Launch app and verify automatic update check
3. Test manual update check from employee info dialog
4. Verify update dialog displays correctly
5. Test download and installation process
6. Confirm successful upgrade

## 📊 Version Comparison

| Feature | v1.4.5 | v1.5.0 |
|---------|--------|--------|
| Automatic Updates | ❌ | ✅ |
| Update Notifications | ❌ | ✅ |
| Download Progress | ❌ | ✅ |
| Force Update Support | ❌ | ✅ |
| Manual Update Check | ❌ | ✅ |

## 🐛 Known Issues

None currently identified.

## 📝 Installation Instructions

### For End Users
1. Receive APK file `warehouse-app-v1.5.0-build40.apk`
2. Enable "Install from Unknown Sources" if not already enabled
3. Open APK file to install
4. Grant necessary permissions when prompted
5. Launch app and verify version in employee info dialog

### For Developers
```bash
# Install via ADB
adb install -r releases/warehouse-app-v1.5.0-build40.apk

# Verify installation
adb shell dumpsys package com.example.picking_verification_app | grep versionName
```

## 🔮 Future Enhancements

- Automatic background downloads on WiFi
- Update scheduling (install on next app restart)
- Rollback capability for failed updates
- Delta updates to reduce download size
- Update history and changelog viewer

## 📧 Support

For issues or questions, contact the development team.

---

**Note**: This version introduces the foundational auto-update system. Future releases will be delivered seamlessly through this mechanism, reducing manual distribution efforts and ensuring all devices stay up-to-date.
