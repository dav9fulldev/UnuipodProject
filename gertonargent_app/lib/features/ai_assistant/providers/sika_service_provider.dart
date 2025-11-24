import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service pour controler Sika en arriere-plan (wake word detection)
class SikaServiceState {
  final bool isServiceRunning;
  final bool hasOverlayPermission;
  final bool hasMicrophonePermission;
  final String? error;

  const SikaServiceState({
    this.isServiceRunning = false,
    this.hasOverlayPermission = false,
    this.hasMicrophonePermission = false,
    this.error,
  });

  SikaServiceState copyWith({
    bool? isServiceRunning,
    bool? hasOverlayPermission,
    bool? hasMicrophonePermission,
    String? error,
  }) {
    return SikaServiceState(
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      hasMicrophonePermission: hasMicrophonePermission ?? this.hasMicrophonePermission,
      error: error,
    );
  }
}

class SikaServiceNotifier extends StateNotifier<SikaServiceState> {
  static const _channel = MethodChannel('com.gertonargent/sika');

  SikaServiceNotifier() : super(const SikaServiceState()) {
    _checkStatus();
  }

  /// Verifier le status du service et des permissions
  Future<void> _checkStatus() async {
    try {
      final isRunning = await _channel.invokeMethod<bool>('isSikaServiceRunning') ?? false;
      final hasMic = await _channel.invokeMethod<bool>('checkMicrophonePermission') ?? false;
      
      state = state.copyWith(
        isServiceRunning: isRunning,
        hasMicrophonePermission: hasMic,
      );
    } catch (e) {
      debugPrint('Error checking Sika status: \$e');
    }
  }

  /// Demarrer le service de detection du wake word "Sika"
  Future<void> startSikaService() async {
    try {
      await _channel.invokeMethod('startSikaService');
      state = state.copyWith(isServiceRunning: true, error: null);
      debugPrint('Sika wake word service started');
    } catch (e) {
      debugPrint('Error starting Sika service: \$e');
      state = state.copyWith(
        error: 'Impossible de demarrer le service Sika',
      );
    }
  }

  /// Arreter le service de detection
  Future<void> stopSikaService() async {
    try {
      await _channel.invokeMethod('stopSikaService');
      state = state.copyWith(isServiceRunning: false, error: null);
      debugPrint('Sika wake word service stopped');
    } catch (e) {
      debugPrint('Error stopping Sika service: \$e');
      state = state.copyWith(
        error: 'Impossible d arreter le service Sika',
      );
    }
  }

  /// Afficher l overlay Sika manuellement (sans wake word)
  Future<void> showSikaOverlay() async {
    try {
      await _channel.invokeMethod('showSikaOverlay');
      debugPrint('Sika overlay shown');
    } catch (e) {
      debugPrint('Error showing Sika overlay: \$e');
      state = state.copyWith(
        error: 'Impossible d afficher Sika',
      );
    }
  }

  /// Masquer l overlay Sika
  Future<void> hideSikaOverlay() async {
    try {
      await _channel.invokeMethod('hideSikaOverlay');
      debugPrint('Sika overlay hidden');
    } catch (e) {
      debugPrint('Error hiding Sika overlay: \$e');
    }
  }

  /// Toggle le service (on/off)
  Future<void> toggleService() async {
    if (state.isServiceRunning) {
      await stopSikaService();
    } else {
      await startSikaService();
    }
  }

  /// Rafraichir le status
  Future<void> refresh() async {
    await _checkStatus();
  }
}

/// Provider pour le service Sika en arriere-plan
final sikaServiceProvider = StateNotifierProvider<SikaServiceNotifier, SikaServiceState>((ref) {
  return SikaServiceNotifier();
});
