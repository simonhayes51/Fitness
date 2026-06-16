import '../../core/constants/app_constants.dart';
import '../models/workout.dart';
import '../services/local_db_service.dart';

class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({required this.date, required this.set});
  final DateTime date;
  final SetEntry set;
}

class OneRepMaxPoint {
  const OneRepMaxPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

class WeeklySetCount {
  const WeeklySetCount({required this.thisWeek, required this.lastWeek});
  final int thisWeek;
  final int lastWeek;
}

class WeeklyVolume {
  const WeeklyVolume({required this.thisWeek, required this.lastWeek});
  final double thisWeek;
  final double lastWeek;
}

class RecentPR {
  const RecentPR({required this.exerciseName, required this.estimated1RM});
  final String exerciseName;
  final double estimated1RM;
}

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
  List<WorkoutHistoryEntry> historyForExercise(String exerciseId) {
    final out = <WorkoutHistoryEntry>[];
    for (final w in getCompleted()) {
      for (final ex in w.exercises.where((e) => e.exerciseId == exerciseId)) {
        for (final s in ex.sets.where((s) => s.completed)) {
          out.add(WorkoutHistoryEntry(date: w.completedAt ?? w.startedAt, set: s));
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
  List<OneRepMaxPoint> oneRepMaxSeries(String exerciseId) {
    final byDay = <String, OneRepMaxPoint>{};
    for (final h in historyForExercise(exerciseId)) {
      final key = '${h.date.year}-${h.date.month}-${h.date.day}';
      final e1rm = h.set.estimated1RM;
      final existing = byDay[key];
      if (existing == null || e1rm > existing.value) {
        byDay[key] = OneRepMaxPoint(date: h.date, value: e1rm);
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

  /// Sets logged in the most recent session for [exerciseId], in order.
  List<SetEntry> lastSessionSets(String exerciseId) {
    final history = historyForExercise(exerciseId);
    if (history.isEmpty) return [];
    final lastDate = history.first.date;
    return history
        .where((h) =>
            h.date.year == lastDate.year &&
            h.date.month == lastDate.month &&
            h.date.day == lastDate.day)
        .map((h) => h.set)
        .toList();
  }

  /// Completed workouts that finished on [day].
  List<Workout> workoutsForDay(DateTime day) {
    return getCompleted().where((w) {
      final d = w.completedAt ?? w.startedAt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  /// Volume logged this week vs the previous week, per muscle group.
  Map<String, WeeklySetCount> weeklySetComparison() {
    final thisWeek = weeklySetsByMuscle(weeks: 1);
    final lastWeek = <String, int>{};
    final cutoffStart = DateTime.now().subtract(const Duration(days: 14));
    final cutoffEnd = DateTime.now().subtract(const Duration(days: 7));
    for (final w in getCompleted()) {
      final d = w.completedAt ?? w.startedAt;
      if (d.isBefore(cutoffStart) || d.isAfter(cutoffEnd)) continue;
      for (final ex in w.exercises) {
        lastWeek[ex.muscleGroup] =
            (lastWeek[ex.muscleGroup] ?? 0) + ex.completedSets;
      }
    }
    final keys = <String>{...thisWeek.keys, ...lastWeek.keys};
    return {
      for (final k in keys)
        k: WeeklySetCount(
          thisWeek: thisWeek[k] ?? 0,
          lastWeek: lastWeek[k] ?? 0,
        ),
    };
  }

  /// Total volume this week vs last week.
  WeeklyVolume weeklyVolumeComparison() {
    double tw = 0, lw = 0;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMidnight =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final lastWeekStart = weekStartMidnight.subtract(const Duration(days: 7));
    for (final w in getCompleted()) {
      final d = w.completedAt ?? w.startedAt;
      if (!d.isBefore(weekStartMidnight)) {
        tw += w.totalVolume;
      } else if (!d.isBefore(lastWeekStart)) {
        lw += w.totalVolume;
      }
    }
    return WeeklyVolume(thisWeek: tw, lastWeek: lw);
  }

  int get totalWorkouts => getCompleted().length;

  /// Returns exercises where a new estimated-1RM PR was set in the last 7 days.
  List<RecentPR> recentPRs() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    // All-time best e1RM per exercise from workouts BEFORE the cutoff.
    final allTimeBest = <String, double>{};
    final recentBest = <String, double>{};
    final exerciseNames = <String, String>{};

    for (final w in getCompleted()) {
      final d = w.completedAt ?? w.startedAt;
      final isRecent = d.isAfter(cutoff);
      for (final ex in w.exercises) {
        exerciseNames[ex.exerciseId] = ex.exerciseName;
        for (final s in ex.sets.where((s) => s.completed)) {
          final e1rm = s.estimated1RM;
          if (!isRecent) {
            final prev = allTimeBest[ex.exerciseId] ?? 0;
            if (e1rm > prev) allTimeBest[ex.exerciseId] = e1rm;
          } else {
            final prev = recentBest[ex.exerciseId] ?? 0;
            if (e1rm > prev) recentBest[ex.exerciseId] = e1rm;
          }
        }
      }
    }

    // A PR is a recent best that exceeds the all-time best before that period.
    final prs = <RecentPR>[];
    for (final entry in recentBest.entries) {
      final prev = allTimeBest[entry.key] ?? 0;
      if (entry.value > prev && entry.value > 0) {
        prs.add(RecentPR(
          exerciseName: exerciseNames[entry.key] ?? entry.key,
          estimated1RM: entry.value,
        ));
      }
    }
    prs.sort((a, b) => b.estimated1RM.compareTo(a.estimated1RM));
    return prs.take(3).toList();
  }

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
