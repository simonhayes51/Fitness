import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/calculations.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';

/// User profile: identity, derived metabolic stats and a shareable summary.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataRevisionProvider);
    final profile = ref.watch(profileProvider);
    final workouts = ref.watch(workoutRepositoryProvider);
    final macros = profile.macroTargets;
    final bmi = profile.bmi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withOpacity(0.18),
                  child: Text(
                    (profile.name.isNotEmpty ? profile.name[0] : 'A')
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name.isEmpty ? 'Athlete' : profile.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900)),
                      Text('${profile.goal.label} · ${profile.activityLevel.label}',
                          style: TextStyle(color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editProfile(context, ref),
                ),
              ],
            ),
          ),

          // Metabolic stats.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: StatTile(
                        value: '${profile.tdee.round()}',
                        label: 'TDEE kcal',
                        icon: Icons.local_fire_department,
                        color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                    child: StatTile(
                        value: '${profile.bmr.round()}',
                        label: 'BMR kcal',
                        icon: Icons.bolt,
                        color: AppColors.secondary)),
                const SizedBox(width: 12),
                Expanded(
                    child: StatTile(
                        value: bmi.toStringAsFixed(1),
                        label: Calculations.bmiCategory(bmi),
                        icon: Icons.straighten,
                        color: AppColors.info)),
              ],
            ),
          ),

          const SectionHeader('Daily targets'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: Column(
                children: [
                  _target('Calories', '${macros.calories.round()} kcal',
                      AppColors.calories),
                  _target('Protein', '${macros.protein.round()} g',
                      AppColors.protein),
                  _target('Carbs', '${macros.carbs.round()} g', AppColors.carbs),
                  _target('Fat', '${macros.fat.round()} g', AppColors.fat,
                      last: true),
                ],
              ),
            ),
          ),

          const SectionHeader('Body'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: Column(
                children: [
                  _row('Height',
                      '${profile.heightCm.round()} ${profile.unitSystem.heightUnit}'),
                  _row('Weight',
                      '${Formatters.weight(profile.weightKg)} ${profile.unitSystem.weightUnit}'),
                  _row('Age', '${profile.age}'),
                  _row('Sex', profile.sex.name, last: true),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _shareCard(context, profile.name,
                  workouts.totalWorkouts, workouts.currentStreak()),
              icon: const Icon(Icons.share),
              label: const Text('Share progress card'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _target(String label, String value, Color color, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _shareCard(BuildContext context, String name, int workouts, int streak) {
    final text = '💪 ${name.isEmpty ? 'I' : name} on ForgeFit\n'
        '🏋️ $workouts workouts logged\n'
        '🔥 $streak-day streak\n\n'
        'Forging my strongest self with #ForgeFit';
    if (kIsWeb) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress card copied to clipboard!')),
      );
    } else {
      Share.share(text);
    }
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    final nameController = TextEditingController(text: profile.name);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref
                  .read(profileProvider.notifier)
                  .patch(name: nameController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
