List<Map<String, dynamic>> withBorrowedWorkers(
  List<Map<String, dynamic>> planned,
  List<Map<String, dynamic>> workers,
  List<Map<String, dynamic>> transfers,
  String crew,
  String day,
) {
  return planned.map((row) {
    final assignments = (row['project_labor_assignments'] as List? ?? [])
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList();
    for (final loan in transfers) {
      if (loan['status'] != 'approved' ||
          loan['to_crew_id'] != crew ||
          loan['project_labor_id'] != row['id'])
        continue;
      if (assignments.any((a) => a['worker_id'] == loan['worker_id'])) continue;
      final matching = workers.where((w) => w['id'] == loan['worker_id']);
      if (matching.isEmpty) continue;
      assignments.add({
        'worker_id': loan['worker_id'],
        'workers': matching.first,
        'start_date': day,
        'end_date': day,
        'temporary': true,
      });
    }
    return {...row, 'project_labor_assignments': assignments};
  }).toList();
}

int timeMinutes(String time) {
  final p = time.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

Map<String, dynamic> newLaborSegment({
  required String id,
  required String worker,
  required String labor,
  required String start,
  required String end,
  required String reason,
  String? transfer,
}) {
  final elapsed = timeMinutes(end) - timeMinutes(start);
  if (elapsed <= 0)
    throw ArgumentError('The end time must be after the start time.');
  final pause = elapsed >= 360 ? 30 : 0;
  final net = (elapsed - pause) / 60;
  return {
    'id': id,
    'worker_id': worker,
    'project_labor_id': labor,
    'check_in_time': start,
    'check_out_time': end,
    'break_minutes': pause,
    'break_mode': 'auto_daily',
    'total_net_hours': net,
    'regular_hours': net.clamp(0.0, 8.0),
    'overtime_hours': (net - 8).clamp(0.0, double.infinity),
    'is_unplanned': false,
    'is_standby': false,
    'notes': reason,
    'transfer_id': transfer,
  };
}

/// Proposes one automatic deduction per worker/day. The save RPC applies the
/// same rule under a worker/day lock; saved/manual historical rows stay fixed.
void reconcileAutomaticLaborBreaks(
  List<Map<String, dynamic>> entries, [
  Map<String, dynamic> outside = const {},
]) {
  for (final worker in entries.map((e) => e['worker_id']).toSet()) {
    final rows = entries.where((e) => e['worker_id'] == worker).toList();
    double span(Map<String, dynamic> row) {
      if (row['is_standby'] == true ||
          row['check_in_time'] == null ||
          row['check_out_time'] == null)
        return 0;
      return (timeMinutes(row['check_out_time']) -
              timeMinutes(row['check_in_time']))
          .clamp(0, 1440)
          .toDouble();
    }

    final context = outside[worker] as Map? ?? {};
    final elapsed =
        rows.fold(0.0, (sum, e) => sum + span(e)) +
        (context['elapsed_minutes'] as num? ?? 0);
    final fixed = rows
        .where((e) => e['break_mode'] != 'auto_daily')
        .fold(0.0, (sum, e) => sum + (e['break_minutes'] as num? ?? 0));
    var remaining =
        ((elapsed >= 360 ? 30.0 : 0.0) -
                fixed -
                (context['fixed_break'] as num? ?? 0) -
                (context['auto_break'] as num? ?? 0))
            .clamp(0.0, 30.0);
    final automatic =
        rows
            .where(
              (e) => e['break_mode'] == 'auto_daily' && e['is_standby'] != true,
            )
            .toList()
          ..sort((a, b) {
            final time = (a['check_in_time'] as String? ?? '').compareTo(
              b['check_in_time'] as String? ?? '',
            );
            return time != 0
                ? time
                : (a['id'] as String? ?? '').compareTo(
                    b['id'] as String? ?? '',
                  );
          });
    for (final row in automatic) {
      final elapsed = span(row);
      final pause = remaining.clamp(0.0, elapsed).floor();
      remaining -= pause;
      final net = (elapsed - pause) / 60;
      row['break_minutes'] = pause;
      row['total_net_hours'] = net;
      row['regular_hours'] = net.clamp(0.0, 8.0);
      row['overtime_hours'] = (net - 8).clamp(0.0, double.infinity);
    }
  }
}

bool overlapsSegment(
  Map<String, dynamic> row,
  String worker,
  String start,
  String end,
) {
  if (row['worker_id'] != worker || row['check_in_time'] == null) return false;
  return timeMinutes(row['check_in_time'] as String) < timeMinutes(end) &&
      (row['check_out_time'] == null
              ? 1440
              : timeMinutes(row['check_out_time'] as String)) >
          timeMinutes(start);
}
