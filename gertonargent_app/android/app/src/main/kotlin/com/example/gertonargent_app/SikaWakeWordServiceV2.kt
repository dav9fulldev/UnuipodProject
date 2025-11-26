package com.example.gertonargent_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean

/**
 * SikaWakeWordServiceV2 — Service natif pour détection wake-word "Sika"
 * 
 * Fonctionnalités :
 * 1. Écoute continue du mot "Sika" (fallback simple si Vosk indisponible)
 * 2. À la détection : TTS "Oui {firstname} ?"
 * 3. STT pour capturer la commande complète
 * 4. Parsing et ajout à pending_transactions (SharedPreferences)
 * 5. MethodChannel pour notifier Flutter
 * 6. TTS de confirmation personnalisée
 */
class SikaWakeWordServiceV2 : Service(), TextToSpeech.OnInitListener {

    companion object {
        private const val TAG = "SikaWakeWordServiceV2"
        private const val CHANNEL_ID = "SikaWakeWordChannel"
        private const val NOTIFICATION_ID = 2001
        private const val SAMPLE_RATE = 16000
        private const val WAKE_WORD = "sika"

        const val ACTION_WAKE_WORD_DETECTED = "com.gertonargent.WAKE_WORD_DETECTED"
        const val ACTION_STOP_LISTENING = "com.gertonargent.STOP_LISTENING"

        var isRunning = false
            private set
    }

