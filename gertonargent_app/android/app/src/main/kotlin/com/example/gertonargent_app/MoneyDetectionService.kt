package com.example.gertonargent_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class MoneyDetectionService : AccessibilityService() {

    companion object {
        private const val TAG = "MoneyDetection"
        
        private val MOBILE_MONEY_APPS = setOf(
            "com.wave.personal",
            "sn.senlabs.orange",
            "com.orange.max.it",
            "com.orange.orangemoney",
            "ci.mtn.momo",
            "com.mtn.momo",
            "ci.moov.money",
            "com.moov.money"
        )
    }

    // État de la transaction
    private data class TransactionState(
        var hasAmount: Boolean = false,
        var hasRecipient: Boolean = false,
        var amount: Double? = null,
        var isOnConfirmationScreen: Boolean = false,
        var lastScreenChange: Long = 0
    )

    private val state = TransactionState()
    private var lastAlertTime: Long = 0
    private val ALERT_COOLDOWN = 5000L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        if (!MOBILE_MONEY_APPS.contains(packageName)) {
            resetState()
            return
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // Nouvelle fenêtre/écran
                state.lastScreenChange = System.currentTimeMillis()
                analyzeScreen()
            }
            
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                // Contenu changé (texte saisi, montant affiché)
                analyzeScreen()
            }
            
            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                // Bouton cliqué
                handleClick(event)
            }
        }
    }

    private fun analyzeScreen() {
        val rootNode = rootInActiveWindow ?: return
        val screenText = extractAllText(rootNode).lowercase()
        
        // 1. Chercher un montant
        val foundAmount = findLargestAmount(rootNode)
        if (foundAmount != null && foundAmount >= 100) {
            state.amount = foundAmount
            state.hasAmount = true
            Log.d(TAG, "💰 Montant détecté: $foundAmount FCFA")
        }

        // 2. Détecter si on est sur un écran de confirmation
        val confirmationKeywords = listOf(
            "confirmer", "confirm",
            "résumé", "summary", 
            "récapitulatif", "recap",
            "vérifier", "verify",
            "détails de", "details"
        )
        
        state.isOnConfirmationScreen = confirmationKeywords.any { screenText.contains(it) }

        // 3. Détecter destinataire
        val recipientKeywords = listOf("destinataire", "recipient", "numéro", "number", "à")
        state.hasRecipient = recipientKeywords.any { screenText.contains(it) }

        Log.d(TAG, "📊 État: Montant=${state.hasAmount}(${state.amount}) | Dest=${state.hasRecipient} | Confirm=${state.isOnConfirmationScreen}")

        rootNode.recycle()
    }

    private fun handleClick(event: AccessibilityEvent) {
        val clickedNode = event.source ?: return
        if (!clickedNode.isClickable) {
            clickedNode.recycle()
            return
        }

        val buttonText = "${clickedNode.text ?: ""} ${clickedNode.contentDescription ?: ""}".lowercase()
        Log.d(TAG, "🔘 Clic: '$buttonText'")

        // Mots-clés qui déclenchent l'alerte
        val triggerKeywords = listOf(
            "suivant", "next",
            "continuer", "continue", 
            "envoyer", "send",
            "valider", "validate",
            "payer", "pay",
            "confirmer", "confirm",
            "effectuer", "proceed"
        )

        val shouldTrigger = triggerKeywords.any { buttonText.contains(it) }
        
        // Conditions pour déclencher l'alerte :
        // 1. Le bouton contient un mot-clé de progression
        // 2. On a détecté un montant
        // 3. Le cooldown est passé
        if (shouldTrigger && state.hasAmount && state.amount != null) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastAlertTime >= ALERT_COOLDOWN) {
                Log.d(TAG, "🚨 CONDITIONS REMPLIES - DÉCLENCHEMENT ALERTE!")
                triggerAlert(state.amount!!)
                lastAlertTime = currentTime
            } else {
                Log.d(TAG, "⏸️ Cooldown actif")
            }
        }

        clickedNode.recycle()
    }

    private fun extractAllText(node: AccessibilityNodeInfo): String {
        val sb = StringBuilder()
        
        fun traverse(n: AccessibilityNodeInfo) {
            n.text?.let { sb.append(it).append(" ") }
            n.contentDescription?.let { sb.append(it).append(" ") }
            
            for (i in 0 until n.childCount) {
                n.getChild(i)?.let { child ->
                    traverse(child)
                    child.recycle()
                }
            }
        }
        
        traverse(node)
        return sb.toString()
    }

    private fun findLargestAmount(node: AccessibilityNodeInfo): Double? {
        // Regex pour capturer les montants avec virgules/espaces
        val patterns = listOf(
            Regex("(\\d{1,3}(?:[,\\s]\\d{3})+)"),  // 5,000 ou 5 000
            Regex("(\\d{4,})"),                      // 5000
            Regex("(\\d{1,3}\\.\\d{3})")            // 5.000
        )
        
        val text = extractAllText(node)
        val amounts = mutableListOf<Double>()
        
        patterns.forEach { pattern ->
            pattern.findAll(text).forEach { match ->
                val cleanAmount = match.value.replace("[,\\s.]".toRegex(), "")
                cleanAmount.toDoubleOrNull()?.let {
                    if (it >= 100 && it <= 100_000_000) {
                        amounts.add(it)
                    }
                }
            }
        }
        
        return amounts.maxOrNull()
    }

    private fun triggerAlert(amount: Double) {
        val intent = Intent(this, OverlayService::class.java).apply {
            putExtra("ACTION", "SHOW_TRANSACTION_ALERT")
            putExtra("AMOUNT", amount)
        }
        startService(intent)
        Log.d(TAG, "⚠️ Alerte envoyée: $amount FCFA")
    }

    private fun resetState() {
        state.hasAmount = false
        state.hasRecipient = false
        state.amount = null
        state.isOnConfirmationScreen = false
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrompu")
        resetState()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "✅ Service connecté - Mode INTELLIGENT")
    }
}