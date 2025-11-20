package com.example.gertonargent_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class MoneyDetectionService : AccessibilityService() {

    companion object {
        private const val TAG = "MoneyDetection"
        
        // Apps Mobile Money à surveiller
        private val MOBILE_MONEY_APPS = setOf(
            "com.wave.personal",           // Wave
            "sn.senlabs.orange",           // Orange Money
            "ci.mtn.momo",                 // MTN Mobile Money
            "ci.moov.money"                // Moov Money
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                
                // Vérifier si c'est une app Mobile Money
                if (MOBILE_MONEY_APPS.contains(packageName)) {
                    Log.d(TAG, "Mobile Money app détectée: $packageName")
                    onMobileMoneyAppDetected(packageName)
                }
            }
            
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                
                if (MOBILE_MONEY_APPS.contains(packageName)) {
                    // Analyser le contenu pour détecter les montants
                    analyzeContent(event)
                }
            }
        }
    }

    private fun onMobileMoneyAppDetected(packageName: String) {
        // Lancer le service overlay
        val intent = Intent(this, OverlayService::class.java).apply {
            putExtra("PACKAGE_NAME", packageName)
            putExtra("ACTION", "SHOW_ALERT")
        }
        startService(intent)
        
        // Notifier Flutter
        notifyFlutter(packageName)
    }

    private fun analyzeContent(event: AccessibilityEvent) {
        // Extraire le texte de l'écran
        val text = event.text?.joinToString(" ") ?: return
        
        Log.d(TAG, "Contenu: $text")
        
        // Détecter les montants (regex simple)
        val amountPattern = Regex("(\\d{1,3}(?:[,\\s]\\d{3})*(?:\\.\\d{2})?)")
        val matches = amountPattern.findAll(text)
        
        matches.forEach { match ->
            val amount = match.value.replace("[,\\s]".toRegex(), "")
            Log.d(TAG, "Montant détecté: $amount FCFA")
            
            // Si montant > 1000, afficher l'alerte
            amount.toDoubleOrNull()?.let {
                if (it > 1000) {
                    showTransactionAlert(it)
                }
            }
        }
    }

    private fun showTransactionAlert(amount: Double) {
        val intent = Intent(this, OverlayService::class.java).apply {
            putExtra("ACTION", "SHOW_TRANSACTION_ALERT")
            putExtra("AMOUNT", amount)
        }
        startService(intent)
    }

    private fun notifyFlutter(packageName: String) {
        // Communication vers Flutter via MethodChannel
        // On implémentera ça plus tard
        Log.d(TAG, "Notification Flutter: $packageName")
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrompu")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Service Accessibility connecté")
    }
}