/// App-wide constants: keys, enums-as-strings, and tunable defaults.
class AppConstants {
  AppConstants._();

  static const String appName = 'ForgeFit';
  static const String tagline = 'Forge your strongest self.';

  // Hive box names.
  static const String boxExercises = 'exercises';
  static const String boxWorkouts = 'workouts';
  static const String boxRoutines = 'routines';
  static const String boxFoods = 'foods';
  static const String boxFoodLogs = 'food_logs';
  static const String boxBodyMetrics = 'body_metrics';
  static const String boxGoals = 'goals';
  static const String boxProfile = 'profile';
  static const String boxSettings = 'settings';
  static const String boxWaterLogs = 'water_logs';
  static const String boxSavedMeals = 'saved_meals';
  static const String boxFasting = 'fasting';

  // Asset paths.
  static const String exerciseSeed = 'assets/data/exercises.json';
  static const String foodSeed = 'assets/data/foods.json';

  // Defaults.
  static const int defaultRestSeconds = 120;
  static const double defaultWaterGoalMl = 3000;
  static const int defaultProteinPerKg = 2; // g protein per kg bodyweight.

  static const List<String> muscleGroups = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
    'Full Body',
  ];

  static const List<String> equipmentTypes = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Smith Machine',
    'Kettlebell',
    'Bodyweight',
    'Cardio Machine',
    'Other',
  ];

  static const List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
}

/// Fitness goal targets used by the TDEE calculator and nutrition planner.
enum FitnessGoal { loseFat, maintain, gainMuscle }

extension FitnessGoalX on FitnessGoal {
  String get label => switch (this) {
        FitnessGoal.loseFat => 'Lose Fat',
        FitnessGoal.maintain => 'Maintain',
        FitnessGoal.gainMuscle => 'Gain Muscle',
      };

  /// Calorie delta applied to maintenance TDEE.
  double get calorieMultiplier => switch (this) {
        FitnessGoal.loseFat => 0.80, // ~20% deficit.
        FitnessGoal.maintain => 1.0,
        FitnessGoal.gainMuscle => 1.10, // ~10% surplus.
      };
}

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

extension ActivityLevelX on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.light => 'Lightly Active',
        ActivityLevel.moderate => 'Moderately Active',
        ActivityLevel.active => 'Active',
        ActivityLevel.veryActive => 'Very Active',
      };

  String get description => switch (this) {
        ActivityLevel.sedentary => 'Little or no exercise',
        ActivityLevel.light => 'Exercise 1–3 days/week',
        ActivityLevel.moderate => 'Exercise 3–5 days/week',
        ActivityLevel.active => 'Exercise 6–7 days/week',
        ActivityLevel.veryActive => 'Hard exercise or physical job',
      };

  /// Mifflin-St Jeor activity multiplier.
  double get multiplier => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
        ActivityLevel.veryActive => 1.9,
      };
}

enum Sex { male, female }

enum UnitSystem { metric, imperial }

extension UnitSystemX on UnitSystem {
  String get weightUnit => this == UnitSystem.metric ? 'kg' : 'lbs';
  String get heightUnit => this == UnitSystem.metric ? 'cm' : 'in';
}

/// Set classifications used in the workout logger.
enum SetType { warmup, normal, dropset, failure }

extension SetTypeX on SetType {
  String get label => switch (this) {
        SetType.warmup => 'Warm-up',
        SetType.normal => 'Working',
        SetType.dropset => 'Drop set',
        SetType.failure => 'To failure',
      };

  String get badge => switch (this) {
        SetType.warmup => 'W',
        SetType.normal => '',
        SetType.dropset => 'D',
        SetType.failure => 'F',
      };
}
