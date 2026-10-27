/// Service references for project access, independent of worker/crew dates.
class ProjectAccessPeriod {
  final String name;
  final DateTime? start, end;
  final num? workingDays;
  final bool fromEstimate;
  const ProjectAccessPeriod({
    required this.name,
    this.start,
    this.end,
    this.workingDays,
    this.fromEstimate = false,
  });

  static DateTime? date(dynamic raw) {
    final value = DateTime.tryParse(raw?.toString() ?? '');
    return value == null ? null : DateTime(value.year, value.month, value.day);
  }

  static String iso(DateTime? value) =>
      value?.toIso8601String().substring(0, 10) ?? '';

  static List<ProjectAccessPeriod> fromSources({
    required List<Map<String, dynamic>> quoted,
    required List<Map<String, dynamic>> live,
    required List<Map<String, dynamic>> tasks,
  }) {
    final services = <String, Map<String, dynamic>>{};
    for (final row in quoted) {
      services['q:${row['id']}'] = {...row, 'quote_id': row['id']};
    }
    // A live service linked to the estimate is the same service, not a second row.
    for (final row in live) {
      final key = row['quote_service_id'] == null
          ? 'p:${row['id']}'
          : 'q:${row['quote_service_id']}';
      services[key] = {
        ...?services[key],
        'name': row['name'],
        'live_id': row['id'],
        'quote_id': row['quote_service_id'],
      };
    }
    final periods = <ProjectAccessPeriod>[];
    for (final service in services.values) {
      final relation = service['quote_service_estimations'];
      final estimates = relation is List
          ? List<Map<String, dynamic>>.from(relation)
          : relation is Map
          ? [Map<String, dynamic>.from(relation)]
          : <Map<String, dynamic>>[];
      // Match the planning calendar's latest-estimation precedence.
      estimates.sort((a, b) {
        for (final key in ['updated_at', 'created_at', 'id']) {
          final cmp = (b[key]?.toString() ?? '').compareTo(
            a[key]?.toString() ?? '',
          );
          if (cmp != 0) return cmp;
        }
        return 0;
      });
      final estimate = estimates.firstOrNull;
      final matching = tasks.where(
        (t) =>
            (service['live_id'] != null &&
                t['project_service_id'] == service['live_id']) ||
            (service['quote_id'] != null &&
                t['quote_service_id'] == service['quote_id']),
      );
      final starts =
          matching
              .map((t) => date(t['planned_start_date']))
              .whereType<DateTime>()
              .toList()
            ..sort();
      final ends =
          matching
              .map((t) => date(t['planned_end_date']))
              .whereType<DateTime>()
              .toList()
            ..sort();
      periods.add(
        ProjectAccessPeriod(
          name: service['name']?.toString() ?? 'Unnamed service',
          start: estimate != null
              ? date(estimate['start_date'])
              : starts.firstOrNull,
          end: estimate != null ? date(estimate['end_date']) : ends.lastOrNull,
          workingDays: estimate?['total_working_days'] as num?,
          fromEstimate: estimate != null,
        ),
      );
    }
    return periods..sort((a, b) => a.name.compareTo(b.name));
  }

  static DateTime? firstStart(List<ProjectAccessPeriod> periods) {
    final values = periods.map((p) => p.start).whereType<DateTime>().toList()
      ..sort();
    return values.firstOrNull;
  }

  static DateTime? lastEnd(List<ProjectAccessPeriod> periods) {
    final values = periods.map((p) => p.end).whereType<DateTime>().toList()
      ..sort();
    return values.lastOrNull;
  }
}
