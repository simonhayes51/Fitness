import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/exercises/exercise_detail_screen.dart';
import '../../features/exercises/exercise_library_screen.dart';
import '../../features/nutrition/nutrition_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/workout/active_workout_screen.dart';
import '../../features/workout/workout_home_screen.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

/// Central GoRouter configuration. The bottom-tab shell hosts the five primary
/// destinations; onboarding gates first launch.
final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final onboarded = ref.read(profileProvider).onboarded;
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarded && !atOnboarding) return '/onboarding';
      if (onboarded && atOnboarding) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Bottom-navigation shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            AppScaffold(navigationShell: navShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/workout',
              builder: (context, state) => const WorkoutHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/exercises',
              builder: (context, state) => const ExerciseLibraryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/nutrition',
              builder: (context, state) => const NutritionScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ]),
        ],
      ),

      // Full-screen routes pushed above the shell.
      GoRoute(
        path: '/active-workout',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        path: '/exercise/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
