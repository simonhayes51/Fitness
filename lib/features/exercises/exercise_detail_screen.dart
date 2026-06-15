import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/calculations.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/workout_repository.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Exercise detail: form instructions, tips, demo-video integration point,
/// personal records, an estimated-1RM history chart and a quick 1RM calculator.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({required this.exerciseId, super.key});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseRepositoryProvider).getById(exerciseId);
    final workouts = ref.watch(workoutRepositoryProvider);

    if (exercise == null) {
      return const Scaffold(body: Center(child: Text('Exercise not found')));
    }

    final color = AppColors.forGroup(exercise.muscleGroup);
    final series = workouts.oneRepMaxSeries(exerciseId);
    final pr = workouts.prFor(exerciseId);
    final heaviest = workouts.heaviestFor(exerciseId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: color.withOpacity(0.3),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(exercise.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.5), Colors.transparent],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.play_circle_outline,
                      size: 64, color: color.withOpacity(0.9)),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GroupChip(exercise.muscleGroup),
                    _tag(exercise.equipment),
                    _tag(exercise.mechanic),
                    _tag(exercise.force),
                    _tag(exercise.level),
                  ],
                ),
              ),

              // PRs.
              if (pr > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: Formatters.weight(pr),
                          label: 'est. 1RM PR',
                          icon: Icons.emoji_events,
                          color: AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          value: Formatters.weight(heaviest),
                          label: 'heaviest',
                          icon: Icons.fitness_center,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              if (series.length >= 2) ...[
                const SectionHeader('Estimated 1RM over time'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    child: SizedBox(height: 180, child: _OneRmChart(series: series)),
                  ),
                ),
              ],

              // Demo video integration point.
              const SectionHeader('Demo & form'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  onTap: () => _showVideoPlaceholder(context, exercise.videoUrl),
                  child: Row(
                    children: [
                      const Icon(Icons.ondemand_video, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise.videoUrl.isEmpty
                              ? 'Demo video — add a URL to embed (YouTube/Vimeo)'
                              : exercise.videoUrl,
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),

              const SectionHeader('How to perform'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < exercise.instructions.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.18),
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(exercise.instructions[i],
                                    style: const TextStyle(height: 1.35)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (exercise.tips.isNotEmpty) ...[
                const SectionHeader('Pro tips'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final tip in exercise.tips)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡 '),
                                Expanded(
                                    child: Text(tip,
                                        style: const TextStyle(height: 1.35))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              const SectionHeader('1RM calculator'),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _OneRmCalculator(),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      );

  void _showVideoPlaceholder(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(url.isEmpty
            ? 'No demo video set. Integrate youtube_player_flutter or a WebView here.'
            : 'Would open: $url'),
      ),
    );
  }
}

class _OneRmChart extends StatelessWidget {
  const _OneRmChart({required this.series});
  final List<OneRepMaxPoint> series;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (int i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].value),
    ];
    final minY = series.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxY = series.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: (minY - 5).clamp(0, double.infinity),
        maxY: maxY + 5,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (series.length / 4).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Formatters.monthDay(series[i].date),
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _OneRmCalculator extends StatefulWidget {
  const _OneRmCalculator();

  @override
  State<_OneRmCalculator> createState() => _OneRmCalculatorState();
}

class _OneRmCalculatorState extends State<_OneRmCalculator> {
  double _weight = 100;
  int _reps = 5;
  late final TextEditingController _weightCtrl =
      TextEditingController(text: '100');
  late final TextEditingController _repsCtrl = TextEditingController(text: '5');

  @override
  Widget build(BuildContext context) {
    final oneRm = Calculations.estimated1RM(_weight, _reps);
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _field('Weight', _weightCtrl, (v) {
                  setState(() => _weight = double.tryParse(v) ?? 0);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field('Reps', _repsCtrl, (v) {
                  setState(() => _reps = int.tryParse(v) ?? 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Estimated 1RM',
              style: TextStyle(color: Theme.of(context).hintColor)),
          Text(Formatters.weight(oneRm),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final pct in [0.95, 0.90, 0.85, 0.80, 0.70])
                Chip(
                  label: Text(
                    '${(pct * 100).round()}%: ${Formatters.weight(oneRm * pct)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
      String label, TextEditingController controller, ValueChanged<String> onChanged) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }
}
