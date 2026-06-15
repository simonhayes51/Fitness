import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A food item from the database (or a custom/user-scanned item).
class Food {
  Food({
    String? id,
    required this.name,
    this.brand = '',
    this.barcode = '',
    this.servingSize = 100,
    this.servingUnit = 'g',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.isCustom = false,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final String brand;
  final String barcode;

  /// Reference serving size the macros below are stated per.
  final double servingSize;
  final String servingUnit;

  // Macros per [servingSize] [servingUnit].
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium; // mg
  final bool isCustom;

  String get label => brand.isEmpty ? name : '$name · $brand';

  /// Scale all macros to an arbitrary [amount] of [servingUnit].
  MacroSnapshot forAmount(double amount) {
    final factor = servingSize == 0 ? 0 : amount / servingSize;
    return MacroSnapshot(
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
    );
  }

  factory Food.fromMap(Map<dynamic, dynamic> m) => Food(
        id: m['id'] as String?,
        name: m['name'] as String,
        brand: m['brand'] as String? ?? '',
        barcode: m['barcode'] as String? ?? '',
        servingSize: (m['servingSize'] as num?)?.toDouble() ?? 100,
        servingUnit: m['servingUnit'] as String? ?? 'g',
        calories: (m['calories'] as num?)?.toDouble() ?? 0,
        protein: (m['protein'] as num?)?.toDouble() ?? 0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0,
        fiber: (m['fiber'] as num?)?.toDouble() ?? 0,
        sugar: (m['sugar'] as num?)?.toDouble() ?? 0,
        sodium: (m['sodium'] as num?)?.toDouble() ?? 0,
        isCustom: m['isCustom'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'brand': brand,
        'barcode': barcode,
        'servingSize': servingSize,
        'servingUnit': servingUnit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'isCustom': isCustom,
      };

  String get searchKey => '$name $brand $barcode'.toLowerCase();
}

/// Lightweight, scaled macro totals (not persisted directly).
class MacroSnapshot {
  const MacroSnapshot({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  MacroSnapshot operator +(MacroSnapshot o) => MacroSnapshot(
        calories: calories + o.calories,
        protein: protein + o.protein,
        carbs: carbs + o.carbs,
        fat: fat + o.fat,
      );

  static const zero =
      MacroSnapshot(calories: 0, protein: 0, carbs: 0, fat: 0);
}
