import '../../core/constants/app_constants.dart';
import '../models/body_metric.dart';
import '../models/goal.dart';
import '../models/user_profile.dart';
import '../services/local_db_service.dart';

class ProfileRepository {
  ProfileRepository(this._db);
  final LocalDbService _db;

  static const _profileKey = 'me';

  UserProfile getProfile() {
    final m = _db.read(AppConstants.boxProfile, _profileKey);
    return m != null ? UserProfile.fromMap(m) : UserProfile();
  }

  Future<void> saveProfile(UserProfile p) =>
      _db.put(AppConstants.boxProfile, _profileKey, p.toMap());

  // --- Body metrics --------------------------------------------------------
  List<BodyMetric> bodyMetrics() => _db
      .readAll(AppConstants.boxBodyMetrics)
      .map(BodyMetric.fromMap)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  Future<void> saveBodyMetric(BodyMetric m) =>
      _db.put(AppConstants.boxBodyMetrics, m.id, m.toMap());

  Future<void> deleteBodyMetric(String id) =>
      _db.delete(AppConstants.boxBodyMetrics, id);

  BodyMetric? latestBodyMetric() {
    final list = bodyMetrics();
    return list.isEmpty ? null : list.last;
  }

  /// Only body metrics where an actual weight was recorded (weightKg > 0).
  List<BodyMetric> weightMetrics() =>
      bodyMetrics().where((m) => m.weightKg > 0).toList();

  /// Latest value per measurement site across all body metrics, most-recent wins.
  Map<String, double> latestMeasurements() {
    final result = <String, double>{};
    for (final m in bodyMetrics()) {
      result.addAll(m.measurements);
    }
    return result;
  }

  /// Second-to-last value per measurement site, for trend arrows.
  Map<String, double> previousMeasurements() {
    final all = bodyMetrics();
    final result = <String, double>{};
    for (int i = all.length - 2; i >= 0; i--) {
      for (final e in all[i].measurements.entries) {
        if (!result.containsKey(e.key)) result[e.key] = e.value;
      }
    }
    return result;
  }

  // --- Goals ---------------------------------------------------------------
  List<Goal> goals() =>
      _db.readAll(AppConstants.boxGoals).map(Goal.fromMap).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> saveGoal(Goal g) =>
      _db.put(AppConstants.boxGoals, g.id, g.toMap());

  Future<void> deleteGoal(String id) =>
      _db.delete(AppConstants.boxGoals, id);
}
