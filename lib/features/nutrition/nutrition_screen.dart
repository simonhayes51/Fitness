import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/calculations.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/food_log.dart';
import '../../data/models/saved_meal.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/macro_summary.dart';
import 'food_search_screen.dart';

/// Daily nutrition diary: calories ring, macro bars, water tracker, meals,
/// saved meals, fasting tracker, and workout-burn adjustment.
class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  DateTime _day = DateTime.now();

  @override
  Widget build(BuildContext context) {
    ref.watch(dataRevisionProvider);
    final profile = ref.watch(profileProvider);
    final repo = ref.watch(nutritionRepositoryProvider);
    final workoutRepo = ref.watch(workoutRepositoryProvider);

    final entries = repo.entriesForDay(_day);
    final totals = repo.totalsForDay(_day);
    final targets = profile.macroTargets;
    final water = repo.waterForDay(_day);

    // Calories burned from workouts completed on this day.
    final todayWorkouts = workoutRepo.workoutsForDay(_day);
    final burnedKcal = todayWorkouts.fold(0.0, (sum, w) {
      return sum + Calculations.caloriesBurned(
          weightKg: profile.weightKg, duration: w.duration);
    });

    final netGoal = targets.calories + burnedKcal;
    final remaining = netGoal - totals.calories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu_outlined, size: 20),
            tooltip: 'Saved meals',
            onPressed: () => _showSavedMeals(context, repo),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _dayPicker(),

          // Fasting tracker.
          _FastingCard(
            repo: repo,
            onChanged: () => ref.read(dataRevisionProvider.notifier).state++,
          ),

          // Calories + macros card.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      ProgressRing(
                        progress: netGoal == 0
                            ? 0
                            : totals.calories / netGoal,
                        size: 120,
                        color: AppColors.calories,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${remaining.round().abs()}',
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ])),
                            Text(remaining >= 0 ? 'kcal left' : 'kcal over',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv('Eaten', '${totals.calories.round()}'),
                            const SizedBox(height: 6),
                            _kv('Goal', '${targets.calories.round()}'),
                            if (burnedKcal > 0) ...[
                              const SizedBox(height: 6),
                              _kv('Exercise',
                                  '+${burnedKcal.round()}',
                                  color: AppColors.success),
                              const SizedBox(height: 6),
                              _kv('Net goal', '${netGoal.round()}',
                                  bold: true),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  MacroBars(
                    consumedProtein: totals.protein,
                    consumedCarbs: totals.carbs,
                    consumedFat: totals.fat,
                    targets: targets,
                  ),
                ],
              ),
            ),
          ),

          // Water tracker.
          const SectionHeader('Water'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _WaterCard(
              water: water,
              goalMl: AppConstants.defaultWaterGoalMl,
              onAdd: (ml) async {
                await repo.addWater(_day, ml);
                ref.read(dataRevisionProvider.notifier).state++;
              },
              onCustom: (ml) async {
                await repo.addWater(_day, ml);
                ref.read(dataRevisionProvider.notifier).state++;
              },
              onReset: () async {
                await repo.setWater(_day, 0);
                ref.read(dataRevisionProvider.notifier).state++;
              },
            ),
          ),

          // Meals.
          for (final meal in AppConstants.mealTypes)
            _MealSection(
              meal: meal,
              entries: entries.where((e) => e.mealType == meal).toList(),
              onAdd: () => _addFood(meal),
              onDelete: (id) async {
                await repo.deleteEntry(id);
                ref.read(dataRevisionProvider.notifier).state++;
              },
              onSaveMeal: (mealEntries) =>
                  _saveAsMeal(context, repo, meal, mealEntries),
            ),
        ],
      ),
    );
  }

  Widget _dayPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                setState(() => _day = _day.subtract(const Duration(days: 1))),
          ),
          Text(Formatters.relativeDay(_day),
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday(_day)
                ? null
                : () =>
                    setState(() => _day = _day.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {Color? color, bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: Theme.of(context).hintColor)),
          Text(v,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
                  color: color)),
        ],
      );

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _addFood(String meal) async {
    final entry = await Navigator.of(context).push<FoodLogEntry>(
      MaterialPageRoute(
        builder: (_) => FoodSearchScreen(mealType: meal, day: _day),
      ),
    );
    if (entry != null) {
      await ref.read(nutritionRepositoryProvider).saveEntry(entry);
      ref.read(dataRevisionProvider.notifier).state++;
    }
  }

  void _showSavedMeals(BuildContext context, dynamic repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SavedMealsSheet(
        repo: repo,
        day: _day,
        onLogged: () => ref.read(dataRevisionProvider.notifier).state++,
      ),
    );
  }

  Future<void> _saveAsMeal(BuildContext context, dynamic repo, String meal,
      List<FoodLogEntry> entries) async {
    if (entries.isEmpty) return;
    final ctrl = TextEditingController(text: meal);
    final name = await showDialog<String>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Save as meal'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Meal name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dlgCtx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;
    final savedMeal = SavedMeal(
      name: name,
      items: entries
          .map((e) =>
              SavedMealItem(food: e.food, amount: e.amount, mealType: e.mealType))
          .toList(),
    );
    await repo.saveMeal(savedMeal);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" saved for quick re-logging')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Fasting tracker card.
// ---------------------------------------------------------------------------

class _FastingCard extends StatefulWidget {
  const _FastingCard({required this.repo, required this.onChanged});
  final NutritionRepository repo;
  final VoidCallback onChanged;

  @override
  State<_FastingCard> createState() => _FastingCardState();
}

class _FastingCardState extends State<_FastingCard> {
  late final Stream<int> _tick =
      Stream.periodic(const Duration(seconds: 30), (i) => i);

  @override
  Widget build(BuildContext context) {
    final isFasting = widget.repo.isFasting;
    final duration = widget.repo.fastDuration;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AppCard(
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty, color: AppColors.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: isFasting
                  ? StreamBuilder<int>(
                      stream: _tick,
                      builder: (_, __) {
                        final d = widget.repo.fastDuration;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fasting',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tertiary)),
                            Text(
                              '${d.inHours}h ${d.inMinutes.remainder(60)}m',
                              style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 13),
                            ),
                          ],
                        );
                      },
                    )
                  : Text('Start a fast',
                      style: TextStyle(color: Theme.of(context).hintColor)),
            ),
            TextButton(
              onPressed: () async {
                if (isFasting) {
                  await widget.repo.endFast();
                } else {
                  await widget.repo.startFast();
                }
                widget.onChanged();
                setState(() {});
              },
              child: Text(isFasting ? 'End fast' : 'Start fast',
                  style: TextStyle(
                      color: isFasting ? AppColors.danger : AppColors.tertiary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved meals bottom sheet.
// ---------------------------------------------------------------------------

class _SavedMealsSheet extends StatelessWidget {
  const _SavedMealsSheet(
      {required this.repo, required this.day, required this.onLogged});
  final NutritionRepository repo;
  final DateTime day;
  final VoidCallback onLogged;

  @override
  Widget build(BuildContext context) {
    final meals = repo.savedMeals();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text('Saved meals',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          if (meals.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No saved meals yet.\nLog a meal, then tap ⋮ → "Save as meal".',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                itemCount: meals.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = meals[i];
                  return ListTile(
                    title: Text(m.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${m.totalCalories.round()} kcal · '
                        '${m.totalProtein.round()}g protein · '
                        '${m.items.length} items'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: AppColors.secondary),
                          onPressed: () async {
                            await repo.logSavedMeal(m, day);
                            onLogged();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.danger, size: 20),
                          onPressed: () async {
                            await repo.deleteSavedMeal(m.id);
                            if (context.mounted) Navigator.pop(context);
                            onLogged();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Water tracker card.
// ---------------------------------------------------------------------------

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.water,
    required this.goalMl,
    required this.onAdd,
    required this.onCustom,
    required this.onReset,
  });
  final WaterLog water;
  final double goalMl;
  final Future<void> Function(double) onAdd;
  final Future<void> Function(double) onCustom;
  final Future<void> Function() onReset;

  Future<void> _showCustomDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ml = await showDialog<double>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Add drink'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            suffixText: 'ml',
            hintText: 'e.g. 330',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dlgCtx, double.tryParse(ctrl.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (ml != null && ml > 0) await onCustom(ml);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (water.milliliters / goalMl).clamp(0.0, 1.0);
    final liters = water.milliliters / 1000;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: AppColors.water),
              const SizedBox(width: 8),
              Text('${liters.toStringAsFixed(1)} L',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
              const Spacer(),
              Text('Goal ${(goalMl / 1000).toStringAsFixed(1)} L',
                  style: TextStyle(color: Theme.of(context).hintColor)),
              if (water.milliliters > 0)
                IconButton(
                  icon: Icon(Icons.refresh,
                      size: 18, color: Theme.of(context).hintColor),
                  tooltip: 'Reset',
                  onPressed: onReset,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: AppColors.water.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.water),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ml in [250.0, 330.0, 500.0, 750.0])
                OutlinedButton(
                  onPressed: () async => onAdd(ml),
                  child: Text('+${ml.round()} ml'),
                ),
              OutlinedButton.icon(
                onPressed: () => _showCustomDialog(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Custom'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meal section.
// ---------------------------------------------------------------------------

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.meal,
    required this.entries,
    required this.onAdd,
    required this.onDelete,
    required this.onSaveMeal,
  });
  final String meal;
  final List<FoodLogEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final ValueChanged<List<FoodLogEntry>> onSaveMeal;

  @override
  Widget build(BuildContext context) {
    final cals =
        entries.fold(0.0, (s, e) => s + e.macros.calories).round();
    return Column(
      children: [
        SectionHeader(
          meal,
          action: Row(
            children: [
              Text('$cals kcal',
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 13)),
              if (entries.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined,
                      size: 20, color: AppColors.tertiary),
                  tooltip: 'Save as meal',
                  onPressed: () => onSaveMeal(entries),
                ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.secondary),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Nothing logged',
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 13)),
            ),
          )
        else
          ...entries.map((e) => Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onDelete(e.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: AppColors.danger,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(e.food.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${Formatters.weight(e.amount)} ${e.food.servingUnit} · '
                      'P${e.macros.protein.round()} C${e.macros.carbs.round()} '
                      'F${e.macros.fat.round()}'),
                  trailing: Text('${e.macros.calories.round()}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              )),
      ],
    );
  }
}
