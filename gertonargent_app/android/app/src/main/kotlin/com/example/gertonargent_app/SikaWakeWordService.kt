package com.example.gertonargent_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class SikaWakeWordService : Service() {

    companion object {
        private const val TAG = "SikaWakeWordService"
        private const val CHANNEL_ID = "SikaWakeWordChannel"
        private const val NOTIFICATION_ID = 2001
        private const val SAMPLE_RATE = 16000
        private const val WAKE_WORD = "sika"

        const val ACTION_WAKE_WORD_DETECTED = "com.gertonargent.WAKE_WORD_DETECTED"
        const val ACTION_START_LISTENING = "com.gertonargent.START_LISTENING"
        const val ACTION_STOP_LISTENING = "com.gertonargent.STOP_LISTENING"

        var isRunning = false
            private set
    }

    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private var recognitionThread: Thread? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "======== SikaWakeWordService.onCreate() called ========")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_LISTENING -> {
                stopListening()
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                startForeground(NOTIFICATION_ID, createNotification())
                // Only initialize if not already running
                if (!isRunning) {
                    Log.d(TAG, "Starting service for the first time")
                    isRunning = true
                    initializeVosk()
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
        stopListening()
        isRunning = false
        model?.close()
        recognizer?.close()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Sika Assistant", NotificationManager.IMPORTANCE_LOW)
            channel.description = "Ecoute pour le mot Sika"
            channel.setShowBadge(false)
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val pi = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val stopIntent = Intent(this, SikaWakeWordService::class.java)
        stopIntent.action = ACTION_STOP_LISTENING
        val stopPi = PendingIntent.getService(this, 0, stopIntent, PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sika vous ecoute")
            .setContentText("Dites Sika pour parler")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pi)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun initializeVosk() {
        Log.d(TAG, "Starting Vosk initialization in background thread...")
        Thread {
            try {
                Log.d(TAG, "Background thread: Initializing Vosk model...")
                val modelDir = File(filesDir, "vosk-model-small-fr")
                Log.d(TAG, "Model dir: ${modelDir.absolutePath}")
                
                if (!modelDir.exists()) {
                    Log.d(TAG, "Model not found, copying from assets...")
                    if (!copyAssetFolder("vosk-model-small-fr", modelDir.absolutePath)) {
                        Log.e(TAG, "Failed to copy model from assets")
                        startSimpleWakeWordDetection()
                        return@Thread
                    }
                    Log.d(TAG, "Model copied successfully from assets")
                }
                
                val files = modelDir.listFiles()
                Log.d(TAG, "Model files found: ${files?.size} items")
                
                if (modelDir.exists() && modelDir.listFiles()?.isNotEmpty() == true) {
                    Log.d(TAG, "Loading Vosk model from: ${modelDir.absolutePath}")
                    try {
                        model = Model(modelDir.absolutePath)
                        recognizer = Recognizer(model, SAMPLE_RATE.toFloat())
                        Log.d(TAG, "✅ Vosk initialized successfully, starting listening")
                        startListening()
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to load Vosk model: ${e.message}", e)
                        startSimpleWakeWordDetection()
                    }
                } else { 
                    Log.w(TAG, "Model directory is empty or does not exist: ${modelDir.absolutePath}")
                    startSimpleWakeWordDetection()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Fatal error in initializeVosk: ${e.message}", e)
                startSimpleWakeWordDetection()
            }
        }.start()
    }

    private fun copyAssetFolder(assetPath: String, destPath: String): Boolean {
        return try {
            val files = assets.list(assetPath)
            if (files.isNullOrEmpty()) { copyAssetFile(assetPath, destPath); true }
            else { File(destPath).mkdirs(); files.forEach { copyAssetFolder(assetPath + "/" + it, destPath + "/" + it) }; true }
        } catch (e: IOException) { false }
    }

    private fun copyAssetFile(assetPath: String, destPath: String) {
        try { assets.open(assetPath).use { i -> FileOutputStream(destPath).use { o -> i.copyTo(o) } } } catch (e: IOException) { }
    }

    private fun startListening() {
        if (isListening) return
        try {
            Log.d(TAG, "Starting listening for wake-word...")
            val bs = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT) * 2
            audioRecord = AudioRecord(MediaRecorder.AudioSource.VOICE_RECOGNITION, SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bs)
            
            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord not initialized")
                return
            }
            
            audioRecord?.startRecording()
            isListening = true
            Log.d(TAG, "✅ Listening started, bufferSize=$bs")
            recognitionThread = Thread { recognizeLoop(bs) }
            recognitionThread?.start()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting listening: ${e.message}", e)
        }
    }

    private fun recognizeLoop(bufferSize: Int) {
        val buffer = ShortArray(bufferSize / 2)
        while (isListening && !Thread.interrupted()) {
            try {
                val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (read > 0 && recognizer != null) {
                    val bytes = ByteArray(read * 2)
                    for (i in 0 until read) {
                        bytes[i * 2] = (buffer[i].toInt() and 0xFF).toByte()
                        bytes[i * 2 + 1] = ((buffer[i].toInt() shr 8) and 0xFF).toByte()
                    }
                    val r = if (recognizer!!.acceptWaveForm(bytes, bytes.size)) recognizer!!.result else recognizer!!.partialResult
                    checkForWakeWord(r)
                }
            } catch (e: Exception) { }
        }
    }

    private fun checkForWakeWord(jsonResult: String) {
        try {
            val json = JSONObject(jsonResult)
            val text = json.optString("text", json.optString("partial", "")).lowercase()
            if (text.contains(WAKE_WORD)) onWakeWordDetected()
        } catch (e: Exception) { }
    }

    private fun onWakeWordDetected() {
        sendBroadcast(Intent(ACTION_WAKE_WORD_DETECTED))
        startSikaOverlay()
        recognizer?.reset()
    }

    private fun startSikaOverlay() {
        try {
            val oi = Intent(this, SikaOverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(oi) else startService(oi)
        } catch (e: Exception) { }
    }

    private fun startSimpleWakeWordDetection() {
        Log.w(TAG, "⚠️ Vosk not available, using simple wake-word detection fallback")
        if (isListening) return
        
        try {
            val bs = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT) * 2
            audioRecord = AudioRecord(MediaRecorder.AudioSource.VOICE_RECOGNITION, SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bs)
            
            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed for simple detection")
                return
            }
            
            audioRecord?.startRecording()
            isListening = true
            Log.d(TAG, "Simple wake-word detection started, bufferSize=$bs")
            
            recognitionThread = Thread { simpleWakeWordLoop(bs) }
            recognitionThread?.start()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting simple detection: ${e.message}", e)
        }
    }
    
    private fun simpleWakeWordLoop(bufferSize: Int) {
        val buffer = ByteArray(bufferSize)
        var loudnessCount = 0
        
        while (isListening && !Thread.interrupted()) {
            try {
                val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (read > 0) {
                    // Simple loudness detection: count samples with significant amplitude
                    var loudSamples = 0
                    for (i in 0 until read step 2) {
                        if (i + 1 < read) {
                            val sample = ((buffer[i].toInt() and 0xFF) or ((buffer[i + 1].toInt() and 0xFF) shl 8)).toShort()
                            if (Math.abs(sample) > 2000) loudSamples++
                        }
                    }
                    
                    // If >50% of samples are loud, increment counter
                    if (loudSamples > read / 4) {
                        loudnessCount++
                    } else {
                        loudnessCount = 0
                    }
                    
                    // If loud for 0.5 seconds (~8 frames at 16khz), treat as wake-word
                    if (loudnessCount > 5) {
                        Log.d(TAG, "Simple detection: Loud sound detected, treating as 'Sika'")
                        onWakeWordDetected()
                        loudnessCount = 0
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in simple loop: ${e.message}")
            }
        }
    }

    private fun stopListening() {
        isListening = false
        recognitionThread?.interrupt()
        recognitionThread = null
        try { audioRecord?.stop(); audioRecord?.release(); audioRecord = null } catch (e: Exception) { }
    }
}
