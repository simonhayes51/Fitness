import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A dated body-composition snapshot: weight plus optional measurements.
class BodyMetric {
  BodyMetric({
    String? id,
    DateTime? date,
    required this.weightKg,
    this.bodyFatPct,
    this.measurements = const {},
    this.notes = '',
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  final String id;
  final DateTime date;
  double weightKg;
  double? bodyFatPct;

  /// Tape measurements in cm keyed by site: chest, waist, hips, arms, thighs…
  Map<String, double> measurements;
  String notes;

  String get dayKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  factory BodyMetric.fromMap(Map<dynamic, dynamic> m) => BodyMetric(
        id: m['id'] as String?,
        date: DateTime.parse(m['date'] as String),
        weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0,
        bodyFatPct: (m['bodyFatPct'] as num?)?.toDouble(),
        measurements: ((m['measurements'] as Map?) ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
        notes: m['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'bodyFatPct': bodyFatPct,
        'measurements': measurements,
        'notes': notes,
      };
}
