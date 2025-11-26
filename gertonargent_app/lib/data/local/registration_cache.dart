import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// RegistrationCache — Cache local pour l'inscription multi-étapes
///
/// Utilise Hive comme backend avec fallback sur fichier JSON
/// Permet de sauvegarder et restaurer l'état de l'inscription en cours
class RegistrationCache {
  static const String _boxName = 'registration_cache';
  static late Box<String> _box;
  static bool _initialized = false;

  /// Initialise le cache (à appeler au démarrage de l'app)
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      _initialized = true;
      debugPrint('[RegistrationCache] ✅ Initialized');
    } catch (e) {
      debugPrint('[RegistrationCache] ⚠️ Failed to initialize Hive: $e');
      rethrow;
    }
  }

  /// Sauvegarde une étape du formulaire d'inscription
  ///
  /// Exemple :
  /// ```dart
  /// await RegistrationCache.saveStep('firstname', 'David');
  /// await RegistrationCache.saveStep('lastname', 'Dupont');
  /// ```
  static Future<void> saveStep(String key, dynamic value) async {
    if (!_initialized) {
      debugPrint('[RegistrationCache] ⚠️ Not initialized');
      return;
    }

    try {
      final String jsonValue = jsonEncode(value);
      await _box.put(key, jsonValue);
      debugPrint('[RegistrationCache] Saved: $key = $value');
    } catch (e) {
      debugPrint('[RegistrationCache] Error saving step $key: $e');
    }
  }

  /// Récupère une étape sauvegardée
  ///
  /// Retourne null si la clé n'existe pas
  ///
  /// Exemple :
  /// ```dart
  /// final firstname = RegistrationCache.getStep('firstname') as String?;
  /// final age = RegistrationCache.getStep('age') as int?;
  /// ```
  static dynamic getStep(String key) {
    if (!_initialized) {
      debugPrint('[RegistrationCache] ⚠️ Not initialized');
      return null;
    }

    try {
      final String? jsonValue = _box.get(key);
      if (jsonValue == null) {
        return null;
      }
      final dynamic decoded = jsonDecode(jsonValue);
      debugPrint('[RegistrationCache] Retrieved: $key = $decoded');
      return decoded;
    } catch (e) {
      debugPrint('[RegistrationCache] Error retrieving step $key: $e');
      return null;
    }
  }

  /// Récupère tous les étapes sauvegardées sous forme de Map
  ///
  /// Utilisé pour créer la payload d'inscription finale
  ///
  /// Exemple :
  /// ```dart
  /// final payload = RegistrationCache.getAllSteps();
  /// // {
  /// //   "firstname": "David",
  /// //   "lastname": "Dupont",
  /// //   "email": "david@example.com",
  /// //   "phone": "77123456"
  /// // }
  /// ```
  static Map<String, dynamic> getAllSteps() {
    if (!_initialized) {
      debugPrint('[RegistrationCache] ⚠️ Not initialized');
      return {};
    }

    try {
      final result = <String, dynamic>{};
      for (final key in _box.keys) {
        final String? jsonValue = _box.get(key);
        if (jsonValue != null) {
          result[key] = jsonDecode(jsonValue);
        }
      }
      debugPrint('[RegistrationCache] Retrieved all steps: $result');
      return result;
    } catch (e) {
      debugPrint('[RegistrationCache] Error retrieving all steps: $e');
      return {};
    }
  }

  /// Récupère une étape avec un type générique
  ///
  /// Exemple :
  /// ```dart
  /// final firstname = RegistrationCache.getStepAs<String>('firstname');
  /// final age = RegistrationCache.getStepAs<int>('age');
  /// ```
  static T? getStepAs<T>(String key) {
    final value = getStep(key);
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Efface une seule étape
  static Future<void> clearStep(String key) async {
    if (!_initialized) {
      debugPrint('[RegistrationCache] ⚠️ Not initialized');
      return;
    }

    try {
      await _box.delete(key);
      debugPrint('[RegistrationCache] Cleared: $key');
    } catch (e) {
      debugPrint('[RegistrationCache] Error clearing step $key: $e');
    }
  }

  /// Efface TOUT le cache d'inscription
  /// À appeler après la soumission réussie du formulaire
  static Future<void> clear() async {
    if (!_initialized) {
      debugPrint('[RegistrationCache] ⚠️ Not initialized');
      return;
    }

    try {
      await _box.clear();
      debugPrint('[RegistrationCache] ✅ Cache cleared completely');
    } catch (e) {
      debugPrint('[RegistrationCache] Error clearing cache: $e');
    }
  }

  /// Retourne vrai s'il y a des données en cache
  static bool hasData() {
    if (!_initialized) return false;
    return _box.isNotEmpty;
  }

  /// Retourne le nombre d'étapes en cache
  static int getStepCount() {
    if (!_initialized) return 0;
    return _box.length;
  }

  /// DEBUG: Affiche tout le contenu du cache
  static void debugPrintAll() {
    if (!_initialized) {
      debugPrint('[RegistrationCache] Not initialized');
      return;
    }

    debugPrint('[RegistrationCache] ===== CACHE DUMP =====');
    for (final key in _box.keys) {
      final value = _box.get(key);
      debugPrint('[RegistrationCache] $key = $value');
    }
    debugPrint('[RegistrationCache] =====================');
  }

  /// Ancienne API (pour compatibilité backward)
  static T? getStepTyped<T>(String key) {
    return getStepAs<T>(key);
  }

  static Map<String, dynamic> all() {
    return getAllSteps();
  }
}
