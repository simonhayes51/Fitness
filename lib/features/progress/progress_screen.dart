import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/body_metric.dart';
import '../../data/models/goal.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';

class _WeightResult {
  const _WeightResult(this.weight, this.bodyFat);
  final double weight;
  final double? bodyFat;
}

class _MeasurementResult {
  const _MeasurementResult(this.values);
  final Map<String, double> values;
}

class _ConsistencyData {
  const _ConsistencyData({
    required this.score,
    required this.trainingPct,
    required this.weightLogPct,
    required this.nutritionPct,
    required this.waterPct,
  });
  final int score;
  final double trainingPct;
  final double weightLogPct;
  final double nutritionPct;
  final double waterPct;
}

/// Standard body measurement sites.
const _measurementSites = [
  'Waist',
  'Chest',
  'Arms',
  'Hips',
  'Thighs',
  'Neck',
];

/// Analytics hub: body-weight trend, measurements, consistency score,
/// training volume, weekly muscle-group distribution, and goal tracking.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataRevisionProvider);
    final profileRepo = ref.watch(profileRepositoryProvider);
    final workouts = ref.watch(workoutRepositoryProvider);
    final nutritionRepo = ref.watch(nutritionRepositoryProvider);
    final profile = ref.watch(profileProvider);

    final weightMetrics = profileRepo.weightMetrics();
    final allMetrics = profileRepo.bodyMetrics();
    final latestMeasurements = profileRepo.latestMeasurements();
    final previousMeasurements = profileRepo.previousMeasurements();
    final volumeByDay = workouts.volumeByDay();
    final weeklySets = workouts.weeklySetsByMuscle(weeks: 1);
    final goals = profileRepo.goals();
    final consistency = _computeConsistency(workouts, profileRepo, nutritionRepo);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Consistency score.
          const SectionHeader('Consistency Score'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ConsistencyCard(data: consistency),
          ),

          // Body weight.
          SectionHeader(
            'Body weight',
            action: TextButton.icon(
              onPressed: () => _logWeight(context, ref, profile.weightKg),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (weightMetrics.isNotEmpty) ...[
                    _latestWeightRow(
                        context, weightMetrics.last, profile.unitSystem.weightUnit),
                    const SizedBox(height: 12),
                  ],
                  weightMetrics.length < 2
                      ? const SizedBox(
                          height: 120,
                          child: Center(
                              child: Text('Log your weight to see trends')),
                        )
                      : SizedBox(
                          height: 180,
                          child: _WeightChart(
                            metrics: weightMetrics,
                            unit: profile.unitSystem.weightUnit,
                            toDisplay: (kg) =>
                                profile.unitSystem.weightUnit == 'kg'
                                    ? kg
                                    : kg * 2.20462,
                          ),
                        ),
                ],
              ),
            ),
          ),

          // Body measurements.
          SectionHeader(
            'Body Measurements',
            action: TextButton.icon(
              onPressed: () => _logMeasurements(context, ref, latestMeasurements),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MeasurementCard(
              latest: latestMeasurements,
              previous: previousMeasurements,
              lastDate: allMetrics.isNotEmpty ? allMetrics.last.date : null,
            ),
          ),

          // Training volume.
          const SectionHeader('Training volume'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: volumeByDay.length < 2
                  ? const SizedBox(
                      height: 120,
                      child: Center(child: Text('Complete workouts to chart volume')),
                    )
                  : SizedBox(height: 200, child: _VolumeChart(data: volumeByDay)),
            ),
          ),

          // Weekly muscle distribution.
          const SectionHeader('This week by muscle'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: weeklySets.isEmpty
                  ? const SizedBox(
                      height: 80,
                      child: Center(child: Text('No sets logged this week')),
                    )
                  : Column(
                      children: [
                        for (final entry in (weeklySets.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value))))
                          _MuscleBar(
                            group: entry.key,
                            sets: entry.value,
                            maxSets: weeklySets.values
                                .reduce((a, b) => a > b ? a : b),
                          ),
                      ],
                    ),
            ),
          ),

          // Goals.
          SectionHeader(
            'Goals',
            action: TextButton.icon(
              onPressed: () => _addGoal(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
            ),
          ),
          if (goals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: EmptyState(
                icon: Icons.flag_outlined,
                title: 'No goals yet',
                message: 'Set a strength, body-weight or habit goal to stay '
                    'accountable.',
              ),
            )
          else
            ...goals.map((g) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _GoalCard(
                    goal: g,
                    onUpdate: () => _updateGoalProgress(context, ref, g),
                    onDelete: () async {
                      await profileRepo.deleteGoal(g.id);
                      ref.read(dataRevisionProvider.notifier).state++;
                    },
                  ),
                )),
        ],
      ),
    );
  }

  _ConsistencyData _computeConsistency(
    WorkoutRepository workouts,
    ProfileRepository profileRepo,
    NutritionRepository nutritionRepo,
  ) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    const totalDays = 30;

    // Training days in last 30.
    final trainedDays = <String>{};
    for (final w in workouts.getCompleted()) {
      final d = w.completedAt ?? w.startedAt;
      if (d.isAfter(cutoff)) {
        trainedDays.add('${d.year}-${d.month}-${d.day}');
      }
    }

    // Weight log days in last 30.
    final weightDays = <String>{};
    for (final m in profileRepo.weightMetrics()) {
      if (m.date.isAfter(cutoff)) {
        weightDays.add('${m.date.year}-${m.date.month}-${m.date.day}');
      }
    }

    // Nutrition & water days.
    int nutritionDays = 0;
    int waterDays = 0;
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < totalDays; i++) {
      final day = today.subtract(Duration(days: i));
      if (nutritionRepo.entriesForDay(day).isNotEmpty) nutritionDays++;
      if (nutritionRepo.waterForDay(day).milliliters >= 2000) waterDays++;
    }

    // Targets: 17 workout days (≈4/wk), 8 weight logs (2/wk), 30 nutrition, 30 water.
    final trainingPct = (trainedDays.length / 17).clamp(0.0, 1.0);
    final weightLogPct = (weightDays.length / 8).clamp(0.0, 1.0);
    final nutritionPct = (nutritionDays / totalDays).clamp(0.0, 1.0);
    final waterPct = (waterDays / totalDays).clamp(0.0, 1.0);

    final rawScore = (trainingPct * 40) +
        (weightLogPct * 20) +
        (nutritionPct * 25) +
        (waterPct * 15);
    final score = rawScore.round().clamp(0, 100);

    return _ConsistencyData(
      score: score,
      trainingPct: trainingPct,
      weightLogPct: weightLogPct,
      nutritionPct: nutritionPct,
      waterPct: waterPct,
    );
  }

  Future<void> _logWeight(
      BuildContext context, WidgetRef ref, double current) async {
    final weightCtrl = TextEditingController(text: Formatters.weight(current));
    final bfCtrl = TextEditingController();
    final result = await showDialog<_WeightResult>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Log body weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Weight', suffixText: 'kg'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bfCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Body fat % (optional)', suffixText: '%'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final w = double.tryParse(weightCtrl.text);
              if (w == null) return;
              Navigator.pop(
                  dlgCtx,
                  _WeightResult(w, double.tryParse(bfCtrl.text)));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    weightCtrl.dispose();
    bfCtrl.dispose();
    if (result == null) return;
    await ref.read(profileRepositoryProvider).saveBodyMetric(
          BodyMetric(weightKg: result.weight, bodyFatPct: result.bodyFat),
        );
    await ref.read(profileProvider.notifier).patch(weightKg: result.weight);
    ref.read(dataRevisionProvider.notifier).state++;
  }

  Future<void> _logMeasurements(
      BuildContext context, WidgetRef ref, Map<String, double> latest) async {
    final controllers = {
      for (final site in _measurementSites)
        site: TextEditingController(
            text: latest.containsKey(site)
                ? latest[site]!.toStringAsFixed(1)
                : ''),
    };
    // Custom site support
    final customSiteCtrl = TextEditingController();
    final customValueCtrl = TextEditingController();

    final result = await showDialog<_MeasurementResult>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Log measurements'),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final site in _measurementSites)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[site],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: site,
                        suffixText: 'cm',
                      ),
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: customSiteCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'Custom site'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: customValueCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'cm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final values = <String, double>{};
              for (final site in _measurementSites) {
                final v = double.tryParse(controllers[site]!.text);
                if (v != null) values[site] = v;
              }
              final cSite = customSiteCtrl.text.trim();
              final cVal = double.tryParse(customValueCtrl.text);
              if (cSite.isNotEmpty && cVal != null) values[cSite] = cVal;
              Navigator.pop(dlgCtx, _MeasurementResult(values));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    for (final c in controllers.values) {
      c.dispose();
    }
    customSiteCtrl.dispose();
    customValueCtrl.dispose();
    if (result == null || result.values.isEmpty) return;
    await ref.read(profileRepositoryProvider).saveBodyMetric(
          BodyMetric(weightKg: 0, measurements: result.values),
        );
    ref.read(dataRevisionProvider.notifier).state++;
  }

  Widget _latestWeightRow(
      BuildContext context, BodyMetric latest, String weightUnit) {
    final displayW =
        weightUnit == 'kg' ? latest.weightKg : latest.weightKg * 2.20462;
    final bf = latest.bodyFatPct;
    final leanKg = bf != null ? latest.weightKg * (1 - bf / 100) : null;
    final fatKg = bf != null ? latest.weightKg * (bf / 100) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${Formatters.weight(displayW)} $weightUnit',
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            if (bf != null) ...[
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${bf.toStringAsFixed(1)}% BF',
                  style: const TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ],
            const Spacer(),
            Text(
              Formatters.relativeDay(latest.date),
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
          ],
        ),
        if (leanKg != null && fatKg != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _compositionChip('Lean', leanKg, weightUnit, AppColors.success),
              const SizedBox(width: 10),
              _compositionChip('Fat', fatKg, weightUnit, AppColors.danger),
            ],
          ),
        ],
      ],
    );
  }

  Widget _compositionChip(
      String label, double kg, String unit, Color color) {
    final display = unit == 'kg' ? kg : kg * 2.20462;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          '$label ${Formatters.weight(display)} $unit',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final goal = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _GoalSheet(),
    );
    if (goal == null) return;
    await ref.read(profileRepositoryProvider).saveGoal(goal);
    ref.read(dataRevisionProvider.notifier).state++;
  }

  Future<void> _updateGoalProgress(
      BuildContext context, WidgetRef ref, Goal goal) async {
    final controller =
        TextEditingController(text: Formatters.weight(goal.currentValue));
    final result = await showDialog<double>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text('Update "${goal.title}"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: goal.unit),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dlgCtx, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    goal.currentValue = result;
    final wasComplete = goal.achieved;
    if (goal.progress >= 1.0) goal.achieved = true;
    await ref.read(profileRepositoryProvider).saveGoal(goal);
    if (!wasComplete && goal.achieved && context.mounted) {
      ref.read(notificationServiceProvider).showGoalAchieved(goal.title);
    }
    ref.read(dataRevisionProvider.notifier).state++;
  }
}

