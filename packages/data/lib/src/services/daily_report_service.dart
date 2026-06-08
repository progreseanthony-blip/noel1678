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

  Future<void> rejectReport(String id, {String? reason}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final updates = <String, dynamic>{
      'status': 'rejected',
      'approved_by': currentUserId,
      'approved_at': DateTime.now().toIso8601String(),
    };
    if (reason != null && reason.isNotEmpty) {
      final current = await _supabase.from('daily_reports').select('general_notes').eq('id', id).maybeSingle();
      final existing = current?['general_notes'] as String? ?? '';
      updates['general_notes'] = existing.isNotEmpty
          ? '$existing\n\nRejection reason: $reason'
          : 'Rejection reason: $reason';
    }
    await _supabase.from('daily_reports').update(updates).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getSubmittedReports() async {
    final response = await _supabase
        .from('daily_reports')
        .select('*, projects(title)')
        .eq('status', 'submitted')
        .order('report_date', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
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

  static const _laborColumns = [
    'id', 'daily_report_id', 'worker_id', 'project_labor_id', 'project_task_id',
    'check_in_time', 'check_out_time', 'regular_hours', 'overtime_hours',
    'is_unplanned', 'deviation_reason_id', 'notes', 'created_at',
  ];

  Future<void> saveLaborLogs(String reportId, List<Map<String, dynamic>> logs) async {
    await _supabase.from('report_labor_logs').delete().eq('daily_report_id', reportId);
    if (logs.isEmpty) return;
    await _supabase.from('report_labor_logs').insert(
      logs.map((log) {
        final clean = {for (final k in _laborColumns) if (log.containsKey(k)) k: log[k]};
        clean['daily_report_id'] = reportId;
        return clean;
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

  static const _machineryColumns = [
    'id', 'daily_report_id', 'machinery_id', 'project_machinery_id', 'operator_id',
    'start_meter', 'end_meter', 'total_hours', 'fuel_added',
    'is_unplanned', 'deviation_reason_id', 'notes', 'created_at',
    'production_value', 'production_unit', 'start_shift_photos', 'end_shift_photos',
  ];

  Future<void> saveMachineryLogs(String reportId, List<Map<String, dynamic>> logs) async {
    if (logs.any((l) => l['operator_id'] == null || l['machinery_id'] == null)) {
      throw Exception('All machinery logs must have operator_id and machinery_id');
    }
    if (logs.isEmpty) return;
    await _supabase.from('report_machinery_logs').delete().eq('daily_report_id', reportId);
    await _supabase.from('report_machinery_logs').insert(
      logs.map((log) {
        final clean = {for (final k in _machineryColumns) if (log.containsKey(k)) k: log[k]};
        clean['daily_report_id'] = reportId;
        return clean;
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

  static const _materialColumns = [
    'id', 'daily_report_id', 'material_id', 'project_material_id',
    'quantity_used', 'area_installed', 'unit', 'notes', 'created_at',
  ];

  Future<void> saveMaterialUsage(String reportId, List<Map<String, dynamic>> usage) async {
    await _supabase.from('report_material_usage').delete().eq('daily_report_id', reportId);
    if (usage.isEmpty) return;
    await _supabase.from('report_material_usage').insert(
      usage.map((u) {
        final clean = {for (final k in _materialColumns) if (u.containsKey(k)) k: u[k]};
        clean['daily_report_id'] = reportId;
        return clean;
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
