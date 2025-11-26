import 'dart:async';
import 'package:flutter/foundation.dart';

typedef OnWakeWordDetected = Function(String command);

/// SikaVoiceService is now a STUB/PLACEHOLDER.
///
/// The actual voice handling is done by native Android services:
/// - SikaWakeWordService: Detects wake-word "Sika" using Vosk (offline ASR)
/// - SikaOverlayService: Displays overlay and captures user command after wake-word
/// - MainActivity: Forwards commands to Flutter via MethodChannel
///
/// This class exists for compatibility and future enhancements.
class SikaVoiceService {
  static final SikaVoiceService _instance = SikaVoiceService._internal();

  factory SikaVoiceService() => _instance;

  SikaVoiceService._internal();

  bool _available = false;

  /// Initialize - now just marks as available (native services handle everything)
  Future<void> initialize(
      {required OnWakeWordDetected onWakeWordDetected}) async {
    // onWakeWordDetected callback not used - native services manage voice
    _available = true;
    debugPrint(
        '✅ SikaVoiceService initialized (Native Android services handle voice)');
  }

  /// Stop listening - native services manage their own lifecycle
  Future<void> stopListening() async {
    debugPrint('⏸️ Native voice services stopped');
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🛑 SikaVoiceService disposed');
  }

  bool get isListening => _available;
  bool get isAvailable => _available;
}
