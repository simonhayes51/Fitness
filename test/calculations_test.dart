import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/core/constants/app_constants.dart';
import 'package:forgefit/core/utils/calculations.dart';

void main() {
  group('1RM estimates', () {
    test('returns the lifted weight for a single rep', () {
      expect(Calculations.epley1RM(100, 1), 100);
      expect(Calculations.estimated1RM(100, 1), 100);
    });

    test('Epley increases with reps', () {
      expect(Calculations.epley1RM(100, 5), closeTo(116.67, 0.1));
      expect(Calculations.epley1RM(100, 10), closeTo(133.33, 0.1));
    });

    test('handles invalid input gracefully', () {
      expect(Calculations.epley1RM(0, 5), 0);
      expect(Calculations.brzycki1RM(100, 0), 0);
    });

    test('weightForReps is the inverse of Epley', () {
      final oneRm = Calculations.epley1RM(100, 5);
      expect(Calculations.weightForReps(oneRm, 5), closeTo(100, 0.01));
    });
  });

  group('Volume load', () {
    test('sums weight x reps', () {
      final volume = Calculations.volumeLoad([
        (weight: 100, reps: 5),
        (weight: 80, reps: 10),
      ]);
      expect(volume, 100 * 5 + 80 * 10);
    });
  });

  group('Energy expenditure', () {
    test('BMR (Mifflin-St Jeor) for a male', () {
      // 80kg, 180cm, 30y male -> 10*80 + 6.25*180 - 5*30 + 5 = 1780
      final bmr = Calculations.bmr(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
      );
      expect(bmr, closeTo(1780, 0.1));
    });

    test('TDEE scales BMR by activity multiplier', () {
      final tdee = Calculations.tdee(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        activity: ActivityLevel.moderate,
      );
      expect(tdee, closeTo(1780 * 1.55, 0.1));
    });

    test('calorie target applies the goal delta', () {
      final target = Calculations.calorieTarget(
        tdee: 2500,
        goal: FitnessGoal.loseFat,
      );
      expect(target, closeTo(2000, 0.1)); // 20% deficit.
    });
  });

  group('Macro targets', () {
    test('protein anchored to bodyweight, energy balances', () {
      final macros = Calculations.macroTargets(
        calories: 2500,
        weightKg: 80,
        goal: FitnessGoal.gainMuscle,
      );
      expect(macros.protein, 160); // 2.0 g/kg * 80kg.
      // Total energy should be within rounding of the calorie budget.
      final total = macros.protein * 4 + macros.carbs * 4 + macros.fat * 9;
      expect(total, closeTo(2500, 10));
    });
  });

  group('BMI', () {
    test('computes and categorises', () {
      final bmi = Calculations.bmi(weightKg: 80, heightCm: 180);
      expect(bmi, closeTo(24.69, 0.1));
      expect(Calculations.bmiCategory(bmi), 'Healthy');
    });
  });
}
