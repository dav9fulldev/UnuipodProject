import 'package:hive/hive.dart';

class RegistrationCache {
  static const _boxName = 'registration_cache';

  /// Initialize Hive box (call once during app startup)
  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Future<void> saveStep(String key, dynamic value) async {
    final box = Hive.box(_boxName);
    await box.put(key, value);
  }

  static T? getStep<T>(String key) {
    final box = Hive.box(_boxName);
    final v = box.get(key);
    if (v == null) return null;
    return v as T;
  }

  static Future<void> clear() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }

  /// Return a map of all saved keys (for final payload)
  static Map<String, dynamic> all() {
    final box = Hive.box(_boxName);
    final Map<String, dynamic> ret = {};
    for (final key in box.keys) {
      ret[key.toString()] = box.get(key);
    }
    return ret;
  }
}
