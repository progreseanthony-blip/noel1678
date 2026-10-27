import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';
import 'labor_hours_service.dart';

part 'payroll_service.g.dart';

@riverpod
PayrollService payrollService(PayrollServiceRef ref) {
  return PayrollService(ref.watch(supabaseClientProvider));
}

class PayrollService {
  final SupabaseClient _supabase;

  PayrollService(this._supabase);

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

  Future<Map<String, dynamic>> calculateVirtualPeriod(
    String projectId,
    String startDate,
    String endDate,
  ) async {
    final data = Map<String, dynamic>.from(
      await _supabase.rpc(
            'get_labor_payroll_data',
            params: {
              'p_project': projectId,
              'p_start': startDate,
              'p_end': endDate,
            },
          )
          as Map,
    );
    final rows = LaborHoursService.rows(data['rows']);
    final entries = LaborHoursService.workers(rows);
    for (final entry in entries) {
      final row = rows.firstWhere((r) => r['worker_id'] == entry['worker_id']);
      final rate = (row['hourly_rate'] as num? ?? 0).toDouble();
      entry.addAll({
        'hourly_rate': rate,
        'role_id': row['role_id'],
        'rate_uplift': 0.0,
        'total_pay':
            (entry['regular_hours'] as num) * rate +
            (entry['overtime_hours'] as num) * rate * 1.5,
      });
    }
    for (final machine in LaborHoursService.rows(data['machinery'])) {
      final matching = entries.where(
        (e) => e['worker_id'] == machine['operator_id'],
      );
      if (matching.isEmpty) continue;
      final entry = matching.first;
      final difference =
          (machine['rate_override'] as num? ?? 0) -
          (entry['hourly_rate'] as num);
      final hours = (machine['total_hours'] as num? ?? 0);
      if (difference <= 0 || hours <= 0) continue;
      final uplift = difference * hours;
      entry['rate_uplift'] = (entry['rate_uplift'] as num) + uplift;
      entry['total_pay'] = (entry['total_pay'] as num) + uplift;
    }
    num total(String field) =>
        entries.fold<num>(0, (sum, e) => sum + (e[field] as num));
    return {
      'entries': entries,
      'total_workers': entries.length,
      'total_regular_hours': total('regular_hours'),
      'total_overtime_hours': total('overtime_hours'),
      'total_cost': total('total_pay'),
    };
  }

  Future<List<Map<String, dynamic>>> previewPeriod(String periodId) async {
    final period = await getPeriod(periodId);
    final result = await calculateVirtualPeriod(
      period['project_id'],
      period['start_date'],
      period['end_date'],
    );
    return LaborHoursService.rows(result['entries']);
  }

  Future<List<Map<String, dynamic>>> calculatePeriod(String periodId) async {
    final period = await getPeriod(periodId);
    if (period['status'] == 'closed')
      throw StateError('Closed payroll periods cannot be recalculated.');
    final result = await calculateVirtualPeriod(
      period['project_id'],
      period['start_date'],
      period['end_date'],
    );
    // The database also rejects a concurrent close before this update.
    await _supabase
        .from('payroll_periods')
        .update({
          'total_regular_hours': result['total_regular_hours'],
          'total_overtime_hours': result['total_overtime_hours'],
          'total_workers': result['total_workers'],
          'total_cost': result['total_cost'],
          'status': 'calculated',
        })
        .eq('id', periodId);
    return LaborHoursService.rows(result['entries']);
  }

  Future<List<Map<String, dynamic>>> _hours(
    String periodId,
    String? startDate,
    String? endDate,
  ) async {
    final period = await getPeriod(periodId);
    final data = await LaborHoursService(_supabase).query(
      period['project_id'],
      startDate ?? period['start_date'],
      endDate ?? period['end_date'],
    );
    return LaborHoursService.rows(
      data['rows'],
    ).where((r) => r['validated'] == true).toList();
  }

  Future<Map<String, dynamic>> getWorkerDetailedLogs(
    String periodId, {
    String? startDate,
    String? endDate,
  }) async {
    final workers = LaborHoursService.workers(
      await _hours(periodId, startDate, endDate),
    );
    num total(String field) =>
        workers.fold<num>(0, (sum, w) => sum + (w[field] as num));
    return {
      'workers': workers,
      'total_workers': workers.length,
      'total_regular_hours': total('regular_hours'),
      'total_overtime_hours': total('overtime_hours'),
      'total_hours': total('total_hours'),
    };
  }

  Future<Map<String, dynamic>> getDailyLogsForWorker(
    String periodId,
    String workerId, {
    String? startDate,
    String? endDate,
  }) async {
    final rows = (await _hours(
      periodId,
      startDate,
      endDate,
    )).where((r) => r['worker_id'] == workerId).toList();
    final workers = LaborHoursService.workers(rows);
    final worker = workers.isEmpty ? null : workers.first;
    return {
      'worker': worker,
      'daily_logs': rows
          .map(
            (r) => {
              ...r,
              'check_in': r['check_in'] ?? '',
              'check_out': r['check_out'] ?? '',
              'notes': [
                r['service'],
                r['crew'],
                if (r['transfer_id'] != null) 'Temporary loan',
              ].where((v) => v != null).join(' / '),
            },
          )
          .toList(),
      'total_regular_hours': worker?['regular_hours'] ?? 0,
      'total_overtime_hours': worker?['overtime_hours'] ?? 0,
      'total_hours': worker?['total_hours'] ?? 0,
    };
  }

  Future<void> closePeriod(String id) async {
    await _supabase
        .from('payroll_periods')
        .update({'status': 'closed'})
        .eq('id', id);
  }
}
