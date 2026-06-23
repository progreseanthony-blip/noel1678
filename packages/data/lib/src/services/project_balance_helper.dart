import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectBalanceHelper {
  /// Returns a map of project_material_id -> total quantity_used from submitted/approved reports
  static Future<Map<String, double>> getMaterialUsage(
    SupabaseClient supabase, String projectId,
  ) async {
    final result = await supabase.from('report_material_usage').select('''
      project_material_id, quantity_used,
      daily_reports!inner(status),
      project_materials!inner(project_id)
    ''').eq('project_materials.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);

    final map = <String, double>{};
    for (final row in result ?? []) {
      final id = row['project_material_id']?.toString();
      final qty = (row['quantity_used'] as num?)?.toDouble() ?? 0;
      if (id != null) {
        map[id] = (map[id] ?? 0) + qty;
      }
    }
    return map;
  }

  /// Returns estimation targets per (quote_service_id, machine_id):
  /// { quoteServiceId: { machineId: { capacity_per_trip, trips_per_day, performance_per_day, _machine_name } } }
  static Future<Map<String, Map<String, Map<String, dynamic>>>> getMachineryEstimationTargets(
    SupabaseClient supabase, String projectId,
  ) async {
    final svcIds = await supabase.from('project_machinery').select('quote_service_id').eq('project_id', projectId);
    final ids = (svcIds ?? []).map((r) => r['quote_service_id']?.toString()).whereType<String>().toSet().toList();
    if (ids.isEmpty) return {};

    final result = await supabase.from('quote_service_estimations').select('''
      quote_service_id,
      quote_service_estimation_resources(
        machine_id, capacity_per_trip, trips_per_day, performance_per_day,
        machinery!inner(description)
      )
    ''').in_('quote_service_id', ids);

    final map = <String, Map<String, Map<String, dynamic>>>{};
    for (final row in result ?? []) {
      final qsId = row['quote_service_id']?.toString();
      if (qsId == null) continue;
      final resources = row['quote_service_estimation_resources'] as List? ?? [];
      final byMachine = <String, Map<String, dynamic>>{};
      for (final res in resources) {
        final mId = (res as Map)['machine_id']?.toString();
        if (mId == null) continue;
        final machinery = (res as Map)['machinery'] as Map? ?? {};
        byMachine[mId] = {
          'capacity_per_trip': ((res as Map)['capacity_per_trip'] as num?)?.toDouble() ?? 0,
          'trips_per_day': ((res as Map)['trips_per_day'] as num?)?.toDouble() ?? 0,
          'performance_per_day': ((res as Map)['performance_per_day'] as num?)?.toDouble() ?? 0,
          '_machine_name': (machinery['description'] as String? ?? '').toLowerCase(),
        };
      }
      if (byMachine.isNotEmpty) map[qsId] = byMachine;
    }
    return map;
  }

  /// Returns a map of project_machinery_id -> total raw production_value
  /// from submitted/approved reports (without capacity_yards multiplication).
  /// Trip-based multiplication is applied in step_machinery.dart after estimation data is loaded.
  static Future<Map<String, double>> getMachineryProduction(
    SupabaseClient supabase, String projectId,
  ) async {
    final result = await supabase.from('report_machinery_logs').select('''
      project_machinery_id, production_value,
      machinery!inner(capacity_yards),
      daily_reports!inner(status),
      project_machinery!inner(project_id)
    ''').eq('project_machinery.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);

    final map = <String, double>{};
    for (final row in result ?? []) {
      final id = row['project_machinery_id']?.toString();
      final prod = (row['production_value'] as num?)?.toDouble() ?? 0;
      if (id != null) {
        map[id] = (map[id] ?? 0) + prod;
      }
    }
    return map;
  }

  /// Returns per-entry production values keyed by project_machinery_id,
  /// preserving individual machine values (not aggregated).
  /// Entry order matches report_machinery_logs.id (creation order).
  static Future<Map<String, List<double>>> getMachineryProductionPerEntry(
    SupabaseClient supabase, String projectId,
  ) async {
    final result = await supabase.from('report_machinery_logs').select('''
      id, project_machinery_id, production_value,
      daily_reports!inner(status),
      project_machinery!inner(project_id)
    ''').eq('project_machinery.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved'])
        .order('id');

    final map = <String, List<double>>{};
    for (final row in result ?? []) {
      final pmId = row['project_machinery_id']?.toString();
      final prod = (row['production_value'] as num?)?.toDouble() ?? 0;
      if (pmId != null) {
        map.putIfAbsent(pmId, () => []).add(prod);
      }
    }
    return map;
  }
}
