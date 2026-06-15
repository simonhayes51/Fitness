import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/routine.dart';
import '../../data/models/workout.dart';
import '../../shared/providers/active_workout_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/widgets/common.dart';
import 'routine_editor_screen.dart';
import 'workout_edit_screen.dart';

/// Workout hub: start an empty session, launch a routine template, browse
/// recent history.
class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataRevisionProvider);
    final routines = ref.watch(routineRepositoryProvider).getAll();
    final history = ref.watch(workoutRepositoryProvider).getCompleted();

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startEmpty(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Start',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          SectionHeader(
            'Routines',
            action: TextButton.icon(
              onPressed: () => _newRoutine(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: routines.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _RoutineCard(
                routine: routines[i],
                onStart: () => _startRoutine(context, ref, routines[i]),
                onEdit: () => _editRoutine(context, routines[i]),
              ),
            ),
          ),
          SectionHeader('History (${history.length})'),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.history,
                title: 'No workouts yet',
                message: 'Start a session and it will appear here with full '
                    'stats and personal records.',
              ),
            )
          else
            ...history.take(25).map((w) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _HistoryCard(
                    workout: w,
                    onRepeat: () => _repeatWorkout(context, ref, w),
                    onDelete: () => _deleteWorkout(context, ref, w),
                    onEdit: () => _editWorkout(context, ref, w),
                  ),
                )),
        ],
      ),
    );
  }

  void _startEmpty(BuildContext context, WidgetRef ref) {
    ref.read(activeWorkoutProvider.notifier).startEmpty();
    context.push('/active-workout');
  }

  void _startRoutine(BuildContext context, WidgetRef ref, Routine r) {
    ref.read(activeWorkoutProvider.notifier).startFromRoutine(r);
    context.push('/active-workout');
  }

  void _newRoutine(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const RoutineEditorScreen(),
    ));
  }

  void _editRoutine(BuildContext context, Routine r) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RoutineEditorScreen(existing: r),
    ));
  }

  void _repeatWorkout(BuildContext context, WidgetRef ref, Workout w) {
    ref.read(activeWorkoutProvider.notifier).startFromWorkoutHistory(w);
    context.push('/active-workout');
  }

  Future<void> _deleteWorkout(
      BuildContext context, WidgetRef ref, Workout w) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: Text(
            'This will permanently remove "${w.name}" from your history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(workoutRepositoryProvider).delete(w.id);
    ref.read(dataRevisionProvider.notifier).state++;
  }

  Future<void> _editWorkout(
      BuildContext context, WidgetRef ref, Workout w) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WorkoutEditScreen(workout: w),
    ));
    ref.read(dataRevisionProvider.notifier).state++;
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.onStart,
    required this.onEdit,
  });
  final Routine routine;
  final VoidCallback onStart;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: AppCard(
        onTap: onStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(routine.icon, style: const TextStyle(fontSize: 26)),
                const Spacer(),
                if (!routine.isPreset)
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: Theme.of(context).hintColor),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(routine.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(
              '${routine.exerciseCount} exercises · ${routine.totalSets} sets',
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12.5),
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: routine.muscleGroups
                  .take(3)
                  .map((g) => GroupChip(g, small: true))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.workout,
    required this.onRepeat,
    required this.onDelete,
    required this.onEdit,
  });
  final Workout workout;
  final VoidCallback onRepeat;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(workout.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Text(Formatters.relativeDay(workout.completedAt ?? workout.startedAt),
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(context, Icons.timer_outlined,
                  Formatters.duration(workout.duration)),
              _stat(context, Icons.fitness_center,
                  '${workout.totalSets} sets'),
              _stat(context, Icons.bar_chart,
                  '${Formatters.number(workout.totalVolume.round())} vol'),
            ],
          ),
          if (workout.exercises.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              workout.exercises.map((e) => e.exerciseName).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onRepeat,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
                icon: const Icon(Icons.replay, size: 16),
                label: const Text('Repeat', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger)),
                child: const Icon(Icons.delete_outline, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
