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

  // --- Goals ---------------------------------------------------------------
  List<Goal> goals() =>
      _db.readAll(AppConstants.boxGoals).map(Goal.fromMap).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> saveGoal(Goal g) =>
      _db.put(AppConstants.boxGoals, g.id, g.toMap());

  Future<void> deleteGoal(String id) =>
      _db.delete(AppConstants.boxGoals, id);
}
