import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/ai_coach_service.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Home dashboard: greeting, today's nutrition ring, training streak, weekly
/// volume snapshot and AI coach tips.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataRevisionProvider); // Recompute when data changes.
    final profile = ref.watch(profileProvider);
    final workouts = ref.watch(workoutRepositoryProvider);
    final nutrition = ref.watch(nutritionRepositoryProvider);
    final coach = ref.watch(aiCoachProvider);

    final today = DateTime.now();
    final macros = nutrition.totalsForDay(today);
    final targets = profile.macroTargets;
    final streak = workouts.currentStreak();
    final tips = coach.dailyTips(profile);
    final greeting = _greeting();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.read(dataRevisionProvider.notifier).state++,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greeting,
                              style: TextStyle(color: Theme.of(context).hintColor)),
                          Text(
                            profile.name.isEmpty ? 'Athlete' : profile.name,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withOpacity(0.18),
                        child: Text(
                          (profile.name.isNotEmpty ? profile.name[0] : 'A')
                              .toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Nutrition ring + streak.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AppCard(
                  child: Row(
                    children: [
                      ProgressRing(
                        progress: targets.calories == 0
                            ? 0
                            : macros.calories / targets.calories,
                        size: 104,
                        color: AppColors.calories,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${macros.calories.round()}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text('/ ${targets.calories.round()}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).hintColor)),
                            const Text('kcal', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _miniMacro('Protein', macros.protein, targets.protein,
                                AppColors.protein),
                            const SizedBox(height: 10),
                            _miniMacro('Carbs', macros.carbs, targets.carbs,
                                AppColors.carbs),
                            const SizedBox(height: 10),
                            _miniMacro(
                                'Fat', macros.fat, targets.fat, AppColors.fat),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick stats row.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: '$streak',
                        label: streak == 1 ? 'day streak' : 'day streak',
                        icon: Icons.local_fire_department,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        value: '${workouts.totalWorkouts}',
                        label: 'workouts',
                        icon: Icons.fitness_center,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        value: Formatters.weight(profile.weightKg),
                        label: profile.unitSystem.weightUnit,
                        icon: Icons.monitor_weight_outlined,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),

              // Weekly volume comparison.
              _WeeklyVolumeCard(workouts: workouts),

              // Quick actions.
              const SectionHeader('Quick actions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add,
                        label: 'Start workout',
                        color: AppColors.primary,
                        onTap: () => context.go('/workout'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.restaurant,
                        label: 'Log food',
                        color: AppColors.secondary,
                        onTap: () => context.go('/nutrition'),
                      ),
                    ),
                  ],
                ),
              ),

              // AI coach.
              const SectionHeader('Your coach'),
              ...tips.map((t) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _TipCard(tip: t),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniMacro(String label, double value, double target, Color color) {
    final pct = target == 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            Text('${value.round()}g',
                style: const TextStyle(
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _WeeklyVolumeCard extends ConsumerWidget {
  const _WeeklyVolumeCard({required this.workouts});
  final WorkoutRepository workouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vol = workouts.weeklyVolumeComparison();
    final sets = workouts.weeklySetComparison();

    final pct = vol.lastWeek == 0
        ? null
        : ((vol.thisWeek - vol.lastWeek) / vol.lastWeek * 100);

    final totalSetsThis = sets.values.fold(0, (s, e) => s + e.thisWeek);
    final totalSetsLast = sets.values.fold(0, (s, e) => s + e.lastWeek);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('This week',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                if (pct != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (pct >= 0 ? AppColors.success : AppColors.danger)
                          .withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pct >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _weekStat(
                    context,
                    Icons.bar_chart,
                    '${Formatters.number(vol.thisWeek.round())}',
                    'vol',
                    vol.lastWeek,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _weekStat(
                    context,
                    Icons.check_circle_outline,
                    '$totalSetsThis',
                    'sets',
                    totalSetsLast.toDouble(),
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekStat(BuildContext context, IconData icon, String value,
      String label, double last, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
        Text(
          last == 0 ? 'No data last week' : 'Last: ${Formatters.number(last.round())}',
          style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final CoachTip tip;

  @override
  Widget build(BuildContext context) {
    final color = switch (tip.category) {
      TipCategory.workout => AppColors.primary,
      TipCategory.nutrition => AppColors.secondary,
      TipCategory.recovery => AppColors.info,
    };
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(tip.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(tip.body,
                    style: TextStyle(
                        color: Theme.of(context).hintColor,
                        height: 1.35,
                        fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
