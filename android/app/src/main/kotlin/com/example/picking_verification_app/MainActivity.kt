package com.example.picking_verification_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.picking_verification_app/apk_installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath != null) {
                        try {
                            installApk(apkPath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "APK path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(apkPath: String) {
        val apkFile = File(apkPath)
        if (!apkFile.exists()) {
            throw Exception("APK file does not exist: $apkPath")
        }

        val intent = Intent(Intent.ACTION_VIEW)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Android 7.0+ 需要使用FileProvider
            intent.flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            val apkUri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileProvider",
                apkFile
            )
            intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
        } else {
            // Android 7.0以下直接使用文件URI
            intent.setDataAndType(Uri.fromFile(apkFile), "application/vnd.android.package-archive")
        }

        startActivity(intent)
    }
}
