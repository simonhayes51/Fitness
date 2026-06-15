import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// State for the auto rest-timer countdown shown after completing a set.
class RestTimerState {
  const RestTimerState({
    this.totalSeconds = 0,
    this.remaining = 0,
    this.running = false,
  });

  final int totalSeconds;
  final int remaining;
  final bool running;

  double get progress =>
      totalSeconds == 0 ? 0 : 1 - (remaining / totalSeconds);

  bool get isActive => running && remaining > 0;

  RestTimerState copyWith({int? totalSeconds, int? remaining, bool? running}) =>
      RestTimerState(
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remaining: remaining ?? this.remaining,
        running: running ?? this.running,
      );
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier(this._ref) : super(const RestTimerState());
  final Ref _ref;
  Timer? _timer;

  void start(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remaining: seconds,
      running: true,
    );
    // Schedule a local notification so the alert fires even if the app is
    // backgrounded.
    _ref.read(notificationServiceProvider).scheduleRestComplete(seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.remaining - 1;
      if (next <= 0) {
        t.cancel();
        state = state.copyWith(remaining: 0, running: false);
      } else {
        state = state.copyWith(remaining: next);
      }
    });
  }

  void addTime(int seconds) {
    if (!state.running) return;
    state = state.copyWith(
      totalSeconds: state.totalSeconds + seconds,
      remaining: state.remaining + seconds,
    );
  }

  void skip() {
    _timer?.cancel();
    _ref.read(notificationServiceProvider).cancelRestTimer();
    state = const RestTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>(
        RestTimerNotifier.new);
