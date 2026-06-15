import 'package:uuid/uuid.dart';

import 'food.dart';

const _uuid = Uuid();

/// A named collection of food+amount pairs the user can re-log as a batch.
class SavedMeal {
  SavedMeal({
    String? id,
    required this.name,
    required this.items,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  final List<SavedMealItem> items;
  final DateTime createdAt;

  double get totalCalories =>
      items.fold(0.0, (s, i) => s + i.food.forAmount(i.amount).calories);

  double get totalProtein =>
      items.fold(0.0, (s, i) => s + i.food.forAmount(i.amount).protein);

  factory SavedMeal.fromMap(Map<dynamic, dynamic> m) => SavedMeal(
        id: m['id'] as String?,
        name: m['name'] as String,
        items: ((m['items'] as List?) ?? [])
            .map((e) => SavedMealItem.fromMap(e as Map))
            .toList(),
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class SavedMealItem {
  const SavedMealItem({
    required this.food,
    required this.amount,
    this.mealType = 'Snacks',
  });

  final Food food;
  final double amount;
  final String mealType;

  factory SavedMealItem.fromMap(Map<dynamic, dynamic> m) => SavedMealItem(
        food: Food.fromMap(m['food'] as Map),
        amount: (m['amount'] as num).toDouble(),
        mealType: m['mealType'] as String? ?? 'Snacks',
      );

  Map<String, dynamic> toMap() => {
        'food': food.toMap(),
        'amount': amount,
        'mealType': mealType,
      };
}
