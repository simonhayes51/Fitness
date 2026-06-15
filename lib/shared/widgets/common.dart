import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A rounded surface card used across the app.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

/// Section header with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.action, this.padding, super.key});
  final String title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Compact labelled stat tile.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    super.key,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? AppColors.primary, size: 22),
            const SizedBox(height: 10),
          ],
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty-state placeholder.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated circular progress ring (used for calories & goals).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.size,
    this.strokeWidth = 10,
    this.color = AppColors.primary,
    this.backgroundColor,
    this.center,
    super.key,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? backgroundColor;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: value,
                color: color,
                strokeWidth: strokeWidth,
                background: backgroundColor ?? Colors.white12,
              ),
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.background,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Muscle-group colour chip used in lists and the library.
class GroupChip extends StatelessWidget {
  const GroupChip(this.group, {this.small = false, super.key});
  final String group;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forGroup(group);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        group,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: small ? 11 : 12.5,
        ),
      ),
    );
  }
}
