import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/theme_provider.dart';

/// App settings: units, appearance, notifications, goals, data export & wipe.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _header('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 18)),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18)),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18)),
              ],
              selected: {themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),

          _header('Units'),
          SwitchListTile(
            secondary: const Icon(Icons.straighten),
            title: const Text('Imperial units'),
            subtitle: Text(profile.unitSystem == UnitSystem.imperial
                ? 'lbs / inches'
                : 'kg / cm'),
            value: profile.unitSystem == UnitSystem.imperial,
            onChanged: (v) => ref.read(profileProvider.notifier).patch(
                  unitSystem: v ? UnitSystem.imperial : UnitSystem.metric,
                ),
          ),

          _header('Goal'),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Fitness goal'),
            subtitle: Text(profile.goal.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickGoal(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.directions_run),
            title: const Text('Activity level'),
            subtitle: Text(profile.activityLevel.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickActivity(context, ref),
          ),

          _header('Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Daily workout reminder'),
            subtitle: const Text('Remind me at 18:00'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await ref.read(notificationServiceProvider).requestPermissions();
              await ref
                  .read(notificationServiceProvider)
                  .scheduleDailyReminder(hour: 18, minute: 0);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Daily reminder scheduled for 18:00')),
                );
              }
            },
          ),

          _header('Data'),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export workouts (CSV)'),
            onTap: () => _share(ref.read(exportServiceProvider).exportWorkoutsCsv(),
                'forgefit_workouts.csv'),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export nutrition (CSV)'),
            onTap: () => _share(ref.read(exportServiceProvider).exportNutritionCsv(),
                'forgefit_nutrition.csv'),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Full backup (JSON)'),
            onTap: () => _share(
                ref.read(exportServiceProvider).exportJson(), 'forgefit_backup.json'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.danger),
            title: const Text('Erase all data',
                style: TextStyle(color: AppColors.danger)),
            onTap: () => _confirmWipe(context, ref),
          ),

          _header('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppConstants.appName),
            subtitle: Text('Version 1.0.0 · ${AppConstants.tagline}'),
          ),
          const ListTile(
            leading: Icon(Icons.cloud_off),
            title: Text('Offline-first'),
            subtitle: Text(
                'Your data lives on-device. Enable Firebase for cloud sync — '
                'see docs/FIREBASE_SETUP.md'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.primary)),
      );

  void _share(String content, String filename) {
    Share.share(content, subject: filename);
  }

  Future<void> _pickGoal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: FitnessGoal.values
              .map((g) => ListTile(
                    title: Text(g.label),
                    onTap: () {
                      ref.read(profileProvider.notifier).patch(goal: g);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _pickActivity(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ActivityLevel.values
              .map((a) => ListTile(
                    title: Text(a.label),
                    subtitle: Text(a.description),
                    onTap: () {
                      ref.read(profileProvider.notifier).patch(activityLevel: a);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text(
            'This permanently deletes all workouts, nutrition logs, body '
            'metrics and goals on this device. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(localDbProvider).wipeAll();
      ref.read(dataRevisionProvider.notifier).state++;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data erased')),
        );
      }
    }
  }
}
