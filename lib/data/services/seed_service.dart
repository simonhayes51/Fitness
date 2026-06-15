import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../models/routine.dart';
import 'local_db_service.dart';

/// Seeds the local database on first launch: exercise catalogue, food database,
/// and a set of starter routine templates.
class SeedService {
  SeedService(this._db);

  final LocalDbService _db;

  static const _seedFlag = 'seeded_v1';

  Future<void> seedIfNeeded() async {
    final alreadySeeded = _db.getSetting<bool>(_seedFlag) ?? false;
    if (alreadySeeded && _db.count(AppConstants.boxExercises) > 0) return;

    await _seedExercises();
    await _seedFoods();
    await _seedRoutines();
    await _db.setSetting(_seedFlag, true);
  }

  Future<void> _seedExercises() async {
    if (_db.count(AppConstants.boxExercises) > 0) return;
    final raw = await rootBundle.loadString(AppConstants.exerciseSeed);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final entries = <String, Map<String, dynamic>>{
      for (final e in list) e['id'] as String: e,
    };
    await _db.putAll(AppConstants.boxExercises, entries);
  }

  Future<void> _seedFoods() async {
    if (_db.count(AppConstants.boxFoods) > 0) return;
    final raw = await rootBundle.loadString(AppConstants.foodSeed);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final entries = <String, Map<String, dynamic>>{
      for (final e in list) e['id'] as String: e,
    };
    await _db.putAll(AppConstants.boxFoods, entries);
  }

  Future<void> _seedRoutines() async {
    if (_db.count(AppConstants.boxRoutines) > 0) return;

    RoutineExercise re(String id, String name, String group,
            {int sets = 3, int low = 8, int high = 12, int? ss}) =>
        RoutineExercise(
          exerciseId: id,
          exerciseName: name,
          muscleGroup: group,
          targetSets: sets,
          targetRepsLow: low,
          targetRepsHigh: high,
          supersetGroup: ss,
        );

    final presets = <Routine>[
      Routine(
        name: 'Push Day',
        description: 'Chest, shoulders & triceps',
        icon: '💪',
        isPreset: true,
        exercises: [
          re('bench-press', 'Bench Press', 'Chest', sets: 4, low: 6, high: 10),
          re('incline-dumbbell-press', 'Incline Dumbbell Press', 'Chest'),
          re('standing-overhead-press', 'Standing Overhead Press', 'Shoulders',
              sets: 4, low: 6, high: 10),
          re('dumbbell-lateral-raise', 'Dumbbell Lateral Raise', 'Shoulders',
              sets: 4, low: 12, high: 20),
          re('triceps-pushdown', 'Triceps Pushdown', 'Arms', low: 10, high: 15),
          re('overhead-cable-extension', 'Overhead Cable Extension', 'Arms',
              low: 10, high: 15),
        ],
      ),
      Routine(
        name: 'Pull Day',
        description: 'Back & biceps',
        icon: '🪝',
        isPreset: true,
        exercises: [
          re('conventional-deadlift', 'Conventional Deadlift', 'Back',
              sets: 3, low: 4, high: 6),
          re('pull-up', 'Pull-Up', 'Back', sets: 4, low: 6, high: 12),
          re('seated-cable-row', 'Seated Cable Row', 'Back'),
          re('face-pull', 'Face Pull', 'Back', low: 15, high: 20),
          re('barbell-curl', 'Barbell Curl', 'Arms', low: 8, high: 12),
          re('hammer-curl', 'Hammer Curl', 'Arms', low: 10, high: 15),
        ],
      ),
      Routine(
        name: 'Leg Day',
        description: 'Quads, hamstrings & glutes',
        icon: '🦵',
        isPreset: true,
        exercises: [
          re('back-squat', 'Back Squat', 'Legs', sets: 4, low: 5, high: 8),
          re('romanian-deadlift', 'Romanian Deadlift', 'Back', low: 8, high: 12),
          re('leg-press', 'Leg Press', 'Legs', low: 10, high: 15),
          re('lying-leg-curl', 'Lying Leg Curl', 'Legs', low: 10, high: 15),
          re('standing-calf-raise', 'Standing Calf Raise', 'Legs',
              sets: 4, low: 12, high: 20),
        ],
      ),
      Routine(
        name: 'Full Body',
        description: 'Balanced total-body session',
        icon: '🏋️',
        isPreset: true,
        exercises: [
          re('back-squat', 'Back Squat', 'Legs', sets: 3, low: 6, high: 10),
          re('bench-press', 'Bench Press', 'Chest', sets: 3, low: 6, high: 10),
          re('bent-over-row', 'Bent-Over Row', 'Back', sets: 3, low: 8, high: 12),
          re('seated-overhead-press', 'Seated Overhead Press', 'Shoulders'),
          re('plank', 'Plank', 'Core', sets: 3, low: 30, high: 60),
        ],
      ),
      Routine(
        name: 'Upper Body',
        description: 'Chest, back, shoulders & arms',
        icon: '🔱',
        isPreset: true,
        exercises: [
          re('incline-barbell-press', 'Incline Barbell Press', 'Chest',
              sets: 4, low: 6, high: 10),
          re('lat-pulldown', 'Lat Pulldown', 'Back'),
          re('seated-dumbbell-press', 'Seated Dumbbell Press', 'Shoulders'),
          re('dumbbell-row', 'Dumbbell Row', 'Back'),
          re('barbell-curl', 'Barbell Curl', 'Arms', ss: 1),
          re('triceps-pushdown', 'Triceps Pushdown', 'Arms', ss: 1),
        ],
      ),
    ];

    await _db.putAll(AppConstants.boxRoutines, {
      for (final r in presets) r.id: r.toMap(),
    });
  }
}
