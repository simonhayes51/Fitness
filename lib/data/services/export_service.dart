import 'dart:convert';

import 'package:csv/csv.dart';

import '../models/workout.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/workout_repository.dart';

/// Produces CSV / JSON exports of the user's data for backup or analysis.
class ExportService {
  ExportService(this._workouts, this._nutrition, this._profile);

  final WorkoutRepository _workouts;
  final NutritionRepository _nutrition;
  final ProfileRepository _profile;

  /// Full account backup as a single JSON document.
  String exportJson() {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'profile': _profile.getProfile().toMap(),
      'workouts': _workouts.getAll().map((w) => w.toMap()).toList(),
      'foodLog': _nutrition.allEntries().map((e) => e.toMap()).toList(),
      'bodyMetrics': _profile.bodyMetrics().map((m) => m.toMap()).toList(),
      'goals': _profile.goals().map((g) => g.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Flatten workout history to one row per set — ideal for spreadsheets.
  String exportWorkoutsCsv() {
    final rows = <List<dynamic>>[
      ['Date', 'Workout', 'Exercise', 'Muscle Group', 'Set', 'Type', 'Weight',
       'Reps', 'RPE', 'Volume', 'Est 1RM'],
    ];
    for (final Workout w in _workouts.getCompleted()) {
      final date = (w.completedAt ?? w.startedAt).toIso8601String();
      for (final ex in w.exercises) {
        var setNo = 0;
        for (final s in ex.sets) {
          setNo++;
          rows.add([
            date,
            w.name,
            ex.exerciseName,
            ex.muscleGroup,
            setNo,
            s.type.name,
            s.weight,
            s.reps,
            s.rpe ?? '',
            s.volume,
            s.estimated1RM.toStringAsFixed(1),
          ]);
        }
      }
    }
    return const ListToCsvConverter().convert(rows);
  }

  /// Nutrition diary as CSV.
  String exportNutritionCsv() {
    final rows = <List<dynamic>>[
      ['Date', 'Meal', 'Food', 'Amount', 'Unit', 'Calories', 'Protein',
       'Carbs', 'Fat'],
    ];
    for (final e in _nutrition.allEntries()) {
      final macros = e.macros;
      rows.add([
        e.loggedAt.toIso8601String(),
        e.mealType,
        e.food.label,
        e.amount,
        e.food.servingUnit,
        macros.calories.toStringAsFixed(0),
        macros.protein.toStringAsFixed(1),
        macros.carbs.toStringAsFixed(1),
        macros.fat.toStringAsFixed(1),
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }
}
