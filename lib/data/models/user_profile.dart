import '../../core/constants/app_constants.dart';
import '../../core/utils/calculations.dart';

/// The signed-in user's profile, onboarding data, and derived nutrition targets.
class UserProfile {
  UserProfile({
    this.uid = 'local',
    this.name = '',
    this.email = '',
    this.sex = Sex.male,
    this.age = 25,
    this.heightCm = 175,
    this.weightKg = 75,
    this.activityLevel = ActivityLevel.moderate,
    this.goal = FitnessGoal.maintain,
    this.unitSystem = UnitSystem.metric,
    this.onboarded = false,
    this.customCalorieTarget,
    this.photoUrl = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String uid;
  String name;
  String email;
  Sex sex;
  int age;
  double heightCm;
  double weightKg;
  ActivityLevel activityLevel;
  FitnessGoal goal;
  UnitSystem unitSystem;
  bool onboarded;

  /// If the user manually overrides their calorie goal.
  double? customCalorieTarget;
  String photoUrl;
  final DateTime createdAt;

  double get bmr => Calculations.bmr(
        sex: sex,
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
      );

  double get tdee => Calculations.tdee(
        sex: sex,
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        activity: activityLevel,
      );

  double get bmi =>
      Calculations.bmi(weightKg: weightKg, heightCm: heightCm);

  double get calorieTarget =>
      customCalorieTarget ??
      Calculations.calorieTarget(tdee: tdee, goal: goal);

  MacroTargets get macroTargets => Calculations.macroTargets(
        calories: calorieTarget,
        weightKg: weightKg,
        goal: goal,
      );

  UserProfile copyWith({
    String? name,
    String? email,
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
    String? photoUrl,
  }) =>
      UserProfile(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        sex: sex ?? this.sex,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goal: goal ?? this.goal,
        unitSystem: unitSystem ?? this.unitSystem,
        onboarded: onboarded ?? this.onboarded,
        customCalorieTarget: clearCustomCalorieTarget
            ? null
            : (customCalorieTarget ?? this.customCalorieTarget),
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
      );

  factory UserProfile.fromMap(Map<dynamic, dynamic> m) => UserProfile(
        uid: m['uid'] as String? ?? 'local',
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        sex: Sex.values[(m['sex'] as num?)?.toInt() ?? 0],
        age: (m['age'] as num?)?.toInt() ?? 25,
        heightCm: (m['heightCm'] as num?)?.toDouble() ?? 175,
        weightKg: (m['weightKg'] as num?)?.toDouble() ?? 75,
        activityLevel:
            ActivityLevel.values[(m['activityLevel'] as num?)?.toInt() ?? 2],
        goal: FitnessGoal.values[(m['goal'] as num?)?.toInt() ?? 1],
        unitSystem: UnitSystem.values[(m['unitSystem'] as num?)?.toInt() ?? 0],
        onboarded: m['onboarded'] as bool? ?? false,
        customCalorieTarget: (m['customCalorieTarget'] as num?)?.toDouble(),
        photoUrl: m['photoUrl'] as String? ?? '',
        createdAt: m['createdAt'] != null
            ? DateTime.parse(m['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'sex': sex.index,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel.index,
        'goal': goal.index,
        'unitSystem': unitSystem.index,
        'onboarded': onboarded,
        'customCalorieTarget': customCalorieTarget,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}
