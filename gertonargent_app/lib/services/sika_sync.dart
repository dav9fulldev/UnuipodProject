import 'package:flutter/foundation.dart';
import 'package:gertonargent_app/services/sika_native.dart';
import 'package:gertonargent_app/data/services/api_service.dart';

/// SikaSync — Synchronisation automatique des transactions Sika
///
/// Fonctionnalités :
/// - Lecture des transactions en attente depuis SharedPreferences natif
/// - Tentative de synchronisation avec le backend
/// - Gestion du verrouillage (mutex) pour éviter les exécutions concurrentes
/// - Logs détaillés pour le débogage
class SikaSync {
  static bool _isSyncing = false;

  /// Synchronise les transactions en attente
  ///
  /// Processus :
  /// 1. Vérifier que le token est disponible
  /// 2. Lire les transactions locales
  /// 3. Pour chaque transaction, tenter la sync avec le backend
  /// 4. En cas de succès, supprimer de la liste locale
  /// 5. En cas d'erreur réseau, conserver la transaction
  static Future<void> syncPendingTransactions({
    required ApiService apiService,
    int maxRetries = 3,
  }) async {
    // Verrouillage mutex : éviter les exécutions concurrentes
    if (_isSyncing) {
      debugPrint('[SikaSync] Already syncing, skipping...');
      return;
    }

    _isSyncing = true;

    try {
      debugPrint('[SikaSync] ============ START SYNC ============');

      // 1. Vérifier qu'un token est présent (le token doit être défini par l'appelant)
      if (!apiService.hasToken) {
        debugPrint(
            '[SikaSync] ⚠️ Token not available on ApiService, skipping sync');
        return;
      }

      // 2. Lire les transactions en attente
      final pending = await SikaNative.readPendingTransactions();
      debugPrint('[SikaSync] Found ${pending.length} pending transaction(s)');

      if (pending.isEmpty) {
        debugPrint('[SikaSync] No pending transactions to sync');
        return;
      }

      // 3. Tenter la synchronisation
      int syncedCount = 0;
      final List<int> indicesToRemove = [];

      for (int i = 0; i < pending.length; i++) {
        final tx = pending[i];
        final txId = tx['id'] ?? 'unknown';

        try {
          debugPrint('[SikaSync] Syncing transaction #$i (id=$txId)...');

          // Appeler le backend pour créer la transaction en mappant les champs
          final double? amount =
              tx['amount'] is num ? (tx['amount'] as num).toDouble() : null;
          final String? category = tx['category']?.toString();
          final String? description = tx['description']?.toString();

          if (amount == null || category == null) {
            debugPrint(
                '[SikaSync] ⚠️ Transaction #$i missing amount or category, skipping');
            continue;
          }

          final response = await apiService
              .createTransaction(
                  amount: amount, category: category, description: description)
              .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                  '[SikaSync] Timeout creating transaction $txId');
            },
          );

          // ApiService retourne un Map (response.data) — considérer la sync réussie si un id est présent
          if (response['id'] != null) {
            debugPrint(
                '[SikaSync] ✅ Transaction #$i synced successfully (id=$txId)');
            syncedCount++;
            indicesToRemove.add(i);
          } else {
            debugPrint(
                '[SikaSync] ❌ Failed to sync transaction #$i (response missing id)');
          }
        } catch (e) {
          debugPrint('[SikaSync] ⚠️ Error syncing transaction #$i: $e');
          // Ne pas supprimer en cas d'erreur, conserver pour retry plus tard
        }
      }

      // 4. Supprimer les transactions synchronisées (en ordre inverse pour éviter les décalages d'index)
      for (int index in indicesToRemove.reversed) {
        await SikaNative.removePendingTransaction(index);
      }

      debugPrint(
        '[SikaSync] ============ SYNC COMPLETE: $syncedCount/${pending.length} synced ============',
      );
    } catch (e) {
      debugPrint('[SikaSync] ❌ Fatal error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Vérifie s'il y a des transactions en attente
  static Future<bool> hasPendingTransactions() async {
    final pending = await SikaNative.readPendingTransactions();
    return pending.isNotEmpty;
  }

  /// Retourne le nombre de transactions en attente
  static Future<int> getPendingCount() async {
    final pending = await SikaNative.readPendingTransactions();
    return pending.length;
  }

  /// Force le reset du verrou (utiliser avec prudence, pour tests uniquement)
  static void resetLock() {
    _isSyncing = false;
    debugPrint('[SikaSync] Lock reset');
  }
}

/// Exception levée en cas de timeout
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}
