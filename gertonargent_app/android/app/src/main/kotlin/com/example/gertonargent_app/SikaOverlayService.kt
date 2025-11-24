 package com.example.gertonargent_app

  import android.app.*
  import android.content.Context
  import android.content.Intent
  import android.graphics.Color
  import android.graphics.PixelFormat
  import android.os.Build
  import android.os.Handler
  import android.os.IBinder
  import android.os.Looper
  import android.speech.RecognitionListener
  import android.speech.RecognizerIntent
  import android.speech.SpeechRecognizer
  import android.speech.tts.TextToSpeech
  import android.util.Log
  import android.util.TypedValue
  import android.view.Gravity
  import android.view.View
  import android.view.WindowManager
  import android.widget.LinearLayout
  import android.widget.TextView
  import androidx.cardview.widget.CardView
  import androidx.core.app.NotificationCompat
  import java.util.Locale

  class SikaOverlayService : Service(), TextToSpeech.OnInitListener {

      companion object {
          private const val TAG = "SikaOverlayService"
          private const val NOTIFICATION_ID = 2002
          private const val CHANNEL_ID = "sika_overlay_channel"
          const val ACTION_HIDE_OVERLAY = "com.gertonargent.HIDE_SIKA_OVERLAY"
      }

      private var windowManager: WindowManager? = null
      private var overlayView: View? = null
      private var speechRecognizer: SpeechRecognizer? = null
      private var tts: TextToSpeech? = null
      private var isListening = false
      private val handler = Handler(Looper.getMainLooper())
      private var statusText: TextView? = null
      private var transcriptText: TextView? = null
      private var pulseView: View? = null

      override fun onCreate() {
          super.onCreate()
          windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
          createNotificationChannel()
          tts = TextToSpeech(this, this)
      }

      override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
          when (intent?.action) {
              ACTION_HIDE_OVERLAY -> { hideOverlay(); stopSelf() }
              else -> { startForeground(NOTIFICATION_ID, createNotification()); showSikaOverlay() }
          }
          return START_NOT_STICKY
      }

      override fun onBind(intent: Intent?): IBinder? = null
      override fun onDestroy() { super.onDestroy(); hideOverlay(); speechRecognizer?.destroy(); tts?.shutdown() }
      override fun onInit(status: Int) { if (status == TextToSpeech.SUCCESS) { tts?.language = Locale.FRENCH; tts?.setSpeechRate(0.9f) } }

      private fun createNotificationChannel() {
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
              val channel = NotificationChannel(CHANNEL_ID, "Sika Assistant", NotificationManager.IMPORTANCE_LOW)
              getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
          }
      }

      private fun createNotification(): Notification {
          val hideIntent = Intent(this, SikaOverlayService::class.java).apply { action = ACTION_HIDE_OVERLAY }
          val hidePi = PendingIntent.getService(this, 0, hideIntent, PendingIntent.FLAG_IMMUTABLE)
          return NotificationCompat.Builder(this, CHANNEL_ID)
              .setContentTitle("Sika vous ecoute").setContentText("Parlez...")
              .setSmallIcon(android.R.drawable.ic_btn_speak_now)
              .addAction(android.R.drawable.ic_menu_close_clear_cancel, "X", hidePi)
              .setOngoing(true).build()
      }

      private fun showSikaOverlay() {
          if (overlayView != null) return
          handler.post {
              overlayView = createSikaView()
              val t = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE
              val p = WindowManager.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.WRAP_CONTENT, t, WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT)
              p.gravity = Gravity.BOTTOM; p.y = dp(50)
              windowManager?.addView(overlayView, p)
              handler.postDelayed({ startListening(); speak("Je vous ecoute") }, 500)
          }
      }

      private fun createSikaView(): View {
          val c = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setBackgroundColor(0xF0FFFFFF.toInt()); setPadding(dp(20), dp(15), dp(20), dp(20)) }
          val card = CardView(this).apply { radius = dp(30).toFloat(); cardElevation = dp(15).toFloat(); setCardBackgroundColor(Color.WHITE) }
          val content = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER_HORIZONTAL; setPadding(dp(30), dp(25), dp(30), dp(25)) }
          pulseView = View(this).apply { layoutParams = LinearLayout.LayoutParams(dp(100), dp(100)); background = android.graphics.drawable.GradientDrawable().apply { shape =
  android.graphics.drawable.GradientDrawable.OVAL; setColor(Color.parseColor("#00A86B")) } }
          statusText = TextView(this).apply { text = "Sika ecoute..."; textSize = 20f; setTextColor(Color.parseColor("#00A86B")); gravity = Gravity.CENTER }
          transcriptText = TextView(this).apply { text = ""; textSize = 16f; setTextColor(Color.parseColor("#333333")); gravity = Gravity.CENTER }
          val btn = TextView(this).apply { text = "Fermer"; textSize = 14f; setTextColor(Color.GRAY); setOnClickListener { hideOverlay(); stopSelf() } }
          content.addView(pulseView); content.addView(statusText); content.addView(transcriptText); content.addView(btn)
          card.addView(content); c.addView(card)
          startPulse()
          return c
      }

      private fun startPulse() {
          handler.post(object : Runnable { var s = 1f; var up = true
              override fun run() { if (pulseView == null) return; s += if (up) 0.03f else -0.03f; if (s >= 1.15f) up = false; if (s <= 1f) up = true; pulseView?.scaleX = s; pulseView?.scaleY = s;
  handler.postDelayed(this, 40) }
          })
      }

      private fun hideOverlay() { handler.post { stopListen(); overlayView?.let { windowManager?.removeView(it) }; overlayView = null } }

      private fun startListening() {
          if (isListening) return
          speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
          speechRecognizer?.setRecognitionListener(object : RecognitionListener {
              override fun onReadyForSpeech(p: android.os.Bundle?) { isListening = true; upStatus("Ecoute...") }
              override fun onBeginningOfSpeech() { upStatus("Parlez...") }
              override fun onRmsChanged(r: Float) {}
              override fun onBufferReceived(b: ByteArray?) {}
              override fun onEndOfSpeech() { upStatus("Analyse...") }
              override fun onError(e: Int) { isListening = false; upStatus("Erreur"); handler.postDelayed({ restart() }, 2000) }
              override fun onResults(r: android.os.Bundle?) { isListening = false; r?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.let { upTranscript(it); process(it) } }
              override fun onPartialResults(p: android.os.Bundle?) { p?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.let { upTranscript(it) } }
              override fun onEvent(t: Int, p: android.os.Bundle?) {}
          })
          val i = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply { putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
  putExtra(RecognizerIntent.EXTRA_LANGUAGE, "fr-FR"); putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true) }
          speechRecognizer?.startListening(i)
      }

      private fun stopListen() { isListening = false; speechRecognizer?.cancel() }
      private fun restart() { stopListen(); handler.postDelayed({ startListening() }, 500) }
      private fun upStatus(t: String) { handler.post { statusText?.text = t } }
      private fun upTranscript(t: String) { handler.post { transcriptText?.text = t } }
      private fun speak(t: String) { tts?.speak(t, TextToSpeech.QUEUE_FLUSH, null, "s") }

      private fun process(cmd: String) {
          val l = cmd.lowercase()
          val resp = when { l.contains("bonjour") -> "Bonjour!"; l.contains("fermer") -> { handler.postDelayed({ hideOverlay(); stopSelf() }, 1500); "Au revoir!" }; else -> { sendToFlutter(cmd);
  "Traitement..." } }
          upStatus(resp); speak(resp)
          if (!l.contains("fermer")) handler.postDelayed({ restart() }, 3000)
      }

      private fun sendToFlutter(cmd: String) { sendBroadcast(Intent("com.gertonargent.SIKA_COMMAND").putExtra("command", cmd)) }
      private fun dp(v: Int): Int = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()
  }
