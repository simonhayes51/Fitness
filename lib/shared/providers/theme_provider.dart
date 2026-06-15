import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Persisted theme-mode preference (dark by default — ForgeFit is dark-first).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(_load(_ref));
  final Ref _ref;

  static ThemeMode _load(Ref ref) {
    final raw = ref.read(localDbProvider).getSetting<String>('themeMode');
    return switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _ref.read(localDbProvider).setSetting('themeMode', mode.name);
  }

  Future<void> toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
