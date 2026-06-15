import '../../core/constants/app_constants.dart';
import '../models/exercise.dart';
import '../services/local_db_service.dart';

/// CRUD + querying over the exercise catalogue.
class ExerciseRepository {
  ExerciseRepository(this._db);
  final LocalDbService _db;

  List<Exercise> getAll() => _db
      .readAll(AppConstants.boxExercises)
      .map(Exercise.fromMap)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  Exercise? getById(String id) {
    final m = _db.read(AppConstants.boxExercises, id);
    return m == null ? null : Exercise.fromMap(m);
  }

  /// Filter by free-text query, muscle group and equipment (any may be null).
  List<Exercise> query({
    String? search,
    String? muscleGroup,
    String? equipment,
  }) {
    final q = search?.trim().toLowerCase() ?? '';
    return getAll().where((e) {
      if (q.isNotEmpty && !e.searchKey.contains(q)) return false;
      if (muscleGroup != null && e.muscleGroup != muscleGroup) return false;
      if (equipment != null && e.equipment != equipment) return false;
      return true;
    }).toList();
  }

  Map<String, List<Exercise>> groupedByMuscle() {
    final map = <String, List<Exercise>>{};
    for (final e in getAll()) {
      map.putIfAbsent(e.muscleGroup, () => []).add(e);
    }
    return map;
  }

  Future<void> save(Exercise e) =>
      _db.put(AppConstants.boxExercises, e.id, e.toMap());

  Future<void> delete(String id) =>
      _db.delete(AppConstants.boxExercises, id);

  int get count => _db.count(AppConstants.boxExercises);
}
