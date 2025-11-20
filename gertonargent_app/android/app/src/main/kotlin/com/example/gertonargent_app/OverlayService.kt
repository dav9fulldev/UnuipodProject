package com.example.gertonargent_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class OverlayService : Service() {

    companion object {
        private const val TAG = "OverlayService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "overlay_channel"
    }

    private var windowManager: WindowManager? = null
    private var overlayView: LinearLayout? = null
    private var isOverlayShown = false

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        Log.d(TAG, "Service créé")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())

        val action = intent?.getStringExtra("ACTION")
        
        when (action) {
            "SHOW_ALERT" -> {
                val packageName = intent.getStringExtra("PACKAGE_NAME") ?: ""
                showSimpleAlert(packageName)
            }
            "SHOW_TRANSACTION_ALERT" -> {
                val amount = intent.getDoubleExtra("AMOUNT", 0.0)
                showTransactionAlert(amount)
            }
            "HIDE_ALERT" -> {
                hideOverlay()
            }
        }

        return START_STICKY
    }

    private fun showSimpleAlert(packageName: String) {
        if (isOverlayShown) return

        overlayView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(50, 50, 50, 50)

            addView(TextView(context).apply {
                text = "⚠️ ALERTE GERTONARGENT"
                textSize = 20f
                setTextColor(Color.parseColor("#00A86B"))
                gravity = Gravity.CENTER
            })

            addView(TextView(context).apply {
                text = "\n\nApplication Mobile Money détectée!\n\nAttention à ton budget!"
                textSize = 16f
                setTextColor(Color.BLACK)
                gravity = Gravity.CENTER
            })
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        overlayView?.let { view ->
            view.setOnClickListener {
                hideOverlay()
            }
            windowManager?.addView(view, params)
            isOverlayShown = true
            Log.d(TAG, "Overlay affiché")

            // Auto-fermer après 3 secondes
            android.os.Handler(mainLooper).postDelayed({
                hideOverlay()
            }, 3000)
        }
    }

    private fun showTransactionAlert(amount: Double) {
        if (isOverlayShown) return

        overlayView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(50, 50, 50, 50)

            addView(TextView(context).apply {
                text = "⚠️ ALERTE TRANSACTION"
                textSize = 20f
                setTextColor(Color.RED)
                gravity = Gravity.CENTER
            })

            addView(TextView(context).apply {
                text = "\n\nMontant: ${String.format("%,.0f", amount)} FCFA\n\n" +
                        "Attention à ton budget!\n\n(Toucher pour fermer)"
                textSize = 16f
                setTextColor(Color.BLACK)
                gravity = Gravity.CENTER
            })
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        overlayView?.let { view ->
            view.setOnClickListener {
                hideOverlay()
            }
            windowManager?.addView(view, params)
            isOverlayShown = true
            Log.d(TAG, "Alerte transaction affichée: $amount FCFA")

            android.os.Handler(mainLooper).postDelayed({
                hideOverlay()
            }, 5000)
        }
    }

    private fun hideOverlay() {
        overlayView?.let {
            windowManager?.removeView(it)
            overlayView = null
            isOverlayShown = false
            Log.d(TAG, "Overlay masqué")
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("GèrTonArgent")
            .setContentText("Surveillance active des apps Mobile Money")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Service Overlay",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Surveillance des applications Mobile Money"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
        Log.d(TAG, "Service détruit")
    }
}
