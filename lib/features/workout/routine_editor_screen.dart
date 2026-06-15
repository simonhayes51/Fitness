import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/routine.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../exercises/exercise_picker.dart';

/// Create or edit a custom routine template.
class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({this.existing, super.key});
  final Routine? existing;

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final List<RoutineExercise> _exercises =
      List.of(widget.existing?.exercises ?? []);
  late String _icon = widget.existing?.icon ?? '🏋️';

  static const _icons = ['🏋️', '💪', '🦵', '🪝', '🔱', '🔥', '⚡', '🏃', '🧘'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New routine' : 'Edit routine'),
        actions: [
          TextButton(
            onPressed: _exercises.isEmpty || _name.text.trim().isEmpty
                ? null
                : _save,
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickIcon,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(_icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'Routine name'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader('Exercises', padding: EdgeInsets.only(bottom: 10)),
          if (_exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text('No exercises added yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ),
          for (int i = 0; i < _exercises.length; i++)
            _exerciseTile(_exercises[i], i),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addExercises,
            icon: const Icon(Icons.add),
            label: const Text('Add exercises'),
          ),
        ],
      ),
    );
  }

  Widget _exerciseTile(RoutineExercise re, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GroupChip(re.muscleGroup, small: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(re.exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _exercises.removeAt(index)),
                ),
              ],
            ),
            Row(
              children: [
                _stepper('Sets', re.targetSets, (v) {
                  setState(() => re.targetSets = v.clamp(1, 10));
                }),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reps: ${re.repRange}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      RangeSlider(
                        values: RangeValues(
                            re.targetRepsLow.toDouble(),
                            re.targetRepsHigh.toDouble()),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        labels: RangeLabels(
                            '${re.targetRepsLow}', '${re.targetRepsHigh}'),
                        onChanged: (v) => setState(() {
                          re.targetRepsLow = v.start.round();
                          re.targetRepsHigh = v.end.round();
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: () => onChanged(value - 1),
            ),
            Text('$value',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addExercises() async {
    final chosen = await ExercisePicker.show(context);
    if (chosen == null) return;
    setState(() {
      for (final e in chosen) {
        _exercises.add(RoutineExercise(
          exerciseId: e.id,
          exerciseName: e.name,
          muscleGroup: e.muscleGroup,
        ));
      }
    });
  }

  void _pickIcon() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _icons
                .map((e) => GestureDetector(
                      onTap: () {
                        setState(() => _icon = e);
                        Navigator.pop(context);
                      },
                      child: Text(e, style: const TextStyle(fontSize: 32)),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final routine = Routine(
      id: widget.existing?.id,
      name: _name.text.trim(),
      icon: _icon,
      exercises: _exercises,
      createdAt: widget.existing?.createdAt,
    );
    await ref.read(routineRepositoryProvider).save(routine);
    ref.read(dataRevisionProvider.notifier).state++;
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
}
