import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'daily_report_service.g.dart';

@riverpod
DailyReportService dailyReportService(DailyReportServiceRef ref) {
  return DailyReportService(ref.watch(supabaseClientProvider));
}

class DailyReportService {
  final SupabaseClient _supabase;

  DailyReportService(this._supabase);

  // ── Daily Reports CRUD ──

  Future<List<Map<String, dynamic>>> getReportsByProject(String projectId) async {
    final response = await _supabase
        .from('daily_reports')
        .select()
        .eq('project_id', projectId)
        .order('report_date', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> getReportById(String id) async {
    final response = await _supabase
        .from('daily_reports')
        .select()
        .eq('id', id)
        .single();
    return response;
  }

  Future<Map<String, dynamic>?> getReportByDate(String projectId, String date) async {
    final response = await _supabase
        .from('daily_reports')
        .select()
        .eq('project_id', projectId)
        .eq('report_date', date)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>> createReport(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('daily_reports')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>> getOrCreateTodayReport(String projectId) async {
    final recent = await _supabase
        .from('daily_reports')
        .select()
        .eq('project_id', projectId)
        .eq('status', 'draft')
        .order('report_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (recent != null) return recent;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final existing = await getReportByDate(projectId, today);
    if (existing != null) return existing;

    final currentUserId = _supabase.auth.currentUser?.id;
    return createReport({
      'project_id': projectId,
      'report_date': today,
      'supervisor_id': currentUserId,
      'status': 'draft',
    });
  }

  Future<void> updateReport(String id, Map<String, dynamic> data) async {
    await _supabase.from('daily_reports').update(data).eq('id', id);
  }

  Future<void> submitReport(String id) async {
    await _supabase.from('daily_reports').update({
      'status': 'submitted',
    }).eq('id', id);
  }

  Future<void> approveReport(String id) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    await _supabase.from('daily_reports').update({
      'status': 'approved',
      'approved_by': currentUserId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteReport(String id) async {
    await _supabase.from('daily_reports').delete().eq('id', id);
  }

  // ── Labor Logs ──

  Future<List<Map<String, dynamic>>> getLaborLogsForReport(String reportId) async {
    final response = await _supabase
        .from('report_labor_logs')
        .select('*, workers(full_name, id_number), deviation_reasons(code, description), project_tasks(name)')
        .eq('daily_report_id', reportId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveLaborLogs(String reportId, List<Map<String, dynamic>> logs) async {
    await _supabase.from('report_labor_logs').delete().eq('daily_report_id', reportId);
    if (logs.isEmpty) return;
    await _supabase.from('report_labor_logs').insert(
      logs.map((log) => {
        ...log,
        'daily_report_id': reportId,
      }).toList(),
    );
  }

  // ── Machinery Logs ──

  Future<List<Map<String, dynamic>>> getMachineryLogsForReport(String reportId) async {
    final response = await _supabase
        .from('report_machinery_logs')
        .select('*, machinery(description), workers!operator_id(full_name, id_number), deviation_reasons(code, description)')
        .eq('daily_report_id', reportId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveMachineryLogs(String reportId, List<Map<String, dynamic>> logs) async {
    await _supabase.from('report_machinery_logs').delete().eq('daily_report_id', reportId);
    if (logs.isEmpty) return;
    await _supabase.from('report_machinery_logs').insert(
      logs.map((log) => {
        ...log,
        'daily_report_id': reportId,
      }).toList(),
    );
  }

  // ── Material Usage ──

  Future<List<Map<String, dynamic>>> getMaterialUsageForReport(String reportId) async {
    final response = await _supabase
        .from('report_material_usage')
        .select('*, materials(description, unit)')
        .eq('daily_report_id', reportId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveMaterialUsage(String reportId, List<Map<String, dynamic>> usage) async {
    await _supabase.from('report_material_usage').delete().eq('daily_report_id', reportId);
    if (usage.isEmpty) return;
    await _supabase.from('report_material_usage').insert(
      usage.map((u) => {
        ...u,
        'daily_report_id': reportId,
      }).toList(),
    );
  }

  // ── Planned Resources (read-only from existing planning tables) ──

  Future<List<Map<String, dynamic>>> getPlannedLaborForProject(
      String projectId, String date, {bool filterByDate = true}) async {
    final response = await _supabase
        .from('project_labor')
        .select('*, quote_services(name), labor_roles(id, description, hourly_rate, internal_cost_rate), '
            'project_labor_assignments(*, workers(*))')
        .eq('project_id', projectId)
        .order('role_name');
    final result = List<Map<String, dynamic>>.from(response ?? []);
    if (!filterByDate) return result;
    for (final pl in result) {
      final List assignments = pl['project_labor_assignments'] ?? [];
      pl['project_labor_assignments'] = assignments.where((a) {
        final start = a['start_date'] as String?;
        final end = a['end_date'] as String?;
        if (start == null || end == null) return false;
        try {
          final startDate = DateTime.parse(start.split(' ')[0]);
          final endDate = DateTime.parse(end.split(' ')[0]);
          final reportDate = DateTime.parse(date);
          return !reportDate.isBefore(startDate) && !reportDate.isAfter(endDate);
        } catch (_) {
          return false;
        }
      }).toList();
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getPlannedMachineryForProject(
      String projectId, String date) async {
    final response = await _supabase
        .from('project_machinery')
        .select('*, machinery(description, fuel_gallons, machinery_type, operator_role_id, capacity_yards), machinery_inspections(internal_id), quote_services(name, unit_of_measure)')
        .eq('project_id', projectId)
        .order('machinery_name');
    final result = List<Map<String, dynamic>>.from(response ?? []);
    result.retainWhere((pm) {
      final start = pm['start_date'] as String?;
      final end = pm['end_date'] as String?;
      if (start == null) return true;
      if (end == null) return true;
      try {
        final sd = DateTime.parse(start.split(' ')[0]);
        final ed = DateTime.parse(end.split(' ')[0]);
        final rd = DateTime.parse(date);
        return !rd.isBefore(sd) && !rd.isAfter(ed);
      } catch (_) {
        return true;
      }
    });
    return result;
  }

  Future<List<Map<String, dynamic>>> getPlannedMaterialsForProject(
      String projectId, String date) async {
    final response = await _supabase
        .from('project_materials')
        .select('*, materials(description, unit), quote_services(name)')
        .eq('project_id', projectId)
        .order('material_name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getProjectTasks(String projectId) async {
    final response = await _supabase
        .from('project_tasks')
        .select('id, name')
        .eq('project_id', projectId)
        .order('name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getDeviationReasons({String? category}) async {
    var query = _supabase.from('deviation_reasons').select();
    query = category != null ? query.eq('category', category) : query;
    final response = await query.order('category');
    return List<Map<String, dynamic>>.from(response ?? []);
  }
}
