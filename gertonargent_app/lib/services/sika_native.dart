import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// SikaNative — Wrapper MethodChannel pour l'intégration native Sika
/// 
/// Expose les méthodes natives pour :
/// - Gestion du service wake-word
/// - Lecture/écriture de transactions pendantes
/// - Récupération du prénom utilisateur
/// - Contrôle de l'overlay
class SikaNative {
  static const platform = MethodChannel('com.gertonargent/sika');

  // ============================================================================
  // SERVICE CONTROL
  // ============================================================================

  /// Démarre le service wake-word Sika
  static Future<bool> startSikaService() async {
    try {
      final bool result = await platform.invokeMethod<bool>('startSikaService') ?? false;
      debugPrint('[SikaNative] Service started: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error starting service: $e');
      return false;
    }
  }

  /// Arrête le service wake-word Sika
  static Future<bool> stopSikaService() async {
    try {
      final bool result = await platform.invokeMethod<bool>('stopSikaService') ?? false;
      debugPrint('[SikaNative] Service stopped: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error stopping service: $e');
      return false;
    }
  }

  /// Vérifie si le service est en cours d'exécution
  static Future<bool> isSikaServiceRunning() async {
    try {
      final bool result = await platform.invokeMethod<bool>('isSikaServiceRunning') ?? false;
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error checking service status: $e');
      return false;
    }
  }

  // ============================================================================
  // USER DATA
  // ============================================================================

  /// Récupère le prénom de l'utilisateur stocké côté natif
  static Future<String?> getUserFirstname() async {
    try {
      final String? result = await platform.invokeMethod<String>('getUserFirstname');
      debugPrint('[SikaNative] Retrieved firstname: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error getting firstname: $e');
      return null;
    }
  }

  /// Définit le prénom de l'utilisateur côté natif
  /// À appeler après l'inscription réussie
  static Future<bool> setUserFirstname(String firstname) async {
    try {
      final bool result = await platform.invokeMethod<bool>(
        'setUserFirstname',
        {'firstname': firstname},
      ) ?? false;
      debugPrint('[SikaNative] Firstname set: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error setting firstname: $e');
      return false;
    }
  }

  // ============================================================================
  // PENDING TRANSACTIONS
  // ============================================================================

  /// Récupère toutes les transactions en attente
  static Future<List<Map<String, dynamic>>> readPendingTransactions() async {
    try {
      final String? jsonStr = await platform.invokeMethod<String>('readPendingTransactions');
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      final List decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[SikaNative] Error reading pending transactions: $e');
      return [];
    }
  }

  /// Ajoute une transaction en attente
  static Future<bool> addPendingTransaction(Map<String, dynamic> transaction) async {
    try {
      final String txJson = jsonEncode(transaction);
      final bool result = await platform.invokeMethod<bool>(
        'addPendingTransaction',
        {'transaction': txJson},
      ) ?? false;
      debugPrint('[SikaNative] Transaction added: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error adding transaction: $e');
      return false;
    }
  }

  /// Supprime une transaction en attente par index
  static Future<bool> removePendingTransaction(int index) async {
    try {
      final bool result = await platform.invokeMethod<bool>(
        'removePendingTransaction',
        {'index': index},
      ) ?? false;
      debugPrint('[SikaNative] Transaction removed at index $index: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error removing transaction: $e');
      return false;
    }
  }

  /// Efface toutes les transactions en attente
  static Future<bool> clearPendingTransactions() async {
    try {
      final bool result = await platform.invokeMethod<bool>('clearPendingTransactions') ?? false;
      debugPrint('[SikaNative] Pending transactions cleared: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error clearing transactions: $e');
      return false;
    }
  }

  // ============================================================================
  // OVERLAY CONTROL
  // ============================================================================

  /// Affiche l'overlay Sika avec un message
  static Future<bool> showSikaOverlay({String message = 'Sika vous écoute...'}) async {
    try {
      final bool result = await platform.invokeMethod<bool>(
        'showSikaOverlay',
        {'message': message},
      ) ?? false;
      debugPrint('[SikaNative] Overlay shown: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error showing overlay: $e');
      return false;
    }
  }

  /// Masque l'overlay Sika
  static Future<bool> hideSikaOverlay() async {
    try {
      final bool result = await platform.invokeMethod<bool>('hideSikaOverlay') ?? false;
      debugPrint('[SikaNative] Overlay hidden: $result');
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error hiding overlay: $e');
      return false;
    }
  }

  // ============================================================================
  // PERMISSIONS
  // ============================================================================

  /// Vérifie si la permission microphone est accordée
  static Future<bool> checkMicrophonePermission() async {
    try {
      final bool result = await platform.invokeMethod<bool>('checkMicrophonePermission') ?? false;
      return result;
    } catch (e) {
      debugPrint('[SikaNative] Error checking microphone permission: $e');
      return false;
    }
  }
}
