import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/workout.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Full editor for a completed historical workout.
/// Allows renaming, editing set values, adding/removing sets and exercises.
class WorkoutEditScreen extends ConsumerStatefulWidget {
  const WorkoutEditScreen({super.key, required this.workout});
  final Workout workout;

  @override
  ConsumerState<WorkoutEditScreen> createState() => _WorkoutEditScreenState();
}

class _WorkoutEditScreenState extends ConsumerState<WorkoutEditScreen> {
  late Workout _workout;
  late TextEditingController _nameCtrl;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    // Deep copy via serialisation so edits don't affect the original object.
    _workout = Workout.fromMap(widget.workout.toMap());
    _nameCtrl = TextEditingController(text: _workout.name);
    _nameCtrl.addListener(() {
      if (_nameCtrl.text != _workout.name) setState(() => _dirty = true);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _workout.name = _nameCtrl.text.trim().isEmpty ? 'Workout' : _nameCtrl.text.trim();
    await ref.read(workoutRepositoryProvider).save(_workout);
    ref.read(dataRevisionProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop();
  }

  void _markDirty() => setState(() => _dirty = true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit workout'),
        actions: [
          TextButton(
            onPressed: _dirty ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _dirty ? AppColors.success : Theme.of(context).hintColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Workout name.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Workout name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Date / duration row.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 6),
                Text(
                  Formatters.relativeDay(
                      _workout.completedAt ?? _workout.startedAt),
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer_outlined,
                    size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 6),
                Text(
                  Formatters.duration(_workout.duration),
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exercises.
          for (int ei = 0; ei < _workout.exercises.length; ei++)
            _ExerciseEditor(
              key: ValueKey(_workout.exercises[ei].id),
              exercise: _workout.exercises[ei],
              onChanged: _markDirty,
              onRemove: () => setState(() {
                _workout.exercises.removeAt(ei);
                _dirty = true;
              }),
            ),
        ],
      ),
    );
  }
}

class _ExerciseEditor extends StatelessWidget {
  const _ExerciseEditor({
    super.key,
    required this.exercise,
    required this.onChanged,
    required this.onRemove,
  });
  final WorkoutExercise exercise;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.exerciseName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(exercise.muscleGroup,
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.danger),
                  tooltip: 'Remove exercise',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dlgCtx) => AlertDialog(
                        title: const Text('Remove exercise?'),
                        content: Text(
                            'Remove "${exercise.exerciseName}" from this workout?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(dlgCtx, false),
                              child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.danger),
                            onPressed: () => Navigator.pop(dlgCtx, true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) onRemove();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Set header.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                      width: 32,
                      child: Text('#',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12))),
                  Expanded(
                      child: Text('Weight (kg)',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12))),
                  Expanded(
                      child: Text('Reps',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12))),
                  SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Sets.
            for (int si = 0; si < exercise.sets.length; si++)
              _SetRow(
                key: ValueKey(exercise.sets[si].id),
                index: si,
                set: exercise.sets[si],
                onChanged: onChanged,
                onDelete: () {
                  exercise.sets.removeAt(si);
                  onChanged();
                },
              ),

            // Add set button.
            TextButton.icon(
              onPressed: () {
                final last = exercise.sets.isNotEmpty
                    ? exercise.sets.last
                    : null;
                exercise.sets.add(SetEntry(
                  weight: last?.weight ?? 0,
                  reps: last?.reps ?? 0,
                  completed: true,
                ));
                onChanged();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add set'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  const _SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.onChanged,
    required this.onDelete,
  });
  final int index;
  final SetEntry set;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
        text: widget.set.weight == 0
            ? ''
            : Formatters.weight(widget.set.weight));
    _repsCtrl = TextEditingController(
        text: widget.set.reps == 0 ? '' : '${widget.set.reps}');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _commitWeight(String v) {
    final parsed = double.tryParse(v);
    if (parsed != null) {
      widget.set.weight = parsed;
      widget.onChanged();
    }
  }

  void _commitReps(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null) {
      widget.set.reps = parsed;
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${widget.index + 1}',
                style: TextStyle(
                    color: Theme.of(context).hintColor, fontSize: 13)),
          ),
          Expanded(
            child: _NumField(
              controller: _weightCtrl,
              decimal: true,
              onSubmitted: _commitWeight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumField(
              controller: _repsCtrl,
              decimal: false,
              onSubmitted: _commitReps,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.danger,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: widget.onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.decimal,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final bool decimal;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'[\d.]') : RegExp(r'\d')),
      ],
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(),
      ),
      onChanged: onSubmitted,
      onSubmitted: onSubmitted,
    );
  }
}
