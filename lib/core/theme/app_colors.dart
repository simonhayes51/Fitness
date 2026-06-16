import 'package:flutter/material.dart';

/// EVOLVE colour palette — amber gold accent on deep charcoal surfaces.
/// Dark mode is the primary experience.
class AppColors {
  AppColors._();

  // Brand accent (amber gold).
  static const Color primary = Color(0xFFF4B400);
  static const Color primaryDark = Color(0xFFD4A000);
  static const Color secondary = Color(0xFF2EC4B6); // Teal energy.
  static const Color tertiary = Color(0xFF9B8FFF); // Violet highlight.

  // Dark surfaces (EVOLVE spec: #1C1C1E background, #2C2C2E surface).
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF2C2C2E);
  static const Color darkSurfaceVariant = Color(0xFF3A3A3C);
  static const Color darkCard = Color(0xFF2C2C2E);

  // Light surfaces.
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEDEFF5);

  // Semantic.
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF4D9BFF);

  // Macros.
  static const Color protein = Color(0xFFF4B400); // Gold — primary brand.
  static const Color carbs = Color(0xFF4D9BFF);   // Blue.
  static const Color fat = Color(0xFFFF6B35);      // Orange.
  static const Color calories = Color(0xFF2EC4B6); // Teal.
  static const Color water = Color(0xFF38BDF8);

  // Muscle-group accent map.
  static const Map<String, Color> muscleGroup = {
    'Chest': Color(0xFFFF6B35),
    'Back': Color(0xFF4D9BFF),
    'Legs': Color(0xFF22C55E),
    'Shoulders': Color(0xFFF4B400),
    'Arms': Color(0xFFB388FF),
    'Core': Color(0xFF2EC4B6),
    'Cardio': Color(0xFFFF4D8D),
    'Full Body': Color(0xFFFF9F1C),
  };

  static Color forGroup(String group) => muscleGroup[group] ?? primary;
}
