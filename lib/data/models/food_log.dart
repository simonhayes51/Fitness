import 'package:uuid/uuid.dart';

import 'food.dart';

const _uuid = Uuid();

/// One logged food entry on a given day & meal.
class FoodLogEntry {
  FoodLogEntry({
    String? id,
    required this.food,
    required this.amount,
    required this.mealType,
    DateTime? loggedAt,
    this.photoPath,
  })  : id = id ?? _uuid.v4(),
        loggedAt = loggedAt ?? DateTime.now();

  final String id;
  final Food food;
  double amount; // in food.servingUnit
  String mealType; // Breakfast | Lunch | Dinner | Snacks
  final DateTime loggedAt;
  String? photoPath;

  MacroSnapshot get macros => food.forAmount(amount);

  /// yyyy-MM-dd key for grouping a day's diary.
  String get dayKey =>
      '${loggedAt.year}-${loggedAt.month.toString().padLeft(2, '0')}-${loggedAt.day.toString().padLeft(2, '0')}';

  factory FoodLogEntry.fromMap(Map<dynamic, dynamic> m) => FoodLogEntry(
        id: m['id'] as String?,
        food: Food.fromMap(m['food'] as Map),
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        mealType: m['mealType'] as String? ?? 'Snacks',
        loggedAt: DateTime.parse(m['loggedAt'] as String),
        photoPath: m['photoPath'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'food': food.toMap(),
        'amount': amount,
        'mealType': mealType,
        'loggedAt': loggedAt.toIso8601String(),
        'photoPath': photoPath,
      };
}

/// A daily water intake entry (ml).
class WaterLog {
  WaterLog({required this.dayKey, this.milliliters = 0});

  final String dayKey;
  double milliliters;

  factory WaterLog.fromMap(Map<dynamic, dynamic> m) => WaterLog(
        dayKey: m['dayKey'] as String,
        milliliters: (m['milliliters'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'dayKey': dayKey,
        'milliliters': milliliters,
      };

  static String keyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
