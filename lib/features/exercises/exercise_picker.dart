import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/exercise.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Modal bottom sheet for searching and selecting one or more exercises.
/// Returns the chosen [Exercise]s (multi-select) to the caller.
class ExercisePicker extends ConsumerStatefulWidget {
  const ExercisePicker({this.multiSelect = true, super.key});
  final bool multiSelect;

  static Future<List<Exercise>?> show(BuildContext context,
      {bool multiSelect = true}) {
    return showModalBottomSheet<List<Exercise>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ExercisePicker(multiSelect: multiSelect),
    );
  }

  @override
  ConsumerState<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<ExercisePicker> {
  String _search = '';
  String? _group;
  final _selected = <Exercise>[];

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(exerciseRepositoryProvider);
    final results = repo.query(search: _search, muscleGroup: _group);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Add exercise',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                if (widget.multiSelect && _selected.isNotEmpty)
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text('Add ${_selected.length}'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Search 500+ exercises…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _filterChip('All', _group == null, () => setState(() => _group = null)),
                for (final g in AppConstants.muscleGroups)
                  _filterChip(g, _group == g, () => setState(() => _group = g)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: results.length,
              itemBuilder: (context, i) {
                final ex = results[i];
                final selected = _selected.any((e) => e.id == ex.id);
                return ListTile(
                  onTap: () => _onTap(ex),
                  leading: GroupChip(ex.muscleGroup, small: true),
                  title: Text(ex.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${ex.equipment} · ${ex.level}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: widget.multiSelect
                      ? Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: selected ? Colors.green : null,
                        )
                      : const Icon(Icons.chevron_right),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(Exercise ex) {
    if (!widget.multiSelect) {
      Navigator.pop(context, [ex]);
      return;
    }
    setState(() {
      if (_selected.any((e) => e.id == ex.id)) {
        _selected.removeWhere((e) => e.id == ex.id);
      } else {
        _selected.add(ex);
      }
    });
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
