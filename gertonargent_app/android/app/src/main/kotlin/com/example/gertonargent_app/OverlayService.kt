package com.example.gertonargent_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
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
            "SHOW_TRANSACTION_ALERT" -> {
                val amount = intent.getDoubleExtra("AMOUNT", 0.0)
                showTransactionAlert(amount)
            }
            "SHOW_ALERT" -> {
                showGenericAlert()
            }
            "HIDE_ALERT" -> {
                hideOverlay()
            }
        }

        return START_STICKY
    }

    private fun showTransactionAlert(amount: Double) {
        if (isOverlayShown) {
            hideOverlay()
        }

        // Créer le layout principal
        overlayView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(24), dp(24), dp(24), dp(24))
            
            // Titre avec icône
            addView(TextView(context).apply {
                text = "⚠️ ALERTE BUDGET !"
                textSize = 24f
                setTextColor(Color.parseColor("#FF6B00"))
                gravity = Gravity.CENTER
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                setPadding(0, 0, 0, dp(16))
            })

            // Montant de la transaction
            addView(TextView(context).apply {
                text = "Transaction : ${formatAmount(amount)} FCFA"
                textSize = 18f
                setTextColor(Color.BLACK)
                setPadding(0, 0, 0, dp(12))
            })

            // Impact budget (exemple statique pour l'instant)
            addView(TextView(context).apply {
                text = "Impact : ~${calculateImpact(amount)}% de ton budget mensuel"
                textSize = 16f
                setTextColor(Color.parseColor("#666666"))
                setPadding(0, 0, 0, dp(20))
            })

            // Rappel objectif
            addView(TextView(context).apply {
                text = "🎯 Rappel : Tu économises pour un objectif !"
                textSize = 16f
                setTextColor(Color.parseColor("#00A86B"))
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                setPadding(0, 0, 0, dp(8))
            })

            // Conseil IA
            addView(TextView(context).apply {
                text = "💭 Conseil :\nRéfléchis bien avant de dépenser.\nCette dépense peut impacter tes objectifs."
                textSize = 14f
                setTextColor(Color.parseColor("#666666"))
                setPadding(0, 0, 0, dp(24))
            })

            // Question
            addView(TextView(context).apply {
                text = "Continuer quand même ?"
                textSize = 18f
                setTextColor(Color.BLACK)
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, dp(20))
            })

            // Boutons
            val buttonsLayout = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                weightSum = 2f
            }

            // Bouton Annuler
            val cancelButton = Button(context).apply {
                text = "✗ Non, annuler"
                textSize = 16f
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#F44336"))
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply {
                    setMargins(0, 0, dp(8), 0)
                }
                setPadding(0, dp(12), 0, dp(12))
                setOnClickListener {
                    Log.d(TAG, "❌ Utilisateur a annulé")
                    hideOverlay()
                    // Retourner au dashboard de l'app
                    returnToDashboard()
                }
            }

            // Bouton Continuer
            val continueButton = Button(context).apply {
                text = "✓ Oui, continuer"
                textSize = 16f
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#00A86B"))
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply {
                    setMargins(dp(8), 0, 0, 0)
                }
                setPadding(0, dp(12), 0, dp(12))
                setOnClickListener {
                    Log.d(TAG, "✅ Utilisateur continue")
                    hideOverlay()
                    // L'utilisateur retourne automatiquement à son app Mobile Money
                }
            }

            buttonsLayout.addView(cancelButton)
            buttonsLayout.addView(continueButton)
            addView(buttonsLayout)
        }

        // Paramètres de la fenêtre
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        overlayView?.let { view ->
            // Ajouter ombre/bordure
            view.elevation = dp(16).toFloat()
            
            windowManager?.addView(view, params)
            isOverlayShown = true
            Log.d(TAG, "✅ Overlay affiché avec montant: $amount FCFA")
        }
    }

    private fun showGenericAlert() {
        if (isOverlayShown) return

        overlayView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(24), dp(24), dp(24), dp(24))

            addView(TextView(context).apply {
                text = "⚠️ ALERTE GERTONARGENT"
                textSize = 20f
                setTextColor(Color.parseColor("#00A86B"))
                gravity = Gravity.CENTER
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                setPadding(0, 0, 0, dp(16))
            })

            addView(TextView(context).apply {
                text = "Attention à ton budget !"
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
            view.setOnClickListener { hideOverlay() }
            windowManager?.addView(view, params)
            isOverlayShown = true

            // Auto-fermer après 3 secondes
            android.os.Handler(mainLooper).postDelayed({
                hideOverlay()
            }, 3000)
        }
    }

    private fun hideOverlay() {
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                Log.e(TAG, "Erreur suppression overlay: $e")
            }
            overlayView = null
            isOverlayShown = false
            Log.d(TAG, "Overlay masqué")
        }
    }

    private fun returnToDashboard() {
        // Ouvrir GèrTonArgent
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
    }

    private fun formatAmount(amount: Double): String {
        return String.format("%,.0f", amount).replace(',', ' ')
    }

    private fun calculateImpact(amount: Double): Int {
        // Exemple : budget moyen de 200,000 FCFA
        val averageBudget = 200000.0
        return ((amount / averageBudget) * 100).toInt().coerceIn(1, 100)
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("GèrTonArgent")
            .setContentText("Protection active de ton budget")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Protection Budget",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Surveillance active de tes dépenses"
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