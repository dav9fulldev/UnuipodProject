package com.example.gertonargent_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gertonargent/overlay"
    private val SIKA_CHANNEL = "com.gertonargent/sika"
    private val OVERLAY_PERMISSION_REQUEST = 1001

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val permissions = mapOf(
                        "overlay" to canDrawOverlays(),
                        "accessibility" to isAccessibilityServiceEnabled()
                    )
                    result.success(permissions)
                }
                "requestOverlayPermission" -> { requestOverlayPermission(); result.success(true) }
                "requestAccessibilityPermission" -> { requestAccessibilityPermission(); result.success(true) }
                else -> { result.notImplemented() }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SIKA_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startSikaService" -> { startSikaWakeWordService(); result.success(true) }
                "stopSikaService" -> { stopSikaWakeWordService(); result.success(true) }
                "isSikaServiceRunning" -> { result.success(SikaWakeWordService.isRunning) }
                "showSikaOverlay" -> { showSikaOverlay(); result.success(true) }
                "hideSikaOverlay" -> { hideSikaOverlay(); result.success(true) }
                "checkMicrophonePermission" -> { result.success(hasMicrophonePermission()) }
                else -> { result.notImplemented() }
            }
        }
    }

    private fun startSikaWakeWordService() {
        if (!canDrawOverlays()) { requestOverlayPermission(); return }
        val intent = Intent(this, SikaWakeWordService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
    }

    private fun stopSikaWakeWordService() {
        val intent = Intent(this, SikaWakeWordService::class.java)
        intent.action = SikaWakeWordService.ACTION_STOP_LISTENING
        startService(intent)
    }

    private fun showSikaOverlay() {
        if (!canDrawOverlays()) { requestOverlayPermission(); return }
        val intent = Intent(this, SikaOverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
    }

    private fun hideSikaOverlay() {
        val intent = Intent(this, SikaOverlayService::class.java)
        intent.action = SikaOverlayService.ACTION_HIDE_OVERLAY
        startService(intent)
    }

    private fun hasMicrophonePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else true
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(this) else true
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "\$packageName/\${MoneyDetectionService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        return enabledServices?.contains(serviceName) == true
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:\$packageName"))
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST)
        }
    }

    private fun requestAccessibilityPermission() {
        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }
}
