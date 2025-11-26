package com.example.gertonargent_app

import android.animation.ObjectAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * SikaOverlayServiceV2 — Affiche l'overlay de Sika lors de la capture de commande
 * 
 * Fonctionnalités :
 * - Affichage d'une bulle avec animation pulse
 * - Texte TTS et visualisation de STT
 * - Fermeture automatique après la commande
 */
class SikaOverlayServiceV2 : Service() {

    companion object {
        private const val TAG = "SikaOverlayServiceV2"
        private const val CHANNEL_ID = "SikaOverlayChannel"
        private const val NOTIFICATION_ID = 2002

        const val ACTION_HIDE_OVERLAY = "com.gertonargent.HIDE_OVERLAY"
        const val EXTRA_MESSAGE = "message"
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var pulseAnimator: ObjectAnimator? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "SikaOverlayServiceV2 created")
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_HIDE_OVERLAY -> {
                hideOverlay()
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                val message = intent?.getStringExtra(EXTRA_MESSAGE) ?: "Sika vous écoute..."
                startForeground(NOTIFICATION_ID, createNotification())
                showOverlay(message)
                return START_STICKY
            }
        }
    }

    override fun onBind(intent: Intent?) = null

    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
    }

    private fun showOverlay(message: String) {
        try {
            if (overlayView != null) {
                windowManager?.removeView(overlayView)
            }

            // Créer le conteneur principal
            val container = LinearLayout(this).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.MATCH_PARENT
                )
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setBackgroundColor(android.graphics.Color.argb(200, 0, 0, 0))
            }

            // Créer la bulle de Sika (cercle avec animation)
            val bubbleFrame = FrameLayout(this).apply {
                layoutParams = LinearLayout.LayoutParams(200, 200).apply {
                    bottomMargin = 30
                }
                setBackgroundResource(android.R.drawable.ic_btn_speak_now)
            }

            // Animation pulse
            val pulseView = View(this).apply {
                layoutParams = FrameLayout.LayoutParams(200, 200)
                setBackgroundColor(android.graphics.Color.BLUE)
                alpha = 0.3f
            }
            bubbleFrame.addView(pulseView)

            pulseAnimator = ObjectAnimator.ofFloat(pulseView, "scaleX", 1f, 1.2f).apply {
                duration = 800
                repeatCount = ObjectAnimator.INFINITE
                repeatMode = ObjectAnimator.REVERSE
                start()
            }

            // Texte du message
            val messageText = TextView(this).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                text = message
                textSize = 18f
                setTextColor(android.graphics.Color.WHITE)
                gravity = Gravity.CENTER
            }

            container.addView(bubbleFrame)
            container.addView(messageText)

            overlayView = container

            // Ajouter à WindowManager
            val params = WindowManager.LayoutParams().apply {
                type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
                }
                format = PixelFormat.TRANSLUCENT
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT
                gravity = Gravity.CENTER
            }

            windowManager?.addView(container, params)
            Log.d(TAG, "✅ Overlay shown: $message")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing overlay: ${e.message}", e)
        }
    }

    private fun hideOverlay() {
        try {
            if (overlayView != null) {
                windowManager?.removeView(overlayView)
                overlayView = null
                Log.d(TAG, "Overlay hidden")
            }
            pulseAnimator?.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding overlay: ${e.message}", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Sika Overlay",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val pi = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val hideIntent = Intent(this, SikaOverlayServiceV2::class.java)
        hideIntent.action = ACTION_HIDE_OVERLAY
        val hidePi = PendingIntent.getService(
            this, 0, hideIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sika en conversation")
            .setContentText("Parlez votre commande...")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pi)
            .addAction(android.R.drawable.ic_media_pause, "Fermer", hidePi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
