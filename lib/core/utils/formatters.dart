import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Display formatting helpers.
class Formatters {
  Formatters._();

  static final _dayFmt = DateFormat('EEE, d MMM');
  static final _fullDateFmt = DateFormat('d MMMM yyyy');
  static final _monthDayFmt = DateFormat('d MMM');
  static final _timeFmt = DateFormat('HH:mm');

  static String day(DateTime d) => _dayFmt.format(d);
  static String fullDate(DateTime d) => _fullDateFmt.format(d);
  static String monthDay(DateTime d) => _monthDayFmt.format(d);
  static String time(DateTime d) => _timeFmt.format(d);

  /// Friendly relative label for recent dates.
  static String relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return '$diff days ago';
    return _dayFmt.format(d);
  }

  /// mm:ss countdown / duration formatting.
  static String duration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  static String seconds(int totalSeconds) =>
      duration(Duration(seconds: totalSeconds));

  /// Trim trailing zeros: 50.0 → "50", 52.5 → "52.5".
  static String weight(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  /// Unit-aware weight string. Converts kg→lbs when [unit] is imperial.
  static String weightWithUnit(double kg, UnitSystem unit) {
    if (unit == UnitSystem.imperial) {
      final lbs = kg * 2.20462;
      return '${weight(lbs)} lbs';
    }
    return '${weight(kg)} kg';
  }

  /// Display a weight value already in the user's unit (no conversion).
  static String weightInUnit(double value, UnitSystem unit) =>
      '${weight(value)} ${unit.weightUnit}';

  static String number(num value) => NumberFormat.decimalPattern().format(value);

  static String calories(num value) => '${number(value.round())} kcal';

  static String grams(num value) => '${weight(value.toDouble())}g';

  static String percent(double fraction) =>
      '${(fraction * 100).clamp(0, 999).round()}%';

  static String sodium(double mg) {
    if (mg >= 1000) return '${weight(mg / 1000)}g';
    return '${mg.round()}mg';
  }
}
