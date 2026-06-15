import '../../core/constants/app_constants.dart';
import '../models/workout.dart';
import '../services/local_db_service.dart';

/// Persists workout sessions and derives history/analytics aggregates.
class WorkoutRepository {
  WorkoutRepository(this._db);
  final LocalDbService _db;

  List<Workout> getAll() => _db
      .readAll(AppConstants.boxWorkouts)
      .map(Workout.fromMap)
      .toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  List<Workout> getCompleted() =>
      getAll().where((w) => w.isCompleted).toList();

  Workout? getById(String id) {
    final m = _db.read(AppConstants.boxWorkouts, id);
    return m == null ? null : Workout.fromMap(m);
  }

  Future<void> save(Workout w) =>
      _db.put(AppConstants.boxWorkouts, w.id, w.toMap());

  Future<void> delete(String id) =>
      _db.delete(AppConstants.boxWorkouts, id);

  // ---------------------------------------------------------------------------
  // Analytics helpers.
  // ---------------------------------------------------------------------------

  /// All completed sets for a given exercise across history, newest first.
  List<({DateTime date, SetEntry set})> historyForExercise(String exerciseId) {
    final out = <({DateTime date, SetEntry set})>[];
    for (final w in getCompleted()) {
      for (final ex in w.exercises.where((e) => e.exerciseId == exerciseId)) {
        for (final s in ex.sets.where((s) => s.completed)) {
          out.add((date: w.completedAt ?? w.startedAt, set: s));
        }
      }
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  /// Estimated 1RM personal record for an exercise.
  double prFor(String exerciseId) {
    return historyForExercise(exerciseId)
        .fold(0.0, (m, e) => e.set.estimated1RM > m ? e.set.estimated1RM : m);
  }

  /// Heaviest weight lifted for an exercise.
  double heaviestFor(String exerciseId) {
    return historyForExercise(exerciseId)
        .fold(0.0, (m, e) => e.set.weight > m ? e.set.weight : m);
  }

  /// Best estimated-1RM data points over time for charting.
  List<({DateTime date, double value})> oneRepMaxSeries(String exerciseId) {
    final byDay = <String, ({DateTime date, double value})>{};
    for (final h in historyForExercise(exerciseId)) {
      final key =
          '${h.date.year}-${h.date.month}-${h.date.day}';
      final e1rm = h.set.estimated1RM;
      final existing = byDay[key];
      if (existing == null || e1rm > existing.value) {
        byDay[key] = (date: h.date, value: e1rm);
      }
    }
    final list = byDay.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Total volume per day across all exercises (for the volume chart).
  Map<DateTime, double> volumeByDay() {
    final map = <DateTime, double>{};
    for (final w in getCompleted()) {
      final d = w.completedAt ?? w.startedAt;
      final day = DateTime(d.year, d.month, d.day);
      map[day] = (map[day] ?? 0) + w.totalVolume;
    }
    return map;
  }

  /// Weekly set count per muscle group over the last [weeks] weeks.
  Map<String, int> weeklySetsByMuscle({int weeks = 1}) {
    final cutoff = DateTime.now().subtract(Duration(days: 7 * weeks));
    final map = <String, int>{};
    for (final w in getCompleted()) {
      if ((w.completedAt ?? w.startedAt).isBefore(cutoff)) continue;
      for (final ex in w.exercises) {
        map[ex.muscleGroup] =
            (map[ex.muscleGroup] ?? 0) + ex.completedSets;
      }
    }
    return map;
  }

  /// Progressive-overload suggestion: if the user hit the top of their rep
  /// range on every working set last session, suggest a small load increase.
  String? overloadSuggestion(String exerciseId, {int topReps = 12}) {
    final history = historyForExercise(exerciseId);
    if (history.isEmpty) return null;
    final lastDate = history.first.date;
    final lastSession = history
        .where((h) =>
            h.date.year == lastDate.year &&
            h.date.month == lastDate.month &&
            h.date.day == lastDate.day)
        .toList();
    if (lastSession.isEmpty) return null;
    final allHitTop = lastSession.every((h) => h.set.reps >= topReps);
    if (allHitTop) {
      final next = lastSession.first.set.weight + 2.5;
      final label =
          next == next.roundToDouble() ? next.toInt().toString() : next.toStringAsFixed(1);
      return 'You hit $topReps+ reps on every set. Try $label next time.';
    }
    return null;
  }

  int get totalWorkouts => getCompleted().length;

  /// Current consecutive-day logging streak.
  int currentStreak() {
    final days = getCompleted()
        .map((w) {
          final d = w.completedAt ?? w.startedAt;
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) return 0;

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    // Allow the streak to count if the most recent workout was today or
    // yesterday.
    var cursor = todayMidnight;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
