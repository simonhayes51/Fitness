import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum GoalType { bodyweight, strength, nutrition, habit }

extension GoalTypeX on GoalType {
  String get label => switch (this) {
        GoalType.bodyweight => 'Body Weight',
        GoalType.strength => 'Strength',
        GoalType.nutrition => 'Nutrition',
        GoalType.habit => 'Habit',
      };
}

/// A measurable user goal with progress derived from current vs target value.
class Goal {
  Goal({
    String? id,
    required this.title,
    required this.type,
    required this.startValue,
    required this.targetValue,
    required this.currentValue,
    this.unit = '',
    DateTime? createdAt,
    this.targetDate,
    this.achieved = false,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  GoalType type;
  double startValue;
  double targetValue;
  double currentValue;
  String unit;
  final DateTime createdAt;
  DateTime? targetDate;
  bool achieved;

  /// 0–1 progress, handling both increasing and decreasing goals.
  double get progress {
    final total = targetValue - startValue;
    if (total == 0) return currentValue == targetValue ? 1 : 0;
    final done = currentValue - startValue;
    return (done / total).clamp(0.0, 1.0);
  }

  bool get isComplete => progress >= 1.0 || achieved;

  factory Goal.fromMap(Map<dynamic, dynamic> m) => Goal(
        id: m['id'] as String?,
        title: m['title'] as String,
        type: GoalType.values[(m['type'] as num?)?.toInt() ?? 0],
        startValue: (m['startValue'] as num?)?.toDouble() ?? 0,
        targetValue: (m['targetValue'] as num?)?.toDouble() ?? 0,
        currentValue: (m['currentValue'] as num?)?.toDouble() ?? 0,
        unit: m['unit'] as String? ?? '',
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'] as String)
            : null,
        targetDate: m['targetDate'] != null
            ? DateTime.parse(m['targetDate'] as String)
            : null,
        achieved: m['achieved'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type.index,
        'startValue': startValue,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'unit': unit,
        'createdAt': createdAt.toIso8601String(),
        'targetDate': targetDate?.toIso8601String(),
        'achieved': achieved,
      };
}
