import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../data/models/workout.dart';
import 'providers.dart';

/// Drives the live workout-logging experience: the in-progress [Workout], set
/// edits, supersets, and finishing/persisting the session.
class ActiveWorkoutNotifier extends StateNotifier<Workout?> {
  ActiveWorkoutNotifier(this._ref) : super(null);
  final Ref _ref;

  bool get isActive => state != null;

  /// Start an empty session.
  void startEmpty({String name = 'Quick Workout'}) {
    state = Workout(name: name);
  }

  /// Start a session pre-populated from a routine template.
  void startFromRoutine(Routine routine) {
    final exercises = routine.exercises.map((re) {
      return WorkoutExercise(
        exerciseId: re.exerciseId,
        exerciseName: re.exerciseName,
        muscleGroup: re.muscleGroup,
        restSeconds: re.restSeconds,
        supersetGroup: re.supersetGroup,
        sets: List.generate(
          re.targetSets,
          (_) => SetEntry(reps: re.targetRepsHigh),
        ),
      );
    }).toList();
    state = Workout(name: routine.name, routineId: routine.id, exercises: exercises);
  }

  /// Re-run a past workout with the same exercises and previous weights pre-filled.
  void startFromWorkoutHistory(Workout past) {
    final exercises = past.exercises.map((ex) => WorkoutExercise(
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          muscleGroup: ex.muscleGroup,
          restSeconds: ex.restSeconds,
          supersetGroup: ex.supersetGroup,
          sets: ex.sets
              .where((s) => s.completed)
              .map((s) => SetEntry(
                    weight: s.weight,
                    reps: s.reps,
                    type: s.type,
                  ))
              .toList(),
        )).toList();
    // Remove exercises with no completed sets.
    exercises.removeWhere((e) => e.sets.isEmpty);
    state = Workout(name: past.name, exercises: exercises);
  }

  void addExercise(Exercise exercise) {
    final w = state;
    if (w == null) return;
    final lastSets =
        _ref.read(workoutRepositoryProvider).lastSessionSets(exercise.id);
    final warmupWeight = lastSets.isNotEmpty ? lastSets.first.weight * 0.6 : 0.0;
    final workingWeight = lastSets.isNotEmpty ? lastSets.first.weight : 0.0;

    final sets = <SetEntry>[
      // Auto-add a warm-up set when there's history.
      if (warmupWeight > 0)
        SetEntry(
          weight: (warmupWeight / 2.5).round() * 2.5, // round to nearest 2.5
          reps: 10,
          type: SetType.warmup,
        ),
      SetEntry(weight: workingWeight),
    ];
    w.exercises.add(WorkoutExercise(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      muscleGroup: exercise.muscleGroup,
      sets: sets,
    ));
    _emit();
  }

  void removeExercise(String exerciseInstanceId) {
    state?.exercises.removeWhere((e) => e.id == exerciseInstanceId);
    _emit();
  }

  void addSet(String exerciseInstanceId) {
    final ex = _find(exerciseInstanceId);
    if (ex == null) return;
    // Pre-fill from the previous set for fast logging.
    final last = ex.sets.isNotEmpty ? ex.sets.last : null;
    ex.sets.add(last != null ? last.copy() : SetEntry());
    _emit();
  }

  void removeSet(String exerciseInstanceId, String setId) {
    _find(exerciseInstanceId)?.sets.removeWhere((s) => s.id == setId);
    _emit();
  }

  void updateSet(
    String exerciseInstanceId,
    String setId, {
    double? weight,
    int? reps,
    double? rpe,
    bool? completed,
  }) {
    final ex = _find(exerciseInstanceId);
    final set = ex?.sets.firstWhere((s) => s.id == setId);
    if (set == null) return;
    if (weight != null) set.weight = weight;
    if (reps != null) set.reps = reps;
    if (rpe != null) set.rpe = rpe;
    if (completed != null) set.completed = completed;
    _emit();
  }

  void cycleSetType(String exerciseInstanceId, String setId) {
    final ex = _find(exerciseInstanceId);
    final set = ex?.sets.firstWhere((s) => s.id == setId);
    if (set == null) return;
    final next = (set.type.index + 1) % SetType.values.length;
    set.type = SetType.values[next];
    _emit();
  }

  void updateNotes(String notes) {
    if (state == null) return;
    state!.notes = notes;
    _emit();
  }

  /// Group two adjacent exercises into a superset.
  void toggleSuperset(String exerciseInstanceId) {
    final w = state;
    if (w == null) return;
    final idx = w.exercises.indexWhere((e) => e.id == exerciseInstanceId);
    if (idx < 0 || idx >= w.exercises.length - 1) return;
    final group = w.exercises[idx].supersetGroup;
    if (group == null) {
      final newGroup = (w.exercises
                  .map((e) => e.supersetGroup ?? 0)
                  .fold(0, (a, b) => a > b ? a : b)) +
          1;
      w.exercises[idx].supersetGroup = newGroup;
      w.exercises[idx + 1].supersetGroup = newGroup;
    } else {
      w.exercises[idx].supersetGroup = null;
    }
    _emit();
  }

  void rename(String name) {
    if (state == null) return;
    state!.name = name;
    _emit();
  }

  /// Persist the session as completed and clear the active state.
  Future<Workout?> finish() async {
    final w = state;
    if (w == null) return null;
    w.completedAt = DateTime.now();
    // Drop exercises where no sets were completed.
    w.exercises.removeWhere((e) => e.sets.every((s) => !s.completed));
    await _ref.read(workoutRepositoryProvider).save(w);
    _ref.read(dataRevisionProvider.notifier).state++;
    state = null;
    return w;
  }

  void discard() {
    state = null;
  }

  WorkoutExercise? _find(String id) {
    try {
      return state?.exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void _emit() {
    // StateNotifier only notifies when the state identity changes. Our model is
    // mutable, so re-emit a fresh clone to trigger a rebuild after each edit.
    final w = state;
    if (w == null) return;
    state = Workout.fromMap(w.toMap());
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, Workout?>(
        ActiveWorkoutNotifier.new);
