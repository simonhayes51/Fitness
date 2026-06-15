import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/routine_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/ai_coach_service.dart';
import '../../data/services/export_service.dart';
import '../../data/services/food_api_service.dart';
import '../../data/services/local_db_service.dart';
import '../../data/services/notification_service.dart';

/// ---------------------------------------------------------------------------
/// Infrastructure providers
/// ---------------------------------------------------------------------------

final localDbProvider = Provider<LocalDbService>(
  (ref) => LocalDbService.instance,
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final foodApiProvider = Provider<FoodApiService>((ref) {
  final service = FoodApiService();
  ref.onDispose(service.dispose);
  return service;
});

/// ---------------------------------------------------------------------------
/// Repository providers
/// ---------------------------------------------------------------------------

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(ref.watch(localDbProvider)),
);

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(localDbProvider)),
);

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepository(ref.watch(localDbProvider)),
);

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => NutritionRepository(ref.watch(localDbProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(localDbProvider)),
);

/// ---------------------------------------------------------------------------
/// Service providers
/// ---------------------------------------------------------------------------

final aiCoachProvider = Provider<AiCoachService>(
  (ref) => AiCoachService(ref.watch(workoutRepositoryProvider)),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(
    ref.watch(workoutRepositoryProvider),
    ref.watch(nutritionRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  ),
);

/// Bumped whenever underlying data changes so dependent providers recompute.
/// Simple and predictable for an offline-first app backed by Hive.
final dataRevisionProvider = StateProvider<int>((ref) => 0);

/// Call after any mutation to refresh derived providers.
void bumpData(WidgetRef ref) =>
    ref.read(dataRevisionProvider.notifier).state++;
