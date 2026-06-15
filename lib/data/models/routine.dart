import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A planned exercise inside a routine template (target sets/reps, no logged
/// values yet).
class RoutineExercise {
  RoutineExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.targetSets = 3,
    this.targetRepsLow = 8,
    this.targetRepsHigh = 12,
    this.restSeconds = 120,
    this.supersetGroup,
  });

  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  int targetSets;
  int targetRepsLow;
  int targetRepsHigh;
  int restSeconds;
  int? supersetGroup;

  String get repRange => targetRepsLow == targetRepsHigh
      ? '$targetRepsLow'
      : '$targetRepsLow–$targetRepsHigh';

  factory RoutineExercise.fromMap(Map<dynamic, dynamic> m) => RoutineExercise(
        exerciseId: m['exerciseId'] as String,
        exerciseName: m['exerciseName'] as String,
        muscleGroup: m['muscleGroup'] as String? ?? 'Full Body',
        targetSets: (m['targetSets'] as num?)?.toInt() ?? 3,
        targetRepsLow: (m['targetRepsLow'] as num?)?.toInt() ?? 8,
        targetRepsHigh: (m['targetRepsHigh'] as num?)?.toInt() ?? 12,
        restSeconds: (m['restSeconds'] as num?)?.toInt() ?? 120,
        supersetGroup: (m['supersetGroup'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'muscleGroup': muscleGroup,
        'targetSets': targetSets,
        'targetRepsLow': targetRepsLow,
        'targetRepsHigh': targetRepsHigh,
        'restSeconds': restSeconds,
        'supersetGroup': supersetGroup,
      };
}

/// A reusable workout template (e.g. "Push Day", "Full Body A").
class Routine {
  Routine({
    String? id,
    required this.name,
    this.description = '',
    this.icon = '🏋️',
    List<RoutineExercise>? exercises,
    DateTime? createdAt,
    this.isPreset = false,
  })  : id = id ?? _uuid.v4(),
        exercises = exercises ?? [],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String description;
  String icon;
  final List<RoutineExercise> exercises;
  final DateTime createdAt;
  final bool isPreset;

  int get exerciseCount => exercises.length;
  int get totalSets => exercises.fold(0, (s, e) => s + e.targetSets);
  Set<String> get muscleGroups => exercises.map((e) => e.muscleGroup).toSet();

  factory Routine.fromMap(Map<dynamic, dynamic> m) => Routine(
        id: m['id'] as String?,
        name: m['name'] as String,
        description: m['description'] as String? ?? '',
        icon: m['icon'] as String? ?? '🏋️',
        exercises: ((m['exercises'] as List?) ?? [])
            .map((e) => RoutineExercise.fromMap(e as Map))
            .toList(),
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'] as String)
            : null,
        isPreset: m['isPreset'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isPreset': isPreset,
      };
}
