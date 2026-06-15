import 'package:flutter/material.dart';

/// Centralised colour palette for ForgeFit.
///
/// The brand is "forge" themed — molten orange accents on a deep charcoal
/// canvas. Dark mode is the primary experience; light mode mirrors the same
/// hues with adjusted surfaces.
class AppColors {
  AppColors._();

  // Brand accents.
  static const Color primary = Color(0xFFFF6B35); // Molten orange.
  static const Color primaryDark = Color(0xFFE0531D);
  static const Color secondary = Color(0xFF2EC4B6); // Teal energy.
  static const Color tertiary = Color(0xFFFFD23F); // Amber highlight.

  // Dark surfaces.
  static const Color darkBackground = Color(0xFF0E0F13);
  static const Color darkSurface = Color(0xFF16181F);
  static const Color darkSurfaceVariant = Color(0xFF1E212B);
  static const Color darkCard = Color(0xFF1A1D26);

  // Light surfaces.
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEDEFF5);

  // Semantic.
  static const Color success = Color(0xFF3DDC84);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4D4D);
  static const Color info = Color(0xFF4D9BFF);

  // Macros (consistent across charts & rings).
  static const Color protein = Color(0xFFFF6B35);
  static const Color carbs = Color(0xFF4D9BFF);
  static const Color fat = Color(0xFFFFD23F);
  static const Color calories = Color(0xFF2EC4B6);
  static const Color water = Color(0xFF38BDF8);

  // Muscle-group accent map for the body heatmap & library chips.
  static const Map<String, Color> muscleGroup = {
    'Chest': Color(0xFFFF6B35),
    'Back': Color(0xFF4D9BFF),
    'Legs': Color(0xFF3DDC84),
    'Shoulders': Color(0xFFFFD23F),
    'Arms': Color(0xFFB388FF),
    'Core': Color(0xFF2EC4B6),
    'Cardio': Color(0xFFFF4D8D),
    'Full Body': Color(0xFFFF9F1C),
  };

  static Color forGroup(String group) =>
      muscleGroup[group] ?? primary;
}
