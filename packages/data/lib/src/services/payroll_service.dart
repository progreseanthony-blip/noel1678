import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'payroll_service.g.dart';

@riverpod
PayrollService payrollService(PayrollServiceRef ref) {
  return PayrollService(ref.watch(supabaseClientProvider));
}

class PayrollService {
  final SupabaseClient _supabase;

  PayrollService(this._supabase);

  // ── ISO week helper (ISO 8601) ──

  static int _isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(jan1).inDays;
    return (dayOfYear ~/ 7) + 1;
  }

  // ── Weekly OT calculator ──

  static Map<String, dynamic> _calcWeeklyOT(List<Map<String, dynamic>> logs) {
    // Group by worker_id, then by ISO week
    final Map<String, Map<int, double>> workerWeeklyHours = {};
    final Map<String, Map<String, dynamic>> workerInfo = {};

    for (final log in logs) {
      final wid = log['worker_id'] as String?;
      if (wid == null) continue;

      final dateStr = log['daily_reports']?['report_date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.parse(dateStr);
      final week = _isoWeek(date);

      workerWeeklyHours.putIfAbsent(wid, () => {});
      final net = (log['total_net_hours'] as num?)?.toDouble() ?? 0;
      workerWeeklyHours[wid]![week] = (workerWeeklyHours[wid]![week] ?? 0) + net;

      if (!workerInfo.containsKey(wid)) {
        final w = log['workers'] as Map<String, dynamic>? ?? {};
        final role = w['labor_roles'] as Map<String, dynamic>? ?? {};
        workerInfo[wid] = {
          'worker_id': wid,
          'full_name': w['full_name'] ?? '',
          'role_id': role['id'],
          'role_name': role['description'] ?? '',
          'hourly_rate': (role['hourly_rate'] ?? 0).toDouble(),
        };
      }
    }

    double totalReg = 0, totalOT = 0, totalCost = 0;
    final List<Map<String, dynamic>> entries = [];

    for (final wid in workerInfo.keys) {
      final info = workerInfo[wid]!;
      final weeklyHours = workerWeeklyHours[wid] ?? {};
      final rate = (info['hourly_rate'] as num).toDouble();

      double workerReg = 0, workerOT = 0;
      for (final weekHours in weeklyHours.values) {
        workerReg += weekHours > 40 ? 40 : weekHours;
        workerOT += weekHours > 40 ? weekHours - 40 : 0;
      }

      final cost = (workerReg * rate) + (workerOT * rate * 1.5);
      info['regular_hours'] = workerReg;
      info['overtime_hours'] = workerOT;
      info['total_pay'] = cost;
      entries.add(Map<String, dynamic>.from(info));

      totalReg += workerReg;
      totalOT += workerOT;
      totalCost += cost;
    }

    return {
      'entries': entries,
      'total_regular_hours': totalReg,
      'total_overtime_hours': totalOT,
      'total_workers': entries.length,
      'total_cost': totalCost,
    };
  }

  // ── CRUD ──

  Future<List<Map<String, dynamic>>> getPeriods(String projectId) async {
    final response = await _supabase
        .from('payroll_periods')
        .select()
        .eq('project_id', projectId)
        .order('end_date', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> getPeriod(String id) async {
    final response = await _supabase
        .from('payroll_periods')
        .select()
        .eq('id', id)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> createPeriod(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('payroll_periods')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updatePeriod(String id, Map<String, dynamic> data) async {
    await _supabase.from('payroll_periods').update(data).eq('id', id);
  }

  Future<void> deletePeriod(String id) async {
    await _supabase.from('payroll_periods').delete().eq('id', id);
  }

  // ── Period calculation ──

  Future<List<Map<String, dynamic>>> _fetchLogs(String projectId, String startDate, String endDate) async {
    final reports = await _supabase
        .from('daily_reports')
        .select('id')
        .eq('project_id', projectId)
        .gte('report_date', startDate)
        .lte('report_date', endDate);

    if (reports.isEmpty) return [];

    final reportIds = (reports as List).map((r) => r['id'] as String).toList();

    final logs = await _supabase
        .from('report_labor_logs')
        .select('''
          total_net_hours, worker_id,
          daily_reports!inner(report_date),
          workers(full_name, role_id, labor_roles(id, description, hourly_rate))
        ''')
        .in_('daily_report_id', reportIds);

    return List<Map<String, dynamic>>.from(logs ?? []);
  }

  Future<List<Map<String, dynamic>>> calculatePeriod(String periodId) async {
    final period = await _supabase
        .from('payroll_periods')
        .select('project_id, start_date, end_date')
        .eq('id', periodId)
        .single();
    final projectId = period['project_id'] as String;
    final startDate = period['start_date'] as String;
    final endDate = period['end_date'] as String;

    final logs = await _fetchLogs(projectId, startDate, endDate);

    if (logs.isEmpty) {
      await _supabase.from('payroll_periods').update({
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_workers': 0,
        'total_cost': 0,
        'status': 'calculated',
      }).eq('id', periodId);
      return [];
    }

    final result = _calcWeeklyOT(logs);
    final entries = result['entries'] as List<Map<String, dynamic>>;

    await _supabase.from('payroll_periods').update({
      'total_regular_hours': result['total_regular_hours'],
      'total_overtime_hours': result['total_overtime_hours'],
      'total_workers': result['total_workers'],
      'total_cost': result['total_cost'],
      'status': 'calculated',
    }).eq('id', periodId);

    return entries;
  }

  Future<Map<String, dynamic>> calculateVirtualPeriod(
    String projectId,
    String startDate,
    String endDate,
  ) async {
    final logs = await _fetchLogs(projectId, startDate, endDate);

    if (logs.isEmpty) {
      return {
        'entries': <Map<String, dynamic>>[],
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_workers': 0,
        'total_cost': 0,
      };
    }

    return _calcWeeklyOT(logs);
  }

  Future<void> closePeriod(String id) async {
    await _supabase.from('payroll_periods').update({
      'status': 'closed',
    }).eq('id', id);
  }
}
