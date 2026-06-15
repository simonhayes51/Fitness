import '../../core/constants/app_constants.dart';
import '../models/food.dart';
import '../models/food_log.dart';
import '../services/local_db_service.dart';

/// Food database + daily diary + water logging.
class NutritionRepository {
  NutritionRepository(this._db);
  final LocalDbService _db;

  // --- Food database -------------------------------------------------------
  List<Food> allFoods() =>
      _db.readAll(AppConstants.boxFoods).map(Food.fromMap).toList();

  List<Food> searchFoods(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allFoods().take(50).toList();
    return allFoods().where((f) => f.searchKey.contains(q)).toList();
  }

  Food? foodByBarcode(String barcode) {
    for (final f in allFoods()) {
      if (f.barcode == barcode && barcode.isNotEmpty) return f;
    }
    return null;
  }

  Future<void> saveFood(Food f) =>
      _db.put(AppConstants.boxFoods, f.id, f.toMap());

  // --- Diary ---------------------------------------------------------------
  List<FoodLogEntry> allEntries() => _db
      .readAll(AppConstants.boxFoodLogs)
      .map(FoodLogEntry.fromMap)
      .toList();

  List<FoodLogEntry> entriesForDay(DateTime day) {
    final key = WaterLog.keyFor(day);
    return allEntries().where((e) => e.dayKey == key).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  MacroSnapshot totalsForDay(DateTime day) => entriesForDay(day)
      .fold(MacroSnapshot.zero, (sum, e) => sum + e.macros);

  Future<void> saveEntry(FoodLogEntry e) =>
      _db.put(AppConstants.boxFoodLogs, e.id, e.toMap());

  Future<void> deleteEntry(String id) =>
      _db.delete(AppConstants.boxFoodLogs, id);

  // --- Water ---------------------------------------------------------------
  WaterLog waterForDay(DateTime day) {
    final key = WaterLog.keyFor(day);
    final m = _db.read(AppConstants.boxWaterLogs, key);
    return m != null ? WaterLog.fromMap(m) : WaterLog(dayKey: key);
  }

  Future<void> addWater(DateTime day, double ml) async {
    final log = waterForDay(day);
    log.milliliters = (log.milliliters + ml).clamp(0, 100000);
    await _db.put(AppConstants.boxWaterLogs, log.dayKey, log.toMap());
  }

  Future<void> setWater(DateTime day, double ml) async {
    final log = waterForDay(day);
    log.milliliters = ml.clamp(0, 100000);
    await _db.put(AppConstants.boxWaterLogs, log.dayKey, log.toMap());
  }
}
