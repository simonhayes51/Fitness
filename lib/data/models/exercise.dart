import 'package:flutter/foundation.dart';

/// A single exercise definition from the catalogue (or a user-created custom
/// exercise). Immutable; persisted as a JSON map in Hive.
@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipment = 'Other',
    this.mechanic = 'Compound',
    this.force = 'Push',
    this.level = 'Intermediate',
    this.instructions = const [],
    this.tips = const [],
    this.videoUrl = '',
    this.imageUrl = '',
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;
  final String mechanic; // Compound | Isolation
  final String force; // Push | Pull | Static
  final String level; // Beginner | Intermediate | Advanced
  final List<String> instructions;
  final List<String> tips;
  final String videoUrl;
  final String imageUrl;
  final bool isCustom;

  factory Exercise.fromMap(Map<dynamic, dynamic> m) => Exercise(
        id: m['id'] as String,
        name: m['name'] as String,
        muscleGroup: m['muscleGroup'] as String? ?? 'Full Body',
        primaryMuscles: _strList(m['primaryMuscles']),
        secondaryMuscles: _strList(m['secondaryMuscles']),
        equipment: m['equipment'] as String? ?? 'Other',
        mechanic: m['mechanic'] as String? ?? 'Compound',
        force: m['force'] as String? ?? 'Push',
        level: m['level'] as String? ?? 'Intermediate',
        instructions: _strList(m['instructions']),
        tips: _strList(m['tips']),
        videoUrl: m['videoUrl'] as String? ?? '',
        imageUrl: m['imageUrl'] as String? ?? '',
        isCustom: m['isCustom'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup,
        'primaryMuscles': primaryMuscles,
        'secondaryMuscles': secondaryMuscles,
        'equipment': equipment,
        'mechanic': mechanic,
        'force': force,
        'level': level,
        'instructions': instructions,
        'tips': tips,
        'videoUrl': videoUrl,
        'imageUrl': imageUrl,
        'isCustom': isCustom,
      };

  Exercise copyWith({String? name, String? muscleGroup, String? equipment}) =>
      Exercise(
        id: id,
        name: name ?? this.name,
        muscleGroup: muscleGroup ?? this.muscleGroup,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        equipment: equipment ?? this.equipment,
        mechanic: mechanic,
        force: force,
        level: level,
        instructions: instructions,
        tips: tips,
        videoUrl: videoUrl,
        imageUrl: imageUrl,
        isCustom: isCustom,
      );

  String get searchKey =>
      '$name $muscleGroup $equipment ${primaryMuscles.join(' ')}'.toLowerCase();

  static List<String> _strList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];
}