    private var tts: TextToSpeech? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var audioRecord: AudioRecord? = null
    private var isListening = AtomicBoolean(false)
    private var isProcessingCommand = AtomicBoolean(false)
    private var recognitionThread: Thread? = null
    private lateinit var prefs: SharedPreferences
    private lateinit var mainActivity: Class<*>

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "======== SikaWakeWordServiceV2.onCreate() called ========")
        prefs = getSharedPreferences("sika_prefs", MODE_PRIVATE)
        tts = TextToSpeech(this, this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_LISTENING -> {
                Log.d(TAG, "Received ACTION_STOP_LISTENING")
                stopListening()
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                startForeground(NOTIFICATION_ID, createNotification())
                if (!isRunning) {
                    Log.d(TAG, "Starting service for the first time")
                    isRunning = true
                    startWakeWordDetection()
                } else {
                    Log.d(TAG, "Service already running, ignoring duplicate start request")
                }
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy called")
        stopListening()
        isRunning = false
        tts?.shutdown()
        speechRecognizer?.destroy()
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            Log.d(TAG, "✅ TextToSpeech initialized")
            tts?.language = Locale.FRENCH
        } else {
            Log.e(TAG, "❌ TextToSpeech initialization failed")
        }
    }

    // ============================================================================
    // WAKE-WORD DETECTION
    // ============================================================================

    private fun startWakeWordDetection() {
        Log.d(TAG, "Starting wake-word detection (simple loudness fallback)")
        if (isListening.getAndSet(true)) return

        try {
            val bs = AudioRecord.getMinBufferSize(
                SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
            ) * 2
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT, bs
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed")
                return
            }

            audioRecord?.startRecording()
            Log.d(TAG, "✅ Wake-word detection started")

            recognitionThread = Thread { wakeWordDetectionLoop(bs) }
            recognitionThread?.start()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting detection: ${e.message}", e)
        }
    }

    private fun wakeWordDetectionLoop(bufferSize: Int) {
        val buffer = ByteArray(bufferSize)
        var loudnessCount = 0

        while (isListening.get() && !Thread.interrupted()) {
            try {
                val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (read > 0) {
                    // Détection simple: ampleur audio
                    var loudSamples = 0
                    for (i in 0 until read step 2) {
                        if (i + 1 < read) {
                            val sample = ((buffer[i].toInt() and 0xFF) or
                                    ((buffer[i + 1].toInt() and 0xFF) shl 8)).toShort()
                            if (Math.abs(sample) > 3000) loudSamples++
                        }
                    }

                    // Si >40% de samples sont forts, incrémenter compteur
                    if (loudSamples > read / 2.5) {
                        loudnessCount++
                    } else {
                        loudnessCount = Math.max(0, loudnessCount - 1)
                    }

                    // Si loud pendant ~0.5s, traiter comme "Sika"
                    if (loudnessCount > 8) {
                        Log.d(TAG, "🎤 Wake-word detected (loud sound)")
                        onWakeWordDetected()
                        loudnessCount = 0
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in loop: ${e.message}")
            }
        }
    }

    private fun onWakeWordDetected() {
        if (!isListening.getAndSet(false)) return

        try {
            stopAudioRecord()
            Log.d(TAG, "======== WAKE-WORD DETECTED ========")

            // Broadcast pour Flutter
            val intent = Intent(ACTION_WAKE_WORD_DETECTED)
            sendBroadcast(intent)

            // Récupérer le prénom utilisateur
            val firstname = prefs.getString("user_firstname", "utilisateur") ?: "utilisateur"
            Log.d(TAG, "Username: $firstname")

            // Dire bonjour en TTS
            val greeting = "Oui $firstname ?"
            speakAsync(greeting)

            // Attendre 500ms que le TTS commence
            Thread.sleep(500)

            // Démarrer STT pour capturer la commande
            startCommandCapture()
        } catch (e: Exception) {
            Log.e(TAG, "Error in onWakeWordDetected: ${e.message}", e)
            restartWakeWordDetection()
        }
    }

    // ============================================================================
    // COMMAND CAPTURE (STT)
    // ============================================================================

    private fun startCommandCapture() {
        Log.d(TAG, "Starting command capture...")
        
        if (isProcessingCommand.getAndSet(true)) {
            Log.w(TAG, "Already processing a command, skipping")
            return
        }

        try {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "fr-FR")
            intent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
            intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 5000)
            intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2000)

            val listener = object : RecognitionListener {
                override fun onReadyForSpeech(params: android.os.Bundle?) {
                    Log.d(TAG, "Ready for speech input")
                }
                override fun onBeginningOfSpeech() {
                    Log.d(TAG, "User started speaking")
                }
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {
                    Log.d(TAG, "User finished speaking")
                }
                override fun onError(error: Int) {
                    Log.e(TAG, "STT Error code: $error")
                    isProcessingCommand.set(false)
                    restartWakeWordDetection()
                }
                override fun onResults(results: android.os.Bundle?) {
                    handleSTTResults(results)
                    isProcessingCommand.set(false)
                }
                override fun onPartialResults(partialResults: android.os.Bundle?) {}
                override fun onEvent(eventType: Int, params: android.os.Bundle?) {}
            }

            speechRecognizer?.setRecognitionListener(listener)
            speechRecognizer?.startListening(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting STT: ${e.message}", e)
            isProcessingCommand.set(false)
            restartWakeWordDetection()
        }
    }

    private fun handleSTTResults(results: android.os.Bundle?) {
        try {
            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            if (matches.isNullOrEmpty()) {
                Log.w(TAG, "No speech recognized")
                restartWakeWordDetection()
                return
            }

            val command = matches[0].lowercase(Locale.getDefault())
            Log.d(TAG, "📝 STT result: \"$command\"")

            // Parser la commande
            val (intention, entities) = parseCommand(command)
            Log.d(TAG, "Parsed intention: $intention, entities: $entities")

            when (intention) {
                "add_expense" -> {
                    handleAddExpense(entities)
                }
                "unknown" -> {
                    speakAsync("Désolé, je n'ai pas compris votre demande.")
                    Thread.sleep(2000)
                    restartWakeWordDetection()
                }
                else -> {
                    Log.d(TAG, "Intention not yet handled: $intention")
                    restartWakeWordDetection()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling STT results: ${e.message}", e)
            restartWakeWordDetection()
        }
    }

    // ============================================================================
    // COMMAND PARSING
    // ============================================================================

    private data class ParseResult(val intention: String, val entities: Map<String, String>)

    private fun parseCommand(command: String): ParseResult {
        val entities = mutableMapOf<String, String>()

        // Patterns pour détection de dépense
        if (command.contains(Regex("ajoute|enregistre|ajouter|dépen|expense", RegexOption.IGNORE_CASE))) {
            // Extraire le montant (ex: "5000", "10 mille")
            val amountMatch = Regex("""(\d+)\s*(?:mille|k|fcfa|cfa)?""").find(command)
            if (amountMatch != null) {
                var amount = amountMatch.groupValues[1].toInt()
                if (command.contains(Regex("mille|k", RegexOption.IGNORE_CASE))) {
                    amount *= 1000
                }
                entities["amount"] = amount.toString()
            }

            // Extraire la catégorie (transport, repas, etc.)
            val categoryMatch = Regex(
                """(transport|taxi|bus|essence|food|repas|manger|eat|café|cofee|santé|health|médecin|shopping|course|loisir|divertissement)""",
                RegexOption.IGNORE_CASE
            ).find(command)
            if (categoryMatch != null) {
                entities["category"] = categoryMatch.groupValues[0].lowercase()
            }

            // Notes/description
            entities["description"] = command

            if (entities.containsKey("amount")) {
                return ParseResult("add_expense", entities)
            }
        }

        return ParseResult("unknown", emptyMap())
    }

    // ============================================================================
    // HANDLE EXPENSE
    // ============================================================================

    private fun handleAddExpense(entities: Map<String, String>) {
        try {
            val amount = entities["amount"]?.toIntOrNull() ?: run {
                speakAsync("Je n'ai pas compris le montant.")
                restartWakeWordDetection()
                return
            }
            val category = entities["category"] ?: "autre"
            val description = entities["description"] ?: ""
            val firstname = prefs.getString("user_firstname", "utilisateur") ?: "utilisateur"

            // Créer la transaction
            val transaction = JSONObject().apply {
                put("amount", amount)
                put("category", category)
                put("description", description)
                put("date", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).format(Date()))
                put("source", "sika_voice")
                put("status", "pending")
            }

            // Ajouter à pending_transactions
            addPendingTransaction(transaction)

            // TTS confirmation
            val confirmation = "Très bien $firstname, j'ai enregistré $amount FCFA en $category."
            speakAsync(confirmation)
            Log.d(TAG, "✅ Expense added and confirmed via TTS")

            // Attendre la fin du TTS
            Thread.sleep(3000)

            // Relancer détection
            restartWakeWordDetection()
        } catch (e: Exception) {
            Log.e(TAG, "Error handling expense: ${e.message}", e)
            speakAsync("Une erreur s'est produite.")
            restartWakeWordDetection()
        }
    }

    private fun addPendingTransaction(transaction: JSONObject) {
        try {
            val existing = prefs.getString("pending_transactions", "[]") ?: "[]"
            val array = JSONArray(existing)
            array.put(transaction)
            prefs.edit().putString("pending_transactions", array.toString()).apply()
            Log.d(TAG, "📌 Pending transaction saved (total: ${array.length()})")

            // Notifier Flutter via MethodChannel (sera fait via MainActivity broadcast)
            val intent = Intent("com.gertonargent.PENDING_TRANSACTION_ADDED")
            intent.putExtra("transaction", transaction.toString())
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error adding pending transaction: ${e.message}", e)
        }
    }

    // ============================================================================
    // TTS HELPERS
    // ============================================================================

    private fun speakAsync(text: String) {
        Thread {
            try {
                if (tts?.isSpeaking == true) {
                    tts?.stop()
                    Thread.sleep(500)
                }
                tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null)
                Log.d(TAG, "🔊 TTS: $text")
            } catch (e: Exception) {
                Log.e(TAG, "TTS Error: ${e.message}", e)
            }
        }.start()
    }

    // ============================================================================
    // CLEANUP & RESTART
    // ============================================================================

    private fun stopListening() {
        isListening.set(false)
        recognitionThread?.interrupt()
        recognitionThread = null
        stopAudioRecord()
    }

    private fun stopAudioRecord() {
        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping audioRecord: ${e.message}")
        }
    }

    private fun restartWakeWordDetection() {
        Log.d(TAG, "Restarting wake-word detection...")
        isListening.set(false)
        stopAudioRecord()
        Thread.sleep(500)
        startWakeWordDetection()
    }

    // ============================================================================
    // NOTIFICATION
    // ============================================================================

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Sika Assistant",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Écoute continue pour Sika"
            channel.setShowBadge(false)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val pi = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val stopIntent = Intent(this, SikaWakeWordServiceV2::class.java)
        stopIntent.action = ACTION_STOP_LISTENING
        val stopPi = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sika vous écoute")
            .setContentText("Dites Sika pour parler")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pi)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
