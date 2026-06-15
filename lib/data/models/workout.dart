import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/calculations.dart';

const _uuid = Uuid();

/// A single logged set within a workout exercise.
class SetEntry {
  SetEntry({
    String? id,
    this.weight = 0,
    this.reps = 0,
    this.rpe,
    this.type = SetType.normal,
    this.completed = false,
    this.notes = '',
  }) : id = id ?? _uuid.v4();

  final String id;
  double weight;
  int reps;
  double? rpe; // 1–10 Rate of Perceived Exertion.
  SetType type;
  bool completed;
  String notes;

  double get volume => weight * reps;
  double get estimated1RM => Calculations.estimated1RM(weight, reps);

  factory SetEntry.fromMap(Map<dynamic, dynamic> m) => SetEntry(
        id: m['id'] as String?,
        weight: (m['weight'] as num?)?.toDouble() ?? 0,
        reps: (m['reps'] as num?)?.toInt() ?? 0,
        rpe: (m['rpe'] as num?)?.toDouble(),
        type: SetType.values[(m['type'] as num?)?.toInt() ?? 1],
        completed: m['completed'] as bool? ?? false,
        notes: m['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'weight': weight,
        'reps': reps,
        'rpe': rpe,
        'type': type.index,
        'completed': completed,
        'notes': notes,
      };

  SetEntry copy() => SetEntry(
        weight: weight,
        reps: reps,
        rpe: rpe,
        type: type,
        completed: false,
        notes: notes,
      );
}

/// An exercise within a workout, carrying its ordered list of sets.
class WorkoutExercise {
  WorkoutExercise({
    String? id,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    List<SetEntry>? sets,
    this.notes = '',
    this.restSeconds = AppConstants.defaultRestSeconds,
    this.supersetGroup,
  })  : id = id ?? _uuid.v4(),
        sets = sets ?? [];

  final String id;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final List<SetEntry> sets;
  String notes;
  int restSeconds;

  /// Exercises sharing a [supersetGroup] value are performed back-to-back.
  int? supersetGroup;

  double get totalVolume =>
      sets.where((s) => s.completed).fold(0.0, (sum, s) => sum + s.volume);

  int get completedSets => sets.where((s) => s.completed).length;

  double get best1RM => sets.fold(0.0, (m, s) {
        final e = s.estimated1RM;
        return e > m ? e : m;
      });

  factory WorkoutExercise.fromMap(Map<dynamic, dynamic> m) => WorkoutExercise(
        id: m['id'] as String?,
        exerciseId: m['exerciseId'] as String,
        exerciseName: m['exerciseName'] as String,
        muscleGroup: m['muscleGroup'] as String? ?? 'Full Body',
        sets: ((m['sets'] as List?) ?? [])
            .map((e) => SetEntry.fromMap(e as Map))
            .toList(),
        notes: m['notes'] as String? ?? '',
        restSeconds: (m['restSeconds'] as num?)?.toInt() ??
            AppConstants.defaultRestSeconds,
        supersetGroup: (m['supersetGroup'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'muscleGroup': muscleGroup,
        'sets': sets.map((s) => s.toMap()).toList(),
        'notes': notes,
        'restSeconds': restSeconds,
        'supersetGroup': supersetGroup,
      };
}

/// A workout session — either in-progress or completed history.
class Workout {
  Workout({
    String? id,
    this.name = 'Workout',
    DateTime? startedAt,
    this.completedAt,
    List<WorkoutExercise>? exercises,
    this.notes = '',
    this.routineId,
    this.synced = false,
  })  : id = id ?? _uuid.v4(),
        startedAt = startedAt ?? DateTime.now(),
        exercises = exercises ?? [];

  final String id;
  String name;
  final DateTime startedAt;
  DateTime? completedAt;
  final List<WorkoutExercise> exercises;
  String notes;
  String? routineId;
  bool synced;

  bool get isCompleted => completedAt != null;

  Duration get duration =>
      (completedAt ?? DateTime.now()).difference(startedAt);

  double get totalVolume =>
      exercises.fold(0.0, (sum, e) => sum + e.totalVolume);

  int get totalSets =>
      exercises.fold(0, (sum, e) => sum + e.completedSets);

  int get totalReps => exercises.fold(
      0,
      (sum, e) =>
          sum + e.sets.where((s) => s.completed).fold(0, (a, s) => a + s.reps));

  Set<String> get muscleGroups =>
      exercises.map((e) => e.muscleGroup).toSet();

  factory Workout.fromMap(Map<dynamic, dynamic> m) => Workout(
        id: m['id'] as String?,
        name: m['name'] as String? ?? 'Workout',
        startedAt: DateTime.parse(m['startedAt'] as String),
        completedAt: m['completedAt'] != null
            ? DateTime.parse(m['completedAt'] as String)
            : null,
        exercises: ((m['exercises'] as List?) ?? [])
            .map((e) => WorkoutExercise.fromMap(e as Map))
            .toList(),
        notes: m['notes'] as String? ?? '',
        routineId: m['routineId'] as String?,
        synced: m['synced'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'notes': notes,
        'routineId': routineId,
        'synced': synced,
      };
}
