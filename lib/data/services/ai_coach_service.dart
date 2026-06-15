import '../models/food.dart';
import '../models/user_profile.dart';
import '../repositories/workout_repository.dart';

/// Lightweight, rule-based "AI" coach.
///
/// Generates workout, nutrition and recovery tips from local data with zero
/// network dependency. The [llmIntegrationPoint] method documents exactly where
/// to plug in Gemini / OpenAI for genuinely generative coaching in v2 — the UI
/// consumes [CoachTip]s and doesn't care how they were produced.
class AiCoachService {
  AiCoachService(this._workouts);
  final WorkoutRepository _workouts;

  List<CoachTip> dailyTips(UserProfile profile) {
    final tips = <CoachTip>[];

    // Training frequency / recovery.
    final streak = _workouts.currentStreak();
    final weeklySets = _workouts.weeklySetsByMuscle(weeks: 1);
    final totalWeeklySets =
        weeklySets.values.fold(0, (a, b) => a + b);

    if (_workouts.totalWorkouts == 0) {
      tips.add(const CoachTip(
        icon: '🔥',
        title: 'Log your first session',
        body: 'Start a workout from a preset routine to begin tracking your '
            'progress and unlock strength analytics.',
        category: TipCategory.workout,
      ));
    } else if (streak >= 3) {
      tips.add(CoachTip(
        icon: '⚡',
        title: '$streak-day streak!',
        body: 'Great consistency. Make sure you\'re sleeping 7–9h and eating '
            'enough protein to recover between sessions.',
        category: TipCategory.recovery,
      ));
    }

    // Volume balance — flag undertrained groups.
    final tracked = ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms'];
    if (totalWeeklySets > 0) {
      final laggard = tracked
          .where((g) => (weeklySets[g] ?? 0) < 6)
          .toList();
      if (laggard.isNotEmpty) {
        tips.add(CoachTip(
          icon: '🎯',
          title: 'Balance your volume',
          body: '${laggard.join(', ')} ${laggard.length == 1 ? 'has' : 'have'} '
              'had under 6 sets this week. Aim for 10–20 weekly sets per muscle '
              'group for hypertrophy.',
          category: TipCategory.workout,
        ));
      }
    }

    // Nutrition guidance from goal.
    final macros = profile.macroTargets;
    tips.add(CoachTip(
      icon: '🥗',
      title: 'Today\'s fuel target',
      body: 'For your "${profile.goal.label}" goal, aim for '
          '${macros.calories.toStringAsFixed(0)} kcal and '
          '${macros.protein.toStringAsFixed(0)}g protein. Protein keeps you '
          'full and protects muscle.',
      category: TipCategory.nutrition,
    ));

    // Hydration nudge.
    tips.add(const CoachTip(
      icon: '💧',
      title: 'Stay hydrated',
      body: 'Even mild dehydration reduces strength output. Sip water across '
          'the day and aim for pale-yellow urine.',
      category: TipCategory.recovery,
    ));

    return tips;
  }

  /// A simple meal-balancing suggestion given remaining macros.
  String mealSuggestion(MacroSnapshot remaining) {
    if (remaining.protein > 40) {
      return 'You\'re short on protein. Consider chicken, Greek yogurt, or a '
          'whey shake to top up.';
    }
    if (remaining.calories < 200) {
      return 'You\'re close to your calorie goal — keep the next choice light, '
          'like vegetables or fruit.';
    }
    if (remaining.carbs > 100) {
      return 'Plenty of carbs left — rice, oats or fruit will fuel your next '
          'training session.';
    }
    return 'Balanced choices from here: pair a lean protein with veg and a '
        'measured portion of carbs.';
  }

  /// v2 integration point — replace the rule-based output above with a call to
  /// a hosted LLM. Wire your API key via --dart-define and a Cloud Function
  /// proxy so the key never ships in the client.
  ///
  /// Example (pseudo):
  ///   final res = await functions.httpsCallable('coach').call({
  ///     'profile': profile.toMap(),
  ///     'recentWorkouts': _workouts.getCompleted().take(10)...,
  ///   });
  ///   return (res.data as List).map(CoachTip.fromMap).toList();
  Future<List<CoachTip>> llmIntegrationPoint(UserProfile profile) async {
    return dailyTips(profile);
  }
}

enum TipCategory { workout, nutrition, recovery }

class CoachTip {
  const CoachTip({
    required this.icon,
    required this.title,
    required this.body,
    required this.category,
  });

  final String icon;
  final String title;
  final String body;
  final TipCategory category;
}
