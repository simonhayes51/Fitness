import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';
import 'custom_exercise_screen.dart';

/// Searchable, filterable catalogue of 500+ exercises with lazy list rendering.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _search = '';
  String? _group;
  String? _equipment;

  @override
  Widget build(BuildContext context) {
    ref.watch(dataRevisionProvider);
    final repo = ref.watch(exerciseRepositoryProvider);
    final results = repo.query(
      search: _search,
      muscleGroup: _group,
      equipment: _equipment,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            tooltip: 'Create custom exercise',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomExerciseScreen(),
            )),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ${repo.count} exercises…',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', _group == null && _equipment == null, () {
                  setState(() {
                    _group = null;
                    _equipment = null;
                  });
                }),
                for (final g in AppConstants.muscleGroups)
                  _chip(g, _group == g, () => setState(() => _group = _group == g ? null : g)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${results.length} results',
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12.5)),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message: 'Try a different search or filter.')
                : ListView.builder(
                    // Lazy builder keeps large lists performant.
                    itemCount: results.length,
                    itemExtent: 72,
                    itemBuilder: (context, i) =>
                        _ExerciseTile(exercise: results[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
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

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forGroup(exercise.muscleGroup);
    return ListTile(
      onTap: () => context.push('/exercise/${exercise.id}'),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_iconFor(exercise.muscleGroup), color: color, size: 22),
      ),
      title: Text(exercise.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${exercise.muscleGroup} · ${exercise.equipment}',
          style: const TextStyle(fontSize: 12)),
      trailing: exercise.isCustom
          ? const Icon(Icons.person, size: 16, color: AppColors.secondary)
          : const Icon(Icons.chevron_right),
    );
  }

  IconData _iconFor(String group) => switch (group) {
        'Chest' => Icons.accessibility_new,
        'Back' => Icons.airline_seat_flat,
        'Legs' => Icons.directions_walk,
        'Shoulders' => Icons.sports_gymnastics,
        'Arms' => Icons.fitness_center,
        'Core' => Icons.self_improvement,
        'Cardio' => Icons.directions_run,
        _ => Icons.bolt,
      };
}
