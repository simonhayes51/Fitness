import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/rest_timer_provider.dart';

/// Slim animated bar that surfaces the active rest-timer countdown above the
/// bottom navigation. Hidden when no timer is running.
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);
    if (!timer.isActive) return const SizedBox.shrink();

    final controller = ref.read(restTimerProvider.notifier);

    return Material(
      color: AppColors.darkSurfaceVariant,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: timer.progress,
            minHeight: 3,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.timer, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rest · ${Formatters.seconds(timer.remaining)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                _MiniButton(label: '+30s', onTap: () => controller.addTime(30)),
                const SizedBox(width: 8),
                _MiniButton(label: 'Skip', onTap: controller.skip, filled: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap, this.filled = false});
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.black : AppColors.secondary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
