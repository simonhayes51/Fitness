import 'dart:math' as math;

import '../constants/app_constants.dart';

/// Pure, well-tested fitness maths. Kept free of Flutter imports so it can be
/// unit-tested in isolation (see test/calculations_test.dart).
class Calculations {
  Calculations._();

  // ---------------------------------------------------------------------------
  // One-rep max (1RM) estimates.
  // ---------------------------------------------------------------------------

  /// Epley formula — the default used across the app.
  static double epley1RM(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Brzycki formula — slightly more conservative at higher reps.
  static double brzycki1RM(double weight, int reps) {
    if (reps <= 0 || weight <= 0 || reps >= 37) return 0;
    return weight * 36.0 / (37.0 - reps);
  }

  /// Average of common formulas for a balanced estimate.
  static double estimated1RM(double weight, int reps) {
    if (reps == 1) return weight;
    final e = epley1RM(weight, reps);
    final b = brzycki1RM(weight, reps);
    if (b <= 0) return e;
    return (e + b) / 2;
  }

  /// Predict the weight achievable for [targetReps] given a known 1RM.
  static double weightForReps(double oneRepMax, int targetReps) {
    if (targetReps <= 1) return oneRepMax;
    return oneRepMax / (1 + targetReps / 30.0);
  }

  // ---------------------------------------------------------------------------
  // Volume & intensity.
  // ---------------------------------------------------------------------------

  /// Total volume load = Σ(weight × reps) for a list of (weight, reps) pairs.
  static double volumeLoad(Iterable<({double weight, int reps})> sets) {
    return sets.fold(0.0, (sum, s) => sum + s.weight * s.reps);
  }

  // ---------------------------------------------------------------------------
  // Energy expenditure & macros.
  // ---------------------------------------------------------------------------

  /// Basal Metabolic Rate — Mifflin-St Jeor (the modern standard).
  static double bmr({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return sex == Sex.male ? base + 5 : base - 161;
  }

  /// Total Daily Energy Expenditure.
  static double tdee({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
    required ActivityLevel activity,
  }) {
    return bmr(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age) *
        activity.multiplier;
  }

  /// Calorie target after applying the goal delta to maintenance TDEE.
  static double calorieTarget({
    required double tdee,
    required FitnessGoal goal,
  }) {
    return tdee * goal.calorieMultiplier;
  }

  /// Recommended macro split in grams.
  ///
  /// Protein is anchored to bodyweight (g/kg), fat to ~25% of calories, and
  /// carbohydrate fills the remaining energy budget.
  static MacroTargets macroTargets({
    required double calories,
    required double weightKg,
    required FitnessGoal goal,
  }) {
    final proteinPerKg = switch (goal) {
      FitnessGoal.loseFat => 2.2,
      FitnessGoal.gainMuscle => 2.0,
      FitnessGoal.maintain => 1.8,
    };
    final proteinG = proteinPerKg * weightKg;
    final fatG = (calories * 0.25) / 9.0;
    final remaining = calories - (proteinG * 4 + fatG * 9);
    final carbsG = math.max(0, remaining / 4.0).toDouble();

    return MacroTargets(
      calories: calories.roundToDouble(),
      protein: proteinG.roundToDouble(),
      carbs: carbsG.roundToDouble(),
      fat: fatG.roundToDouble(),
    );
  }

  /// Body Mass Index.
  static double bmi({required double weightKg, required double heightCm}) {
    if (heightCm <= 0) return 0;
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  static String bmiCategory(double bmi) {
    if (bmi <= 0) return '—';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  // ---------------------------------------------------------------------------
  // Energy expenditure from exercise.
  // ---------------------------------------------------------------------------

  /// Rough kcal burned estimate using MET × weight × hours.
  /// MET 5 = moderate resistance training; 7 = heavy/HIIT.
  static double caloriesBurned({
    required double weightKg,
    required Duration duration,
    double met = 5.5,
  }) {
    if (weightKg <= 0 || duration.inSeconds <= 0) return 0;
    return met * weightKg * (duration.inMinutes / 60.0);
  }

  // ---------------------------------------------------------------------------
  // Plate loading.
  // ---------------------------------------------------------------------------

  /// Returns the plates needed per side for [totalWeight] on a [barWeight] bar.
  /// Uses standard plate sizes [25,20,15,10,5,2.5,1.25] kg.
  static List<double> platesPerSide(
      double totalWeight, double barWeight, List<double> plates) {
    var remaining = (totalWeight - barWeight) / 2;
    if (remaining <= 0) return [];
    final result = <double>[];
    for (final p in plates) {
      while (remaining >= p - 0.001) {
        result.add(p);
        remaining -= p;
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Unit conversions.
  // ---------------------------------------------------------------------------
  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;
  static double cmToInches(double cm) => cm / 2.54;
  static double inchesToCm(double inches) => inches * 2.54;
}

/// Immutable macro target value object.
class MacroTargets {
  const MacroTargets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}
