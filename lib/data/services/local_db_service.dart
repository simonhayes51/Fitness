import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Thin wrapper around Hive providing the app's offline-first store.
///
/// Every domain object is persisted as a JSON-style `Map` keyed by its id,
/// which keeps the schema flexible and avoids generated TypeAdapters. The
/// repositories layer on top of this with typed (de)serialisation.
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  bool _initialised = false;

  static const _boxes = [
    AppConstants.boxExercises,
    AppConstants.boxWorkouts,
    AppConstants.boxRoutines,
    AppConstants.boxFoods,
    AppConstants.boxFoodLogs,
    AppConstants.boxBodyMetrics,
    AppConstants.boxGoals,
    AppConstants.boxProfile,
    AppConstants.boxSettings,
    AppConstants.boxWaterLogs,
  ];

  Future<void> init() async {
    if (_initialised) return;
    await Hive.initFlutter();
    for (final name in _boxes) {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox(name);
      }
    }
    _initialised = true;
  }

  Box box(String name) => Hive.box(name);

  /// Read all map records from a box.
  List<Map<dynamic, dynamic>> readAll(String boxName) {
    final b = box(boxName);
    return b.values.whereType<Map>().toList();
  }

  Map<dynamic, dynamic>? read(String boxName, String key) {
    final v = box(boxName).get(key);
    return v is Map ? v : null;
  }

  Future<void> put(String boxName, String key, Map<String, dynamic> value) =>
      box(boxName).put(key, value);

  Future<void> putAll(String boxName, Map<String, Map<String, dynamic>> values) =>
      box(boxName).putAll(values);

  Future<void> delete(String boxName, String key) => box(boxName).delete(key);

  Future<void> clear(String boxName) => box(boxName).clear();

  int count(String boxName) => box(boxName).length;

  // Generic settings helpers (primitive values).
  T? getSetting<T>(String key, {T? defaultValue}) {
    final v = box(AppConstants.boxSettings).get(key, defaultValue: defaultValue);
    return v as T?;
  }

  Future<void> setSetting(String key, dynamic value) =>
      box(AppConstants.boxSettings).put(key, value);

  /// Wipe every box (used by "Erase all data" in settings).
  Future<void> wipeAll() async {
    for (final name in _boxes) {
      await box(name).clear();
    }
  }
}
