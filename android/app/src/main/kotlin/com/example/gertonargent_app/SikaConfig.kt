package com.example.gertonargent_app

/**
 * SikaConfig - Configuration centralisée pour le service Sika
 *
 * Permet d'ajuster facilement les paramètres de détection, TTS, STT, etc.
 */
object SikaConfig {
    
    // ============================================================================
    // WAKE-WORD DETECTION
    // ============================================================================
    
    /** Seuil de loudness pour la détection du wake-word (0-32767)
     *  Plus élevé = moins sensible, moins de faux positifs
     *  Plus bas = plus sensible, plus de faux positifs
     *  Valeur recommandée: 3000-4000
     */
    const val LOUDNESS_THRESHOLD = 3500
    
    /** Nombre minimum de frames consécutifs avec loudness > threshold pour détecter wake-word
     *  Valeur recommandée: 5-10 (correspond à ~50-100ms à 44.1kHz)
     */
    const val MIN_LOUD_FRAMES = 8
    
    /** Fréquence d'échantillonnage en Hz */
    const val SAMPLE_RATE = 44100
    
    /** Taille du buffer audio en samples */
    const val BUFFER_SIZE = 4096
    
    /** Boucle de détection active tous les N millisecondes */
    const val DETECTION_LOOP_INTERVAL_MS = 100L
    
    // ============================================================================
    // TEXT-TO-SPEECH (TTS)
    // ============================================================================
    
    /** Vitesse de parole (0.5 = lent, 1.0 = normal, 2.0 = rapide) */
    const val TTS_SPEED = 1.0f
    
    /** Pitch/Tonalité (0.5 = grave, 1.0 = normal, 2.0 = aigu) */
    const val TTS_PITCH = 1.0f
    
    /** Langue pour TTS (français) */
    const val TTS_LANGUAGE = "fr"
    
    /** Pays pour TTS (France) */
    const val TTS_COUNTRY = "FR"
    
    /** Délai maximal d'initialisation du TTS en millisecondes */
    const val TTS_INIT_TIMEOUT_MS = 5000L
    
    // ============================================================================
    // SPEECH-TO-TEXT (STT)
    // ============================================================================
    
    /** Durée minimale du silence avant fin d'enregistrement (en millisecondes) */
    const val STT_SILENCE_TIMEOUT_MS = 2000
    
    /** Durée d'écoute minimale avant traitement (en millisecondes) */
    const val STT_MIN_LISTEN_DURATION_MS = 500
    
    /** Durée maximale d'enregistrement (en secondes) */
    const val STT_MAX_DURATION_SEC = 10
    
    /** Langue pour STT (français) */
    const val STT_LANGUAGE = "fr-FR"
    
    /** Timeout maximal pour une requête STT (en millisecondes) */
    const val STT_TIMEOUT_MS = 15000
    
    // ============================================================================
    // COMMANDES VOIX
    // ============================================================================
    
    /** Montant minimum pour une dépense (en FCFA) */
    const val MIN_AMOUNT = 100
    
    /** Montant maximum pour une dépense (en FCFA) */
    const val MAX_AMOUNT = 1000000
    
    /** Délai avant redémarrage de la détection après une commande (en millisecondes) */
    const val RESTART_DETECTION_DELAY_MS = 1500L
    
    // ============================================================================
    // OVERLAY
    // ============================================================================
    
    /** Durée de l'animation pulse (en millisecondes) */
    const val OVERLAY_PULSE_DURATION_MS = 600
    
    /** Durée avant disparition automatique de l'overlay (en millisecondes) */
    const val OVERLAY_AUTO_HIDE_DURATION_MS = 3000
    
    /** Taille du bubble en dp */
    const val OVERLAY_BUBBLE_SIZE_DP = 80
    
    // ============================================================================
    // SYNC
    // ============================================================================
    
    /** Timeout maximal par transaction lors de la sync (en secondes) */
    const val SYNC_TIMEOUT_SEC = 10
    
    /** Nombre de retry en cas d'erreur réseau */
    const val SYNC_MAX_RETRIES = 3
    
    /** Délai entre les tentatives de retry (en millisecondes) */
    const val SYNC_RETRY_DELAY_MS = 2000L
    
    // ============================================================================
    // LOGS & DEBUG
    // ============================================================================
    
    /** Activer les logs détaillés */
    const val DEBUG_LOGS = BuildConfig.DEBUG
    
    /** Préfixe pour les logs Sika */
    const val LOG_TAG_PREFIX = "Sika"
    
    // ============================================================================
    // SHARED PREFERENCES
    // ============================================================================
    
    /** Nom de la SharedPreferences pour Sika */
    const val PREFS_NAME = "sika_prefs"
    
    /** Clé pour le prénom utilisateur */
    const val PREFS_KEY_FIRSTNAME = "user_firstname"
    
    /** Clé pour les transactions en attente */
    const val PREFS_KEY_PENDING_TRANSACTIONS = "pending_transactions"
    
    /** Clé pour l'état du service */
    const val PREFS_KEY_SERVICE_STATE = "sika_service_enabled"
    
    // ============================================================================
    // REGEX PATTERNS POUR PARSING
    // ============================================================================
    
    /** Pattern pour détecter une commande "ajouter une dépense" */
    const val PATTERN_ADD_EXPENSE = "(?:ajoute|ajouter|enregistre|enregistrer|une?\\s*dépense|créer|créate).*(?:dépense|montant|coût|frais|argent)"
    
    /** Pattern pour extraire le montant */
    const val PATTERN_AMOUNT = "\\b(\\d+)(?:\\s*(?:mille|k|thousand))?(?:\\s*(?:francs?|fcfa|cfa))?\\b"
    
    /** Pattern pour extraire la catégorie */
    const val PATTERN_CATEGORY = "(?:en|de|pour|à|dans)\\s+([a-zàâäéèêëïîôöùûüœæçàâäéèêëïîôöùûüœæ]+)"
    
    // ============================================================================
    // MÉTHODE UTILE: Activer/Désactiver les logs
    // ============================================================================
    
    fun logDebug(tag: String, message: String) {
        if (DEBUG_LOGS) {
            android.util.Log.d("$LOG_TAG_PREFIX/$tag", message)
        }
    }
    
    fun logError(tag: String, message: String, throwable: Throwable? = null) {
        android.util.Log.e("$LOG_TAG_PREFIX/$tag", message, throwable)
    }
    
    fun logWarning(tag: String, message: String) {
        android.util.Log.w("$LOG_TAG_PREFIX/$tag", message)
    }
    
    fun logInfo(tag: String, message: String) {
        android.util.Log.i("$LOG_TAG_PREFIX/$tag", message)
    }
}
