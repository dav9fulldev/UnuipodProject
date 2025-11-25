import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef OnWakeWordDetected = Function(String command);

class SikaVoiceService {
  static final SikaVoiceService _instance = SikaVoiceService._internal();

  factory SikaVoiceService() => _instance;

  SikaVoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  bool _awaitingCommand = false;
  Timer? _restartTimer;

  OnWakeWordDetected? _onWakeWordDetected;

  /// Initialize speech recognition and start continuous listening
  Future<void> initialize(
      {required OnWakeWordDetected onWakeWordDetected}) async {
    _onWakeWordDetected = onWakeWordDetected;

    _available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );

    if (_available) {
      await _startListeningContinuous();
    } else {
      debugPrint('Speech recognition not available');
    }
  }

  void _onStatus(String status) {
    debugPrint(
        'SikaVoiceService status: $status, _listening=$_listening, _awaitingCommand=$_awaitingCommand');

    if (status == 'done' || status == 'notListening') {
      _listening = false;
      if (!_awaitingCommand) {
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(milliseconds: 300), () {
          if (!_awaitingCommand) {
            debugPrint(
                'Auto-restarting continuous listening after status=$status');
            _startListeningContinuous();
          }
        });
      }
    }
  }

  void _onError(dynamic error) {
    try {
      final msg = error?.errorMsg ?? error?.toString();
      debugPrint('SikaVoiceService error: $msg');
    } catch (e) {
      debugPrint('SikaVoiceService error (unknown): $error');
    }

    _listening = false;
    if (!_awaitingCommand) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(milliseconds: 500), () {
        if (!_awaitingCommand) {
          debugPrint('Auto-restarting after error');
          _startListeningContinuous();
        }
      });
    }
  }

  Future<void> _startListeningContinuous() async {
    if (!_available) {
      debugPrint('Speech not available, skipping start');
      return;
    }
    if (_listening) {
      debugPrint('Already listening, skipping start');
      return;
    }

    _listening = true;
    debugPrint('🎤 Starting brief listening session (5s) to detect Sika...');

    try {
      await _speech.listen(
        onResult: _onSpeechResultContinuous,
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
        cancelOnError: false,
        pauseFor:
            const Duration(seconds: 5), // stop listening after 5s of silence
        listenFor:
            const Duration(seconds: 5), // brief 5s session to detect wake-word
      );
    } catch (e) {
      debugPrint('❌ Error starting continuous listen: $e');
      _listening = false;
    }
  }

  void _onSpeechResultContinuous(dynamic result) {
    String recognized = '';
    try {
      recognized =
          (result?.recognizedWords ?? result?.recognized ?? '') as String;
    } catch (e) {
      recognized = result?.toString() ?? '';
    }

    if (recognized.isNotEmpty) {
      debugPrint('🔊 Recognized: "$recognized"');
    }

    // Detect wake-word "Sika" - only trigger if not already processing
    if (!_awaitingCommand && recognized.toLowerCase().contains('sika')) {
      debugPrint(
          '✅ 🎤 WAKE WORD DETECTED: "Sika" - Triggering command overlay...');
      _awaitingCommand = true;
      _listening = false; // Stop listening while processing command
      _onWakeWordDetected?.call('Sika detected');

      // Auto-reset after command is processed (native overlay will handle speech)
      Future.delayed(const Duration(seconds: 3), () {
        debugPrint(
            '⏸️ Resuming continuous listening after wake-word processing');
        _awaitingCommand = false;
        // Restart listening to detect "Sika" again
        _startListeningContinuous();
      });
    }
  }

  Future<void> stopListening() async {
    _restartTimer?.cancel();
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
  }

  Future<void> dispose() async {
    _restartTimer?.cancel();
    await stopListening();
  }

  bool get isListening => _listening;
  bool get isAvailable => _available;
}
