import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../providers/active_workout_provider.dart';
import 'rest_timer_bar.dart';

/// Shell scaffold hosting the five primary tabs plus a persistent
/// "active workout" resume banner and the rest-timer bar.
class AppScaffold extends ConsumerWidget {
  const AppScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home'),
    (icon: Icons.fitness_center_outlined, active: Icons.fitness_center, label: 'Workout'),
    (icon: Icons.menu_book_outlined, active: Icons.menu_book, label: 'Library'),
    (icon: Icons.restaurant_outlined, active: Icons.restaurant, label: 'Nutrition'),
    (icon: Icons.insights_outlined, active: Icons.insights, label: 'Progress'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RestTimerBar(),
          if (activeWorkout != null) _ResumeWorkoutBanner(name: activeWorkout.name),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.active, color: AppColors.primary),
                  label: d.label,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumeWorkoutBanner extends StatelessWidget {
  const _ResumeWorkoutBanner({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: InkWell(
        onTap: () => context.push('/active-workout'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Workout in progress · $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Text('Resume',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
