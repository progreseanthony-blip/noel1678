import 'package:flutter/material.dart';
import 'labor_planning_dates.dart';

class MachineryPlanningDates {
  final DateTime? start, end;
  const MachineryPlanningDates(this.start, this.end);

  factory MachineryPlanningDates.propose(
    Map<String, dynamic> machinery, {
    DateTime? referenceStart,
    DateTime? referenceEnd,
    num? workingDays,
    Map<String, double> calendar = const {},
  }) {
    DateTime? day(dynamic value) {
      final d = LaborPlanningDates.date(value);
      return d == null ? null : DateTime(d.year, d.month, d.day);
    }

    referenceStart = day(referenceStart);
    referenceEnd = day(referenceEnd);
    final assignments =
        (machinery['project_machinery_assignments'] as List? ?? []);
    final starts =
        assignments
            .map((a) => day(a['start_date']))
            .whereType<DateTime>()
            .toList()
          ..sort();
    final ends =
        assignments
            .map((a) => day(a['end_date']))
            .whereType<DateTime>()
            .toList()
          ..sort();
    final start =
        starts.firstOrNull ?? day(machinery['start_date']) ?? referenceStart;
    var end = ends.lastOrNull ?? day(machinery['end_date']);
    if (end == null && start != null) {
      end = start == referenceStart ? referenceEnd : null;
      end ??= LaborPlanningDates.endFor(start, workingDays, calendar);
      if (end == null && referenceEnd != null && !referenceEnd.isBefore(start))
        end = referenceEnd;
    }
    return MachineryPlanningDates(start, end);
  }

  static DateTimeRange? common(List<MachineryPlanningDates> periods) {
    if (periods.isEmpty || periods.any((p) => p.start == null || p.end == null))
      return null;
    final first = periods.first;
    if (first.end!.isBefore(first.start!) ||
        periods.any((p) => p.start != first.start || p.end != first.end))
      return null;
    return DateTimeRange(start: first.start!, end: first.end!);
  }

  static int missingUnits(Map<String, dynamic> machinery) {
    final expected = (machinery['expected_quantity'] as num?)?.toInt() ?? 0;
    final planned = (machinery['project_machinery_assignments'] as List? ?? [])
        .fold<int>(
          0,
          (sum, a) => sum + ((a['quantity'] as num?)?.toInt() ?? 1),
        );
    return (expected - planned).clamp(0, expected < 0 ? 0 : expected);
  }
}
