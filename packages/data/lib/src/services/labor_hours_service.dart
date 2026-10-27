import 'package:supabase_flutter/supabase_flutter.dart';

/// Operational projection: never reads or recalculates financial payroll rows.
class LaborHoursService {
  final SupabaseClient client;
  LaborHoursService(this.client);

  Future<List<Map<String, dynamic>>> projects() async =>
      rows(await client.rpc('get_labor_hours_projects'));

  Future<Map<String, dynamic>> query(
    String project,
    String start,
    String end, {
    String? crew,
  }) async => Map<String, dynamic>.from(
    await client.rpc(
          'get_labor_hours',
          params: {
            'p_project': project,
            'p_start': start,
            'p_end': end,
            'p_crew': crew,
          },
        )
        as Map,
  );

  static List<Map<String, dynamic>> rows(dynamic value) =>
      (value as List? ?? [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();

  /// Shared by the screen and both existing time-report PDF templates.
  static List<Map<String, dynamic>> workers(
    List<Map<String, dynamic>> entries,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final row in entries.where((r) => r['validated'] == true)) {
      final worker = result.putIfAbsent(
        row['worker_id'] as String,
        () => {
          'worker_id': row['worker_id'],
          'full_name': row['worker'],
          'id_number': row['id_number'] ?? '',
          'role_name': row['role'] ?? '',
          'regular_hours': 0.0,
          'overtime_hours': 0.0,
          'total_hours': 0.0,
        },
      );
      for (final field in ['regular_hours', 'overtime_hours']) {
        worker[field] = (worker[field] as num) + (row[field] as num? ?? 0);
      }
      worker['total_hours'] =
          (worker['total_hours'] as num) + (row['net_hours'] as num? ?? 0);
    }
    return result.values.toList()..sort(
      (a, b) => (a['full_name'] as String).compareTo(b['full_name'] as String),
    );
  }
}
