import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';

/// Root application widget. Owns theming, localisation and routing.
class ForgeFitApp extends ConsumerWidget {
  const ForgeFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      // Multi-language support: add ARB files + flutter_localizations delegates.
      // English is the default; locales below are placeholders for v1.1.
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('de'),
        Locale('fr'),
      ],
    );
  }
}