// ---------------------------------------------------------------------------
// Consistency score card.
// ---------------------------------------------------------------------------

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.data});
  final _ConsistencyData data;

  @override
  Widget build(BuildContext context) {
    final score = data.score;
    final color = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.primary
            : AppColors.danger;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$score',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1),
              ),
              const Text(' / 100',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score >= 80
                        ? 'Excellent'
                        : score >= 60
                            ? 'Good'
                            : score >= 40
                                ? 'Building'
                                : 'Getting started',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  const Text('Last 30 days',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _bar(context, 'Training', data.trainingPct, AppColors.primary,
              '(target 4/wk)'),
          _bar(context, 'Nutrition', data.nutritionPct, AppColors.success,
              '(daily logging)'),
          _bar(context, 'Hydration', data.waterPct, AppColors.info,
              '(2L goal)'),
          _bar(context, 'Weight log', data.weightLogPct, AppColors.secondary,
              '(2×/wk)'),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, String label, double pct, Color color,
      String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                Text(hint,
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 12,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body measurements card.
// ---------------------------------------------------------------------------

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({
    required this.latest,
    required this.previous,
    required this.lastDate,
  });
  final Map<String, double> latest;
  final Map<String, double> previous;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final knownSites = [
      ..._measurementSites.where((s) => latest.containsKey(s)),
      ...latest.keys.where((k) => !_measurementSites.contains(k)),
    ];

    if (knownSites.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.straighten_outlined,
                size: 36, color: Theme.of(context).hintColor),
            const SizedBox(height: 10),
            Text('No measurements yet',
                style: TextStyle(color: Theme.of(context).hintColor)),
            const SizedBox(height: 4),
            Text('Tap "Log" to record waist, chest, arms and more.',
                style: TextStyle(
                    color: Theme.of(context).hintColor, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Last logged ${Formatters.relativeDay(lastDate!)}',
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).hintColor),
              ),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final site in knownSites)
                _MeasurementChip(
                  site: site,
                  value: latest[site]!,
                  prev: previous[site],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeasurementChip extends StatelessWidget {
  const _MeasurementChip({
    required this.site,
    required this.value,
    required this.prev,
  });
  final String site;
  final double value;
  final double? prev;

  @override
  Widget build(BuildContext context) {
    IconData? trendIcon;
    Color trendColor = Colors.grey;
    if (prev != null) {
      if (value < prev! - 0.1) {
        trendIcon = Icons.trending_down;
        trendColor = AppColors.success;
      } else if (value > prev! + 0.1) {
        trendIcon = Icons.trending_up;
        trendColor = AppColors.danger;
      } else {
        trendIcon = Icons.trending_flat;
        trendColor = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(site,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.toStringAsFixed(1)} cm',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              if (trendIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trendIcon, size: 14, color: trendColor),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts.
// ---------------------------------------------------------------------------

class _WeightChart extends StatelessWidget {
  const _WeightChart({
    required this.metrics,
    required this.unit,
    required this.toDisplay,
  });
  final List<BodyMetric> metrics;
  final String unit;
  final double Function(double kg) toDisplay;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (int i = 0; i < metrics.length; i++)
        FlSpot(i.toDouble(), toDisplay(metrics[i].weightKg)),
    ];
    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: minY - 2,
        maxY: maxY + 2,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (metrics.length / 4).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= metrics.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Formatters.monthDay(metrics[i].date),
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.info,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.info.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.data});
  final Map<DateTime, double> data;

  @override
  Widget build(BuildContext context) {
    final days = data.keys.toList()..sort();
    final recent = days.length > 14 ? days.sublist(days.length - 14) : days;
    final maxVal = recent.map((d) => data[d]!).fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= recent.length) return const SizedBox.shrink();
                if (i % 2 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Formatters.monthDay(recent[i]),
                      style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < recent.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[recent[i]]!,
                color: AppColors.primary,
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]),
        ],
      ),
    );
  }
}

