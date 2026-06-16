import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/workout_repository.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';

/// EVOLVE Dashboard: greeting, nutrition ring, water, recovery score,
/// quick actions, recent PRs, goal snapshot and weekly volume.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataRevisionProvider);
    final profile = ref.watch(profileProvider);
    final workouts = ref.watch(workoutRepositoryProvider);
    final nutrition = ref.watch(nutritionRepositoryProvider);
    final profileRepo = ref.watch(profileRepositoryProvider);

    final today = DateTime.now();
    final macros = nutrition.totalsForDay(today);
    final targets = profile.macroTargets;
    final water = nutrition.waterForDay(today);
    final streak = workouts.currentStreak();
    final goals = profileRepo.goals().where((g) => !g.isComplete).take(2).toList();
    final recentPRs = workouts.recentPRs();

    // Recovery score: water (35%), training frequency (35%), calorie adherence (30%).
    final waterScore = (water.milliliters / AppConstants.defaultWaterGoalMl).clamp(0.0, 1.0);
    final trainingDays = _trainingDaysThisWeek(workouts);
    final trainingScore = (trainingDays / 4).clamp(0.0, 1.0);
    final calDiff = targets.calories == 0
        ? 1.0
        : (1 - ((macros.calories - targets.calories).abs() / targets.calories)).clamp(0.0, 1.0);
    final recoveryScore = ((waterScore * 35) + (trainingScore * 35) + (calDiff * 30)).round();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.read(dataRevisionProvider.notifier).state++,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Header — greeting + avatar.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(),
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
                      onTap: () => context.go('/profile'),
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

              // Nutrition ring + macros.
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
                            _miniMacro(context, 'Protein', macros.protein,
                                targets.protein, AppColors.protein),
                            const SizedBox(height: 10),
                            _miniMacro(context, 'Carbs', macros.carbs,
                                targets.carbs, AppColors.carbs),
                            const SizedBox(height: 10),
                            _miniMacro(context, 'Fat', macros.fat,
                                targets.fat, AppColors.fat),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats: streak, workouts, weight.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: '$streak',
                        label: 'day streak',
                        icon: Icons.local_fire_department,
                        color: AppColors.warning,
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

              // Water + Recovery row.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    // Water progress.
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.water_drop,
                                    color: AppColors.water, size: 16),
                                const SizedBox(width: 6),
                                const Text('Water',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(water.milliliters / 1000).toStringAsFixed(1)} L',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (water.milliliters /
                                        AppConstants.defaultWaterGoalMl)
                                    .clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor:
                                    AppColors.water.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.water),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Goal ${(AppConstants.defaultWaterGoalMl / 1000).toStringAsFixed(0)} L',
                              style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Recovery score.
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.favorite_border,
                                    color: _recoveryColor(recoveryScore),
                                    size: 16),
                                const SizedBox(width: 6),
                                const Text('Recovery',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$recoveryScore',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: _recoveryColor(recoveryScore)),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: recoveryScore / 100,
                                minHeight: 6,
                                backgroundColor:
                                    _recoveryColor(recoveryScore).withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation(
                                    _recoveryColor(recoveryScore)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'out of 100',
                              style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick actions — 2×2 grid.
              const SectionHeader('Quick actions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.fitness_center,
                            label: 'Start workout',
                            color: AppColors.primary,
                            onTap: () => context.go('/workout'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.restaurant,
                            label: 'Log meal',
                            color: AppColors.secondary,
                            onTap: () => context.go('/nutrition'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Log weight',
                            color: AppColors.info,
                            onTap: () => context.go('/progress'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.water_drop_outlined,
                            label: 'Add water',
                            color: AppColors.water,
                            onTap: () => context.go('/nutrition'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Recent PRs.
              if (recentPRs.isNotEmpty) ...[
                const SectionHeader('Recent PRs'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: AppCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < recentPRs.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(recentPRs[i].exerciseName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                              Text(
                                '${Formatters.weight(recentPRs[i].estimated1RM)} kg e1RM',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Active goals snapshot.
              if (goals.isNotEmpty) ...[
                SectionHeader(
                  'Goals',
                  action: TextButton(
                    onPressed: () => context.go('/progress'),
                    child: const Text('See all'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: AppCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < goals.length; i++) ...[
                          if (i > 0) const Divider(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(goals[i].title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  Text(
                                    Formatters.percent(goals[i].progress),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: goals[i].progress,
                                  minHeight: 6,
                                  backgroundColor:
                                      AppColors.success.withOpacity(0.15),
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.success),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Weekly volume comparison.
              _WeeklyVolumeCard(workouts: workouts),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniMacro(BuildContext context, String label, double value,
      double target, Color color) {
    final pct = target == 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5)),
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

  Color _recoveryColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  int _trainingDaysThisWeek(WorkoutRepository repo) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monday = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final days = repo
        .getCompleted()
        .where((w) {
          final d = w.completedAt ?? w.startedAt;
          return !d.isBefore(monday);
        })
        .map((w) {
          final d = w.completedAt ?? w.startedAt;
          return DateTime(d.year, d.month, d.day).toString();
        })
        .toSet()
        .length;
    return days;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ---------------------------------------------------------------------------

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

    final totalSetsThis =
        sets.values.fold<int>(0, (s, e) => s + e.thisWeek);
    final totalSetsLast =
        sets.values.fold<int>(0, (s, e) => s + e.lastWeek);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('This week',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                if (pct != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          (pct >= 0 ? AppColors.success : AppColors.danger)
                              .withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            pct >= 0 ? AppColors.success : AppColors.danger,
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
                    Formatters.number(vol.thisWeek.round()),
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
                style:
                    TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ],
        ),
        Text(
          last == 0
              ? 'No data last week'
              : 'Last: ${Formatters.number(last.round())}',
          style:
              TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
