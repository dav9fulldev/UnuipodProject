package com.example.gertonargent_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BootReceiver - Auto-start Sika service when device boots
 *
 * Permet à Sika de redémarrer automatiquement après un redémarrage de l'appareil,
 * même si l'app n'a jamais été ouverte.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "🔌 Boot receiver triggered: ${intent?.action}")
        
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED && context != null) {
            Log.d(TAG, "✅ Device boot completed, starting Sika service")
            
            try {
                val serviceIntent = Intent(context, SikaWakeWordServiceV2::class.java)
                context.startForegroundService(serviceIntent)
                Log.d(TAG, "✅ Sika service auto-started on boot")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to start service on boot", e)
            }
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
