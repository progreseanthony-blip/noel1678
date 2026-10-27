import 'package:noel_data/noel_data.dart';

/// Mirrors slot selection for early feedback. The server still validates and
/// locks the complete batch; this snapshot cannot guarantee live availability.
class LaborPlanningAvailability {
  final List<Map<String, dynamic>> labor, assignments;
  LaborPlanningAvailability(this.labor, this.assignments);
  static bool overlaps(String from, String until, dynamic a, dynamic b) =>
      (a == null || a.toString().compareTo(until) <= 0) &&
      (b == null || b.toString().compareTo(from) >= 0);
  List<Map<String, dynamic>> slots(String id) {
    final source = labor.where((l) => l['id'] == id).firstOrNull;
    if (source == null) return [];
    return labor
        .where(
          (l) =>
              l['service_key'] == source['service_key'] &&
              l['role_name'] == source['role_name'] &&
              (l['operational_role'] ?? 'none') ==
                  (source['operational_role'] ?? 'none') &&
              (l['coverage_scope'] ?? 'service') ==
                  (source['coverage_scope'] ?? 'service') &&
              l['team_resource_id'] == source['team_resource_id'],
        )
        .toList()
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  }

  List<Map<String, dynamic>> registered(String id) {
    final ids = slots(id).map((l) => l['id']).toSet();
    return assignments
        .where((a) => ids.contains(a['project_labor_id']))
        .toList();
  }

  int registeredSlots(String id) =>
      registered(id).map((a) => a['project_labor_id']).toSet().length;

  List<Map<String, dynamic>> occupants(String id, String from, String until) {
    final ids = slots(id).map((l) => l['id']).toSet();
    return assignments
        .where(
          (a) =>
              ids.contains(a['project_labor_id']) &&
              overlaps(from, until, a['start_date'], a['end_date']),
        )
        .toList();
  }

  int available(String id, String from, String until) => slots(id)
      .where(
        (l) => !assignments.any(
          (a) =>
              a['project_labor_id'] == l['id'] &&
              overlaps(from, until, a['start_date'], a['end_date']),
        ),
      )
      .length;
  String? validate(List<Map<String, dynamic>> requests) {
    final allocations = assignments
        .map((a) => Map<String, dynamic>.from(a))
        .toList();
    for (final r in requests.where((r) => r['assignment_id'] == null)) {
      final id = r['project_labor_id'] as String;
      final from = r['valid_from'] as String,
          until = r['valid_until'] as String;
      if (allocations.any(
        (a) =>
            a['worker_id'] == r['worker_id'] &&
            overlaps(from, until, a['start_date'], a['end_date']),
      )) {
        return '${r['worker_name'] ?? 'The worker'} already has an assignment in this project during $from → $until. Review Personnel or choose another period.';
      }
      final chosen = slots(id)
          .where(
            (l) => !allocations.any(
              (a) =>
                  a['project_labor_id'] == l['id'] &&
                  (a['worker_id'] == r['worker_id'] ||
                      overlaps(from, until, a['start_date'], a['end_date'])),
            ),
          )
          .firstOrNull;
      if (chosen == null) {
        final role =
            labor.where((l) => l['id'] == id).firstOrNull?['role_name'] ??
            'this trade';
        final busy = occupants(id, from, until)
            .map(
              (a) =>
                  '${a['worker_name'] ?? 'Assigned worker'} (${a['start_date'] ?? 'No start'} → ${a['end_date'] ?? 'No end'})',
            )
            .join(', ');
        return 'No positions are available for $role for $from → $until.${busy.isEmpty ? ' The selection exceeds the available positions for this period.' : ' Assigned: $busy.'} Review Personnel to adjust existing assignments or choose another period.';
      }
      allocations.add({
        'project_labor_id': chosen['id'],
        'worker_id': r['worker_id'],
        'worker_name': r['worker_name'],
        'start_date': from,
        'end_date': until,
      });
    }
    return null;
  }
}

String laborPlanningError(Object error) {
  if (error is! PostgrestException) return error.toString();
  final message = error.message;
  const prefix = 'No planned vacancy covers the full interval for role ';
  if (message.startsWith(prefix))
    return 'No positions are available for ${message.substring(prefix.length)} during the selected period. Review Personnel assignments or choose other dates. Reopen this form to refresh availability if needed.';
  if (message.contains('Worker already has planning'))
    return 'This worker already has a plan overlapping these dates. Review their assignments or choose another period.';
  if (message.contains('Worker already belongs to a crew'))
    return 'This worker already belongs to another crew during this period. Review the crew membership dates.';
  if (message.contains('No planned vacancy'))
    return 'No position is available for the full period. Review Personnel or choose other dates.';
  return 'Could not save the plan. $message';
}
