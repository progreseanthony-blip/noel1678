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

  Future<List<Map<String, dynamic>>> calculatePeriod(String periodId) async {
    final period = await _supabase
        .from('payroll_periods')
        .select('project_id, start_date, end_date')
        .eq('id', periodId)
        .single();
    final projectId = period['project_id'] as String;
    final startDate = period['start_date'] as String;
    final endDate = period['end_date'] as String;

    final reports = await _supabase
        .from('daily_reports')
        .select('id')
        .eq('project_id', projectId)
        .gte('report_date', startDate)
        .lte('report_date', endDate);

    if (reports.isEmpty) {
      await _supabase.from('payroll_periods').update({
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_workers': 0,
        'total_cost': 0,
        'status': 'calculated',
      }).eq('id', periodId);
      return [];
    }

    final reportIds = (reports as List).map((r) => r['id'] as String).toList();

    final logs = await _supabase
        .from('report_labor_logs')
        .select('''
          regular_hours, overtime_hours, worker_id,
          workers(full_name, role_id, labor_roles(id, description, hourly_rate))
        ''')
        .in_('daily_report_id', reportIds);

    final Map<String, Map<String, dynamic>> agg = {};
    for (final log in logs) {
      final wid = log['worker_id'] as String?;
      if (wid == null) continue;
      final w = log['workers'] as Map<String, dynamic>? ?? {};
      final role = w['labor_roles'] as Map<String, dynamic>? ?? {};

      agg.putIfAbsent(wid, () => {
        'worker_id': wid,
        'full_name': w['full_name'] ?? '',
        'role_id': role['id'],
        'role_name': role['description'] ?? '',
        'hourly_rate': (role['hourly_rate'] ?? 0).toDouble(),
        'regular_hours': 0.0,
        'overtime_hours': 0.0,
      });

      agg[wid]!['regular_hours'] =
          (agg[wid]!['regular_hours'] as num) + (log['regular_hours'] ?? 0);
      agg[wid]!['overtime_hours'] =
          (agg[wid]!['overtime_hours'] as num) + (log['overtime_hours'] ?? 0);
    }

    final entries = agg.values.toList();

    num totalReg = 0, totalOT = 0, totalCost = 0;
    for (final entry in entries) {
      final reg = (entry['regular_hours'] as num);
      final ot = (entry['overtime_hours'] as num);
      final rate = (entry['hourly_rate'] as num);
      final cost = (reg + ot) * rate;
      entry['total_pay'] = cost;
      totalReg += reg;
      totalOT += ot;
      totalCost += cost;
    }

    await _supabase.from('payroll_periods').update({
      'total_regular_hours': totalReg,
      'total_overtime_hours': totalOT,
      'total_workers': entries.length,
      'total_cost': totalCost,
      'status': 'calculated',
    }).eq('id', periodId);

    return entries;
  }

  Future<Map<String, dynamic>> calculateVirtualPeriod(
    String projectId,
    String startDate,
    String endDate,
  ) async {
    final reports = await _supabase
        .from('daily_reports')
        .select('id')
        .eq('project_id', projectId)
        .gte('report_date', startDate)
        .lte('report_date', endDate);

    if (reports.isEmpty) {
      return {
        'entries': <Map<String, dynamic>>[],
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_workers': 0,
        'total_cost': 0,
      };
    }

    final reportIds = (reports as List).map((r) => r['id'] as String).toList();

    final logs = await _supabase
        .from('report_labor_logs')
        .select('''
          regular_hours, overtime_hours, worker_id,
          workers(full_name, role_id, labor_roles(id, description, hourly_rate))
        ''')
        .in_('daily_report_id', reportIds);

    final Map<String, Map<String, dynamic>> agg = {};
    for (final log in logs) {
      final wid = log['worker_id'] as String?;
      if (wid == null) continue;
      final w = log['workers'] as Map<String, dynamic>? ?? {};
      final role = w['labor_roles'] as Map<String, dynamic>? ?? {};

      agg.putIfAbsent(wid, () => {
        'worker_id': wid,
        'full_name': w['full_name'] ?? '',
        'role_id': role['id'],
        'role_name': role['description'] ?? '',
        'hourly_rate': (role['hourly_rate'] ?? 0).toDouble(),
        'regular_hours': 0.0,
        'overtime_hours': 0.0,
      });

      agg[wid]!['regular_hours'] =
          (agg[wid]!['regular_hours'] as num) + (log['regular_hours'] ?? 0);
      agg[wid]!['overtime_hours'] =
          (agg[wid]!['overtime_hours'] as num) + (log['overtime_hours'] ?? 0);
    }

    final entries = agg.values.toList();

    num totalReg = 0, totalOT = 0, totalCost = 0;
    for (final entry in entries) {
      final reg = (entry['regular_hours'] as num);
      final ot = (entry['overtime_hours'] as num);
      final rate = (entry['hourly_rate'] as num);
      final cost = (reg + ot) * rate;
      entry['total_pay'] = cost;
      totalReg += reg;
      totalOT += ot;
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

  Future<void> closePeriod(String id) async {
    await _supabase.from('payroll_periods').update({
      'status': 'closed',
    }).eq('id', id);
  }
}
