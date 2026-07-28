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

  static Map<String, dynamic> _calcWeeklyOT(List<Map<String, dynamic>> logs, [List<Map<String, dynamic>> machineryLogs = const []]) {
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
      info['rate_uplift'] = 0.0;
      entries.add(Map<String, dynamic>.from(info));

      totalReg += workerReg;
      totalOT += workerOT;
      totalCost += cost;
    }

    // Apply rate uplift from machinery logs
    for (final m in machineryLogs) {
      final wid = m['operator_id'] as String?;
      if (wid == null || !workerInfo.containsKey(wid)) continue;
      final override = (m['rate_override'] as num?)?.toDouble() ?? 0;
      final hours = (m['total_hours'] as num?)?.toDouble() ?? 0;
      final baseRate = (workerInfo[wid]!['hourly_rate'] as num).toDouble();
      if (override > baseRate && hours > 0) {
        final uplift = (override - baseRate) * hours;
        workerInfo[wid]!['rate_uplift'] = (workerInfo[wid]!['rate_uplift'] as num).toDouble() + uplift;
        totalCost += uplift;
      }
    }

    // Update total_pay with uplift
    for (final entry in entries) {
      final uplift = entry['rate_uplift'] as double;
      if (uplift > 0) {
        entry['total_pay'] = (entry['total_pay'] as num).toDouble() + uplift;
      }
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
          workers(full_name, id_number, role_id, labor_roles(id, description, hourly_rate))
        ''')
        .in_('daily_report_id', reportIds);

    return List<Map<String, dynamic>>.from(logs ?? []);
  }

  Future<List<Map<String, dynamic>>> _fetchMachineryLogs(String projectId, String startDate, String endDate) async {
    final reports = await _supabase
        .from('daily_reports')
        .select('id')
        .eq('project_id', projectId)
        .gte('report_date', startDate)
        .lte('report_date', endDate);

    if (reports.isEmpty) return [];

    final reportIds = (reports as List).map((r) => r['id'] as String).toList();

    final logs = await _supabase
        .from('report_machinery_logs')
        .select('operator_id, total_hours, rate_override')
        .in_('daily_report_id', reportIds)
        .not('rate_override', 'is', null);

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
    final machLogs = await _fetchMachineryLogs(projectId, startDate, endDate);

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

    final result = _calcWeeklyOT(logs, machLogs);
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
    final machLogs = await _fetchMachineryLogs(projectId, startDate, endDate);

    if (logs.isEmpty) {
      return {
        'entries': <Map<String, dynamic>>[],
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_workers': 0,
        'total_cost': 0,
      };
    }

    return _calcWeeklyOT(logs, machLogs);
  }

  // ── Worker sign-off report helpers ──

  Future<Map<String, dynamic>> getWorkerDetailedLogs(String periodId) async {
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
      return {
        'workers': <Map<String, dynamic>>[],
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_hours': 0,
        'total_workers': 0,
      };
    }

    // Group by worker_id using the same OT logic but returning only hours
    final result = _calcWeeklyOT(logs, []);
    final entries = result['entries'] as List<Map<String, dynamic>>;

    // Rebuild entries without pay info, add id_number
    final workers = <Map<String, dynamic>>[];
    for (final e in entries) {
      // Fetch worker id_number from the original logs
      final wid = e['worker_id'] as String?;
      String? idNumber;
      if (wid != null) {
        for (final log in logs) {
          if (log['worker_id'] == wid) {
            final w = log['workers'] as Map<String, dynamic>?;
            idNumber = w?['id_number'] as String?;
            if (idNumber != null) break;
          }
        }
      }
      workers.add({
        'worker_id': e['worker_id'],
        'full_name': e['full_name'],
        'id_number': idNumber ?? '',
        'role_name': e['role_name'],
        'regular_hours': e['regular_hours'],
        'overtime_hours': e['overtime_hours'],
        'total_hours': (e['regular_hours'] as num) + (e['overtime_hours'] as num),
      });
    }

    return {
      'workers': workers,
      'total_regular_hours': result['total_regular_hours'],
      'total_overtime_hours': result['total_overtime_hours'],
      'total_hours': (result['total_regular_hours'] as num) + (result['total_overtime_hours'] as num),
      'total_workers': workers.length,
    };
  }

  Future<Map<String, dynamic>> getDailyLogsForWorker(String periodId, String workerId) async {
    final period = await _supabase
        .from('payroll_periods')
        .select('project_id, start_date, end_date')
        .eq('id', periodId)
        .single();
    final projectId = period['project_id'] as String;
    final startDate = period['start_date'] as String;
    final endDate = period['end_date'] as String;

    // Fetch daily reports in the period
    final reports = await _supabase
        .from('daily_reports')
        .select('id, report_date')
        .eq('project_id', projectId)
        .gte('report_date', startDate)
        .lte('report_date', endDate);

    if (reports.isEmpty) {
      return {
        'worker': null,
        'daily_logs': <Map<String, dynamic>>[],
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_hours': 0,
      };
    }

    final reportIds = (reports as List).map((r) => r['id'] as String).toList();
    // Build a date lookup by report id
    final Map<String, String> reportDates = {};
    for (final r in reports) {
      reportDates[r['id'] as String] = r['report_date'] as String;
    }

    final logs = await _supabase
        .from('report_labor_logs')
        .select('''
          daily_report_id, check_in_time, check_out_time,
          regular_hours, overtime_hours, break_minutes,
          total_net_hours, notes,
          daily_reports!inner(report_date),
          workers!inner(full_name, id_number, labor_roles(id, description, hourly_rate))
        ''')
        .in_('daily_report_id', reportIds)
        .eq('worker_id', workerId)
        .order('daily_report_id', ascending: true);

    final logList = List<Map<String, dynamic>>.from(logs ?? []);
    if (logList.isEmpty) {
      return {
        'worker': null,
        'daily_logs': <Map<String, dynamic>>[],
        'total_regular_hours': 0,
        'total_overtime_hours': 0,
        'total_hours': 0,
      };
    }

    // Extract worker info from first log
    final firstLog = logList.first;
    final w = firstLog['workers'] as Map<String, dynamic>? ?? {};
    final role = w['labor_roles'] as Map<String, dynamic>? ?? {};
    final workerInfo = {
      'full_name': w['full_name'] ?? '',
      'id_number': w['id_number'] ?? '',
      'role_name': role['description'] ?? '',
    };

    // Build daily logs with date from the report
    final dailyLogs = <Map<String, dynamic>>[];
    double totalReg = 0, totalOT = 0;

    for (final log in logList) {
      final reportId = log['daily_report_id'] as String?;
      final dateStr = reportDates[reportId] ?? log['daily_reports']?['report_date'] as String? ?? '';
      final reg = (log['regular_hours'] as num?)?.toDouble() ?? 0;
      final ot = (log['overtime_hours'] as num?)?.toDouble() ?? 0;
      dailyLogs.add({
        'date': dateStr,
        'check_in': log['check_in_time'] as String? ?? '',
        'check_out': log['check_out_time'] as String? ?? '',
        'regular_hours': reg,
        'overtime_hours': ot,
        'break_minutes': log['break_minutes'] as int? ?? 0,
        'net_hours': (log['total_net_hours'] as num?)?.toDouble() ?? 0,
        'notes': log['notes'] as String? ?? '',
      });
      totalReg += reg;
      totalOT += ot;
    }

    dailyLogs.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    return {
      'worker': workerInfo,
      'daily_logs': dailyLogs,
      'total_regular_hours': totalReg,
      'total_overtime_hours': totalOT,
      'total_hours': totalReg + totalOT,
    };
  }

  Future<void> closePeriod(String id) async {
    await _supabase.from('payroll_periods').update({
      'status': 'closed',
    }).eq('id', id);
  }
}
