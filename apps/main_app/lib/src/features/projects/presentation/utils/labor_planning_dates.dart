import 'package:noel_core/noel_core.dart';

/// Same working calendar as Resource Planning: Saturday 0.5, Sunday 0,
/// plus project non-working/partial days. Explicit saved dates always win.
class LaborPlanningDates {
  final DateTime? start, end;
  const LaborPlanningDates(this.start, this.end);
  static List<Map<String, dynamic>> coverageRoles(
    List<Map<String, dynamic>> roles,
    Map<String, double> calendar,
  ) {
    final starts =
        roles
            .map((r) => date(r['reference_start']))
            .whereType<DateTime>()
            .toList()
          ..sort();
    final ends =
        roles
            .map((r) => date(r['reference_end']))
            .whereType<DateTime>()
            .toList()
          ..sort();
    if (starts.isEmpty ||
        ends.isEmpty ||
        ends.last.isBefore(starts.first) ||
        ends.last.difference(starts.first).inDays > 36600)
      return roles;
    final start = starts.first, end = ends.last;
    var days = 0.0;
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      days += getWorkingDayContribution(day, calendar);
    }
    return roles
        .map(
          (r) => r['coverage_scope'] == 'project'
              ? <String, dynamic>{
                  ...r,
                  'reference_start': iso(start),
                  'reference_end': iso(end),
                  'reference_service_name': 'Cobertura del proyecto',
                  'reference_source': 'project_span',
                  'working_days': days,
                }
              : r,
        )
        .toList();
  }

  static DateTime? date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
  static String iso(DateTime? value) =>
      value?.toIso8601String().substring(0, 10) ?? '';

  static DateTime? endFor(
    DateTime start,
    num? days,
    Map<String, double> calendar,
  ) {
    if (days == null || !days.isFinite || days <= 0) return null;
    var current = DateTime(start.year, start.month, start.day);
    var remaining = days.toDouble();
    // Bounded for malformed legacy estimates/calendars; never hang the form.
    for (var i = 0; i < 36600; i++) {
      final contribution = getWorkingDayContribution(current, calendar);
      if (contribution > 0) {
        remaining -= contribution;
        if (remaining <= 0.0000001) return current;
      }
      current = current.add(const Duration(days: 1));
    }
    return null;
  }

  factory LaborPlanningDates.propose(
    Map<String, dynamic> role,
    Map<String, double> calendar,
  ) {
    final savedStart = date(role['start_date']),
        savedEnd = date(role['end_date']);
    final referenceStart = date(role['reference_start']),
        referenceEnd = date(role['reference_end']);
    final start = savedStart ?? referenceStart;
    if (start == null) {
      return LaborPlanningDates(null, savedEnd ?? referenceEnd);
    }
    // An explicitly shifted role start needs a correspondingly shifted end.
    var end = savedEnd;
    if (end == null && (savedStart == null || savedStart == referenceStart)) {
      end = referenceEnd;
    }
    end ??= endFor(start, role['working_days'] as num?, calendar);
    // A partial reference may still supply a valid end when no duration exists.
    end ??= referenceEnd != null && !referenceEnd.isBefore(start)
        ? referenceEnd
        : null;
    return LaborPlanningDates(start, end);
  }
}
