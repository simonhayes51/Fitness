import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/calculations.dart';

/// Horizontal macro progress bars (protein / carbs / fat) against targets.
class MacroBars extends StatelessWidget {
  const MacroBars({
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFat,
    required this.targets,
    super.key,
  });

  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;
  final MacroTargets targets;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _bar('Protein', consumedProtein, targets.protein, AppColors.protein),
        const SizedBox(height: 12),
        _bar('Carbs', consumedCarbs, targets.carbs, AppColors.carbs),
        const SizedBox(height: 12),
        _bar('Fat', consumedFat, targets.fat, AppColors.fat),
      ],
    );
  }

  Widget _bar(String label, double value, double target, Color color) {
    final pct = target == 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(
              '${value.round()} / ${target.round()}g',
              style: const TextStyle(
                fontSize: 12.5,
                fontFeatures: [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
