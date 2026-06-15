import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/user_profile.dart';
import 'providers.dart';

/// Holds and persists the user profile. The single source of truth for goals,
/// units and nutrition targets across the app.
class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier(this._ref) : super(_ref.read(profileRepositoryProvider).getProfile());

  final Ref _ref;

  Future<void> update(UserProfile profile) async {
    await _ref.read(profileRepositoryProvider).saveProfile(profile);
    state = profile;
  }

  Future<void> patch({
    String? name,
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    FitnessGoal? goal,
    UnitSystem? unitSystem,
    bool? onboarded,
    double? customCalorieTarget,
    bool clearCustomCalorieTarget = false,
  }) async {
    await update(state.copyWith(
      name: name,
      sex: sex,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goal: goal,
      unitSystem: unitSystem,
      onboarded: onboarded,
      customCalorieTarget: customCalorieTarget,
      clearCustomCalorieTarget: clearCustomCalorieTarget,
    ));
  }

  Future<void> completeOnboarding() => patch(onboarded: true);
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

/// Convenience selector for the active unit system.
final unitSystemProvider = Provider<UnitSystem>(
  (ref) => ref.watch(profileProvider).unitSystem,
);
