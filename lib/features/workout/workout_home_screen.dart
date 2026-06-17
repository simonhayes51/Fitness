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
      appBar: AppBar(
        title: const Text('Train'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Exercise Library',
            onPressed: () => context.push('/exercises'),
          ),
        ],
      ),
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
          const SectionHeader('Training Calendar'),
          _WorkoutCalendar(workouts: ref.watch(workoutRepositoryProvider)),
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

class _WorkoutCalendar extends StatefulWidget {
  const _WorkoutCalendar({required this.workouts});
  final WorkoutRepository workouts;

  @override
  State<_WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<_WorkoutCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _prev() => setState(
      () => _month = DateTime(_month.year, _month.month - 1, 1));

  void _next() => setState(
      () => _month = DateTime(_month.year, _month.month + 1, 1));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth =
        DateUtils.getDaysInMonth(_month.year, _month.month);
    final startPad =
        DateTime(_month.year, _month.month, 1).weekday - 1; // Mon=0
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    final trainingDays = <int>{};
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_month.year, _month.month, d);
      if (widget.workouts.workoutsForDay(day).isNotEmpty) {
        trainingDays.add(d);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: AppCard(
        child: Column(
          children: [
            // Month navigation header.
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prev,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: Text(
                    '${_monthName(_month.month)} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right,
                      color: isCurrentMonth ? Colors.grey : null),
                  onPressed: isCurrentMonth ? null : _next,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Weekday labels.
            Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => Expanded(
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Day grid.
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
              ),
              itemCount: startPad + daysInMonth,
              itemBuilder: (context, i) {
                if (i < startPad) return const SizedBox.shrink();
                final day = i - startPad + 1;
                final hasWorkout = trainingDays.contains(day);
                final isToday = isCurrentMonth && day == now.day;
                final isFuture = isCurrentMonth && day > now.day;

                return Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasWorkout
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primary.withOpacity(0.20)
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: hasWorkout
                              ? FontWeight.w800
                              : FontWeight.w400,
                          color: hasWorkout
                              ? Colors.black
                              : isFuture
                                  ? Colors.grey.withOpacity(0.35)
                                  : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            // Legend.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Workout day',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _monthName(int month) => _months[month - 1];
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
