package com.example.gertonargent_app

import android.content.Intent
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.IntentFilter
import android.content.BroadcastReceiver

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gertonargent/overlay"
    private val SIKA_CHANNEL = "com.gertonargent/sika"
    private val OVERLAY_PERMISSION_REQUEST = 1001
    private var sikaReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Method channel for Sika commands from native services
        val sikaChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SIKA_CHANNEL)
        // BroadcastReceiver to forward native Sika commands to Flutter
        sikaReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent == null) return
                if (intent.action == "com.gertonargent.SIKA_COMMAND") {
                    val cmd = intent.getStringExtra("command") ?: ""
                    sikaChannel.invokeMethod("onSikaCommand", cmd)
                }
            }
        }
        // Register receiver
        val filter = IntentFilter("com.gertonargent.SIKA_COMMAND")
        registerReceiver(sikaReceiver, filter)

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
                // ===== Service Control =====
                "startSikaService" -> {
                    startSikaServiceV2()
                    result.success(true)
                }
                "stopSikaService" -> {
                    stopSikaServiceV2()
                    result.success(true)
                }
                "isSikaServiceRunning" -> {
                    result.success(SikaWakeWordServiceV2.isRunning)
                }

                // ===== User Data =====
                "getUserFirstname" -> {
                    try {
                        val prefs = getSharedPreferences("sika_prefs", Context.MODE_PRIVATE)
                        val firstname = prefs.getString("user_firstname", null)
                        result.success(firstname)
                    } catch (e: Exception) {
                        result.error("err", "Failed to get firstname: ${e.message}", null)
                    }
                }
                "setUserFirstname" -> {
                    try {
                        val firstname = call.argument<String>("firstname") ?: ""
                        val prefs = getSharedPreferences("sika_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putString("user_firstname", firstname).apply()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("err", e.message, null)
                    }
                }

                // ===== Pending Transactions =====
                "readPendingTransactions" -> {
                    try {
                        val prefs = getSharedPreferences("sika_prefs", Context.MODE_PRIVATE)
                        val value = prefs.getString("pending_transactions", "[]") ?: "[]"
                        result.success(value)
                    } catch (e: Exception) {
                        result.error("err", e.message, null)
                    }
                }
                "addPendingTransaction" -> {
                    try {
                        val txJson = call.argument<String>("transaction") ?: return@setMethodCallHandler
                        val prefs = getSharedPreferences("sika_prefs", Context.MODE_PRIVATE)
                        val existing = prefs.getString("pending_transactions", "[]") ?: "[]"
                        val array = org.json.JSONArray(existing)
                        array.put(org.json.JSONObject(txJson))
                        prefs.edit().putString("pending_transactions", array.toString()).apply()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("err", e.message, null)
                    }
                }
                "clearPendingTransactions" -> {
                    try {
                        val prefs = getSharedPreferences("sika_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putString("pending_transactions", "[]").apply()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("err", e.message, null)
                    }
                }
                "removePendingTransaction" -> {
                    try {
                        val index = call.argument<Int>("index") ?: return@setMethodCallHandler
                        val prefs = getSharedPreferences("sika_prefs", Context.MODE_PRIVATE)
                        val existing = prefs.getString("pending_transactions", "[]") ?: "[]"
                        val array = org.json.JSONArray(existing)
                        if (index >= 0 && index < array.length()) {
                            // JSONArray doesn't have remove(), so we rebuild
                            val newArray = org.json.JSONArray()
                            for (i in 0 until array.length()) {
                                if (i != index) {
                                    newArray.put(array.get(i))
                                }
                            }
                            prefs.edit().putString("pending_transactions", newArray.toString()).apply()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("err", e.message, null)
                    }
                }

                // ===== Overlay Control =====
                "showSikaOverlay" -> {
                    val message = call.argument<String>("message") ?: "Sika vous écoute..."
                    showSikaOverlayV2(message)
                    result.success(true)
                }
                "hideSikaOverlay" -> {
                    hideSikaOverlayV2()
                    result.success(true)
                }

                // ===== Permissions =====
                "checkMicrophonePermission" -> {
                    result.success(hasMicrophonePermission())
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Auto-start Sika wake-word service if permissions are available
        if (canDrawOverlays() && hasMicrophonePermission()) {
            startSikaWakeWordService()
        }
    }

    override fun onDestroy() {
        try { sikaReceiver?.let { unregisterReceiver(it); sikaReceiver = null } } catch (e: Exception) {}
        super.onDestroy()
    }

    private fun startSikaWakeWordService() {
        if (!canDrawOverlays()) { requestOverlayPermission(); return }
        val intent = Intent(this, SikaWakeWordService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
    }

    private fun startSikaServiceV2() {
        Log.d("MainActivity", "Starting SikaWakeWordServiceV2...")
        if (!canDrawOverlays()) {
            Log.w("MainActivity", "Overlay permission not granted")
            requestOverlayPermission()
            return
        }
        val intent = Intent(this, SikaWakeWordServiceV2::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            @Suppress("DEPRECATION")
            startService(intent)
        }
    }

    private fun stopSikaServiceV2() {
        Log.d("MainActivity", "Stopping SikaWakeWordServiceV2...")
        val intent = Intent(this, SikaWakeWordServiceV2::class.java)
        intent.action = SikaWakeWordServiceV2.ACTION_STOP_LISTENING
        startService(intent)
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

    private fun showSikaOverlayV2(message: String) {
        Log.d("MainActivity", "Showing Sika overlay: $message")
        if (!canDrawOverlays()) {
            Log.w("MainActivity", "Overlay permission not granted")
            requestOverlayPermission()
            return
        }
        val intent = Intent(this, SikaOverlayServiceV2::class.java)
        intent.putExtra(SikaOverlayServiceV2.EXTRA_MESSAGE, message)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            @Suppress("DEPRECATION")
            startService(intent)
        }
    }

    private fun hideSikaOverlay() {
        val intent = Intent(this, SikaOverlayService::class.java)
        intent.action = SikaOverlayService.ACTION_HIDE_OVERLAY
        startService(intent)
    }

    private fun hideSikaOverlayV2() {
        Log.d("MainActivity", "Hiding Sika overlay")
        val intent = Intent(this, SikaOverlayServiceV2::class.java)
        intent.action = SikaOverlayServiceV2.ACTION_HIDE_OVERLAY
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
