import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/workout.dart';
import '../../shared/providers/active_workout_provider.dart';
import '../../shared/providers/rest_timer_provider.dart';
import '../../shared/widgets/common.dart';
import '../exercises/exercise_picker.dart';

/// The live workout logger — the most-used screen during training. Large tap
/// targets, fast set entry, set-type cycling, supersets and an auto rest timer.
class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    final controller = ref.read(activeWorkoutProvider.notifier);

    if (workout == null) {
      // The session was finished/discarded; navigation is handled explicitly by
      // _finish / _confirmExit, so just render a neutral frame for the moment
      // between state clearing and the route being popped.
      return const Scaffold(body: SizedBox.shrink());
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _confirmExit(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => context.pop(),
          ),
          title: _ElapsedTitle(startedAt: workout.startedAt),
          actions: [
            TextButton(
              onPressed: () => _finish(context, ref),
              child: const Text('Finish',
                  style: TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _summaryStat('${workout.totalSets}', 'sets'),
                  _summaryStat(
                      Formatters.number(workout.totalVolume.round()), 'volume'),
                  _summaryStat('${workout.exercises.length}', 'exercises'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final ex in workout.exercises)
              _ExerciseBlock(
                key: ValueKey(ex.id),
                workout: workout,
                exercise: ex,
                controller: controller,
                onRest: () =>
                    ref.read(restTimerProvider.notifier).start(ex.restSeconds),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _addExercise(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add exercise'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final chosen = await ExercisePicker.show(context);
    if (chosen == null) return;
    for (final e in chosen) {
      ref.read(activeWorkoutProvider.notifier).addExercise(e);
    }
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final workout = await ref.read(activeWorkoutProvider.notifier).finish();
    ref.read(restTimerProvider.notifier).skip();
    if (context.mounted) {
      context.pop();
      if (workout != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Workout saved · ${workout.totalSets} sets · '
                '${Formatters.number(workout.totalVolume.round())} volume'),
          ),
        );
      }
    }
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.minimize),
              title: const Text('Minimise (keep training)'),
              subtitle: const Text('Resume from the banner anytime'),
              onTap: () {
                Navigator.pop(context);
                context.pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Discard workout',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () {
                ref.read(activeWorkoutProvider.notifier).discard();
                ref.read(restTimerProvider.notifier).skip();
                Navigator.pop(context);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()])),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ElapsedTitle extends StatefulWidget {
  const _ElapsedTitle({required this.startedAt});
  final DateTime startedAt;

  @override
  State<_ElapsedTitle> createState() => _ElapsedTitleState();
}

class _ElapsedTitleState extends State<_ElapsedTitle> {
  late final Stream<int> _tick =
      Stream.periodic(const Duration(seconds: 1), (i) => i);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _tick,
      builder: (context, _) {
        final elapsed = DateTime.now().difference(widget.startedAt);
        return Text(Formatters.duration(elapsed),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()]));
      },
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({
    required this.workout,
    required this.exercise,
    required this.controller,
    required this.onRest,
    super.key,
  });

  final Workout workout;
  final WorkoutExercise exercise;
  final ActiveWorkoutNotifier controller;
  final VoidCallback onRest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (exercise.supersetGroup != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('SS${exercise.supersetGroup}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tertiary)),
                  ),
                Expanded(
                  child: Text(exercise.exerciseName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (v) {
                    switch (v) {
                      case 'rest':
                        _editRest(context);
                      case 'superset':
                        controller.toggleSuperset(exercise.id);
                      case 'remove':
                        controller.removeExercise(exercise.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'rest', child: Text('Rest time…')),
                    const PopupMenuItem(
                        value: 'superset', child: Text('Toggle superset')),
                    const PopupMenuItem(
                        value: 'remove', child: Text('Remove exercise')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Header row.
            const _SetHeaderRow(),
            for (int i = 0; i < exercise.sets.length; i++)
              _SetRow(
                index: i + 1,
                set: exercise.sets[i],
                onChanged: (weight, reps, rpe, done) => controller.updateSet(
                  exercise.id,
                  exercise.sets[i].id,
                  weight: weight,
                  reps: reps,
                  rpe: rpe,
                  completed: done,
                ),
                onComplete: (done) {
                  controller.updateSet(exercise.id, exercise.sets[i].id,
                      completed: done);
                  if (done) onRest();
                },
                onCycleType: () =>
                    controller.cycleSetType(exercise.id, exercise.sets[i].id),
                onDelete: () =>
                    controller.removeSet(exercise.id, exercise.sets[i].id),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.addSet(exercise.id),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42)),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add set'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onRest,
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(Formatters.seconds(exercise.restSeconds)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editRest(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [60, 90, 120, 150, 180, 240]
              .map((s) => ListTile(
                    title: Text(Formatters.seconds(s)),
                    onTap: () {
                      exercise.restSeconds = s;
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _SetHeaderRow extends StatelessWidget {
  const _SetHeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).hintColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('SET', style: style)),
          Expanded(child: Text('WEIGHT', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text('REPS', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text('RPE', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.onChanged,
    required this.onComplete,
    required this.onCycleType,
    required this.onDelete,
  });

  final int index;
  final SetEntry set;
  final void Function(double? weight, int? reps, double? rpe, bool? done)
      onChanged;
  final ValueChanged<bool> onComplete;
  final VoidCallback onCycleType;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final badge = set.type.badge;
    final badgeColor = switch (set.type) {
      SetType.warmup => AppColors.warning,
      SetType.dropset => AppColors.info,
      SetType.failure => AppColors.danger,
      SetType.normal => AppColors.primary,
    };

    return Dismissible(
      key: ValueKey('set-${set.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: set.completed
              ? AppColors.success.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: GestureDetector(
                onTap: onCycleType,
                child: badge.isEmpty
                    ? Text('$index',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700))
                    : Text(badge,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w900, color: badgeColor)),
              ),
            ),
            Expanded(
              child: _NumField(
                value: set.weight == 0 ? '' : Formatters.weight(set.weight),
                hint: '0',
                onChanged: (v) => onChanged(double.tryParse(v) ?? 0, null, null, null),
              ),
            ),
            Expanded(
              child: _NumField(
                value: set.reps == 0 ? '' : '${set.reps}',
                hint: '0',
                onChanged: (v) => onChanged(null, int.tryParse(v) ?? 0, null, null),
              ),
            ),
            Expanded(
              child: _NumField(
                value: set.rpe == null ? '' : Formatters.weight(set.rpe!),
                hint: '–',
                onChanged: (v) => onChanged(null, null, double.tryParse(v), null),
              ),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: Icon(
                  set.completed
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: set.completed ? AppColors.success : null,
                ),
                onPressed: () => onComplete(!set.completed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numeric entry that owns its controller so it never loses focus when the
/// parent rebuilds (which happens on every set mutation). External changes are
/// only synced in while the field isn't being edited.
class _NumField extends StatefulWidget {
  const _NumField({
    required this.value,
    required this.hint,
    required this.onChanged,
  });
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(_NumField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          hintText: widget.hint,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }
}
