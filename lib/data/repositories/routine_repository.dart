import '../../core/constants/app_constants.dart';
import '../models/routine.dart';
import '../services/local_db_service.dart';

class RoutineRepository {
  RoutineRepository(this._db);
  final LocalDbService _db;

  List<Routine> getAll() => _db
      .readAll(AppConstants.boxRoutines)
      .map(Routine.fromMap)
      .toList()
    ..sort((a, b) {
      // Presets first, then by creation date.
      if (a.isPreset != b.isPreset) return a.isPreset ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

  Routine? getById(String id) {
    final m = _db.read(AppConstants.boxRoutines, id);
    return m == null ? null : Routine.fromMap(m);
  }

  Future<void> save(Routine r) =>
      _db.put(AppConstants.boxRoutines, r.id, r.toMap());

  Future<void> delete(String id) =>
      _db.delete(AppConstants.boxRoutines, id);
}