class _MuscleBar extends StatelessWidget {
  const _MuscleBar({
    required this.group,
    required this.sets,
    required this.maxSets,
  });
  final String group;
  final int sets;
  final int maxSets;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forGroup(group);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(group,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: maxSets == 0 ? 0 : sets / maxSets,
                minHeight: 16,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$sets',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onUpdate,
    required this.onDelete,
  });
  final Goal goal;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onUpdate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(goal.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              if (goal.isComplete)
                const Icon(Icons.emoji_events, color: AppColors.tertiary)
              else
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close,
                      size: 18, color: Theme.of(context).hintColor),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: AppColors.success.withOpacity(0.14),
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${Formatters.weight(goal.currentValue)} / '
            '${Formatters.weight(goal.targetValue)} ${goal.unit} · '
            '${Formatters.percent(goal.progress)}',
            style: TextStyle(
                color: Theme.of(context).hintColor, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet();

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  final _title = TextEditingController();
  final _start = TextEditingController();
  final _target = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  GoalType _type = GoalType.strength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New goal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Title', hintText: 'e.g. Bench press 100kg'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: GoalType.values
                  .map((t) => ChoiceChip(
                        label: Text(t.label),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _start,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Start'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _target,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Target'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Create goal')),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    final start = double.tryParse(_start.text) ?? 0;
    Navigator.pop(
      context,
      Goal(
        title: _title.text.trim(),
        type: _type,
        startValue: start,
        currentValue: start,
        targetValue: double.tryParse(_target.text) ?? 0,
        unit: _unit.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _start.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }
}
